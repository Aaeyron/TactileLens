"""Decide whether a formula block is safe to translate into Braille.

PaddleOCR-VL sometimes returns LaTeX that the Braille path cannot
linearise, or reads a worked example's explanation column as part of the
math. BrailleMathNormalizer turns any unknown command into a plain word,
so the result would look like Braille but be wrong. This check looks at
the raw LaTeX instead and holds such blocks for review: no Braille is
produced and the raw text is shown with a note.

A false positive only means a teacher checks the block, which is the safe
direction.
"""

import re
from dataclasses import dataclass
from typing import Final

from services.braille.braille_math_normalizer import BrailleMathNormalizer

# Provisional thresholds, approved with the Stage 3 findings. Words are
# runs of ASCII letters; LaTeX command names and FUNCTION_NAMES never count.
LONG_WORD_LENGTH: Final[int] = 4
SHORT_WORD_LENGTH: Final[int] = 3
SHORT_WORD_LIMIT: Final[int] = 2
TOTAL_WORD_LIMIT: Final[int] = 6

UNSUPPORTED_LATEX: Final[str] = "unsupported_latex"
ALIGNMENT: Final[str] = "alignment"
ENGLISH_TEXT: Final[str] = "english_text"
LEFTOVER_MARKUP: Final[str] = "leftover_markup"
ROOT: Final[str] = "root"

# The Liblouis Nemeth table (en-us-mathtext.ctb, 3.38.0) has no radical
# symbols: a root comes out as an escape such as '\x221a' written in
# Braille cells. Roots stay held until the Braille expert confirms the
# Nemeth radical. The offline app uses the same reason text.
ROOT_SYMBOLS: Final[str] = "√∛∜"
ROOT_REASON: Final[str] = "contains a root (√): Nemeth radical not yet confirmed"

# Wrappers whose contents are meant to be words, such as "\text{area}".
_TEXT_WRAPPER = re.compile(
    r"\\(?:text|textrm|textbf|textit|mbox|mathrm|operatorname)\s*\{"
)
_ROW_BREAK = re.compile(r"\\\\")
_ENVIRONMENT = re.compile(r"\\(?:begin|end)\s*\{([^{}]*)\}")
_COMMAND = re.compile(r"\\([A-Za-z]+)")
_COLUMN = re.compile(r"(?<!\\)&")
_WORD = re.compile(r"[A-Za-z]+")

_WORDS_IN_REASON: Final[int] = 4


@dataclass(frozen=True)
class FormulaReview:
    needs_review: bool = False
    categories: tuple[str, ...] = ()
    reason: str = ""


NO_REVIEW: Final[FormulaReview] = FormulaReview()


def review_formula(raw_content: str, braille_input: str) -> FormulaReview:
    """Check one formula block before it is sent to Liblouis.

    [raw_content] is the LaTeX from OCR; [braille_input] is what
    BrailleMathNormalizer made of it.
    """

    if not isinstance(raw_content, str) or not raw_content.strip():
        return NO_REVIEW

    # Stacked fractions legitimately use rows and "array"; take them out
    # first, exactly as the normalizer does.
    structure = BrailleMathNormalizer.replace_stacked_fractions(raw_content)

    findings: list[tuple[str, str]] = []

    unsupported = _unsupported_latex(structure)

    if unsupported:
        findings.append(
            (UNSUPPORTED_LATEX, "unsupported LaTeX: " + ", ".join(unsupported))
        )

    if _has_unsupported_alignment(structure):
        findings.append((ALIGNMENT, "alignment or row markup (& or \\\\)"))

    words = _english_words(structure)

    if words:
        shown = ", ".join(words[:_WORDS_IN_REASON])
        more = ", ..." if len(words) > _WORDS_IN_REASON else ""
        findings.append(
            (
                ENGLISH_TEXT,
                f"contains English text ({len(words)} words: {shown}{more})",
            )
        )

    # BrailleMathNormalizer turns every \sqrt into √, so this also catches
    # roots written as LaTeX.
    if contains_root(braille_input):
        findings.append((ROOT, ROOT_REASON))

    # Safety net: anything still looking like markup after normalization.
    if not findings and any(mark in braille_input for mark in "\\{}&"):
        findings.append((LEFTOVER_MARKUP, "markup left after normalization"))

    if not findings:
        return NO_REVIEW

    return FormulaReview(
        needs_review=True,
        categories=tuple(category for category, _ in findings),
        reason="; ".join(reason for _, reason in findings),
    )


def review_table(table_text: str) -> FormulaReview:
    """Check a table's row text, which is also translated with Nemeth."""

    if not contains_root(table_text):
        return NO_REVIEW

    return FormulaReview(needs_review=True, categories=(ROOT,), reason=ROOT_REASON)


def contains_root(content: str) -> bool:
    return any(symbol in content for symbol in ROOT_SYMBOLS)


def _unsupported_latex(structure: str) -> list[str]:
    # Remove row breaks first so "\\x" is not read as the command "\x".
    text = _ROW_BREAK.sub(" ", structure)

    environments = {
        name.strip()
        for name in _ENVIRONMENT.findall(text)
        if name.strip() not in BrailleMathNormalizer.SUPPORTED_ENVIRONMENTS
    }

    commands = {
        name
        for name in _COMMAND.findall(_ENVIRONMENT.sub(" ", text))
        if name not in BrailleMathNormalizer.SUPPORTED_COMMANDS
        and name not in BrailleMathNormalizer.FUNCTION_NAMES
    }

    return sorted(f"\\{name}" for name in commands) + sorted(
        f"{name} environment" for name in environments
    )


def _has_unsupported_alignment(structure: str) -> bool:
    if not _ROW_BREAK.search(structure) and not _COLUMN.search(structure):
        return False

    environments = {name.strip() for name in _ENVIRONMENT.findall(structure)}

    return not environments or not environments <= (
        BrailleMathNormalizer.SUPPORTED_ENVIRONMENTS
    )


def _english_words(structure: str) -> list[str]:
    """Words that look like English, outside then inside text wrappers.

    Returns an empty list when the thresholds are not reached.
    """

    outside, inside = _split_text_wrappers(structure)

    def words_of(text: str) -> list[str]:
        text = _ENVIRONMENT.sub(" ", text)
        text = _COMMAND.sub(" ", text)

        return [
            word
            for word in _WORD.findall(text)
            if len(word) >= SHORT_WORD_LENGTH
            and word.lower() not in BrailleMathNormalizer.FUNCTION_NAMES
        ]

    outside_words = words_of(outside)
    inside_words = words_of(inside)
    all_words = outside_words + inside_words

    has_long_word = any(len(word) >= LONG_WORD_LENGTH for word in outside_words)

    if (
        has_long_word
        or len(outside_words) >= SHORT_WORD_LIMIT
        or len(all_words) >= TOTAL_WORD_LIMIT
    ):
        return all_words

    return []


def _split_text_wrappers(structure: str) -> tuple[str, str]:
    """Split LaTeX into the parts outside and inside \\text{...} groups."""

    outside: list[str] = []
    inside: list[str] = []
    index = 0

    while True:
        match = _TEXT_WRAPPER.search(structure, index)

        if match is None:
            outside.append(structure[index:])
            break

        outside.append(structure[index : match.start()])

        # match.end() is just past the opening brace.
        depth = 1
        position = match.end()

        while position < len(structure) and depth:
            if structure[position] == "{":
                depth += 1
            elif structure[position] == "}":
                depth -= 1
            position += 1

        inside.append(structure[match.end() : position - 1 if depth == 0 else position])
        index = position

    return " ".join(outside), " ".join(inside)
