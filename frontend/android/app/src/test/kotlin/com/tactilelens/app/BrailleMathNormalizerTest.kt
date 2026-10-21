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

    @Test
    fun documentedExamplesAreUnchanged() {
        assertEquals("(x+1)/(2)=3", normalize("""\frac{x+1}{2}=3"""))
        assertEquals("(√(2))^2=2", normalize("""\left(\sqrt{2}\right)^{2}=2"""))
        assertEquals("x-5=12", normalize("""$$ x-5=12 $$"""))
    }
}
