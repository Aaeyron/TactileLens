package com.tactilelens.app

/**
 * Kotlin port of ai_service/services/braille_math_normalizer.py
 * (BrailleMathNormalizer.normalize) plus the Nemeth input replacements
 * from braille_translation_service.py, so offline and online produce the
 * same Nemeth for the same LaTeX.
 *
 * Example: \frac{x+1}{2}=3            -> (x+1)/(2)=3
 *          \left(\sqrt{2}\right)^{2}=2 -> (√(2))^2=2
 *
 * Braces are escaped in every pattern because Android's regex engine
 * rejects bare '{' / '}' that Python accepts; matching is unchanged.
 */
object BrailleMathNormalizer {
    private val FRACTION_COMMAND =
        Regex("""\\(?:dfrac|tfrac|frac)\b""")

    private val RADICAL_COMMAND =
        Regex("""\\sqrt\b""")

    private val FORMATTING_COMMAND =
        Regex("""\\(?:text|textrm|mathrm|mathbf|mathit|operatorname)\b""")

    private val GROUPED_EXPONENT =
        Regex("""\^\s*\{\s*([^\{\}]+?)\s*\}""")

    private val GROUPED_SUBSCRIPT =
        Regex("""_\s*\{\s*([^\{\}]+?)\s*\}""")

    private val STACKED_ARRAY_FRACTION = Regex(
        """\\left\s*\(\s*\\begin\{array\}\{[^\{\}]*\}\s*(.+?)\s*\\\\\s*(.+?)\s*\\end\{array\}\s*\\right\s*\)""",
        RegexOption.DOT_MATCHES_ALL,
    )

    private val STACKED_DOUBLE_SLASH_FRACTION =
        Regex("""\(\s*([A-Za-z0-9.+\- ]+?)\s*\\\\\s*([A-Za-z0-9.+\- ]+?)\s*\)""")

    private val STACKED_SINGLE_SLASH_FRACTION =
        Regex("""\(\s*([A-Za-z0-9.+\- ]+?)\s*\\\s*([A-Za-z0-9.+\- ]+?)\s*\)""")

    private val INTEGER_EXPONENT =
        Regex("""\^\s*(?:\{\s*([+-]?\s*\d+)\s*\}|([+-]?\s*\d+))""")

    private val SIMPLE_SCRIPT = Regex("""[A-Za-z0-9+-]+""")
    private val SPACING_COMMAND = Regex("""\\[,;:!]""")
    private val ENVIRONMENT_COMMAND = Regex("""\\(?:begin|end)\{[^\{\}]*\}""")
    private val ANY_COMMAND = Regex("""\\([A-Za-z]+)\b""")
    private val WHITESPACE = Regex("""\s+""")

    // Same order as Python: longer commands before shorter prefixes.
    private val OPERATOR_REPLACEMENTS: List<Pair<String, String>> = listOf(
        "\\left" to "",
        "\\right" to "",
        "\\times" to "×",
        "\\div" to "÷",
        "\\cdot" to "·",
        "\\pm" to "±",
        "\\mp" to "∓",
        "\\leq" to "≤",
        "\\le" to "≤",
        "\\geq" to "≥",
        "\\ge" to "≥",
        "\\neq" to "≠",
        "\\ne" to "≠",
        "\\approx" to "≈",
        "\\sum" to "∑",
        "\\prod" to "∏",
        "\\int" to "∫",
        "\\infty" to "∞",
        "\\alpha" to "α",
        "\\beta" to "β",
        "\\gamma" to "γ",
        "\\delta" to "δ",
        "\\theta" to "θ",
        "\\lambda" to "λ",
        "\\mu" to "μ",
        "\\pi" to "π",
        "\\sigma" to "σ",
        "\\%" to "%",
    )

    // From BrailleTranslationService._NEMETH_INPUT_REPLACEMENTS.
    private val NEMETH_INPUT_REPLACEMENTS: List<Pair<String, String>> = listOf(
        "≤" to "<=",
        "≥" to ">=",
        "≠" to "!=",
        "≈" to "~=",
    )

    /** LaTeX -> Liblouis-friendly linear math (Python: normalize()). */
    fun normalize(content: String): String {
        var normalized = removeMathDelimiters(content.trim())

        if (normalized.isEmpty()) {
            return ""
        }

        normalized = replaceStackedFractions(normalized)
        normalized = replaceFractions(normalized)
        normalized = replaceRadicals(normalized)
        normalized = unwrapFormattingCommands(normalized)

        normalized = INTEGER_EXPONENT.replace(normalized) { match ->
            val exponent = match.groups[1]?.value ?: match.groups[2]?.value ?: ""
            "^" + exponent.replace(" ", "")
        }

        normalized = GROUPED_EXPONENT.replace(normalized) { match ->
            script("^", match.groupValues[1])
        }

        normalized = GROUPED_SUBSCRIPT.replace(normalized) { match ->
            script("_", match.groupValues[1])
        }

        for ((command, symbol) in OPERATOR_REPLACEMENTS) {
            normalized = normalized.replace(command, symbol)
        }

        normalized = normalized.replace("~", " ")
        normalized = SPACING_COMMAND.replace(normalized, " ")
        normalized = ENVIRONMENT_COMMAND.replace(normalized, " ")
        normalized = ANY_COMMAND.replace(normalized) { match -> match.groupValues[1] }

        normalized = normalized
            .replace("{", "(")
            .replace("}", ")")
            .replace("\\\\", " ")
            .replace("\\", " ")

        normalized = WHITESPACE.replace(normalized, " ")

        return normalized.trim()
    }

