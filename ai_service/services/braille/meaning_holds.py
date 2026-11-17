"""Hold formulas whose Braille would read as a different formula.

Same rules and reason text as the app's on-device holds
(frontend/lib/services/braille/offline_braille_holds.dart); the cases in
fixtures/meaning_holds_shared.json are checked by both test suites.

- ≠ ≤ ≥ ≈ are rewritten to "!=", "<=", ">=", "~=" before the Nemeth table
  (BrailleTranslationService._NEMETH_INPUT_REPLACEMENTS), which reads
  "a != 0" as "a! = 0" and "x <= 3" as two signs.
- BrailleMathNormalizer drops the braces of an exponent or subscript made of
  [A-Za-z0-9+-], so x^{n+1} and x^{n}+1 (or 2^{3}4 and 2^{34}) give the same
  Braille.
- \\{ \\} become parentheses.

Only holds: a held block gets no Braille and shows the reason.
"""

import re
from typing import Final

from services.braille.formula_braille_guard import NO_REVIEW, FormulaReview

RELATION_SIGN: Final[str] = "relation_sign"
SCRIPT_GROUPING: Final[str] = "script_grouping"
SET_BRACES: Final[str] = "set_braces"

RELATION_SIGN_REASON: Final[str] = (
    "contains ≠, ≤, ≥ or ≈: this sign does not come out right in Braille yet"
)
SCRIPT_GROUPING_REASON: Final[str] = (
    "where an exponent or subscript ends is lost in Braille, so it could be "
    "read as a different formula"
)
SET_BRACES_REASON: Final[str] = (
    "contains set braces { }: they would come out as parentheses"
)

_RELATION = re.compile(
    r"\\(?:neq|ne|leq|le|geq|ge|leqslant|geqslant|approx|nleq|ngeq)"
    r"(?![A-Za-z])|[≠≤≥≈]"
)
_SET_BRACE = re.compile(r"\\[{}]|\\[lr]brace(?![A-Za-z])")
_SCRIPT_START = re.compile(r"[\^_]\s*\{")
_FLATTENED = re.compile(r"^[A-Za-z0-9+\-]+$")
_PLAIN_NUMBER = re.compile(r"^-?\d+$")
_CLOSERS = re.compile(r"^(?:\\right)?[)\]}|.]*")


def review_meaning(content: str) -> FormulaReview:
    """Whether [content] (formula LaTeX or table text) must be held."""

    if not isinstance(content, str) or not content:
        return NO_REVIEW

    findings: list[tuple[str, str]] = []

    if _RELATION.search(content):
        findings.append((RELATION_SIGN, RELATION_SIGN_REASON))

    if _loses_script_grouping(content):
        findings.append((SCRIPT_GROUPING, SCRIPT_GROUPING_REASON))

    if _SET_BRACE.search(content):
        findings.append((SET_BRACES, SET_BRACES_REASON))

    if not findings:
        return NO_REVIEW

    return FormulaReview(
        needs_review=True,
        categories=tuple(category for category, _ in findings),
        reason="; ".join(reason for _, reason in findings),
    )


def _loses_script_grouping(latex: str) -> bool:
    for match in _SCRIPT_START.finditer(latex):
        opening = match.end() - 1
        closing = _closing_brace(latex, opening)

        if closing is None:
            continue

        inner = latex[opening + 1 : closing].replace(" ", "")

        if not inner or not _FLATTENED.match(inner):
            # Written with brackets, e.g. ^(2x+1): its end is kept.
            continue

        rest = latex[closing + 1 :].lstrip()
        following = _CLOSERS.sub("", rest, count=1)

        if len(inner) > 1:
            has_operator = bool(re.search(r"[+-]", inner[1:]))
            plain_number_at_end = not following and bool(_PLAIN_NUMBER.match(inner))

            if has_operator or not plain_number_at_end:
                return True
        elif re.match(r"\d", rest):
            return True

    return False


def _closing_brace(text: str, opening: int) -> int | None:
    depth = 0
    index = opening

    while index < len(text):
        character = text[index]

        if character == "\\":
            index += 2
            continue

        if character == "{":
            depth += 1
        elif character == "}":
            depth -= 1

            if depth == 0:
                return index

        index += 1

    return None
