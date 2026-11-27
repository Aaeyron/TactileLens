"""Generated algebra lines with raised characters, by topic.

Every line is made up here from templates and random letters and numbers:
no textbook or worksheet text. A line is a list of segments
(text, raised); the label writes raised characters with the Unicode
superscripts the recognizer knows (digits, + - = ( ) and n).

Topics and sub-cases match topics.csv. A row there whose sub-case has no
template below is generated from its "example" text as written (raised
characters given as Unicode superscripts), so new rows work without code.
"""

from __future__ import annotations

import random
from dataclasses import dataclass, field
from typing import Callable

from common import PLAIN_OF_SUPERSCRIPT, SUPERSCRIPT, SUPERSCRIPT_CHARS

Segment = tuple[str, bool]
MINUS = "−"  # U+2212, as printed; the recognizer's dictionary has it

VARIABLES = "abcmnpqrstxyz"


@dataclass
class Line:
    topic: str
    subcase: str
    segments: list[Segment]
    fixed: bool = False
    notes: dict = field(default_factory=dict)

    @property
    def label(self) -> str:
        out = []
        for text, raised in self.segments:
            out.append("".join(SUPERSCRIPT[c] for c in text) if raised else text)
        return "".join(out)

    @property
    def has_superscript(self) -> bool:
        return any(c in SUPERSCRIPT_CHARS for c in self.label)


def from_unicode(text: str) -> list[Segment]:
    """'x² + 3x' -> [('x', False), ('2', True), (' + 3x', False)]."""

    segments: list[Segment] = []
    for c in text:
        raised = c in SUPERSCRIPT_CHARS
        plain = PLAIN_OF_SUPERSCRIPT.get(c, c)
        if raised and plain == "-":
            plain = MINUS
        if segments and segments[-1][1] == raised:
            segments[-1] = (segments[-1][0] + plain, raised)
        else:
            segments.append((plain, raised))
    return segments


# Your seven cases, fixed.
FIXED_CASES = [
    ("exponents", "single_digit", "x²"),
    ("exponents", "letter_n", "xⁿ"),
    ("exponents", "bracket_power", "(a+b)²"),
    ("negative_exponents", "power_of_ten", "10⁻³"),
    ("products_of_powers", "two_variables", "2x³y²"),
    ("polynomials", "quadratic", "x² + 3x − 5"),
    ("equations_with_powers", "products", "a²b³ = c²"),
]


# ------------------------------------------------------------- templates


def _var(rng: random.Random, avoid: str = "") -> str:
    return rng.choice([v for v in VARIABLES if v not in avoid])


def _coef(rng: random.Random, low: int = 2, high: int = 12) -> str:
    return str(rng.randint(low, high))


def _exp(rng: random.Random) -> str:
    return rng.choice(["2", "2", "2", "3", "3", "4", "5", "6", "7", "8", "9", "n", "10", "12"])


def _op(rng: random.Random, spaced: bool, op: str) -> str:
    return f" {op} " if spaced else op


def _single_digit(rng, spaced):
    v = _var(rng)
    return [(v, False), (rng.choice("23456789"), True)]


def _letter_n(rng, spaced):
    base = rng.choice([_var(rng, "n"), _coef(rng, 2, 10)])
    return [(base, False), ("n", True)]


def _multi_digit(rng, spaced):
    base = rng.choice([_var(rng), "2", "3", "10"])
    return [(base, False), (str(rng.randint(10, 20)), True)]


def _bracket_power(rng, spaced):
    a, b = _var(rng), _var(rng)
    while b == a:
        b = _var(rng)
    op = rng.choice(["+", MINUS])
    return [(f"({a}{_op(rng, spaced, op)}{b})", False), (rng.choice("2233n"), True)]


def _power_of_ten(rng, spaced):
    return [("10", False), (MINUS + str(rng.randint(1, 9)), True)]


def _negative_variable(rng, spaced):
    return [(_var(rng), False), (MINUS + str(rng.randint(1, 5)), True)]


