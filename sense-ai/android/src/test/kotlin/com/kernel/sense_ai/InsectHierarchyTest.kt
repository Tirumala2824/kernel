package com.kernel.sense_ai

import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test

/** Hand-specified distributions exercise rules only, not model accuracy. */
class InsectHierarchyTest {
    private val labels = listOf("Myopsaltaleona", "Myopsaltalongicauda", "Platypleuracapensis", "Chorthippusbiguttulus", "Pseudochorthippusparallelus", "Grylluscampestris")
    @Test fun specificityUsesInclusivePointSixWithNoSpeciesGuessBelowIt() {
        assertEquals("species" to labels[0], InsectSoundAdapter.identify(labels,doubleArrayOf(.6,.0,.0,.1,.1,.2)))
        assertEquals("genus" to "Myopsalta", InsectSoundAdapter.identify(labels,doubleArrayOf(.3,.3,.0,.1,.1,.2)))
        assertEquals("group" to "Cicadidae (cicadas)", InsectSoundAdapter.identify(labels,doubleArrayOf(.2,.2,.2,.1,.1,.2)))
        assertEquals("unknown" to null, InsectSoundAdapter.identify(labels,doubleArrayOf(.2,.1,.2,.2,.1,.2)))
    }
}
