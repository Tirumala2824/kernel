package com.kernel.sense_ai

class ScoredClass(val index: Int, val label: String, val score: Float)

class PreFilterResult(
    /** Top class is speech, music or TV: the event is not reported. */
    val rejected: Boolean,
    /** Top classes plus allow-listed ones, highest score first. Raw, uncalibrated. */
    val labels: List<ScoredClass>,
    /** Best allow-listed label when it scores at least [SoundPreFilter.HINT_MIN_SCORE]. */
    val hint: String?,
)

/**
 * Sound pre-filter decision on YAMNet-class scores (AudioSet ontology, 521
 * classes). Pure logic; the interpreter lives in [SoundClassifier].
 *
 * Label names come from the model file when it embeds a label list;
 * otherwise only the allow-listed and fallback reject indices are named.
 */
object SoundPreFilter {
    const val YAMNET_CLASSES = 521
    const val HINT_MIN_SCORE = 0.05f
    const val LIST_MIN_SCORE = 0.02f
    const val TOP_N = 5

    /** Pest-relevant AudioSet classes (YAMNet indices). */
    val ALLOWLIST: Map<Int, String> = mapOf(
        49 to "Chewing, mastication",
        50 to "Biting",
        118 to "Rodents, rats, mice",
        119 to "Mouse",
        120 to "Patter",
        121 to "Insect",
        122 to "Cricket",
        123 to "Mosquito",
        124 to "Fly, housefly",
        126 to "Bee, wasp, etc.",
        355 to "Squeak",
        468 to "Scratch",
    )

    /** Speech, music and TV/radio classes, matched by name when labels are known. */
    val REJECT_NAMES: Set<String> = setOf(
        "Speech",
        "Child speech, kid speaking",
        "Conversation",
        "Narration, monologue",
        "Babbling",
        "Speech synthesizer",
        "Music",
        "Television",
        "Radio",
    )

    /** Speech family (0-5) and Music (132) when the model has no label list. */
    val REJECT_INDICES_FALLBACK: Set<Int> = setOf(0, 1, 2, 3, 4, 5, 132)

    fun evaluate(scores: FloatArray, labels: List<String>?): PreFilterResult {
        val named = labels != null && labels.size == scores.size
        val allow: Set<Int> = if (named) {
            val names = ALLOWLIST.values.toSet()
            scores.indices.filterTo(HashSet()) { labels!![it] in names }
        } else if (scores.size == YAMNET_CLASSES) {
            ALLOWLIST.keys
        } else {
            emptySet()
        }
        val reject: Set<Int> = if (named) {
            scores.indices.filterTo(HashSet()) { labels!![it] in REJECT_NAMES }
        } else if (scores.size == YAMNET_CLASSES) {
            REJECT_INDICES_FALLBACK
        } else {
            emptySet()
        }
        fun name(i: Int): String = if (named) labels!![i] else ALLOWLIST[i] ?: "class_$i"

        val order = scores.indices.sortedByDescending { scores[it] }
        val top = order.firstOrNull()
        val rejected = top != null && top in reject
        val picked = LinkedHashSet<Int>()
        order.take(TOP_N).forEach { picked.add(it) }
        allow.filter { scores[it] >= LIST_MIN_SCORE }.forEach { picked.add(it) }
        val list = picked.sortedByDescending { scores[it] }.map { ScoredClass(it, name(it), scores[it]) }
        val bestAllowed = allow.maxByOrNull { scores[it] }
        val hint = bestAllowed?.takeIf { scores[it] >= HINT_MIN_SCORE }?.let { name(it) }
        return PreFilterResult(rejected, list, hint)
    }
}