def _scientific(rng, spaced):
    mantissa = f"{rng.randint(1, 9)}.{rng.randint(0, 99):02d}".rstrip("0").rstrip(".")
    return [(f"{mantissa}{_op(rng, spaced, '×')}10", False), (MINUS + str(rng.randint(2, 9)), True)]


def _two_variables(rng, spaced):
    a, b = _var(rng), _var(rng)
    while b == a:
        b = _var(rng)
    out: list[Segment] = []
    if rng.random() < 0.7:
        out.append((_coef(rng, 2, 9), False))
    out += [(a, False), (_exp(rng), True), (b, False), (_exp(rng), True)]
    return _merge(out)


def _quadratic(rng, spaced):
    v = _var(rng)
    lead = rng.choice(["", "", "2", "3", "4", "5"])
    # A coefficient of 1 is not printed ("x", not "1x").
    b, c = _coef(rng, 2, 15), _coef(rng, 1, 20)
    op1, op2 = rng.choice(["+", MINUS]), rng.choice(["+", MINUS])
    return _merge([
        (f"{lead}{v}", False), ("2", True),
        (f"{_op(rng, spaced, op1)}{b}{v}{_op(rng, spaced, op2)}{c}", False),
    ])


def _cubic(rng, spaced):
    v = _var(rng)
    ops = [rng.choice(["+", MINUS]) for _ in range(3)]
    return _merge([
        (f"{rng.choice(['', '2', '3'])}{v}", False), ("3", True),
        (f"{_op(rng, spaced, ops[0])}{_coef(rng, 2, 9)}{v}", False), ("2", True),
        (f"{_op(rng, spaced, ops[1])}{_coef(rng, 2, 9)}{v}{_op(rng, spaced, ops[2])}{_coef(rng, 1, 20)}", False),
    ])


def _products(rng, spaced):
    a, b, c = rng.sample(VARIABLES, 3)
    return _merge([
        (a, False), (_exp(rng), True), (b, False), (_exp(rng), True),
        (_op(rng, spaced, "="), False), (c, False), (_exp(rng), True),
    ])


def _square_equals(rng, spaced):
    v = _var(rng)
    n = rng.randint(2, 15)
    return [(v, False), ("2", True), (f"{_op(rng, spaced, '=')}{n * n}", False)]


def _bracket_equation(rng, spaced):
    v = _var(rng)
    k = rng.randint(1, 9)
    return [(f"({v}{_op(rng, spaced, rng.choice(['+', MINUS]))}{k})", False), ("2", True),
            (f"{_op(rng, spaced, '=')}{rng.randint(2, 12) ** 2}", False)]


def _root_of_square(rng, spaced):
    a, b = rng.sample(VARIABLES, 2)
    return [(f"√({a}", False), ("2", True), (f"{_op(rng, spaced, '+')}{b}", False), ("2", True), (")", False)]


def _cube_root(rng, spaced):
    n = rng.randint(2, 9)
    return [(f"∛{n ** 3}{_op(rng, spaced, '=')}{n}", False)]


def _linear_fraction(rng, spaced):
    v = _var(rng)
    return [(f"({v}", False), ("2", True), (f"{_op(rng, spaced, '+')}{rng.randint(1, 9)})/{rng.randint(2, 9)}", False)]


def _quadratic_inequality(rng, spaced):
    v = _var(rng)
    sign = rng.choice(["<", ">", "≤", "≥"])
    return [(v, False), ("2", True), (f"{_op(rng, spaced, sign)}{rng.randint(2, 12) ** 2}", False)]


def _linear_inequality(rng, spaced):
    v = _var(rng)
    sign = rng.choice(["<", ">", "≤", "≥"])
    return [(f"{_coef(rng)}{v}{_op(rng, spaced, rng.choice(['+', MINUS]))}{rng.randint(1, 20)}{_op(rng, spaced, sign)}{rng.randint(1, 40)}", False)]


def _control_equation(rng, spaced):
    v = _var(rng)
    return [(f"{_coef(rng)}{v}{_op(rng, spaced, rng.choice(['+', MINUS]))}{rng.randint(1, 20)}{_op(rng, spaced, '=')}{rng.randint(1, 60)}", False)]


