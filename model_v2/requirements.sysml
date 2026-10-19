package TandemRequirements {
    private import Tandem::*;

    requirement <'ACQ-1'> noFollowWithoutApproval {
        doc /* Tandem shall not begin following a person until the operator has approved that person. */
        subject tandem : TandemSystem;
        comment Source /* AcquireTarget */
        comment Rationale /* No one is followed without a human decision. */
        comment Verify /* Test */
    }

    requirement <'ACQ-2'> fullCircleSearch {
        doc /* When no persons are in view, Tandem shall scan for persons through a full circle within 30 s [TBR]. */
        subject tandem : TandemSystem;
        comment Source /* AcquireTarget */
        comment Rationale /* Find a person anywhere around the drone without operator steering. */
        comment Verify /* Test */
    }

    requirement <'ACQ-3'> detectedPersonDisplay {
        doc /* While no target is approved, Tandem shall display every person in view to the operator as selectable within 1s [TBR] of the person entering view.*/
        subject tandem : TandemSystem;
        comment Source /* AcquireTarget */
        comment Rationale /* All detected persons presented to operator for target selection in a timely manner. */
        comment Verify /* Test */
    }

    requirement <'ACQ-4'> proposeOnePerson {
        doc /* While no target is approved, Tandem shall propose one displayed person [selection rule TBD, e.g. nearest] for operator approval.*/
        subject tandem : TandemSystem;
        comment Source /* AcquireTarget*/
        comment Rationale /* Gives most likely person based on selection rule to approve first. */
        comment Verify /* Test */
    }

    requirement <'ACQ-5'> noReproposeRejected {
        doc /* When the operator rejects a proposed person, Tandem shall not propose that person again during the current acquisition. */
        subject tandem : TandemSystem;
        comment Source /* AcquireTarget */
        comment Rationale /* Do not want to continously disapprove the same person. */
        comment Verify /* Test */
    }

    requirement <'ACQ-6'> proposeNextAfterReject {
        doc /* When the operator rejects a proposed person, Tandem shall propose another person in view, or scan for persons (ACQ-2) if no other person is in view. */
        subject tandem : TandemSystem;
        comment Source /* AcquireTarget*/
        comment Rationale /* Find next available target or reinitiate scan. */
        comment Verify /* Test */
    }

        requirement <'ACQ-7'> {
        doc /* When the operator approves any displayed person, Tandem shall make that person the target. */
        subject tandem : TandemSystem;
        comment Source /**/
        comment Rationale /**/
        comment Verify /**/
    }
            requirement <'ACQ-8'> {
        doc /* Tandem shall confirm a new target to the operator within 1s [TBR] of approval.*/
        subject tandem : TandemSystem;
        comment Source /**/
        comment Rationale /**/
        comment Verify /**/
    }

        requirement <'ACQ-9'> {
        doc /* If a full scan finds no persons, Tandem shall alert the operator.*/
        subject tandem : TandemSystem;
        comment Source /**/
        comment Rationale /**/
        comment Verify /**/
    }

        requirement <'ACQ-10'> {
        doc /* Tandem shall remove a person from the operator's display within 1s [TBR] of them leaving view. */
        subject tandem : TandemSystem;
        comment Source /**/
        comment Rationale /**/
        comment Verify /**/
    }

        requirement <'ACQ-11'> {
        doc /* Tandem shall refuse an approval of a person who is no longer in view.*/
        subject tandem : TandemSystem;
        comment Source /**/
        comment Rationale /**/
        comment Verify /**/
    }

            requirement <'ACQ-12'> {
        doc /* When tandem refuses an approval, it shall tell the operator why.*/
        subject tandem : TandemSystem;
        comment Source /**/
        comment Rationale /**/
        comment Verify /**/
    }

        requirement <'ACQ-13'> {
        doc /* While no target is approved, Tandem shall hold position, moving only to rotate in place for scanning. */
        subject tandem : TandemSystem;
        comment Source /**/
        comment Rationale /**/
        comment Verify /**/
    }

            requirement <''> {
        doc /**/
        subject tandem : TandemSystem;
        comment Source /**/
        comment Rationale /**/
        comment Verify /**/
    }

        requirement <''> {
        doc /**/
        subject tandem : TandemSystem;
        comment Source /**/
        comment Rationale /**/
        comment Verify /**/
    }

            requirement <''> {
        doc /**/
        subject tandem : TandemSystem;
        comment Source /**/
        comment Rationale /**/
        comment Verify /**/
    }

        requirement <''> {
        doc /**/
        subject tandem : TandemSystem;
        comment Source /**/
        comment Rationale /**/
        comment Verify /**/
    }

            requirement <''> {
        doc /**/
        subject tandem : TandemSystem;
        comment Source /**/
        comment Rationale /**/
        comment Verify /**/
    }

        requirement <''> {
        doc /**/
        subject tandem : TandemSystem;
        comment Source /**/
        comment Rationale /**/
        comment Verify /**/
    }
}