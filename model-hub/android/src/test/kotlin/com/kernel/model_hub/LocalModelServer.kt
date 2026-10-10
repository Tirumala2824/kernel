package com.kernel.model_hub

import java.io.BufferedReader
import java.io.IOException
import java.io.InputStreamReader
import java.io.OutputStream
import java.net.InetAddress
import java.net.ServerSocket
import java.net.Socket
import java.security.MessageDigest
import java.util.Collections
import java.util.concurrent.atomic.AtomicInteger

/**
 * Minimal HTTP/1.1 server on 127.0.0.1 (plain ServerSocket, one request per
 * connection) that behaves like the HF resolver + CDN:
 * `/resolve/model.bin` answers 302 with X-Linked-Size / X-Linked-ETag and a
 * Location on `/cdn/model.bin`, which serves real Range requests.
 * Knobs reproduce the edge cases the downloader must survive.
 */
class LocalModelServer(val content: ByteArray) : AutoCloseable {
    private val socket = ServerSocket(0, 50, InetAddress.getByName("127.0.0.1"))
    private val acceptor: Thread

    val resolveHits = AtomicInteger()
    val cdnHits = AtomicInteger()
    val cdnRequests: MutableList<Map<String, String?>> = Collections.synchronizedList(ArrayList())

    @Volatile var linkedEtag: String? = sha256Hex(content)
    @Volatile var linkedSize: Long? = content.size.toLong()
    @Volatile var ignoreRange = false
    @Volatile var wrongRangeStartOnce = false
    @Volatile var dropAfterBytesOnce: Int? = null
    @Volatile var rateLimitTimes = 0
    @Volatile var redirectLocation: String? = null

    init {
        acceptor = Thread {
            while (!socket.isClosed) {
                val client = try {
                    socket.accept()
                } catch (_: IOException) {
                    break
                }
                Thread { handle(client) }.apply { isDaemon = true }.start()
            }
        }.apply { isDaemon = true }
        acceptor.start()
    }

    val resolveUrl: String get() = "http://127.0.0.1:${socket.localPort}/resolve/model.bin"

    private fun handle(client: Socket) {
        client.use { s ->
            try {
                val reader = BufferedReader(InputStreamReader(s.getInputStream(), Charsets.ISO_8859_1))
                val requestLine = reader.readLine() ?: return
                val headers = HashMap<String, String>()
                while (true) {
                    val line = reader.readLine() ?: break
                    if (line.isEmpty()) break
                    val i = line.indexOf(':')
                    if (i > 0) headers[line.substring(0, i).trim().lowercase()] = line.substring(i + 1).trim()
                }
                val path = requestLine.split(' ').getOrNull(1) ?: "/"
                val out = s.getOutputStream()
                when {
                    path.startsWith("/resolve/") -> resolve(out)
                    path.startsWith("/cdn/") -> cdn(out, headers)
                    else -> respond(out, 404, emptyMap(), ByteArray(0))
                }
            } catch (_: IOException) {
                // Client went away.
            }
        }
    }

    private fun resolve(out: OutputStream) {
        resolveHits.incrementAndGet()
        if (rateLimitTimes > 0) {
            rateLimitTimes--
            respond(out, 429, mapOf("Retry-After" to "1"), ByteArray(0))
            return
        }
        val h = LinkedHashMap<String, String>()
        linkedEtag?.let { h["X-Linked-ETag"] = "\"$it\"" }
        linkedSize?.let { h["X-Linked-Size"] = it.toString() }
        h["Location"] = redirectLocation ?: "/cdn/model.bin?sig=${resolveHits.get()}"
        respond(out, 302, h, ByteArray(0))
    }

    private fun cdn(out: OutputStream, headers: Map<String, String>) {
        cdnHits.incrementAndGet()
        val range = headers["range"]
        cdnRequests.add(mapOf("Range" to range, "Accept-Encoding" to headers["accept-encoding"]))
        val honour = range != null && !ignoreRange
        var start = if (honour) {
            Regex("""bytes=(\d+)-""").find(range!!)?.groupValues?.get(1)?.toLong() ?: 0
        } else {
            0L
        }
        if (honour && start >= content.size) {
            respond(out, 416, mapOf("Content-Range" to "bytes */${content.size}"), ByteArray(0))
            return
        }
        if (honour && wrongRangeStartOnce) {
            wrongRangeStartOnce = false
            start /= 2
        }
        val body = content.copyOfRange(start.toInt(), content.size)
        val h = LinkedHashMap<String, String>()
        val code = if (honour) {
            h["Content-Range"] = "bytes $start-${content.size - 1}/${content.size}"
            206
        } else {
            200
        }
        val drop = dropAfterBytesOnce
        if (drop != null && drop < body.size) {
            dropAfterBytesOnce = null
            // Announce the full length, send only part of it, then close.
            respond(out, code, h, body, sendBytes = drop)
            return
        }
        respond(out, code, h, body)
    }

    private fun respond(
        out: OutputStream,
        code: Int,
        headers: Map<String, String>,
        body: ByteArray,
        sendBytes: Int = body.size,
    ) {
        val sb = StringBuilder("HTTP/1.1 $code X\r\n")
        for ((k, v) in headers) sb.append(k).append(": ").append(v).append("\r\n")
        sb.append("Content-Length: ").append(body.size).append("\r\n")
        sb.append("Connection: close\r\n\r\n")
        out.write(sb.toString().toByteArray(Charsets.ISO_8859_1))
        out.write(body, 0, sendBytes)
        out.flush()
    }

    override fun close() {
        socket.close()
    }

    companion object {
        fun sha256Hex(b: ByteArray): String =
            MessageDigest.getInstance("SHA-256").digest(b).joinToString("") { "%02x".format(it) }
    }
}
