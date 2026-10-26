package TandemRequirements {
    private import Tandem::*;
    package Acquire {
        requirement <'ACQ-1'> noFollowWithoutApproval {
            doc /* Tandem shall not begin following a person until the operator has approved that person. */
            subject tandem : TandemSystem;
            comment Rationale /* No one is followed without a human decision. */
            comment Verify /* Test */
        }

        requirement <'ACQ-2'> fullCircleSearch {
            doc /* When no persons are in view, Tandem shall scan for persons through a full circle within 30 s [TBR]. */
            subject tandem : TandemSystem;
            comment Rationale /* Find a person anywhere around the drone without operator steering. */
            comment Verify /* Test */
        }

        requirement <'ACQ-3'> detectedPersonDisplay {
            doc /* While no target is approved, Tandem shall display every person in view to the operator as selectable within 1s [TBR] of the person entering view.*/
            subject tandem : TandemSystem;
            comment Rationale /* All detected persons presented to operator for target selection in a timely manner. */
            comment Verify /* Test */
        }

        requirement <'ACQ-4'> proposeOnePerson {
            doc /* While no target is approved, Tandem shall propose one displayed person [selection rule TBD, e.g. nearest; after an overlap, the person Tandem judges most likely to be the previous target] for operator approval. */
            subject tandem : TandemSystem;
            comment Rationale /* Gives most likely person based on selection rule to approve first. */
            comment Verify /* Test */
        }

        requirement <'ACQ-5'> noReproposeRejected {
            doc /* When the operator rejects a proposed person, Tandem shall not propose that person again during the current acquisition. */
            subject tandem : TandemSystem;
            comment Rationale /* Do not want to continously disapprove the same person. */
            comment Verify /* Test */
        }

        requirement <'ACQ-6'> proposeNextAfterReject {
            doc /* When the operator rejects a proposed person, Tandem shall propose another person in view, or scan for persons (ACQ-2) if no other person is in view. */
            subject tandem : TandemSystem;
            comment Rationale /* Find next available target or reinitiate scan. */
            comment Verify /* Test */
        }

        requirement <'ACQ-7'> approvedPersonBecomesTarget {
            doc /* When the operator approves any displayed person, Tandem shall make that person the target. */
            subject tandem : TandemSystem;
            comment Rationale /* The operator's approval is the only way a person becomes a target. */
            comment Verify /* Test */
        }
        requirement <'ACQ-8'> confirmNewTarget {
            doc /* Tandem shall confirm a new target to the operator within 1s [TBR] of approval.*/
            subject tandem : TandemSystem;
            comment Rationale /* The operator must know the right person was locked before the drone moves. */
            comment Verify /* Test */
        }

        requirement <'ACQ-9'> alertNoPersonsFound {
            doc /* If a full scan finds no persons, Tandem shall alert the operator.*/
            subject tandem : TandemSystem;
            comment Rationale /* The operator should know the area looks empty, rather than waiting indefinitely. */
            comment Verify /* Test */
        }

        requirement <'ACQ-10'> removeDepartedPerson {
            doc /* Tandem shall remove a person from the operator's display within 1s [TBR] of them leaving view. */
            subject tandem : TandemSystem;
            comment Rationale /* The display must only offer people who can actually be selected. */
            comment Verify /* Test */
        }

        requirement <'ACQ-11'> refuseOutOfViewApproval {
            doc /* Tandem shall refuse an approval of a person who is no longer in view.*/
            subject tandem : TandemSystem;
            comment Rationale /* Never lock onto someone Tandem can't see; prevents following a wrong or stale person. */
            comment Verify /* Test */
        }

        requirement <'ACQ-12'> explainRefusedApproval {
            doc /* When Tandem refuses an approval, it shall tell the operator why.*/
            subject tandem : TandemSystem;
            comment Rationale /* A refusal without a reason leaves the operator guessing what to do next. */
            comment Verify /* Demonstration */
        }

        requirement <'ACQ-13'> holdPositionWhileAcquiring {
            doc /* While no target is approved, Tandem shall hold position, moving only to rotate in place for scanning. */
            subject tandem : TandemSystem;
            comment Rationale /* No unapproved movement before a target exists; keeps the drone predictable while the operator decides. */
            comment Verify /* Test */
        }
    }
    package Launch {    
        requirement <'LCH-1'> takeOffWhenArmed {
            doc /* When the operator commands launch while armed, Tandem shall take off.*/
            subject tandem : TandemSystem;
            comment Rationale /* Launch only happens through two deliberate operator actions: arm then command. */
            comment Verify /* Test */
        }

        requirement <'LCH-2'> reachLaunchAltitude {
            doc /* Tandem shall reach a launch altitude of 6m [TBR] +/- 1m [TBR] within 10s [TBR] of takeoff.*/
            subject tandem : TandemSystem;
            comment Rationale /* Search starts from a known height with a good camera angle; the tolerance allows for noraml altitude-hodl wander. */
            comment Verify /* Test */
        }

    }
    package Follow {
        requirement <'FLW-1'> stayInFramingZone {
            doc /* While following a target moving at up to 3 m/s [TBR], Tandem shall keep the drone within the configured framing zone (distance ±2 m [TBR]). */
            subject tandem : TandemSystem;
            comment Rationale /* The operator gets a stable view of the person within their chosen framing. */
            comment Verify /* Test */
        }

        requirement <'FLW-2'> holdInsideZone {
            doc /* While the drone is inside the framing zone, Tandem shall not move it to correct its offset. */
            subject tandem : TandemSystem;
            comment Rationale /* Avoids needless swings on turns; smoother video, less battery.*/
            comment Verify /* Test */
        }
        requirement <'FLW-3'> configurableFollowSettings {
            doc /* Tandem shall allow the operator to set distance, angle, zone width and height within the ranges in [the table]. */
            subject tandem : TandemSystem;
            comment Rationale /* The operator chooses the view that suits the task. */
            comment Verify /* Demonstration */
        }

        requirement <'FLW-4'> limitCameraToTargetDistance {
            doc /* Tandem shall not accept settings whose combined camera-to-target distance exceeds 20m [TBR].*/
            subject tandem : TandemSystem;
            comment Rationale /* Beyond 20m the person cannot be reliably detected. */
            comment Verify /* Test */
        }

        requirement <'FLW-5'> keepTargetCentered {
            doc /* While following or paused, with the target moving at up to 3 m/s [TBR], Tandem shall keep the target within ±10° [TBR] of the centre of the camera view. */
            subject tandem : TandemSystem;
            comment Rationale /* The operator sees the person framed, not drifting out of the picture. */
            comment Verify /* Test */
        }

        requirement <'FLW-6'> noUnplannedFollowStop {
            doc /* Tandem shall not stop or suspend following unless the target is lost, the operator pauses or ends the flight, the pilot takes manual control, or a failsafe triggers. */
            subject tandem : TandemSystem;
            comment Rationale /* Following only ends by decisions or for safety, never by itself. */
            comment Verify /* Test */
        }
        requirement <'FLW-7'> freezeZoneWhenStationary {
            doc /* While the target is stationary, Tandem shall keep the framing zone fixed relative to the target's last direction of travel. */
            subject tandem : TandemSystem;
            comment Definition /* Stationary: the target moves less than 0.5m [TBR] within 2s [TBR]. */
            comment Rationale /* Prevents the drone wandering while the person stands still; the zone has no meaning without a direction of travel.*/
            comment Verify /* Test */
        }

        requirement <'FLW-8'> lostAfterNotSeen {
            doc /* Tandem shall treat the target as lost when it has not been seen for 2s [TBR]. */
            subject tandem : TandemSystem;
            comment Rationale /* Brief gaps must not drop the target, but a target that's really gone must not be recognized so the drone stops acting on stale information.*/
            comment Verify /* Test */
        }

        requirement <'FLW-9'> returnToAcquisitionWhenLost {
            doc /* When the target is lost, Tandem shall return to target acquisition. */
            subject tandem : TandemSystem;
            comment Rationale /* Losing the target mus tnever lead to following someone else unapproved; re-entering ecquisition reuses human approval path. */
            comment Verify /* Test */
        }

        requirement <'FLW-10'> alertOperatorWhenLost {
            doc /* When the target is lost, Tandem shall alert the operator within 1s [TBR]. */
            subject tandem : TandemSystem;
            comment Rationale /* The operator must know the follow has stopped so they can watch for the person and re-approve. */
            comment Verify /* Test */
        }
        requirement <'FLW-11'> alertFallingBehind {
            doc /* When the drone has been farther than the configured distance plus 2m [TBR] for more than 3s [TBR], Tandem shall alert the opreator it is falling behind. */
            subject tandem : TandemSystem;
            comment Rationale /* Gives the operator time to act before the target is lost. */
            comment Verify /* Test */
        }

        requirement <'FLW-12'> reacquireOnOverlap {
            doc /* When another person overlaps the target in view, Tandem shall return to target acquisition. */
            subject tandem : TandemSystem;
            comment Rationale /* Tandem cannot detect an identity swap itself, so it asks the operator to re-approve whenever a swap is possible. */
            comment Verify /* Test*/
        }

        requirement <'FLW-13'> rejectOutOfRangeSettings {
            doc /* Tandem shall not accept a follow setting outside its allowed range. */
            subject tandem : TandemSystem;
            comment Rationale /* Settings outside their ranges could put the drone inside the keep-out zone or beyond reliable detection. */
            comment Verify /* Test */
        }

        requirement <'FLW-14'> showAllowedRange {
            doc /* When Tandem refuses a follow setting, it shall show the operator the allowed range. */
            subject tandem : TandemSystem;
            comment Rationale /* The operator needs to know what is allowed to correct the entry quickly. */
            comment Verify /* Demonstration */
        }

        requirement <'FLW-17'> gradualRepositioning {
            doc /* When the follow settings change or following resumes, Tandem shall move the drone to the new position at no more than 2 m/s [TBR] relative to the target. */
            subject tandem : TandemSystem;
            comment Rationale /* Smooth video, and predictable movement near the target. */
            comment Verify /* Test */
        }

        requirement <'FLW-18'> newestSettingsWins {
            doc /* When the operator changes the follow settings during a move from a previous change, Tandem shall move toward the newest settings.*/
            subject tandem : TandemSystem;
            comment Rationale /* The drone always heads where the operator currently wants, it does not finish an outdated move. */
            comment Verify /* Test */
        }

        requirement <'FLW-19'> holdOnPause {
            doc /* When the operator commands pause, Tandem shall hold the drone's position. */
            subject tandem : TandemSystem;
            comment Rationale /* Let the operator stop the drone's movement without losing the target. */
            comment Verify /* Test */
        }

        requirement <'FLW-20'> resume {
            doc /* When the operator commands resume, Tandem shall resume following the current target without re-approval. */
            subject tandem : TandemSystem;
            comment Rationale /* The target was tracked throughout the pause, so asking the operator to re-approve would add a step with no safety benefit. */
            comment Verify /* Test */
        }


        // --- traceability ---
        private import TandemUseCases::*;
        dependency from stayInFramingZone           to FilmTarget::stayInZone;
        dependency from holdInsideZone              to FilmTarget::stayInZone;
        dependency from keepTargetCentered          to FilmTarget::keepCentered;
        dependency from noUnplannedFollowStop       to FilmTarget::repeatUntilStopped;
        dependency from freezeZoneWhenStationary    to FilmTarget::targetStill;
        dependency from lostAfterNotSeen            to FilmTarget::targetLost;
        dependency from returnToAcquisitionWhenLost to FilmTarget::targetLost;
        dependency from alertOperatorWhenLost       to FilmTarget::targetLost;
        dependency from alertFallingBehind          to FilmTarget::fallingBehind;
        dependency from reacquireOnOverlap          to FilmTarget::overlap;

        dependency from configurableFollowSettings  to AdjustFraming::enterValues;
        dependency from limitCameraToTargetDistance to AdjustFraming::outOfRange;
        dependency from rejectOutOfRangeSettings    to AdjustFraming::outOfRange;
        dependency from showAllowedRange            to AdjustFraming::outOfRange;
        dependency from confirmSettingsReceived     to AdjustFraming::confirmReceived;
        dependency from alertSettingsNotApplied     to AdjustFraming::notReceived;
        dependency from gradualRepositioning        to AdjustFraming::moveGradually;
        dependency from newestSettingsWin           to AdjustFraming::newestWins;

        dependency from rejectOutOfRangeSettings    to PrepareForFlight::invalidSetting;
        dependency from showAllowedRange            to PrepareForFlight::invalidSetting;

        dependency from resumeSameTarget            to PauseFollowing::selectResume;
        dependency from resumeSameTarget            to PauseFollowing::returnToZone;
        dependency from keepTargetCentered          to PauseFollowing::holdAndTrack;
        dependency from gradualRepositioning        to PauseFollowing::returnToZone;
    }
    
    package PreFlight {
        requirement <'PRE-1'> readyOnlyWhenPrechecksPass {
            doc /* Tandem shall not report ready unless all prechecks pass. */
            subject tandem : TandemSystem;
            comment Definition /* Precheks: ground-statin link, RC link, GPS position, camera, battery above minimum [TBR], flight-safety checks. */
            comment Rationale /**/
            comment Verify /**/
        }

        requirement <'PRE-2'> noArmOnFailedPrechecks {
            doc /*When prechecks fail, Tandem shall refuse to arm. */
            subject tandem : TandemSystem;
            comment Rationale /* Never fly with a known fault. */
            comment Verify /* Test */
        }

        requirement <'PRE-3'> showPrecheckFailures {
            doc /* When prechecks fail, Tandem shall display precheck failures to the operator. */
            subject tandem : TandemSystem;
            comment Rationale /* The operator needs to know what to fix. */
            comment Verify /* Demonstration */
        }
        requirement <'PRE-4'> confirmSettingsBeforeArming {
            doc /* Tandem shall not arm until the operator has confirmed the follow settings. */
            subject tandem : TandemSystem;
            comment Rationale /* Prevents flying on the settings left over from a previous flight without the operator noticing. */
            comment Verify /* Test */
        }
    }

    package CrossCutting {
        private import TandemUseCases::*;

        requirement <'XC-1'> confirmOperatorCommands {
            doc /* Tandem shall confirm each operator command to the operator within 1 s [TBR]. */
            subject tandem : TandemSystem;
            comment Rationale /* The operator must always know whether a command took effect. */
            comment Verify /* Test */
        }
        requirement <'XC-2'> alertCommandNotApplied {
            doc /* When an operator command is not confirmed within 1 s [TBR], Tandem shall tell the operator it was not applied. */
            subject tandem : TandemSystem;
            comment Rationale /* The operator must never assume a command took effect when it did not. */
            comment Verify /* Test */
        }

        // --- traceability ---
        dependency from confirmOperatorCommands     to AdjustFraming::confirmReceived;
        dependency from confirmOperatorCommands     to PauseFollowing::confirmPaused;
        dependency from alertCommandNotApplied      to AdjustFraming::notReceived;
        dependency from alertCommandNotApplied      to PauseFollowing::pauseNotConfirmed;
    }

    package EndFlight {
        
        requirement <'END-1'> returnToLaunchPoint {
            doc /*When the operator commands return to launch, Tandem shall fly to within 2m of the launch point at the return altitude (6m [TBR]). */
            subject tandem : TandemSystem;
            comment Rationale /* Brings the drone back to where the operator is, at a height known to be clear. */
            comment Verify /* Test */
        }
    
        requirement <'END-2'> landInPlace {
            doc /* When the operator commands land here, Tandem shall land within 10m [TBR] horizontally of its position at the time of the command. */
            subject tandem : TandemSystem;
            comment Rationale /* error budget at top speed: 0.5s command latency (2.5m) + braking (~5m) + position error (~2m), plus margin. */
            comment Verify /* Test */
        }

        requirement <'END-3'> releaseTargetOnEnd {
            doc /* When the operator commands end flight, Tandem shall stop following the target. */
            subject tandem : TandemSystem;
            comment Rationale /* Once the flight is ending, the drone's job is to land safely. not to keep chasing someone. */
            comment Verify /* Test */
        }

        requirement <'END-4'> disarmAfterLanding {
            doc /* When the drone has landed, Tandem shall disarm within 3s [TBR]. */
            subject tandem : TandemSystem;
            comment Rationale /* Spinning props on the ground are a hazard to anyone approaching the drone. */
            comment Verify /* Test */
        }

        requirement <'END-5'> showLandingSpot {
            doc /* During descent, Tandem shall show the operator a live view of the area beneath the drone. */
            subject tandem : TandemSystem;
            comment Rationale /* Tandem can't sense obstacles below, so the operator needs to see the spot to takeover if it is not clear. */
            comment Verify /* Demonstration */
        }

        requirement <'END-6'> holdIfPersonBelow {
            doc /* During descent, if a person is detected beneath the drone, Tandem shall stop descending and hold its position. */
            subject tandem : TandemSystem;
            comment Rationale /* Never continue lowering a drone onto a person.*/
            comment Verify /* Test */
        }

        requirement <'END-7'> alertPersonBelow {
            doc /* When Tandem stops a descent because a person is beneath it, tandem shall alert the operator within 1s [TBR]. */
            subject tandem : TandemSystem;
            comment Rationale /* The operator needs to know why the landing stoppedm so they can decide what to do. */
            comment Verify /* Test */
        }

        requirement <'END-8'> landIfPositionLost {
            doc /* If Tandem loses its position during a return to launch, Tandem shall land in place. */
            subject tandem : TandemSystem;
            comment Rationale /* Without a position the drone cannot find the launch point; landing where it is slowly is the safest option. */
            comment Verify /* Test */
        }

        requirement <'END-9'> alertPositionLost {
            doc /* When tandem lands in place because its position was lost, Tandem shall alert the operator within 1s [TBR]. */
            subject tandem : TandemSystem;
            comment Rationale /* The pilot can still fly by RC without position and may prefer to bring the drone back manually. */
            comment Verify /* Test */
        }
        //--- Traceability ---
        private import TandemUseCases::*;
        dependency from returnToLaunchPoint to EndFlight::selectEndFlight;
        dependency from returnToLaunchPoint to EndFlight::returnToLaunch;
        dependency from landInPlace         to EndFlight::selectEndFlight;
        dependency from landInPlace         to EndFlight::landHere;
        dependency from releaseTargetOnEnd  to EndFlight::confirmEnd;
        dependency from disarmAfterLanding  to EndFlight::disarm;
        dependency from showLandingSpot     to EndFlight::watchLandingSpot;
        dependency from holdIfPersonBelow   to EndFlight::personBelow;
        dependency from alertPersonBelow    to EndFlight::personBelow;
        dependency from landIfPositionLost  to EndFlight::positionLost;
        dependency from alertPositionLost to EndFlight::positionLost;
    }
        
package Constraints {

        requirement <'CON-1'> limitDescentRate {
            doc /* When landing, Tandem shall descend at no more than 0.6 m/s [TBR]. */
            subject tandem : TandemSystem;
            comment Rationale /* A slow descent gives the operator time to watch the spot and take over, and gives Tandem time to spot a person below. */
            comment Verify /**/
        }

        requirement <'CON-2'> {
            doc /**/
            subject tandem : TandemSystem;
            comment Rationale /**/
            comment Verify /**/
        }

    // ---- Traceability ----
        private import TandemUseCases::*;
        dependency from limitDescentRate    to EndFlight::descendAndLand;
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