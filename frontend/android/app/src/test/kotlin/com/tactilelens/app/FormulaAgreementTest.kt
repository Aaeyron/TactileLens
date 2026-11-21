package com.tactilelens.app

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** Agreement check between the two formula models (plain JVM). */
class FormulaAgreementTest {
    @Test
    fun theSameFormulaAgrees() {
        assertTrue(FormulaAgreement.agrees("0=k+3h", "0=k+3h"))
        assertTrue(FormulaAgreement.agrees("""\frac{x+1}{2}=3""", """\frac{x+1}{2}=3"""))
    }

    @Test
    fun notationThatGivesTheSameBrailleAgrees() {
        // Spacing and braces around a single exponent do not change the Braille input.
        assertTrue(FormulaAgreement.agrees("""x^{2} + 1""", """x^2+1"""))
        assertTrue(FormulaAgreement.agrees("""3 - 5""", """3 − 5"""))
        assertTrue(FormulaAgreement.agrees("""\left(x+2\right)""", """(x+2)"""))
    }

    @Test
    fun aDifferentReadingDisagrees() {
        // From the tuning pages: the original model dropped the 0.
        assertFalse(FormulaAgreement.agrees("=k+3h", "0=k+3h"))
        assertFalse(FormulaAgreement.agrees("""\frac{S}{2}""", """\frac{5}{2}"""))
        assertFalse(FormulaAgreement.agrees("""x^{-8}""", """x-8"""))
    }

    @Test
    fun aMissingCheckReadingIsNotAgreement() {
        assertFalse(FormulaAgreement.agrees("x=1", null))
        assertFalse(FormulaAgreement.agrees("x=1", ""))
        assertFalse(FormulaAgreement.agrees("", ""))
    }

    @Test
    fun theCheckModelIsInTheRegistry() {
        assertTrue(OfflineModelFiles.ALL.contains(OfflineModelFiles.FORMULA_CHECK))
        assertTrue(OfflineModelFiles.FORMULA_CHECK.installedPath != OfflineModelFiles.FORMULA.installedPath)
    }
}
