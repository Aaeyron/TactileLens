import re


class OcrContentNormalizer:
    """Normalizes PaddleOCR-VL content for preview and translation."""

    FORMULA_BLOCK_TYPES = frozenset(
        {
            "formula",
            "display_formula",
            "inline_formula",
        }
    )

    # Unicode constants are used to avoid file-encoding corruption.
    PESO_SIGN = "\u20B1"
    CHECKED_BOX = "\u2611"
    BALLOT_BOX_WITH_X = "\u2612"

    # ============================================================
    # MATH DELIMITERS
    # ============================================================

    _opening_display_math = re.compile(
        r"^\s*\$\$\s*"
    )

    _closing_display_math = re.compile(
        r"\s*\$\$\s*$"
    )

    _opening_bracket_math = re.compile(
        r"^\s*\\\[\s*"
    )

    _closing_bracket_math = re.compile(
        r"\s*\\\]\s*$"
    )

    _opening_inline_math = re.compile(
        r"^\s*\\\(\s*"
    )

    _closing_inline_math = re.compile(
        r"\s*\\\)\s*$"
    )

    # ============================================================
    # PHILIPPINE PESO NORMALIZATION
    # ============================================================

    # PaddleOCR-VL may recognize the Philippine peso symbol
    # as an inline LaTeX lowercase or uppercase letter b.
    _misrecognized_peso = re.compile(
        r"\$\s*\\text\s*"
        r"\{\s*[bB]\s*\}\s*"
        r"\$\s*(?=\d)"
    )

    # PaddleOCR-VL may recognize the peso symbol as:
    #
    # P
    # Unicode checked box U+2611
    # Unicode ballot box with X U+2612
    #
    # These candidates are replaced only when currency context
    # is present and they appear before a number or x variable.
    _peso_symbol_candidate = re.compile(
        rf"(?<![\w{PESO_SIGN}])"
        rf"(?:P|{CHECKED_BOX}|{BALLOT_BOX_WITH_X})"
        r"[ \t]*(?=(?:\d|[xX]\b))"
    )

    _currency_context = re.compile(
        r"\b(?:"
        r"peso|pesos|money|price|prices|"
        r"cost|costs|costing|"
        r"buy|buys|buying|bought|"
        r"purchase|purchases|purchased|"
        r"pay|pays|paying|paid|"
        r"spend|spends|spending|spent|"
        r"cash|change|budget|wallet|"
        r"sale|worth|amount|"
        r"notebook|pen|item|items"
        r")\b",
        re.IGNORECASE,
    )

    # ============================================================
    # LATEX FORMATTING
    # ============================================================

    _latex_formatting_command = re.compile(
        r"\\(?:"
        r"text|mathrm|mathbf|boldsymbol|"
        r"mathit|mathsf|mathtt|operatorname"
        r")\s*\{([^{}]*)\}"
    )

    _latex_spacing_command = re.compile(
        r"\\[,;:!]"
    )

    _escaped_space = re.compile(
        r"\\\s+"
    )

    # ============================================================
    # WHITESPACE
    # ============================================================

    _multiple_horizontal_spaces = re.compile(
        r"[ \t]+"
    )

    _excessive_newlines = re.compile(
        r"\n{3,}"
    )

    # ============================================================
    # PUBLIC NORMALIZATION
    # ============================================================

    @classmethod
    def normalize(
        cls,
        content: str,
        block_type: str,
    ) -> str:
        """Return normalized content without changing the raw input."""

        if not isinstance(content, str):
            return ""

        normalized_type = (
            block_type.strip().lower()
            if isinstance(block_type, str)
            else ""
        )

        normalized_content = content.strip()

        if not normalized_content:
            return ""

        if normalized_type in cls.FORMULA_BLOCK_TYPES:
            return cls._normalize_formula(
                normalized_content
            )

        return cls._normalize_text(
            normalized_content
        )

    # ============================================================
    # FORMULA NORMALIZATION
    # ============================================================

    @classmethod
    def _normalize_formula(
        cls,
        content: str,
    ) -> str:
        normalized = cls._remove_outer_math_delimiters(
            content
        )

        normalized = cls._unwrap_formatting_commands(
            normalized
        )

        normalized = cls._replace_spacing_commands(
            normalized
        )

        return cls._normalize_whitespace(
            normalized
        )

    # ============================================================
    # TEXT NORMALIZATION
    # ============================================================

    @classmethod
    def _normalize_text(
        cls,
        content: str,
    ) -> str:
        normalized = cls._misrecognized_peso.sub(
            cls.PESO_SIGN,
            content,
        )

        normalized = cls._unwrap_formatting_commands(
            normalized
        )

        # Remove inline LaTeX dollar delimiters.
        #
        # "$5$" becomes "5"
        # "$x$" becomes "x"
        normalized = normalized.replace(
            "$",
            "",
        )

        normalized = cls._replace_spacing_commands(
            normalized
        )

        normalized = cls._normalize_whitespace(
            normalized
        )

        return cls._restore_contextual_peso_symbols(
            normalized
        )

    @classmethod
    def _restore_contextual_peso_symbols(
        cls,
        content: str,
    ) -> str:
        """Restore OCR peso candidates when the text indicates money."""

        if not cls._currency_context.search(content):
            return content

        return cls._peso_symbol_candidate.sub(
            cls.PESO_SIGN,
            content,
        )

    # ============================================================
    # MATH DELIMITER REMOVAL
    # ============================================================

    @classmethod
    def _remove_outer_math_delimiters(
        cls,
        content: str,
    ) -> str:
        normalized = content

        normalized = cls._opening_display_math.sub(
            "",
            normalized,
            count=1,
        )

        normalized = cls._closing_display_math.sub(
            "",
            normalized,
            count=1,
        )

        normalized = cls._opening_bracket_math.sub(
            "",
            normalized,
            count=1,
        )

        normalized = cls._closing_bracket_math.sub(
            "",
            normalized,
            count=1,
        )

        normalized = cls._opening_inline_math.sub(
            "",
            normalized,
            count=1,
        )

        normalized = cls._closing_inline_math.sub(
            "",
            normalized,
            count=1,
        )

        return normalized.strip()

    # ============================================================
    # LATEX COMMAND CLEANUP
    # ============================================================

    @classmethod
    def _unwrap_formatting_commands(
        cls,
        content: str,
    ) -> str:
        normalized = content

        # Repeat because formatting commands can be nested.
        for _ in range(5):
            updated = cls._latex_formatting_command.sub(
                r"\1",
                normalized,
            )

            if updated == normalized:
                break

            normalized = updated

        return normalized

    @classmethod
    def _replace_spacing_commands(
        cls,
        content: str,
    ) -> str:
        normalized = cls._latex_spacing_command.sub(
            " ",
            content,
        )

        normalized = cls._escaped_space.sub(
            " ",
            normalized,
        )

        normalized = normalized.replace(
            "~",
            " ",
        )

        return normalized

    # ============================================================
    # WHITESPACE NORMALIZATION
    # ============================================================

    @classmethod
    def _normalize_whitespace(
        cls,
        content: str,
    ) -> str:
        normalized_lines = [
            cls._multiple_horizontal_spaces.sub(
                " ",
                line,
            ).strip()
            for line in content.splitlines()
        ]

        normalized = "\n".join(
            normalized_lines
        )

        normalized = cls._excessive_newlines.sub(
            "\n\n",
            normalized,
        )

        return normalized.strip()