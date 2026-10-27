package TandemRequirements {
    private import Tandem::*;
    
    requirement def TandemRequirement {
        subject tandem : TandemSystem;
    }

    package PreFlight {

        requirement <'PRE-1'> readyOnlyWhenPrechecksPass : TandemRequirement {
            doc /* Tandem shall not report ready unless all prechecks pass. */
            comment Definition /* Prechecks: ground-station link, RC link, GPS position, camera, battery above minimum [TBR], flight-safety checks. */
            comment Rationale /* Never fly with a known fault or without a way for the pilot to take over. */
            comment Verify /* Test */
        }

        requirement <'PRE-2'> noArmOnFailedPrechecks : TandemRequirement {
            doc /* When prechecks fail, Tandem shall refuse to arm. */
            comment Rationale /* Never fly with a known fault. */
            comment Verify /* Test */
        }

        requirement <'PRE-3'> showPrecheckFailures : TandemRequirement {
            doc /* When prechecks fail, Tandem shall display precheck failures to the operator. */
            comment Rationale /* The operator needs to know what to fix. */
            comment Verify /* Demonstration */
        }
        requirement <'PRE-4'> confirmSettingsBeforeArming : TandemRequirement {
            doc /* Tandem shall not arm until the operator has confirmed the follow settings. */
            comment Rationale /* Prevents flying on the settings left over from a previous flight without the operator noticing. */
            comment Verify /* Test */
        }

    }

    package Launch {   

        requirement <'LCH-1'> takeOffWhenArmed : TandemRequirement {
            doc /* When the operator commands launch while armed, Tandem shall take off.*/
            comment Rationale /* Launch only happens through two deliberate operator actions: arm then command. */
            comment Verify /* Test */
        }

        requirement <'LCH-2'> reachLaunchAltitude : TandemRequirement {
            doc /* Tandem shall reach a launch altitude of 6m [TBR] +/- 1m [TBR] within 10s [TBR] of takeoff.*/
            comment Rationale /* Search starts from a known height with a good camera angle; the tolerance allows for normal altitude-hold wander. */
            comment Verify /* Test */
        }

    }

    package Acquire {

        requirement <'ACQ-1'> noFollowWithoutApproval : TandemRequirement {
            doc /* Tandem shall not begin following a person until the operator has approved that person. */
            comment Rationale /* No one is followed without a human decision. */
            comment Verify /* Test */
        }

        requirement <'ACQ-2'> fullCircleSearch : TandemRequirement {
            doc /* When no persons are in view, Tandem shall scan for persons through a full circle within 30 s [TBR]. */
            comment Rationale /* Find a person anywhere around the drone without operator steering. */
            comment Verify /* Test */
        }

        requirement <'ACQ-3'> detectedPersonDisplay : TandemRequirement {
            doc /* During target acquisition, Tandem shall display every person in view to the operator as selectable within 1s [TBR] of the person entering view.*/
            comment Rationale /* All detected persons presented to operator for target selection in a timely manner. */
            comment Verify /* Test */
        }

        requirement <'ACQ-4'> proposeOnePerson : TandemRequirement {
            doc /* During target acquisition, Tandem shall propose one displayed person [selection rule TBD, e.g. nearest; after an overlap, the person Tandem judges most likely to be the previous target] for operator approval. */
            comment Rationale /* Gives most likely person based on selection rule to approve first. */
            comment Verify /* Test */
        }

        requirement <'ACQ-5'> noReproposeRejected : TandemRequirement {
            doc /* When the operator rejects a proposed person, Tandem shall not propose that person again during the current acquisition. */
            comment Rationale /* Do not want to continuously disapprove the same person. */
            comment Verify /* Test */
        }

        requirement <'ACQ-6'> proposeNextAfterReject : TandemRequirement {
            doc /* When the operator rejects a proposed person, Tandem shall propose another person in view, or scan for persons (ACQ-2) if no other person is in view. */
            comment Rationale /* Find next available target or reinitiate scan. */
            comment Verify /* Test */
        }

        requirement <'ACQ-7'> approvedPersonBecomesTarget : TandemRequirement {
            doc /* When the operator approves any displayed person, Tandem shall make that person the target. */
            comment Rationale /* The operator's approval is the only way a person becomes a target. */
            comment Verify /* Test */
        }
        requirement <'ACQ-8'> confirmNewTarget : TandemRequirement {
            doc /* Tandem shall confirm a new target to the operator within 1s [TBR] of approval.*/
            comment Rationale /* The operator must know the right person was locked before the drone moves. */
            comment Verify /* Test */
        }

        requirement <'ACQ-9'> alertNoPersonsFound : TandemRequirement {
            doc /* If a full scan finds no persons, Tandem shall alert the operator.*/
            comment Rationale /* The operator should know the area looks empty, rather than waiting indefinitely. */
            comment Verify /* Test */
        }

        requirement <'ACQ-10'> removeDepartedPerson : TandemRequirement {
            doc /* Tandem shall remove a person from the operator's display within 1s [TBR] of them leaving view. */
            comment Rationale /* The display must only offer people who can actually be selected. */
            comment Verify /* Test */
        }

        requirement <'ACQ-11'> refuseOutOfViewApproval : TandemRequirement {
            doc /* Tandem shall refuse an approval of a person who is no longer in view.*/
            comment Rationale /* Never lock onto someone Tandem can't see; prevents following a wrong or stale person. */
            comment Verify /* Test */
        }

        requirement <'ACQ-12'> explainRefusedApproval : TandemRequirement {
            doc /* When Tandem refuses an approval, it shall tell the operator why.*/
            comment Rationale /* A refusal without a reason leaves the operator guessing what to do next. */
            comment Verify /* Demonstration */
        }

        requirement <'ACQ-13'> holdPositionWhileAcquiring : TandemRequirement {
            doc /* During target acquisition, Tandem shall hold position, moving only to rotate in place for scanning. */
            comment Rationale /* No unapproved movement before a target exists; keeps the drone predictable while the operator decides. */
            comment Verify /* Test */
        }

    }

    package Follow {
        requirement <'FLW-1'> stayInFramingZone : TandemRequirement {
            doc /* While following a target moving at up to 3 m/s [TBR], Tandem shall keep the drone within the configured framing zone (distance ±2 m [TBR]). */
            comment Rationale /* The operator gets a stable view of the person within their chosen framing. */
            comment Verify /* Test */
        }

        requirement <'FLW-2'> holdInsideZone : TandemRequirement {
            doc /* While the drone is inside the framing zone, Tandem shall not move it to correct its offset. */
            comment Rationale /* Avoids needless swings on turns; smoother video, less battery.*/
            comment Verify /* Test */
        }
        requirement <'FLW-3'> configurableFollowSettings : TandemRequirement {
            doc /* Tandem shall allow the operator to set distance, angle, zone width and height within the ranges in [the table]. */
            comment Rationale /* The operator chooses the view that suits the task. */
            comment Verify /* Demonstration */
        }

        requirement <'FLW-4'> limitCameraToTargetDistance : TandemRequirement {
            doc /* Tandem shall not accept settings whose combined camera-to-target distance exceeds 20m [TBR].*/
            comment Rationale /* Beyond 20m the person cannot be reliably detected. */
            comment Verify /* Test */
        }

        requirement <'FLW-5'> keepTargetCentered : TandemRequirement {
            doc /* While following or paused, with the target moving at up to 3 m/s [TBR], Tandem shall keep the target within ±10° [TBR] of the centre of the camera view. */
            comment Rationale /* The operator sees the person framed, not drifting out of the picture. */
            comment Verify /* Test */
        }

        requirement <'FLW-6'> noUnplannedFollowStop : TandemRequirement {
            doc /* Tandem shall not stop or suspend following unless the target is lost or overlapped by another person, the operator pauses or ends the flight, the pilot takes manual control, or a failsafe triggers. */
            comment Rationale /* Following only ends by decisions or for safety, never by itself. */
            comment Verify /* Test */
        }
        requirement <'FLW-7'> freezeZoneWhenStationary : TandemRequirement {
            doc /* While the target is stationary, Tandem shall keep the framing zone fixed relative to the target's last direction of travel. */
            comment Definition /* Stationary: the target moves less than 0.5m [TBR] within 2s [TBR]. */
            comment Rationale /* Prevents the drone wandering while the person stands still; the zone has no meaning without a direction of travel.*/
            comment Verify /* Test */
        }

        requirement <'FLW-8'> lostAfterNotSeen : TandemRequirement {
            doc /* Tandem shall treat the target as lost when it has not been seen for 2s [TBR]. */
            comment Rationale /* Brief gaps must not drop the target, but a target that's really gone must be recognized so the drone stops acting on stale information.*/
            comment Verify /* Test */
        }

        requirement <'FLW-9'> returnToAcquisitionWhenLost : TandemRequirement {
            doc /* When the target is lost, Tandem shall return to target acquisition. */
            comment Rationale /* Losing the target must never lead to following someone else unapproved; re-entering acquisition reuses human approval path. */
            comment Verify /* Test */
        }

        requirement <'FLW-10'> alertOperatorWhenLost : TandemRequirement {
            doc /* When the target is lost, Tandem shall alert the operator within 1s [TBR]. */
            comment Rationale /* The operator must know the follow has stopped so they can watch for the person and re-approve. */
            comment Verify /* Test */
        }
        requirement <'FLW-11'> alertFallingBehind : TandemRequirement {
            doc /* When the drone has been farther than the configured distance plus 2m [TBR] for more than 3s [TBR], Tandem shall alert the operator it is falling behind. */
            comment Rationale /* Gives the operator time to act before the target is lost. */
            comment Verify /* Test */
        }

        requirement <'FLW-12'> reacquireOnOverlap : TandemRequirement {
            doc /* When another person overlaps the target in view, Tandem shall return to target acquisition. */
            comment Definition /* Overlap: another person's box covers more than 30% [TBR] of the target's box for at least 0.5 s [TBR]. */
            comment Rationale /* Tandem cannot detect an identity swap itself, so it asks the operator to re-approve whenever a swap is possible. */
            comment Verify /* Test */
        }

        requirement <'FLW-13'> rejectOutOfRangeSettings : TandemRequirement {
            doc /* Tandem shall not accept a follow setting outside its allowed range. */
            comment Rationale /* Settings outside their ranges could put the drone inside the keep-out zone or beyond reliable detection. */
            comment Verify /* Test */
        }

        requirement <'FLW-14'> showAllowedRange : TandemRequirement {
            doc /* When Tandem refuses a follow setting, it shall show the operator the allowed range. */
            comment Rationale /* The operator needs to know what is allowed to correct the entry quickly. */
            comment Verify /* Demonstration */
        }

        requirement <'FLW-17'> gradualRepositioning : TandemRequirement {
            doc /* When the follow settings change or following resumes, Tandem shall move the drone to the new position at no more than 2 m/s [TBR] relative to the target. */
            comment Rationale /* Smooth video, and predictable movement near the target. */
            comment Verify /* Test */
        }

        requirement <'FLW-18'> newestSettingsWins : TandemRequirement {
            doc /* When the operator changes the follow settings during a move from a previous change, Tandem shall move toward the newest settings.*/
            comment Rationale /* The drone always heads where the operator currently wants, it does not finish an outdated move. */
            comment Verify /* Test */
        }

        requirement <'FLW-19'> holdOnPause : TandemRequirement {
            doc /* When the operator commands pause, Tandem shall hold the drone's position. */
            comment Rationale /* Let the operator stop the drone's movement without losing the target. */
            comment Verify /* Test */
        }

        requirement <'FLW-20'> resumeSameTarget : TandemRequirement {
            doc /* When the operator commands resume, Tandem shall resume following the current target without re-approval. */
            comment Rationale /* The target was tracked throughout the pause, so asking the operator to re-approve would add a step with no safety benefit. */
            comment Verify /* Test */
        }

    }
    
    package End {
        
        requirement <'END-1'> returnToLaunchPoint : TandemRequirement {
            doc /*When the operator commands return to launch, Tandem shall fly to within 2m [TBR] of the launch point at the return altitude (6m [TBR]). */
            comment Rationale /* Brings the drone back to where the operator is, at a height known to be clear. */
            comment Verify /* Test */
        }
    
        requirement <'END-2'> landInPlace : TandemRequirement {
            doc /* When the operator commands land here, Tandem shall land within 10m [TBR] horizontally of its position at the time of the command. */
            comment Rationale /* error budget at top speed: 0.5s command latency (2.5m) + braking (~5m) + position error (~2m), plus margin. */
            comment Verify /* Test */
        }

        requirement <'END-3'> releaseTargetOnEnd : TandemRequirement {
            doc /* When the operator commands end flight, Tandem shall stop following the target. */
            comment Rationale /* Once the flight is ending, the drone's job is to land safely, not to keep chasing someone. */
            comment Verify /* Test */
        }

        requirement <'END-4'> disarmAfterLanding : TandemRequirement {
            doc /* When the drone has landed, Tandem shall disarm within 3s [TBR]. */
            comment Rationale /* Spinning props on the ground are a hazard to anyone approaching the drone. */
            comment Verify /* Test */
        }

        requirement <'END-5'> showLandingSpot : TandemRequirement {
            doc /* During descent, Tandem shall show the operator a live view of the area beneath the drone. */
            comment Rationale /* Tandem can't sense obstacles below, so the operator needs to see the spot to takeover if it is not clear. */
            comment Verify /* Demonstration */
        }

        requirement <'END-6'> holdIfPersonBelow : TandemRequirement {
            doc /* During descent, if a person is detected beneath the drone, Tandem shall stop descending and hold its position. */
            comment Rationale /* Never continue lowering a drone onto a person.*/
            comment Verify /* Test */
        }

        requirement <'END-7'> alertPersonBelow : TandemRequirement {
            doc /* When Tandem stops a descent because a person is beneath it, Tandem shall alert the operator within 1s [TBR]. */
            comment Rationale /* The operator needs to know why the landing stopped so they can decide what to do. */
            comment Verify /* Test */
        }

        requirement <'END-8'> landIfPositionLost : TandemRequirement {
            doc /* If Tandem loses its position during a return to launch, Tandem shall land in place. */
            comment Rationale /* Without a position the drone cannot find the launch point; landing slowly where it is, is the safest option. */
            comment Verify /* Test */
        }

        requirement <'END-9'> alertPositionLost : TandemRequirement {
            doc /* When Tandem lands in place because its position was lost, Tandem shall alert the operator within 1s [TBR]. */
            comment Rationale /* The pilot can still fly by RC without position and may prefer to bring the drone back manually. */
            comment Verify /* Test */
        }

    }
    package ManualControl {

        requirement <'MAN-1'> manualOverrideStopsAutonomy : TandemRequirement {
            doc /* In any flight state, when the pilot selects manual control on the RC, Tandem shall stop all autonomous movement within 0.5s [TBR]. */
            comment Rationale /* A human must always be able to take control immediately; at top speed, 0.5s limits uncommanded travel to about 2.5m. */
            comment Verify /* Test */
        }

        requirement <'MAN-2'> holdUntilStickInput : TandemRequirement {
            doc /* After the pilot takes manual control, Tandem shall hold position until it receives stick input from the RC. */
            comment Rationale /* The drone stays put after a takeover, so the pilot isn't caught out by drift while getting oriented. */
            comment Verify /* Test */
        }
        
        requirement <'MAN-3'> manualControlOnly : TandemRequirement {
            doc /* While under manual control, Tandem shall move the drone only in response to pilot input, except when a failsafe triggers. */
            comment Rationale /* Once a human has taken over, nothing else may move the drone except a safety response to a lost link. */
            comment Verify /* Test */
        }

        requirement <'MAN-4'> reacquireAfterHandBack : TandemRequirement {
            doc /* When the pilot hands control back to Tandem, Tandem shall return to target acquisition. */
            comment Rationale /* The pilot may have moved the drone during manual flight, so the target must be re-approved before Tandem follows anyone. */
            comment Verify /* Test */
        }

    } 

    package CrossCutting {

        requirement <'XC-1'> confirmOperatorCommands : TandemRequirement {
            doc /* Tandem shall confirm each operator command to the operator within 1 s [TBR]. */
            comment Rationale /* The operator must always know whether a command took effect. */
            comment Verify /* Test */
        }

        requirement <'XC-2'> alertCommandNotApplied : TandemRequirement {
            doc /* When an operator command is not confirmed within 1 s [TBR], Tandem shall tell the operator it was not applied. */
            comment Rationale /* The operator must never assume a command took effect when it did not. */
            comment Verify /* Test */
        }

        requirement <'XC-3'> respectKeepOutZone : TandemRequirement {
            doc /* Tandem shall not move the drone into the target's keep-out zone. */
            comment Definition /* Keep-out zone: horizontal distance from the target of less than 5m [TBR]. */
            comment Rationale /* Keeps the drone a safe margin from the person it is working with; Tandem only moves where it can see. */
            comment Verify /* Test */
        }

        requirement <'XC-4'> holdWhileTargetInside : TandemRequirement {
            doc /* While the target is inside the keep-out zone, Tandem shall hold position.  */
            comment Rationale /* Backing away would fly the drone into space the camera is not watching; holding is safer until obstacle sensing exists. */
            comment Verify /* Test */
        }

    }

    package Constraints {

        requirement <'CON-1'> limitDescentRate : TandemRequirement {
            doc /* When landing, Tandem shall descend at no more than 0.6 m/s [TBR]. */
            comment Rationale /* A slow descent gives the operator time to watch the spot and take over, and gives Tandem time to spot a person below. */
            comment Verify /* Test */
        }

        requirement <'CON-2'> limitHorizontalSpeed : TandemRequirement {
            doc /* While flying autonomously, Tandem shall not exceed a horizontal speed of 5 m/s [TBR]. */
            comment Rationale /* Bounds how far the drone can travel before the pilot or a failsafe can react; the stopping distances in END-2 and MAN-1 assume this speed. */
            comment Verify /* Test */
        }

    }


        requirement <''> : TandemRequirement {
            doc /**/
            comment Rationale /**/
            comment Verify /**/
        }

        requirement <''> : TandemRequirement {
            doc /**/
            comment Rationale /**/
            comment Verify /**/
        }
        requirement <''> : TandemRequirement {
            doc /**/
            comment Rationale /**/
            comment Verify /**/
        }

        requirement <''> : TandemRequirement {
            doc /**/
            comment Rationale /**/
            comment Verify /**/
        }

        requirement <''> : TandemRequirement {
            doc /**/
            comment Rationale /**/
            comment Verify /**/
        }

        requirement <''> : TandemRequirement {
            doc /**/
            comment Rationale /**/
            comment Verify /**/
        }
        requirement <''> : TandemRequirement {
            doc /**/
            comment Rationale /**/
            comment Verify /**/
        }

        requirement <''> : TandemRequirement {
            doc /**/
            comment Rationale /**/
            comment Verify /**/
        }

        requirement <''> : TandemRequirement {
            doc /**/
            comment Rationale /**/
            comment Verify /**/
        }

        requirement <''> : TandemRequirement {
            doc /**/
            comment Rationale /**/
            comment Verify /**/
        }
}