package com.kernel.sense_ai

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.StandardMethodCodec
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test
import java.nio.ByteBuffer

class InsectSoundChannelTest {
    private class Messenger : BinaryMessenger {
        var handler: BinaryMessenger.BinaryMessageHandler? = null
        var background = false
        override fun send(channel: String, message: ByteBuffer?) = Unit
        override fun send(channel: String, message: ByteBuffer?, callback: BinaryMessenger.BinaryReply?) = Unit
        override fun makeBackgroundTaskQueue(): BinaryMessenger.TaskQueue = object : BinaryMessenger.TaskQueue { }
        override fun setMessageHandler(channel: String, handler: BinaryMessenger.BinaryMessageHandler?) { this.handler = handler }
        override fun setMessageHandler(channel: String, handler: BinaryMessenger.BinaryMessageHandler?, taskQueue: BinaryMessenger.TaskQueue?) {
            assertEquals("com.kernel.sense_ai/insect_sound", channel)
            background = taskQueue != null
            this.handler = handler
        }
        fun call(method: String, args: Any?): Any? {
            val data = StandardMethodCodec.INSTANCE.encodeMethodCall(MethodCall(method,args)).apply { flip() }
            var response: ByteBuffer? = null
            handler!!.onMessage(data) { response = it }
            val bytes = response ?: return null
            bytes.flip()
            return StandardMethodCodec.INSTANCE.decodeEnvelope(bytes)
        }
    }
    @Test fun channelRegistersOffUiThreadDispatchesAndDetaches() {
        val messenger = Messenger()
        val channel = InsectSoundChannel(messenger) { throw AssertionError("No assets for missing file") }
        assertNotNull(messenger.handler)
        assertTrue(messenger.background)
        val result = messenger.call("classifyWavFile",mapOf("path" to "missing-file.wav")) as Map<*,*>
        assertEquals("unavailable",result["status"])
        assertEquals(listOf("file_unreadable"), result["reasons"])
        val invalid = messenger.call("classifyWavFile",emptyMap<String,Any>()) as Map<*,*>
        assertEquals("unavailable",invalid["status"])
        assertEquals(listOf("invalid_path"),invalid["reasons"])
        assertNull(messenger.call("other",null))
        channel.detach()
        assertNull(messenger.handler)
    }
}