def _control_brackets(rng, spaced):
    v = _var(rng)
    return [(f"{_coef(rng, 2, 9)}({v}{_op(rng, spaced, '+')}{rng.randint(1, 9)}){_op(rng, spaced, '=')}{rng.randint(10, 90)}", False)]


def _control_prose(rng, spaced):
    words = rng.choice([
        "Solve for {v}.", "Simplify each expression.", "Find the value of {v}.",
        "Write the answer in simplest form.", "Expand and simplify.", "Factor completely.",
        "Evaluate when {v} = {n}.", "Check your answer.",
    ])
    return [(words.format(v=_var(rng), n=rng.randint(1, 9)), False)]


# Plain words for generated sentences (no superscripts), so training
# keeps reading ordinary text. Common English and classroom words.
_WORDS = (
    "the a an and or of to in on for with from by at as is are was be this that "
    "these each every all some any no not more less most least than then when "
    "find solve simplify expand factor evaluate write show check explain compare "
    "answer question number numbers value values term terms expression equation "
    "equations sum product difference quotient total area perimeter length width "
    "height side sides angle angles line lines point points graph table chart "
    "page step steps example examples exercise practice review part section "
    "student students teacher class lesson unit test quiz homework work book "
    "first second third last next before after above below left right top bottom "
    "half twice double even odd whole positive negative greater smaller equal "
    "same different correct simplest form units square cube root power powers "
    "base exponent fraction decimal percent ratio rate time day week year minute "
    "hour meter metre centimeter gram litre money cost price change pattern rule"
).split()


# The recognizer's training config has max_text_length 25; longer labels
# are dropped by the trainer, so generated lines stay within it.
MAX_LABEL_LENGTH = 25


def _control_text(rng, spaced):
    words = [rng.choice(_WORDS) for _ in range(rng.randint(2, 7))]
    if rng.random() < 0.3:
        words.insert(rng.randrange(len(words) + 1), str(rng.randint(1, 999)))
    while len(" ".join(words)) > MAX_LABEL_LENGTH - 1 and len(words) > 1:
        words.pop()
    text = " ".join(words)
    if rng.random() < 0.7:
        text = text[0].upper() + text[1:]
    return [(text + rng.choice([".", ".", ":", "?", ""]), False)]


def _merge(segments: list[Segment]) -> list[Segment]:
    out: list[Segment] = []
    for text, raised in segments:
        if not text:
            continue
        if out and out[-1][1] == raised:
            out[-1] = (out[-1][0] + text, raised)
        else:
            out.append((text, raised))
    return out


TEMPLATES: dict[tuple[str, str], Callable[[random.Random, bool], list[Segment]]] = {
    ("exponents", "single_digit"): _single_digit,
    ("exponents", "letter_n"): _letter_n,
    ("exponents", "multi_digit"): _multi_digit,
    ("exponents", "bracket_power"): _bracket_power,
    ("negative_exponents", "power_of_ten"): _power_of_ten,
    ("negative_exponents", "variable"): _negative_variable,
    ("negative_exponents", "scientific_notation"): _scientific,
    ("products_of_powers", "two_variables"): _two_variables,
    ("polynomials", "quadratic"): _quadratic,
    ("polynomials", "cubic"): _cubic,
    ("equations_with_powers", "products"): _products,
    ("equations_with_powers", "square_equals"): _square_equals,
    ("equations_with_powers", "bracket_equation"): _bracket_equation,
    ("roots", "root_of_squares"): _root_of_square,
    ("roots", "cube_root"): _cube_root,
    ("fractions", "linear_with_power"): _linear_fraction,
    ("inequalities", "quadratic"): _quadratic_inequality,
    ("inequalities", "linear"): _linear_inequality,
    ("controls", "linear_equation"): _control_equation,
    ("controls", "brackets"): _control_brackets,
    ("controls", "prose"): _control_prose,
    ("controls", "plain_text"): _control_text,
}


