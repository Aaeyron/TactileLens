package com.tactilelens.app

import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * The line handling around Liblouis (the JNI call itself cannot run in a
 * JVM test): each line is translated on its own and the line breaks stay.
 */
class LiblouisLineByLineTest {
    private val calls = mutableListOf<String>()

    private fun translate(content: String) =
        LiblouisLines.translateLineByLine(content) { line ->
            calls += line
            "<$line>"
        }

    @Test
    fun eachListItemIsTranslatedOnItsOwnAndKeepsItsLine() {
        val result = translate("1. Add the numbers.\n2. Subtract.\n3. Check.")

        assertEquals(listOf("1. Add the numbers.", "2. Subtract.", "3. Check."), calls)
        assertEquals("<1. Add the numbers.>\n<2. Subtract.>\n<3. Check.>", result)
    }

    @Test
    fun aSingleLineIsOneCallUnchanged() {
        assertEquals("<Solve for x.>", translate("Solve for x."))
        assertEquals(listOf("Solve for x."), calls)
    }

    @Test
    fun spacesAtLineEndsAndBlankLinesAreDropped() {
        assertEquals("<a) 12>\n<b) 15>", translate("  a) 12  \n\n b) 15\n"))
    }
}
