package com.tactilelens.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Test

/**
 * Plain JVM tests: BrailleMathNormalizer has no Android dependencies.
 * They check the linear math sent to Liblouis, not the Braille itself.
 */
class BrailleMathNormalizerTest {
    private fun normalize(latex: String) = BrailleMathNormalizer.normalize(latex)

    @Test
    fun aCommandAfterABackslashIsNotAFraction() {
        // Previously "(x)/(right)" and "(x+1)/(right)^2".
        assertEquals("(x)", normalize("""\left(x\right)"""))
        assertEquals("(x+1)^2", normalize("""\left(x+1\right)^{2}"""))
        assertEquals("(x)+1", normalize("""$$ \left(x\right)+1 $$"""))
    }

    @Test
    fun sizedDelimitersAreNoLongerReadAsAFraction() {
        // \bigl and \bigr themselves are not supported offline yet (that is
        // part of the later port of fix (b)); only the false fraction is gone.
        val result = normalize("""\bigl(x\bigr)""")

        assertFalse(result, result.contains("/"))
    }

    @Test
    fun stackedFractionsStillWork() {
        assertEquals("(3)/(4)", normalize("""(3 \ 4)"""))
        assertEquals("(3)/(4)", normalize("""(3 \\ 4)"""))
        assertEquals(
            "(3)/(4)",
            normalize("""\left( \begin{array}{c} 3 \\ 4 \end{array} \right)"""),
        )
    }

    // (Unicode superscript form, the same expression in caret form). The
    // same cases are in the Python test_braille_math_normalizer.py.
    private val superscriptCases = listOf(
        "x²" to """x^{2}""",
        "xⁿ" to """x^{n}""",
        "(a+b)²" to """(a+b)^{2}""",
        "10⁻³" to """10^{-3}""",
        "2x³y²" to """2x^{3}y^{2}""",
        "x² + 3x - 5" to """x^{2} + 3x - 5""",
        "a²b³ = c²" to """a^{2}b^{3} = c^{2}""",
        "xⁿ⁺¹" to """x^{n+1}""",
        "x⁰ + y¹ + z⁴⁵⁶⁷⁸⁹" to """x^{0} + y^{1} + z^{456789}""",
    )

    @Test
    fun unicodeSuperscriptsBecomeTheCaretForm() {
        assertEquals("x^2", normalize("x²"))
        assertEquals("x^n", normalize("xⁿ"))
        assertEquals("(a+b)^2", normalize("(a+b)²"))
        assertEquals("10^-3", normalize("10⁻³"))
        assertEquals("2x^3y^2", normalize("2x³y²"))
        assertEquals("a^2b^3 = c^2", normalize("a²b³ = c²"))
        // Grouped like x^{n+1}; see the expert note on baseline return.
        assertEquals("x^n+1", normalize("xⁿ⁺¹"))
    }

    @Test
    fun unicodeSuperscriptsMatchTheirCaretForm() {
        for ((unicodeForm, caretForm) in superscriptCases) {
            assertEquals(unicodeForm, normalize(caretForm), normalize(unicodeForm))
        }
    }

    @Test
    fun spacesAroundOperatorsAreRemoved() {
        // Same cases as the Python test_spaces_around_operators_are_removed.
        val cases = listOf(
            "x + 3x - 5" to "x+3x-5",
            "x - 5" to "x-5",
            "x- 5" to "x-5",
            "x -5" to "x-5",
            "x = -5" to "x=-5",
            "x − 5" to "x−5",
            "x != 5" to "x!=5",
            "x <= 5" to "x<=5",
            "2 × 3 ÷ 6 · 1" to "2×3÷6·1",
            "(x) / (2)" to "(x)/(2)",
            "- 5 + x" to "-5+x",
        )

        for ((text, expected) in cases) {
            assertEquals(text, expected, BrailleMathNormalizer.tightenOperators(text))
        }
    }

    @Test
    fun aSignAfterASeparatorKeepsItsPlace() {
        assertEquals("Row 1: x; -3", BrailleMathNormalizer.tightenOperators("Row 1: x; -3"))
        assertEquals("a, -3", BrailleMathNormalizer.tightenOperators("a, - 3"))
    }

    @Test
    fun lineBreaksBetweenRowsAreKept() {
        assertEquals("x+1=4\nx=3", BrailleMathNormalizer.tightenOperators("x + 1 = 4\nx = 3"))
    }

    @Test
    fun nemethInputIsTightenedBeforeTheReplacements() {
        assertEquals("x<=5", BrailleMathNormalizer.toNemethInput("x ≤ 5"))
        assertEquals("x+3x-5", BrailleMathNormalizer.toNemethInput("x + 3x - 5"))
    }

    @Test
    fun documentedExamplesAreUnchanged() {
        assertEquals("(x+1)/(2)=3", normalize("""\frac{x+1}{2}=3"""))
        assertEquals("(√(2))^2=2", normalize("""\left(\sqrt{2}\right)^{2}=2"""))
        assertEquals("x-5=12", normalize("""$$ x-5=12 $$"""))
    }
}
