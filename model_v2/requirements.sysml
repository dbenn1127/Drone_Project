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

        requirement <'ACQ-7'> approvedPersonBecomesTarget {
        doc /* When the operator approves any displayed person, Tandem shall make that person the target. */
        subject tandem : TandemSystem;
        comment Source /* AcquireTarget */
        comment Rationale /* The operator's approval is the only way a person becomes a target. */
        comment Verify /* Test */
    }
            requirement <'ACQ-8'> confirmNewTarget {
        doc /* Tandem shall confirm a new target to the operator within 1s [TBR] of approval.*/
        subject tandem : TandemSystem;
        comment Source /* AcquireTarget */
        comment Rationale /* The operator must know the right person was locked before the drone moves. */
        comment Verify /* Test */
    }

        requirement <'ACQ-9'> alertNoPersonsFound {
        doc /* If a full scan finds no persons, Tandem shall alert the operator.*/
        subject tandem : TandemSystem;
        comment Source /* AcquireTarget */
        comment Rationale /* The operator should know the area looks empty, rather than waiting indefinitely. */
        comment Verify /* Test */
    }

        requirement <'ACQ-10'> removeDepartedPerson {
        doc /* Tandem shall remove a person from the operator's display within 1s [TBR] of them leaving view. */
        subject tandem : TandemSystem;
        comment Source /* AcquireTarget */
        comment Rationale /* The display must only offer people who can actually be selected. */
        comment Verify /* Test */
    }

        requirement <'ACQ-11'> refuseOutOfViewApproval {
        doc /* Tandem shall refuse an approval of a person who is no longer in view.*/
        subject tandem : TandemSystem;
        comment Source /* AcquireTarget*/
        comment Rationale /* Never lock onto someone Tandem can't see; prevents following a wrong or stale person. */
        comment Verify /* Test */
    }

            requirement <'ACQ-12'> explainRefusedApproval {
        doc /* When Tandem refuses an approval, it shall tell the operator why.*/
        subject tandem : TandemSystem;
        comment Source /* AcquireTarget */
        comment Rationale /* A refusal without a reason leaves the operator guessing what to do next. */
        comment Verify /* Demonstration */
    }

        requirement <'ACQ-13'> holdPositionWhileAcquiring {
        doc /* While no target is approved, Tandem shall hold position, moving only to rotate in place for scanning. */
        subject tandem : TandemSystem;
        comment Source /* AcquireTarget */
        comment Rationale /* No unapproved movement before a target exists; keeps the drone predictable while the operator decides. */
        comment Verify /* Test */
    }

            requirement <'LCH-1'> takeOffWhenArmed {
        doc /* When the operator commands launch while armed, Tandem shall take off.*/
        subject tandem : TandemSystem;
        comment Source /* LaunchDrone */
        comment Rationale /* Launch only happens through two deliberate operator actions: arm then command. */
        comment Verify /* Test */
    }

        requirement <'LCH-2'> reachLaunchAltitude {
        doc /* Tandem shall reach a launch altitude of 6m [TBR] +/- 1m [TBR] within 10s [TBR] of takeoff.*/
        subject tandem : TandemSystem;
        comment Source /* LaunchDrone */
        comment Rationale /* Search starts from a known height with a good camera angle; the tolerance allows for noraml altitude-hodl wander. */
        comment Verify /* Test */
    }

            requirement <'LCH-3'> noArmOnFailedPrechecks {
        doc /*When prechecks fail, Tandem shall refuse to arm. */
        subject tandem : TandemSystem;
        comment Source /* LaunchDrone */
        comment Rationale /* Never fly with a known fault. */
        comment Verify /* Test */
    }

        requirement <'LCH-4'> showPrecheckFailures {
        doc /* When prechecks fail, Tandem shall display precheck failures to the operator. */
        subject tandem : TandemSystem;
        comment Source /* Launch Drone */
        comment Rationale /* The operator needs to know what to fix. */
        comment Verify /* Demonstration */
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