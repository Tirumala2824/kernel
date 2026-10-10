package com.kernel.sensor_link.link

/** Status.health bits (docs/sensor-protocol.md 4.6). */
object HealthBits {
    const val JAMMED = 1 shl 0
    const val CLIPPED = 1 shl 1
    const val LOW_BATTERY = 1 shl 2
    const val SURVEY_NEEDED = 1 shl 3
    const val SURVEY_ACTIVE = 1 shl 4
    const val SESSION_ACTIVE = 1 shl 5
    const val TIME_VALID = 1 shl 6
    const val AUTHENTICATED = 1 shl 7
    const val WARMING_UP = 1 shl 8
    const val SENSOR_FAULT = 1 shl 9
    const val EVENTS_OVERWRITTEN = 1 shl 10

    private const val NOT_EVALUATED = JAMMED or CLIPPED or SURVEY_NEEDED or SURVEY_ACTIVE or SENSOR_FAULT

    /**
     * Jammed, clipped, surveying/survey-needed and sensor faults mean the node
     * is not evaluating: never "nothing there" (guardrails section 10).
     */
    fun isEvaluated(bits: Int): Boolean = (bits and NOT_EVALUATED) == 0
}

/** One step of the connect/reconnect sequence. */
enum class LinkStep {
    CONNECT,
    BOND,
    REQUEST_MTU,
    PREFER_2M_PHY,
    DISCOVER,
    SUBSCRIBE_STATUS,
    SUBSCRIBE_CONTROL_POINT,
    SUBSCRIBE_EVENT,
    SUBSCRIBE_SNIPPET,
    SUBSCRIBE_BAND_FRAME,
    READ_DEVICE_INFO,
    AUTHENTICATE,
    READ_STATUS,
    READ_BAND_TABLE,
    SET_TIME,
    GET_EVENTS_SINCE,
}

/**
 * The reconnect sequence (docs/sensor-protocol.md section 6). Pure, so the order
 * is unit-tested: auth before any data, SET_TIME before GET_EVENTS_SINCE.
 */
object ReconnectPlan {
    const val MTU = 517

    fun steps(alreadyBonded: Boolean, supports2mPhy: Boolean, liveBands: Boolean): List<LinkStep> = buildList {
        add(LinkStep.CONNECT)
        if (!alreadyBonded) add(LinkStep.BOND)
        add(LinkStep.REQUEST_MTU)
        if (supports2mPhy) add(LinkStep.PREFER_2M_PHY)
        add(LinkStep.DISCOVER)
        add(LinkStep.SUBSCRIBE_STATUS)
        add(LinkStep.SUBSCRIBE_CONTROL_POINT)
        add(LinkStep.SUBSCRIBE_EVENT)
        add(LinkStep.SUBSCRIBE_SNIPPET)
        if (liveBands) add(LinkStep.SUBSCRIBE_BAND_FRAME)
        add(LinkStep.READ_DEVICE_INFO)
        add(LinkStep.AUTHENTICATE)
        add(LinkStep.READ_STATUS)
        add(LinkStep.READ_BAND_TABLE)
        add(LinkStep.SET_TIME)
        add(LinkStep.GET_EVENTS_SINCE)
    }
}

/** Reconnect backoff for a session whose node dropped: 2, 4, 8 ... capped at 5 min. */
object Backoff {
    fun delayMs(attempt: Int): Long = (2_000L shl attempt.coerceIn(0, 8)).coerceAtMost(300_000L)
}

/**
 * Event counter for the session notification. Reports a rate ("N events in M
 * minutes"), never a verdict.
 */
class SessionStats(private val startedAtMs: Long) {
    var events: Int = 0
        private set

    fun onEvent() {
        events++
    }

    fun minutes(nowMs: Long): Int = ((nowMs - startedAtMs).coerceAtLeast(0) / 60_000L).toInt()

    fun summary(nowMs: Long): String {
        val m = minutes(nowMs)
        val ev = if (events == 1) "1 signal" else "$events signals"
        val min = if (m == 1) "1 minute" else "$m minutes"
        return "$ev in $min (experimental)"
    }
}