    /** Symbol replacements applied before the Nemeth table (Python: translate_formula()). */
    fun toNemethInput(content: String): String {
        var result = content

        for ((symbol, replacement) in NEMETH_INPUT_REPLACEMENTS) {
            result = result.replace(symbol, replacement)
        }

        return result
    }

    private fun script(prefix: String, raw: String): String {
        val value = raw.trim()
        return if (SIMPLE_SCRIPT.matches(value)) "$prefix$value" else "$prefix($value)"
    }

    private fun replaceStackedFractions(content: String): String {
        val toFraction: (MatchResult) -> CharSequence = { match ->
            val numerator = match.groupValues[1].replace("&", "").trim()
            val denominator = match.groupValues[2].replace("&", "").trim()

            if (numerator.isEmpty() || denominator.isEmpty()) {
                match.value
            } else {
                "($numerator)/($denominator)"
            }
        }

        var normalized = STACKED_ARRAY_FRACTION.replace(content, toFraction)
        normalized = STACKED_DOUBLE_SLASH_FRACTION.replace(normalized, toFraction)
        normalized = STACKED_SINGLE_SLASH_FRACTION.replace(normalized, toFraction)

        return normalized
    }

    private fun replaceFractions(content: String): String {
        val output = StringBuilder()
        var searchIndex = 0

        while (true) {
            val match = FRACTION_COMMAND.find(content, searchIndex)

            if (match == null) {
                output.append(content, searchIndex, content.length)
                break
            }

            output.append(content, searchIndex, match.range.first)

            val numeratorStart = skipSpaces(content, match.range.last + 1)
            val numerator = readBracedGroup(content, numeratorStart)

            if (numerator == null) {
                output.append(match.value)
                searchIndex = match.range.last + 1
                continue
            }

            val denominatorStart = skipSpaces(content, numerator.second)
            val denominator = readBracedGroup(content, denominatorStart)

            if (denominator == null) {
                output.append(content, match.range.first, numerator.second)
                searchIndex = numerator.second
                continue
            }

            output
                .append("(")
                .append(replaceFractions(numerator.first))
                .append(")/(")
                .append(replaceFractions(denominator.first))
                .append(")")

            searchIndex = denominator.second
        }

        return output.toString()
    }

    private fun replaceRadicals(content: String): String {
        val output = StringBuilder()
        var searchIndex = 0

        while (true) {
            val match = RADICAL_COMMAND.find(content, searchIndex)

            if (match == null) {
                output.append(content, searchIndex, content.length)
                break
            }

            output.append(content, searchIndex, match.range.first)

            var contentIndex = skipSpaces(content, match.range.last + 1)
            var rootIndex = ""

            if (contentIndex < content.length && content[contentIndex] == '[') {
                val indexGroup = readBracketedGroup(content, contentIndex)

                if (indexGroup != null) {
                    rootIndex = indexGroup.first
                    contentIndex = skipSpaces(content, indexGroup.second)
                }
            }

            val radicand = readBracedGroup(content, contentIndex)

            if (radicand == null) {
                output.append(match.value)
                searchIndex = match.range.last + 1
                continue
            }

            val linearRadicand = replaceRadicals(radicand.first)

            if (rootIndex.isNotBlank()) {
                output.append("√[").append(rootIndex.trim()).append("](")
                    .append(linearRadicand).append(")")
            } else {
                output.append("√(").append(linearRadicand).append(")")
            }

            searchIndex = radicand.second
        }

        return output.toString()
    }

    private fun unwrapFormattingCommands(content: String): String {
        val output = StringBuilder()
        var searchIndex = 0

        while (true) {
            val match = FORMATTING_COMMAND.find(content, searchIndex)

            if (match == null) {
                output.append(content, searchIndex, content.length)
                break
            }

            output.append(content, searchIndex, match.range.first)

            val groupStart = skipSpaces(content, match.range.last + 1)
            val group = readBracedGroup(content, groupStart)

            if (group == null) {
                output.append(match.value)
                searchIndex = match.range.last + 1
                continue
            }

            output.append(unwrapFormattingCommands(group.first))
            searchIndex = group.second
        }

        return output.toString()
    }

    private fun skipSpaces(content: String, start: Int): Int {
        var index = start

        while (index < content.length && content[index].isWhitespace()) {
            index++
        }

        return index
    }

    /** Returns (inner text, index after the closing brace), or null. */
    private fun readBracedGroup(content: String, start: Int): Pair<String, Int>? =
        readGroup(content, start, '{', '}')

    private fun readBracketedGroup(content: String, start: Int): Pair<String, Int>? =
        readGroup(content, start, '[', ']')

    private fun readGroup(
        content: String,
        start: Int,
        open: Char,
        close: Char,
    ): Pair<String, Int>? {
        if (start >= content.length || content[start] != open) {
            return null
        }

        var depth = 0

        for (index in start until content.length) {
            when (content[index]) {
                open -> depth++
                close -> {
                    depth--

                    if (depth == 0) {
                        return content.substring(start + 1, index) to (index + 1)
                    }
                }
            }
        }

        return null
    }

    private fun removeMathDelimiters(content: String): String {
        val normalized = content.trim()

        val delimiters = listOf(
            "$$" to "$$",
            "\\[" to "\\]",
            "\\(" to "\\)",
            "$" to "$",
        )

        for ((opening, closing) in delimiters) {
            if (
                normalized.startsWith(opening) &&
                normalized.endsWith(closing) &&
                normalized.length >= opening.length + closing.length
            ) {
                return normalized
                    .substring(opening.length, normalized.length - closing.length)
                    .trim()
            }
        }

        return normalized
    }
}