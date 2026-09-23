import re
from typing import Final


class BrailleMathNormalizer:
    """Convert PaddleOCR-VL LaTeX into linear math for Liblouis."""

    _fraction_command = re.compile(r"\\(?:dfrac|tfrac|frac)\b")

    _radical_command = re.compile(r"\\sqrt\b")

    _formatting_command = re.compile(
        r"\\(?:text|textrm|mathrm|mathbf|mathit|operatorname)\b"
    )

    _grouped_exponent = re.compile(r"\^\s*\{\s*([^{}]+?)\s*\}")

    _grouped_subscript = re.compile(r"_\s*\{\s*([^{}]+?)\s*\}")

    _stacked_array_fraction = re.compile(
        r"\\left\s*\(\s*"
        r"\\begin\{array\}\{[^{}]*\}\s*"
        r"(.+?)\s*\\\\\s*(.+?)\s*"
        r"\\end\{array\}\s*"
        r"\\right\s*\)",
        re.DOTALL,
    )

    _stacked_double_slash_fraction = re.compile(
        r"\(\s*" r"([A-Za-z0-9.+\- ]+?)" r"\s*\\\\\s*" r"([A-Za-z0-9.+\- ]+?)" r"\s*\)"
    )

    _stacked_single_slash_fraction = re.compile(
        r"\(\s*" r"([A-Za-z0-9.+\- ]+?)" r"\s*\\\s*" r"([A-Za-z0-9.+\- ]+?)" r"\s*\)"
    )

    _integer_exponent = re.compile(
        r"\^\s*(?:" r"\{\s*([+-]?\s*\d+)\s*\}" r"|" r"([+-]?\s*\d+)" r")"
    )

    _operator_replacements: Final[tuple[tuple[str, str], ...]] = (
        # Longer commands must appear before shorter prefixes.
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
        (r"\sum", "∑"),
        (r"\prod", "∏"),
        (r"\int", "∫"),
        (r"\infty", "∞"),
        (r"\alpha", "α"),
        (r"\beta", "β"),
        (r"\gamma", "γ"),
        (r"\delta", "δ"),
        (r"\theta", "θ"),
        (r"\lambda", "λ"),
        (r"\mu", "μ"),
        (r"\pi", "π"),
        (r"\sigma", "σ"),
        (r"\%", "%"),
    )

    @classmethod
    def normalize(
        cls,
        content: str,
    ) -> str:
        """Return Liblouis-friendly linear mathematical content."""

        if not isinstance(content, str):
            return ""

        normalized = cls._remove_math_delimiters(content.strip())

        if not normalized:
            return ""

        normalized = cls._replace_stacked_fractions(normalized)

        normalized = cls._replace_fractions(normalized)

        normalized = cls._replace_radicals(normalized)

        normalized = cls._unwrap_formatting_commands(normalized)

        normalized = cls._integer_exponent.sub(
            cls._replace_integer_exponent,
            normalized,
        )

        normalized = cls._grouped_exponent.sub(
            cls._replace_grouped_exponent,
            normalized,
        )

        normalized = cls._grouped_subscript.sub(
            cls._replace_grouped_subscript,
            normalized,
        )

        for latex_command, symbol in cls._operator_replacements:
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
            r"\\(?:begin|end)\{[^{}]*\}",
            " ",
            normalized,
        )

        normalized = re.sub(
            r"\\([A-Za-z]+)\b",
            r"\1",
            normalized,
        )

        normalized = (
            normalized.replace("{", "(")
            .replace("}", ")")
            .replace(r"\\", " ")
            .replace("\\", " ")
        )

        normalized = re.sub(
            r"\s+",
            " ",
            normalized,
        )

        return normalized.strip()

    @classmethod
    def _replace_radicals(
        cls,
        content: str,
    ) -> str:
        """Convert LaTeX radicals into readable linear math."""

        output: list[str] = []
        search_index = 0

        while True:
            match = cls._radical_command.search(
                content,
                search_index,
            )

            if match is None:
                output.append(content[search_index:])
                break

            output.append(content[search_index : match.start()])

            content_index = cls._skip_spaces(
                content,
                match.end(),
            )

            root_index = ""

            if content_index < len(content) and content[content_index] == "[":
                index_group = cls._read_bracketed_group(
                    content,
                    content_index,
                )

                if index_group is not None:
                    root_index, content_index = index_group
                    content_index = cls._skip_spaces(
                        content,
                        content_index,
                    )

            radicand = cls._read_braced_group(
                content,
                content_index,
            )

            if radicand is None:
                output.append(match.group(0))
                search_index = match.end()
                continue

            radicand_content, radicand_end = radicand

            linear_radicand = cls._replace_radicals(radicand_content)

            if root_index.strip():
                output.append(f"√[{root_index.strip()}]" f"({linear_radicand})")
            else:
                output.append(f"√({linear_radicand})")

            search_index = radicand_end

        return "".join(output)

    @classmethod
    def _unwrap_formatting_commands(
        cls,
        content: str,
    ) -> str:
        """Remove visual LaTeX wrappers but preserve their text."""

        output: list[str] = []
        search_index = 0

        while True:
            match = cls._formatting_command.search(
                content,
                search_index,
            )

            if match is None:
                output.append(content[search_index:])
                break

            output.append(content[search_index : match.start()])

            group_start = cls._skip_spaces(
                content,
                match.end(),
            )

            group = cls._read_braced_group(
                content,
                group_start,
            )

            if group is None:
                output.append(match.group(0))
                search_index = match.end()
                continue

            group_content, group_end = group

            output.append(cls._unwrap_formatting_commands(group_content))

            search_index = group_end

        return "".join(output)

    @staticmethod
    def _replace_grouped_exponent(
        match: re.Match[str],
    ) -> str:
        exponent = match.group(1).strip()

        if re.fullmatch(r"[A-Za-z0-9+-]+", exponent):
            return f"^{exponent}"

        return f"^({exponent})"

    @staticmethod
    def _replace_grouped_subscript(
        match: re.Match[str],
    ) -> str:
        subscript = match.group(1).strip()

        if re.fullmatch(r"[A-Za-z0-9+-]+", subscript):
            return f"_{subscript}"

        return f"_({subscript})"

    @staticmethod
    def _replace_integer_exponent(
        match: re.Match[str],
    ) -> str:
        exponent = match.group(1) if match.group(1) is not None else match.group(2)

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
            numerator = match.group(1).replace("&", "").strip()

            denominator = match.group(2).replace("&", "").strip()

            if not numerator or not denominator:
                return match.group(0)

            return f"({numerator})/({denominator})"

        normalized = cls._stacked_array_fraction.sub(
            replace_fraction,
            content,
        )

        normalized = cls._stacked_double_slash_fraction.sub(
            replace_fraction,
            normalized,
        )

        normalized = cls._stacked_single_slash_fraction.sub(
            replace_fraction,
            normalized,
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
                output.append(content[search_index:])
                break

            output.append(content[search_index : match.start()])

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
                output.append(content[match.start() : numerator_end])
                search_index = numerator_end
                continue

            denominator_content, denominator_end = denominator

            linear_numerator = cls._replace_fractions(numerator_content)

            linear_denominator = cls._replace_fractions(denominator_content)

            output.append(f"({linear_numerator})/" f"({linear_denominator})")

            search_index = denominator_end

        return "".join(output)

    @staticmethod
    def _skip_spaces(
        content: str,
        start: int,
    ) -> int:
        index = start

        while index < len(content) and content[index].isspace():
            index += 1

        return index

    @staticmethod
    def _read_braced_group(
        content: str,
        start: int,
    ) -> tuple[str, int] | None:
        if start >= len(content) or content[start] != "{":
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
    def _read_bracketed_group(
        content: str,
        start: int,
    ) -> tuple[str, int] | None:
        if start >= len(content) or content[start] != "[":
            return None

        depth = 0

        for index in range(start, len(content)):
            character = content[index]

            if character == "[":
                depth += 1
            elif character == "]":
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
                and len(normalized) >= len(opening) + len(closing)
            ):
                return normalized[len(opening) : -len(closing)].strip()

        return normalized