# Hyphens in ordinary text, so the model learns that "-" in words, ranges
# and dates is a hyphen (or an en dash), not a minus.
_HYPHENATED = (
    "well-known x-axis y-axis y-intercept x-intercept two-step one-step "
    "step-by-step left-hand right-hand long-term self-check re-check "
    "follow-up warm-up real-world two-digit three-digit non-zero "
    "multi-step co-ordinate mid-point up-to-date"
).split()


def _hyphenated_words(rng, spaced):
    words = [rng.choice(_WORDS) for _ in range(rng.randint(0, 2))]
    words.insert(rng.randrange(len(words) + 1), rng.choice(_HYPHENATED))
    if rng.random() < 0.5:
        words.insert(rng.randrange(len(words) + 1), rng.choice(_HYPHENATED))
    while len(" ".join(words)) > MAX_LABEL_LENGTH - 1 and len(words) > 1:
        words.pop(0)
    text = " ".join(words)
    if rng.random() < 0.6:
        text = text[0].upper() + text[1:]
    return [(text + rng.choice(["", ".", ":"]), False)]


def _ranges_and_dates(rng, spaced):
    dash = rng.choice(["-", "-", "–"])  # hyphen or en dash, labelled as drawn
    a = rng.randint(1, 60)
    kind = rng.randrange(5)
    if kind == 0:
        text = f"{rng.choice(['pages', 'Pages', 'p.', 'Questions', 'Items'])} {a}{dash}{a + rng.randint(1, 9)}"
    elif kind == 1:
        text = f"{a}{dash}{a + rng.randint(1, 20)} {rng.choice(['minutes', 'min', 'marks', 'points'])}"
    elif kind == 2:
        text = f"{rng.randint(2020, 2030)}-{rng.randint(1, 12):02d}-{rng.randint(1, 28):02d}"
    elif kind == 3:
        text = f"{rng.randint(1, 28):02d}-{rng.randint(1, 12):02d}-{rng.randint(2020, 2030)}"
    else:
        text = f"Grade {rng.randint(7, 12)} {dash} {rng.choice(['Algebra', 'Unit ' + str(rng.randint(1, 9)), 'Review', 'Quiz'])}"
    return [(text, False)]


TEMPLATES[("controls", "hyphenated_words")] = _hyphenated_words
TEMPLATES[("controls", "ranges_and_dates")] = _ranges_and_dates

ITEM_LABELS = ("{n}.", "{n})", "({l})", "{l})", "{l}.", "Q{n}.")


def with_item_label(line: Line, rng: random.Random) -> Line:
    """Puts an item label in front of the line ("3. x² + 1"), as on a worksheet."""

    label = rng.choice(ITEM_LABELS).format(n=rng.randint(1, 20), l=rng.choice("abcdefgh"))
    segments = [(f"{label} ", False)] + list(line.segments)
    if len(Line(line.topic, line.subcase, segments).label) > MAX_LABEL_LENGTH:
        return line
    return Line(line.topic, line.subcase, _merge(segments), line.fixed, {**line.notes, "item_label": label})


def with_minus(line: Line, glyph: str) -> Line:
    """Draws every minus as [glyph] ("-" hyphen or "−" true minus). Labels
    follow what is drawn; a raised minus is always labelled ⁻."""

    if glyph == MINUS:
        return line
    segments = [(text.replace(MINUS, glyph), raised) for text, raised in line.segments]
    return Line(line.topic, line.subcase, segments, line.fixed, {**line.notes, "minus": glyph})


def make_line(topic: str, subcase: str, example: str, rng: random.Random) -> Line:
    spaced = rng.random() < 0.6
    template = TEMPLATES.get((topic, subcase))
    if template is None:
        return Line(topic, subcase, from_unicode(example), fixed=True)
    return Line(topic, subcase, template(rng, spaced), notes={"spaced": spaced})


def fixed_line(topic: str, subcase: str, text: str) -> Line:
    return Line(topic, subcase, from_unicode(text), fixed=True)
