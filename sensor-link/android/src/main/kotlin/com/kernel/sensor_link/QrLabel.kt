package com.kernel.sensor_link

import com.kernel.sensor_link.protocol.SensorTypes

/**
 * Node QR label: `kernel:sensor:v1:<AA:BB:CC:DD:EE:FF>:<base64url key>:<type>`
 * (docs/sensor-protocol.md section 7). Mirrors lib/src/qr.dart; both are
 * tested against firmware/reference/vectors/qr_v1.json.
 */
class QrLabel(val address: String, val key: ByteArray, val sensorType: Int) {
    /** Zero the key copy once it has been imported into the Keystore. */
    fun wipe() = key.fill(0)

    companion object {
        private val TYPES = mapOf(
            "us_air" to SensorTypes.US_AIR,
            "contact_piezo" to SensorTypes.CONTACT_PIEZO,
            "contact_accel" to SensorTypes.CONTACT_ACCEL,
            "audio_air" to SensorTypes.AUDIO_AIR,
        )
        private val HEX2 = Regex("^[0-9A-Fa-f]{2}$")

        fun parse(payload: String): QrLabel {
            if (payload.isEmpty()) throw QrFormatException("empty")
            val parts = payload.split(':')
            if (parts.size < 3 || parts[0] != "kernel" || parts[1] != "sensor") throw QrFormatException("prefix")
            if (parts[2] != "v1") throw QrFormatException("version")
            if (parts.size != 11) throw QrFormatException("fields")
            val octets = parts.subList(3, 9)
            if (!octets.all { HEX2.matches(it) }) throw QrFormatException("address")
            val address = octets.joinToString(":") { it.uppercase() }
            val key = Base64Url.decode(parts[9]) ?: throw QrFormatException("keyEncoding")
            if (key.size != 32) throw QrFormatException("keyLength")
            val type = TYPES[parts[10]] ?: throw QrFormatException("type")
            return QrLabel(address, key, type)
        }
    }
}

class QrFormatException(val reason: String) : IllegalArgumentException("invalid sensor QR label: $reason")

/** RFC 4648 section 5 base64url, padding optional. No android.util dependency (JVM-testable, API 24+). */
object Base64Url {
    private const val ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"

    fun decode(text: String): ByteArray? {
        var s = text
        while (s.endsWith("=")) s = s.dropLast(1)
        if (s.length % 4 == 1) return null
        val out = java.io.ByteArrayOutputStream(s.length * 3 / 4)
        var acc = 0
        var bits = 0
        for (c in s) {
            val v = ALPHABET.indexOf(c)
            if (v < 0) return null
            acc = (acc shl 6) or v
            bits += 6
            if (bits >= 8) {
                bits -= 8
                out.write((acc shr bits) and 0xFF)
            }
        }
        // Leftover bits must be zero in canonical encodings.
        if (bits > 0 && (acc and ((1 shl bits) - 1)) != 0) return null
        return out.toByteArray()
    }
}
