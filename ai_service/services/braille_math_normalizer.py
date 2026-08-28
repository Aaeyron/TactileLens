import re
from typing import Final


class BrailleMathNormalizer:
    """Convert PaddleOCR-VL LaTeX into linear math for Liblouis."""

    _fraction_command = re.compile(
        r"\\(?:dfrac|tfrac|frac)\b"
    )

    _stacked_array_fraction = re.compile(
        r"\\left\s*\(\s*"
        r"\\begin\{array\}\{[^{}]*\}\s*"
        r"(.+?)\s*\\\\\s*(.+?)\s*"
        r"\\end\{array\}\s*"
        r"\\right\s*\)",
        re.DOTALL,
    )

    _stacked_double_slash_fraction = re.compile(
        r"\(\s*"
        r"([A-Za-z0-9.+\- ]+?)"
        r"\s*\\\\\s*"
        r"([A-Za-z0-9.+\- ]+?)"
        r"\s*\)"
    )

    _stacked_single_slash_fraction = re.compile(
        r"\(\s*"
        r"([A-Za-z0-9.+\- ]+?)"
        r"\s*\\\s*"
        r"([A-Za-z0-9.+\- ]+?)"
        r"\s*\)"
    )

    _integer_exponent = re.compile(
        r"\^\s*(?:"
        r"\{\s*([+-]?\s*\d+)\s*\}"
        r"|"
        r"([+-]?\s*\d+)"
        r")"
    )

    _operator_replacements: Final[
        tuple[tuple[str, str], ...]
    ] = (
        # Remove structural commands before replacing shorter
        # commands such as \le, which is a prefix of \left.
        (r"\left", ""),
        (r"\right", ""),
        (r"\times", "×"),
        (r"\div", "÷"),
        (r"\cdot", "·"),
        (r"\pm", "±"),
        (r"\mp", "∓"),
        (r"\leq", "≤"),
        (r"\le", "≤"),
        (r"\geq", "≥"),
        (r"\ge", "≥"),
        (r"\neq", "≠"),
        (r"\ne", "≠"),
        (r"\approx", "≈"),
    )

    @classmethod
    def normalize(
        cls,
        content: str,
    ) -> str:
        """Return Liblouis-friendly linear mathematical content."""

        if not isinstance(content, str):
            return ""

        normalized = cls._remove_math_delimiters(
            content.strip()
        )

        if not normalized:
            return ""

        normalized = cls._replace_stacked_fractions(
            normalized
        )

        normalized = cls._replace_fractions(
            normalized
        )

        normalized = cls._integer_exponent.sub(
            cls._replace_integer_exponent,
            normalized,
        )

        for latex_command, symbol in (
            cls._operator_replacements
        ):
            normalized = normalized.replace(
                latex_command,
                symbol,
            )

        normalized = normalized.replace(
            "~",
            " ",
        )

        normalized = re.sub(
            r"\\[,;:!]",
            " ",
            normalized,
        )

        normalized = re.sub(
            r"[ \t]+",
            " ",
            normalized,
        )

        return normalized.strip()

    @staticmethod
    def _replace_integer_exponent(
        match: re.Match[str],
    ) -> str:
        exponent = (
            match.group(1)
            if match.group(1) is not None
            else match.group(2)
        )

        normalized_exponent = exponent.replace(
            " ",
            "",
        )

        return f"^{normalized_exponent}"

    @classmethod
    def _replace_stacked_fractions(
        cls,
        content: str,
    ) -> str:
        """Recover OCR fractions represented as stacked rows."""

        def replace_fraction(
            match: re.Match[str],
        ) -> str:
            numerator = (
                match.group(1)
                .replace("&", "")
                .strip()
            )

            denominator = (
                match.group(2)
                .replace("&", "")
                .strip()
            )

            if not numerator or not denominator:
                return match.group(0)

            return f"({numerator})/({denominator})"

        normalized = cls._stacked_array_fraction.sub(
            replace_fraction,
            content,
        )

        normalized = (
            cls._stacked_double_slash_fraction.sub(
                replace_fraction,
                normalized,
            )
        )

        normalized = (
            cls._stacked_single_slash_fraction.sub(
                replace_fraction,
                normalized,
            )
        )

        return normalized

    @classmethod
    def _replace_fractions(
        cls,
        content: str,
    ) -> str:
        output: list[str] = []
        search_index = 0

        while True:
            match = cls._fraction_command.search(
                content,
                search_index,
            )

            if match is None:
                output.append(
                    content[search_index:]
                )
                break

            output.append(
                content[search_index : match.start()]
            )

            numerator_start = cls._skip_spaces(
                content,
                match.end(),
            )

            numerator = cls._read_braced_group(
                content,
                numerator_start,
            )

            if numerator is None:
                output.append(match.group(0))
                search_index = match.end()
                continue

            numerator_content, numerator_end = numerator

            denominator_start = cls._skip_spaces(
                content,
                numerator_end,
            )

            denominator = cls._read_braced_group(
                content,
                denominator_start,
            )

            if denominator is None:
                output.append(
                    content[
                        match.start() : numerator_end
                    ]
                )

                search_index = numerator_end
                continue

            denominator_content, denominator_end = (
                denominator
            )

            linear_numerator = cls._replace_fractions(
                numerator_content
            )

            linear_denominator = cls._replace_fractions(
                denominator_content
            )

            output.append(
                f"({linear_numerator})/"
                f"({linear_denominator})"
            )

            search_index = denominator_end

        return "".join(output)

    @staticmethod
    def _skip_spaces(
        content: str,
        start: int,
    ) -> int:
        index = start

        while (
            index < len(content)
            and content[index].isspace()
        ):
            index += 1

        return index

    @staticmethod
    def _read_braced_group(
        content: str,
        start: int,
    ) -> tuple[str, int] | None:
        if (
            start >= len(content)
            or content[start] != "{"
        ):
            return None

        depth = 0

        for index in range(
            start,
            len(content),
        ):
            character = content[index]

            if character == "{":
                depth += 1
            elif character == "}":
                depth -= 1

                if depth == 0:
                    return (
                        content[start + 1 : index],
                        index + 1,
                    )

        return None

    @staticmethod
    def _remove_math_delimiters(
        content: str,
    ) -> str:
        normalized = content.strip()

        delimiters = (
            ("$$", "$$"),
            (r"\[", r"\]"),
            (r"\(", r"\)"),
            ("$", "$"),
        )

        for opening, closing in delimiters:
            if (
                normalized.startswith(opening)
                and normalized.endswith(closing)
                and len(normalized)
                >= len(opening) + len(closing)
            ):
                return normalized[
                    len(opening) : -len(closing)
                ].strip()

        return normalized