package com.tactilelens.app

/**
 * Offline routing for short lines that may have lost an exponent.
 *
 * PP-OCRv6 reads a small raised "2" as an ordinary "2", so "x²" arrives
 * as "x2". Such a line has no operator, so the math fallback in
 * OfflineDocumentPipeline never sends it to the formula model. This
 * object decides which of those lines get one formula read, and whether
 * the formula model's answer may replace the OCR text.
 *
 * Plain Kotlin (no Android types), so it is unit tested on the JVM.
 */
object ExponentRouting {
    /** Longest line (characters, spaces included) that is checked. */
    const val MAX_CHARACTERS = 24

    /** Extra formula reads per page for these lines (each costs ~1-1.5 s). */
    const val MAX_CHECKS_PER_PAGE = 6

    // A letter or ")" directly followed by a digit ("x2", "(a+b)2"), or a
    // digit directly followed by a letter ("2x3y2").
    private val LOST_EXPONENT = Regex("""[A-Za-z)]\d|\d[A-Za-z]""")

    // Three or more letters in a row is a word, except standard function
    // names. Same rule as the pipeline's math fallback.
    private val REAL_WORD = Regex("""[A-Za-z]{3,}""")
    private val MATH_FUNCTION_WORDS = setOf(
        "sin", "cos", "tan", "sec", "csc", "cot", "log", "ln",
        "sqrt", "abs", "max", "min", "lim",
    )

    // What is ignored when the formula result is compared with the OCR text.
    private val EXPONENT_MARKUP = Regex("""[\^{}\s]""")
    private val SPACING_COMMAND = Regex("""\\[ ,;:!]|\\q?quad(?![A-Za-z])""")

    /** True if [text] contains a word that is not a math function name. */
    fun hasProse(text: String): Boolean =
        REAL_WORD.findAll(text).any { match ->
            match.value.lowercase() !in MATH_FUNCTION_WORDS
        }

    /** True if [text] is a short line, without prose, that may hide an exponent. */
    fun isCandidate(text: String): Boolean {
        val trimmed = text.trim()

        return trimmed.isNotEmpty() &&
            trimmed.length <= MAX_CHARACTERS &&
            !hasProse(trimmed) &&
            LOST_EXPONENT.containsMatchIn(trimmed)
    }

    /**
     * Keep the formula model's [latex] instead of [ocrText] only when it
     * adds an exponent and is otherwise the same text: "x^{2}" for "x2",
     * "2x^{3}y^{2}" for "2x3y2". Anything else (a different reading, or the
     * same text with no exponent) keeps the OCR text.
     */
    fun keepsFormula(ocrText: String, latex: String): Boolean {
        if ('^' !in latex) {
            return false
        }

        val formula = EXPONENT_MARKUP.replace(SPACING_COMMAND.replace(latex, ""), "")
        val ocr = EXPONENT_MARKUP.replace(ocrText, "").replace('−', '-')

        return formula.isNotEmpty() && formula == ocr
    }
}
