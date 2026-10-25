package com.tactilelens.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Which short lines get a formula read because they may hide an exponent,
 * and when the formula result replaces the OCR text. Lines with an
 * operator or "=" ("x2 + 3x - 5", "10-3", "a2b3 = c2") already go to the
 * formula model through the pipeline's math fallback and are not checked
 * here.
 */
class ExponentRoutingTest {
    @Test
    fun routingTable() {
        val table = listOf(
            // OCR text of the exponent cases, exponent lost.
            "x2" to true,
            "(a+b)2" to true,
            "2x3y2" to true,
            "a2b3" to true,
            "3x2" to true,
            // No digit next to a letter: nothing to check.
            "xn" to false,
            "12" to false,
            "- 12 -" to false,
            "p. 5" to false,
            // Prose and headings never go.
            "Solve each equation." to false,
            "Chapter 3" to false,
            "Figure 2" to false,
            "Exercise 4b" to false,
            "Use A4 paper" to false,
            // Short tokens without a word: checked (false positives the
            // safeguard below keeps as text).
            "A4" to true,
            "H2O" to true,
            "Q1" to true,
            "1a" to true,
            // Too long to be one short expression.
            "x2 y2 z2 a2 b2 c2 d2 e2 f2" to false,
        )

        for ((text, expected) in table) {
            assertEquals(text, expected, ExponentRouting.isCandidate(text))
        }
    }

    @Test
    fun theFormulaResultIsKeptOnlyWhenItAddsAnExponentToTheSameText() {
        assertTrue(ExponentRouting.keepsFormula("x2", """x^{2}"""))
        assertTrue(ExponentRouting.keepsFormula("(a+b)2", """(a+b)^{2}"""))
        assertTrue(ExponentRouting.keepsFormula("2x3y2", """2x^{3}y^{2}"""))
        assertTrue(ExponentRouting.keepsFormula("a2b3", """a^{2}b^{3}"""))
        assertTrue(ExponentRouting.keepsFormula("x2", """x^2"""))
        assertTrue(ExponentRouting.keepsFormula("x 2", """x^{2}"""))
    }

    @Test
    fun otherwiseTheOcrTextIsKept() {
        // Same text, no exponent: nothing gained.
        assertFalse(ExponentRouting.keepsFormula("A4", "A4"))
        assertFalse(ExponentRouting.keepsFormula("1a", "1a"))
        // A different reading.
        assertFalse(ExponentRouting.keepsFormula("x2", """x^{2}+1"""))
        assertFalse(ExponentRouting.keepsFormula("A4", """A^{4}_{1}"""))
        // A subscript is not an exponent: H2O stays text.
        assertFalse(ExponentRouting.keepsFormula("H2O", """H_{2}O"""))
        assertFalse(ExponentRouting.keepsFormula("x2", ""))
    }

    @Test
    fun proseUsesTheMathFallbackRule() {
        assertTrue(ExponentRouting.hasProse("Solve for x"))
        assertFalse(ExponentRouting.hasProse("sin x + cos x"))
        assertFalse(ExponentRouting.hasProse("x2"))
    }

    @Test
    fun atMostSixChecksPerPage() {
        assertEquals(6, ExponentRouting.MAX_CHECKS_PER_PAGE)
    }
}
