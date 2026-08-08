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

    # PaddleOCR-VL may recognize the Philippine peso sign
    # as an inline LaTeX lowercase or uppercase letter b.
    # This is intentionally restricted to a value followed by a digit.
    _misrecognized_peso = re.compile(
        r"\$\s*\\text\s*"
        r"\{\s*[bB]\s*\}\s*"
        r"\$\s*(?=\d)"
    )

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

    _multiple_horizontal_spaces = re.compile(
        r"[ \t]+"
    )

    _excessive_newlines = re.compile(
        r"\n{3,}"
    )

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

    @classmethod
    def _normalize_text(
        cls,
        content: str,
    ) -> str:
        normalized = cls._misrecognized_peso.sub(
            "₱",
            content,
        )

        normalized = cls._unwrap_formatting_commands(
            normalized
        )

        # Remove inline LaTeX dollar delimiters from text blocks.
        # Example: "$5$" becomes "5" and "$x$" becomes "x".
        normalized = normalized.replace("$", "")

        normalized = cls._replace_spacing_commands(
            normalized
        )

        return cls._normalize_whitespace(
            normalized
        )

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

    @classmethod
    def _unwrap_formatting_commands(
        cls,
        content: str,
    ) -> str:
        normalized = content

        # Repeat because LaTeX formatting commands can be nested.
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

        normalized = normalized.replace("~", " ")

        return normalized

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

        normalized = "\n".join(normalized_lines)

        normalized = cls._excessive_newlines.sub(
            "\n\n",
            normalized,
        )

        return normalized.strip()