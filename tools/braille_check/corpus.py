"""Worksheet corpus used by the round-trip check and the expert sample.

Self-written on 2026-11-17: 50 text blocks (instructions, numbers, capitals,
punctuation, abbreviations, single letters, lists, hyphenated words, text
with math) and 25 formulas as the formula model returns them (LaTeX).
"""

TEXT = {
    # instructions
    "t01": "Solve for x.",
    "t02": "Read each question carefully and show your work.",
    "t03": "Answer the following questions (5 points each).",
    "t04": "Write your final answer on the line provided.",
    # numbers inside words and sentences
    "t05": "There are 3 apples and 12 oranges in the basket.",
    "t06": "The 2nd and 3rd rows are 10cm wide.",
    "t07": "1,000,000 people live in the city.",
    "t08": "Score: 45/50 (90%)",
    "t09": "Time: 10:30 a.m. on Nov. 21, 2026",
    "t10": "Use 3.14 for pi and round to 2 decimal places.",
    "t11": "The answer is -5.",
    "t12": "Questions 1-10 are worth 2 points.",
    # capitals and all-caps
    "t13": "Chapter 2: Linear Equations",
    "t14": "NOTE: Write your answers in the box.",
    "t15": "USE A PENCIL ONLY.",
    "t16": "Do NOT write on the TEST PAPER.",
    "t17": "TactileLens McDonald iPhone",
    # punctuation
    "t18": "It's the students' turn; don't forget!",
    "t19": "She said, \"Math is fun.\"",
    "t20": "Name: ____________ Date: ________",
    "t21": "What is the value of y?",
    "t22": "(Hint: draw a picture first.)",
    # abbreviations
    "t23": "e.g. the value is 3.5, i.e. three and a half.",
    "t24": "Mr. Cruz gave Ms. Reyes 2 books.",
    "t25": "Find the area in sq. cm (approx.).",
    # single letters
    "t26": "Let x be a number.",
    "t27": "Is it a or b?",
    "t28": "Find the value of y when x is 4.",
    "t29": "Points A, B and C are on line l.",
    "t30": "Part A",
    # letters next to numbers
    "t31": "Item 3b and part 2a are optional.",
    "t32": "A1, B2 and C3",
    "t33": "Grade 7 Mathematics",
    "t34": "Q1. What is 5 times 6?",
    # lists
    "t35": "1. Simplify each expression.",
    "t36": "a) Find x.",
    "t37": "1. Add the numbers.\n2. Subtract the smaller number.\n3. Check your answer.",
    "t38": "a) Solve for x.\nb) Solve for y.",
    "t39": "(a) 12\n(b) 15",
    "t40": "Directions:\n1. Read the problem.\n2. Show your solution.",
    # hyphenated words
    "t41": "a well-known self-test with twenty-one items",
    "t42": "x-axis and y-intercept",
    "t43": "a two-step equation",
    # mixed text + math lines (as offline text blocks; math stays as text)
    "t44": "Solve 2x + 3 = 7 for x.",
    "t45": "Find x if 3x = 12.",
    "t46": "If a = 2 and b = 5, find a + b.",
    "t47": "Evaluate x^2 when x = 3.",
    "t48": "Simplify 4(x - 2).",
    # long paragraph (line-length checks)
    "t49": (
        "A rectangle has a length of 12 centimeters and a width of 5 centimeters. "
        "Find its perimeter and its area, and show every step of your solution."
    ),
    "t50": "Page 12 of 20",
}

# Nemeth formula inputs as LaTeX (what the offline formula model returns).
FORMULA = {
    "f01": r"2x+3=7",
    "f02": r"x^{2}-5x+6=0",
    "f03": r"\frac{x+1}{2}=3",
    "f04": r"3x-5\leq 10",
    "f05": r"y=mx+b",
    "f06": r"x^{2}+y^{2}=r^{2}",
    "f07": r"\left(x+2\right)\left(x-3\right)",
    "f08": r"a\neq 0",
    "f09": r"\frac{3x}{10}=6",
    "f10": r"2\left(x-4\right)=10",
    "f11": r"x \times 3 = 12",
    "f12": r"12 \div 4 = 3",
    "f13": r"\sqrt{x+9}=5",
    "f14": r"\text{6.}\ 3x^{2}-x-2=0",
    "f15": r"-\frac{1}{2}x+4",
    "f16": r"x = 3.5",
    "f17": r"f(x)=2x^{3}-1",
    "f18": r"\pi r^{2}",
    "f19": r"x_{1}+x_{2}",
    "f20": r"\begin{array}{c}x+y=5\\x-y=1\end{array}",
    "f21": r"x \geq -2",
    "f22": r"\frac{x-4}{2}-\frac{x}{5}=\frac{1}{10}",
    "f23": r"10^{-3}",
    "f24": r"\text{the area of the square}",
    "f25": r"\lefted{x}+1",
}
