package TandemRequirements {
    private import Tandem::*;
    package Acquire {
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
            doc /* While no target is approved, Tandem shall propose one displayed person [selection rule TBD, e.g. nearest; after an overlap, the person Tandem judges most likely to be the previous target] for operator approval. */
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
    }
    package Launch {    
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

    }
    package Follow {
        requirement <'FLW-1'> stayInFramingZone {
            doc /* While following a target moving at up to 3 m/s [TBR], Tandem shall keep the drone within the configured framing zone (distance ±2 m [TBR]). */
            subject tandem : TandemSystem;
            comment Source /* FilmTarget */
            comment Rationale /* The operator gets a stable view of the person within their chosen framing. */
            comment Verify /* Test */
        }

        requirement <'FLW-2'> holdInsideZone {
            doc /* While the drone is inside the framing zone, Tandem shall not move it to correct its offset. */
            subject tandem : TandemSystem;
            comment Source /* FilmTarget */
            comment Rationale /* Avoids needless swings on turns; smoother video, less battery.*/
            comment Verify /* Test */
        }
        requirement <'FLW-3'> configurableFollowSettings {
            doc /* Tandem shall allow the operator to set distance, angle, zone width and height within the ranges in [the table]. */
            subject tandem : TandemSystem;
            comment Source /* FilmTarget */
            comment Rationale /* The operator chooses the view that suits the task. */
            comment Verify /* Demonstration */
        }

        requirement <'FLW-4'> limitCameraToTargetDistance {
            doc /* Tandem shall not accept settings whose combined camera-to-target distance exceeds 20m [TBR].*/
            subject tandem : TandemSystem;
            comment Source /* FilmTarget */
            comment Rationale /* Beyond 20m the person cannot be reliably detected. */
            comment Verify /* Test */
        }

        requirement <'FLW-5'> keepTargetCentered {
            doc /* While following a target moving at up to 3m/s [TBR], Tandem shall keep the target within ±10° [TBR] of the center of the camera view. */
            subject tandem : TandemSystem;
            comment Source /* FilmTarget*/
            comment Rationale /* The operator sees the person framed, not drifting out of the picture. */
            comment Verify /* Test */
        }

        requirement <'FLW-6'> noUnplannedFollowStop {
            doc /* Tandem shall not stop or suspend following unless the target is lost, the operator pauses or ends the flight, the pilot takes manual control, or a failsafe triggers. */
            subject tandem : TandemSystem;
            comment Source /* FilmTarget */
            comment Rationale /* Following only ends by decisions or for safety, never by itself. */
            comment Verify /* Test */
        }
        requirement <'FLW-7'> freezeZoneWhenStationary {
            doc /* While the target is stationary, Tandem shall keep the framing zone fixed relative to the target's last direction of travel. */
            subject tandem : TandemSystem;
            comment Definition /* Stationary: the target moves less than 0.5m [TBR] within 2s [TBR]. */
            comment Source /* FilmTarget*/
            comment Rationale /* Prevents the drone wandering while the person stands still; the zone has no meaning without a direction of travel.*/
            comment Verify /* Test */
        }

        requirement <'FLW-8'> lostAfterNotSeen {
            doc /* Tandem shall treat the target as lost when it has not been seen for 2s [TBR]. */
            subject tandem : TandemSystem;
            comment Source /* FilmTarget*/
            comment Rationale /* Brief gaps must not drop the target, but a target that's really gone must not be recognized so the drone stops acting on stale information.*/
            comment Verify /* Test */
        }

        requirement <'FLW-9'> returnToAcquisitionWhenLost {
            doc /* When the target is lost, Tandem shall return to target acquisition. */
            subject tandem : TandemSystem;
            comment Source /* FilmTarget */
            comment Rationale /* Losing the target mus tnever lead to following someone else unapproved; re-entering ecquisition reuses human approval path. */
            comment Verify /* Test */
        }

        requirement <'FLW-10'> alertOperatorWhenLost {
            doc /* When the target is lost, Tandem shall alert the operator within 1s [TBR]. */
            subject tandem : TandemSystem;
            comment Source /* FilmTarget */
            comment Rationale /* The operator must know the follow has stopped so they can watch for the person and re-approve. */
            comment Verify /* Test */
        }
        requirement <'FLW-11'> alertFallingBehind {
            doc /* When the drone has been farther than the configured distance plus 2m [TBR] for more than 3s [TBR], Tandem shall alert the opreator it is falling behind. */
            subject tandem : TandemSystem;
            comment Source /* FilmTarget */
            comment Rationale /* Gives the operator time to act before the target is lost. */
            comment Verify /* Test */
        }

        requirement <'FLW-12'> reacquireOnOverlap {
            doc /* When another person overlaps the target in view, Tandem shall return to target acquisition. */
            subject tandem : TandemSystem;
            comment Source /* FilmTarget*/
            comment Rationale /* Tandem cannot detect an identity swap itself, so it asks the operator to re-approve whenever a swap is possible. */
            comment Verify /* Test*/
        }

        requirement <'FLW-13'> rejectOutOfRangeSettings {
            doc /* Tandem shall not accept a follow setting outside its allowed range. */
            subject tandem : TandemSystem;
            comment Source /* AdjustFraming */
            comment Rationale /* Settings outside their ranges could put the drone inside the keep-out zone or beyond reliable detection. */
            comment Verify /* Test */
        }

        requirement <'FLW-14'> showAllowedRange {
            doc /* When Tandem refuses a follow setting, it shall show the operator the allowed range. */
            subject tandem : TandemSystem;
            comment Source /* AdjustFraming */
            comment Rationale /* The operator needs to know what is allowed to correct the entry quickly. */
            comment Verify /* Demonstration */
        }
    }
    
    package PreFlight {
        requirement <'PRE-1'> readyOnlyWhenPrechecksPass {
            doc /* Tandem shall not report ready unless all prechecks pass. */
            subject tandem : TandemSystem;
            comment Definition /* Precheks: ground-statin link, RC link, GPS position, camera, battery above minimum [TBR], flight-safety checks. */
            comment Source /* PrepareForFlight */
            comment Rationale /**/
            comment Verify /**/
        }

        requirement <'PRE-2'> noArmOnFailedPrechecks {
            doc /*When prechecks fail, Tandem shall refuse to arm. */
            subject tandem : TandemSystem;
            comment Source /* PrepareForFlight */
            comment Rationale /* Never fly with a known fault. */
            comment Verify /* Test */
        }

        requirement <'PRE-3'> showPrecheckFailures {
            doc /* When prechecks fail, Tandem shall display precheck failures to the operator. */
            subject tandem : TandemSystem;
            comment Source /* PrepareForFlight*/
            comment Rationale /* The operator needs to know what to fix. */
            comment Verify /* Demonstration */
        }
        requirement <'PRE-4'> confirmSettingsBeforeArming {
            doc /* Tandem shall not arm until the operator has confirmed the follow settings. */
            subject tandem : TandemSystem;
            comment Source /* PrepareForFlight */
            comment Rationale /* Prevents flying on the settings left over from a previous flight without the operator noticing. */
            comment Verify /* Test */
        }
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