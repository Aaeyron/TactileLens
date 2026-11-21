package com.tactilelens.app

/**
 * Agreement check between the two on-device formula models (the app's model
 * and the check model). Two readings agree when they give the same input to
 * the Nemeth table, so they would give the same Braille; everything after this
 * point (Liblouis, the Braille guard) is deterministic. A formula whose
 * readings disagree is held for review instead of showing Braille that may
 * read as a different formula.
 *
 * Measured on 40 held-out worksheet pages on the phone (2026-11-21): wrong
 * Braille shown without a hold went from 44 formulas to 2, while correctly
 * shown formulas went from 40 to 31.
 */
object FormulaAgreement {
    fun nemethInput(latex: String): String =
        BrailleMathNormalizer.toNemethInput(
            BrailleMathNormalizer.normalize(
                latex.replace('−', '-').replace('–', '-').replace('—', '-').trim(),
            ),
        )

    /** Both readings present and the same Nemeth input. */
    fun agrees(main: String, check: String?): Boolean {
        if (check == null || main.isBlank() || check.isBlank()) {
            return false
        }

        return nemethInput(main) == nemethInput(check)
    }
}
