# Tandem - Requirements Traceability Matrix

Generated 2026-11-13 by `tools/trace_matrix.py` from `model_v2/`. Do not edit by hand; change the model and re-run.

## Summary

| | Count |
|---|---|
| Requirements | 72 |
| Requirements with at least one trace | 72 |
| Scenario actions | 102 |
| Actions covered by a requirement | 96 |
| Trace links | 137 |
| Broken references | 0 |

## 1. Requirements to scenarios


### Acquire

| ID | Name | Requirement | Verify | # | Traces to |
|---|---|---|---|---|---|
| ACQ-1 | `noFollowWithoutApproval` | Tandem shall not begin following a person until the operator has approved that person. | Test | 2 | `AcquireTarget::operatorApproves`<br>`AcquireTarget::noResponse` |
| ACQ-2 | `fullCircleSearch` | When no persons are in view, Tandem shall scan for persons through a full circle within 30 s [TBR]. | Test | 2 | `AcquireTarget::scanForPersons`<br>`AcquireTarget::aimCamera` |
| ACQ-3 | `detectedPersonDisplay` | During target acquisition, Tandem shall display every person in view to the operator as selectable within 1s [TBR] of the person entering view. | Test | 1 | `AcquireTarget::showPersons` |
| ACQ-4 | `proposeOnePerson` | During target acquisition, Tandem shall propose one displayed person [selection rule TBD, e.g. nearest; after an overlap, the person Tandem judges most likely to be the previous target] for operator approval. | Test | 1 | `AcquireTarget::proposePerson` |
| ACQ-5 | `noReproposeRejected` | When the operator rejects a proposed person, Tandem shall not propose that person again during the current acquisition. | Test | 1 | `AcquireTarget::reject` |
| ACQ-6 | `proposeNextAfterReject` | When the operator rejects a proposed person, Tandem shall propose another person in view, or scan for persons (ACQ-2) if no other person is in view. | Test | 1 | `AcquireTarget::reject` |
| ACQ-7 | `approvedPersonBecomesTarget` | When the operator approves any displayed person, Tandem shall make that person the target. | Test | 2 | `AcquireTarget::targetSet`<br>`AcquireTarget::otherPick` |
| ACQ-8 | `confirmNewTarget` | Tandem shall confirm a new target to the operator within 1s [TBR] of approval. | Test | 1 | `AcquireTarget::targetSet` |
| ACQ-9 | `alertNoPersonsFound` | If a full scan finds no persons, Tandem shall alert the operator. | Test | 1 | `AcquireTarget::noneFound` |
| ACQ-10 | `removeDepartedPerson` | Tandem shall remove a person from the operator's display within 1s [TBR] of them leaving view. | Test | 1 | `AcquireTarget::personLeaves` |
| ACQ-11 | `refuseOutOfViewApproval` | Tandem shall refuse an approval of a person who is no longer in view. | Test | 1 | `AcquireTarget::checkApproval` |
| ACQ-12 | `explainRefusedApproval` | When Tandem refuses an approval, it shall tell the operator why. | Demonstration | 1 | `AcquireTarget::explainRefusal` |
| ACQ-13 | `holdPositionWhileAcquiring` | During target acquisition, Tandem shall hold position, moving only to rotate in place for scanning. | Test | 1 | `AcquireTarget::holdPosition` |

### Constraints

| ID | Name | Requirement | Verify | # | Traces to |
|---|---|---|---|---|---|
| CON-1 | `limitDescentRate` | When landing, Tandem shall descend at no more than 0.6 m/s [TBR]. | Test | 1 | `EndFlight::descend` |
| CON-2 | `limitHorizontalSpeed` | While flying autonomously, Tandem shall not exceed a horizontal speed of 5 m/s [TBR]. | Test | 2 | `FilmTarget::stayInZone`<br>`EndFlight::returnToLaunch` |
| CON-3 | `broadcastRemoteID` | Tandem shall broadcast Remote ID from takeoff to shutdown. | Demonstration | 1 | `KeepPersonInView` |

### End

| ID | Name | Requirement | Verify | # | Traces to |
|---|---|---|---|---|---|
| END-1 | `returnToLaunchPoint` | When the operator commands return to launch, Tandem shall fly to within 2m [TBR] of the launch point at the return altitude (6m [TBR]). | Test | 2 | `EndFlight::selectEndFlight`<br>`EndFlight::returnToLaunch` |
| END-2 | `landInPlace` | When the operator commands land here, Tandem shall land within 10m [TBR] horizontally of its position at the time of the command. | Test | 2 | `EndFlight::selectEndFlight`<br>`EndFlight::stopInPlace` |
| END-3 | `releaseTargetOnEnd` | When the operator commands end flight, Tandem shall stop following the target. | Test | 1 | `EndFlight::releaseTarget` |
| END-4 | `disarmAfterLanding` | When the drone has landed, Tandem shall disarm within 3s [TBR]. | Test | 1 | `EndFlight::disarm` |
| END-5 | `showLandingSpot` | During descent, Tandem shall show the operator a live view of the area beneath the drone. | Demonstration | 1 | `EndFlight::showLandingSpot` |
| END-6 | `holdIfPersonBelow` | During an operator-commanded descent, if a person is detected beneath the drone, Tandem shall stop descending and hold its position. | Test | 1 | `EndFlight::stopDescent` |
| END-7 | `alertPersonBelow` | When Tandem stops a descent because a person is beneath it, Tandem shall alert the operator within 1s [TBR]. | Test | 1 | `EndFlight::alertPersonBelow` |

### Follow

| ID | Name | Requirement | Verify | # | Traces to |
|---|---|---|---|---|---|
| FLW-1 | `stayInFramingZone` | While following a target moving at up to 3 m/s [TBR], Tandem shall keep the drone within the configured framing zone (distance ±2 m [TBR]). | Test | 2 | `FilmTarget::stayInZone`<br>`AdjustFraming::settle` |
| FLW-2 | `holdInsideZone` | While the drone is inside the framing zone, Tandem shall not move it to correct its offset. | Test | 1 | `FilmTarget::stayInZone` |
| FLW-3 | `configurableFollowSettings` | Tandem shall allow the operator to set distance, angle, zone width and height within the ranges in [the table]. | Demonstration | 2 | `AdjustFraming::enterValues`<br>`AdjustFraming::showCurrentSettings` |
| FLW-4 | `limitCameraToTargetDistance` | Tandem shall not accept settings whose combined camera-to-target distance exceeds 20m [TBR]. | Test | 1 | `AdjustFraming::rejectOutOfRange` |
| FLW-5 | `keepTargetCentered` | While following or paused, with the target moving at up to 3 m/s [TBR], Tandem shall keep the target within ±10° [TBR] of the centre of the camera view. | Test | 3 | `FilmTarget::keepCentered`<br>`PauseFollowing::keepCentered`<br>`AdjustFraming::keepCentered` |
| FLW-6 | `noUnplannedFollowStop` | Tandem shall not stop or suspend following unless the target is lost or overlapped by another person, the operator pauses or ends the flight, the pilot takes manual control, or a failsafe triggers. | Test | 2 | `FilmTarget::repeatUntilStopped`<br>`TandemStates::TandemModes::autonomous::following` |
| FLW-7 | `freezeZoneWhenStationary` | While the target is stationary, Tandem shall keep the framing zone fixed relative to the target's last direction of travel. | Test | 1 | `FilmTarget::holdWhileStationary` |
| FLW-8 | `lostAfterNotSeen` | Tandem shall treat the target as lost when it has not been seen for 2s [TBR]. | Test | 3 | `FilmTarget::reportTargetLost`<br>`PauseFollowing::endPauseOnTargetLost`<br>`AdjustFraming::stopMoveOnTargetLost` |
| FLW-9 | `returnToAcquisitionWhenLost` | When the target is lost, Tandem shall return to target acquisition. | Test | 4 | `FilmTarget::reportTargetLost`<br>`PauseFollowing::endPauseOnTargetLost`<br>`AdjustFraming::stopMoveOnTargetLost`<br>`KeepPersonInView::returnToAcquisition` |
| FLW-10 | `alertOperatorWhenLost` | When the target is lost, Tandem shall alert the operator within 1s [TBR]. | Test | 1 | `FilmTarget::reportTargetLost` |
| FLW-11 | `alertFallingBehind` | When the drone has been farther than the configured distance plus 2m [TBR] for more than 3s [TBR], Tandem shall alert the operator it is falling behind. | Test | 1 | `FilmTarget::reportFallingBehind` |
| FLW-12 | `reacquireOnOverlap` | When another person overlaps the target in view, Tandem shall return to target acquisition. | Test | 4 | `FilmTarget::reportOverlap`<br>`PauseFollowing::endPauseOnOverlap`<br>`KeepPersonInView::returnToAcquisition`<br>`AdjustFraming::stopMoveOnOverlap` |
| FLW-13 | `rejectOutOfRangeSettings` | Tandem shall not accept a follow setting outside its allowed range. | Test | 2 | `AdjustFraming::rejectOutOfRange`<br>`PrepareForFlight::invalidSetting` |
| FLW-14 | `showAllowedRange` | When Tandem refuses a follow setting, it shall show the operator the allowed range. | Demonstration | 2 | `AdjustFraming::rejectOutOfRange`<br>`PrepareForFlight::invalidSetting` |
| FLW-17 | `gradualRepositioning` | When the follow settings change or following resumes, Tandem shall move the drone to the new position at no more than 2 m/s [TBR] relative to the target. | Test | 2 | `AdjustFraming::moveGradually`<br>`PauseFollowing::returnToZone` |
| FLW-18 | `newestSettingsWins` | When the operator changes the follow settings during a move from a previous change, Tandem shall move toward the newest settings. | Test | 1 | `AdjustFraming::switchToNewest` |
| FLW-19 | `holdOnPause` | When the operator commands pause, Tandem shall hold the drone's position. | Test | 2 | `PauseFollowing::selectPause`<br>`PauseFollowing::holdPosition` |
| FLW-20 | `resumeSameTarget` | When the operator commands resume, Tandem shall resume following the current target without re-approval. | Test | 2 | `PauseFollowing::selectResume`<br>`PauseFollowing::returnToZone` |

### Launch

| ID | Name | Requirement | Verify | # | Traces to |
|---|---|---|---|---|---|
| LCH-1 | `takeOffWhenArmed` | When the operator commands launch while armed, Tandem shall take off. | Test | 2 | `LaunchDrone::triggerLaunch`<br>`LaunchDrone::climb` |
| LCH-2 | `reachLaunchAltitude` | Tandem shall reach a launch altitude of 6m [TBR] +/- 1m [TBR] within 10s [TBR] of takeoff. | Test | 2 | `LaunchDrone::climb`<br>`LaunchDrone::hoverAtAltitude` |
| LCH-3 | `alertAltitudeNotReached` | When launch altitude is not reached within 10s [TBR] Tandem shall alert the operator. | Test | 1 | `LaunchDrone::altitudeNotReached` |

### ManualControl

| ID | Name | Requirement | Verify | # | Traces to |
|---|---|---|---|---|---|
| MAN-1 | `manualOverrideStopsAutonomy` | In any flight state, when the pilot selects manual control on the RC, Tandem shall stop all autonomous movement within 0.5s [TBR]. | Test | 9 | `TakeManualControl::selectManual`<br>`TakeManualControl::stopAutonomy`<br>`KeepPersonInView::handOverToPilot`<br>`PauseFollowing::handOverToPilot`<br>`LaunchDrone::handOverToPilot`<br>`AcquireTarget::handOverToPilot`<br>`FilmTarget::handOverToPilot`<br>`AdjustFraming::handOverToPilot`<br>`EndFlight::handOverToPilot` |
| MAN-2 | `holdUntilStickInput` | After the pilot takes manual control, Tandem shall hold position until it receives stick input from the RC. | Test | 1 | `TakeManualControl::holdPosition` |
| MAN-3 | `manualControlOnly` | While under manual control, Tandem shall move the drone only in response to pilot input, except when a failsafe triggers. | Test | 1 | `TakeManualControl::followStickInput` |
| MAN-4 | `reacquireAfterHandBack` | When the pilot hands control back to Tandem, Tandem shall return to target acquisition. | Test | 1 | `TakeManualControl::resumeAcquisition` |

### PreFlight

| ID | Name | Requirement | Verify | # | Traces to |
|---|---|---|---|---|---|
| PRE-1 | `readyOnlyWhenPrechecksPass` | Tandem shall not report ready unless all prechecks pass. | Test | 4 | `PrepareForFlight::connectToGroundStation`<br>`PrepareForFlight::runPrechecks`<br>`PrepareForFlight::noConnection`<br>`PrepareForFlight::notReady` |
| PRE-2 | `noArmOnFailedPrechecks` | When prechecks fail, Tandem shall refuse to arm. | Test | 2 | `PrepareForFlight::prechecksFail`<br>`PrepareForFlight::arm` |
| PRE-3 | `showPrecheckFailures` | When prechecks fail, Tandem shall display precheck failures to the operator. | Demonstration | 2 | `PrepareForFlight::prechecksFail`<br>`PrepareForFlight::notReady` |
| PRE-4 | `confirmSettingsBeforeArming` | Tandem shall not arm until the operator has confirmed the follow settings. | Test | 3 | `PrepareForFlight::showSettings`<br>`PrepareForFlight::confirmSettings`<br>`PrepareForFlight::arm` |

### Performance

| ID | Name | Requirement | Verify | # | Traces to |
|---|---|---|---|---|---|
| PRF-1 | `detectionRange` | Under nominal conditions, Tandem shall detect a person at a distance of up to 20m [TBR] camera-to-target in at least 90% [TBR] of video frames. | Test | 4 | `AdjustFraming::trackTarget`<br>`PauseFollowing::trackTarget`<br>`AcquireTarget::scanForPersons`<br>`FilmTarget::trackTarget` |
| PRF-2 | `commandResponseTime` | Anywhere inside the geofence, Tandem shall begin acting on an operator command within 0.5s [TBR] of the operator sending it. | Test | 4 | `AdjustFraming::confirmReceived`<br>`PauseFollowing::confirmPaused`<br>`PauseFollowing::confirmResumed`<br>`EndFlight::confirmEnd` |
| PRF-3 | `followEndurance` | Under nominal conditions, starting from a full battery, Tandem shall be able to follow a target for at least 8 minutes [TBR] before the low-battery return (XC-7) triggers. | Analysis, Test | 1 | `KeepPersonInView` |
| PRF-4 | `videoRange` | Under nominal conditions, Tandem shall provide usable video to the operator at up to 150m [TBR] from the ground control station. | Test | 1 | `KeepPersonInView` |
| PRF-5 | `videoLatency` | Under nominal conditions, within video range (PRF-4), Tandem shall provide video to the operator with a latency of no more than 500ms. | Test (short range), Analysis (at range) | 2 | `KeepPersonInView`<br>`EndFlight::showLandingSpot` |

### CrossCutting

| ID | Name | Requirement | Verify | # | Traces to |
|---|---|---|---|---|---|
| XC-1 | `confirmOperatorCommands` | Tandem shall confirm each operator command to the operator within 1 s [TBR]. | Test | 6 | `AdjustFraming::confirmReceived`<br>`PauseFollowing::confirmPaused`<br>`PauseFollowing::confirmResumed`<br>`EndFlight::confirmEnd`<br>`TakeManualControl::confirmManual`<br>`TakeManualControl::confirmHandBack` |
| XC-2 | `alertCommandNotApplied` | When an operator command is not confirmed within 1 s [TBR], Tandem shall tell the operator it was not applied. | Test | 4 | `AdjustFraming::reportNotReceived`<br>`PauseFollowing::reportPauseNotConfirmed`<br>`PauseFollowing::reportResumeNotConfirmed`<br>`EndFlight::reportNotConfirmed` |
| XC-3 | `respectKeepOutZone` | Tandem shall not move the drone into the target's keep-out zone. | Test | 3 | `FilmTarget::holdForKeepOut`<br>`AdjustFraming::routeAroundKeepOut`<br>`PauseFollowing::routeAroundKeepOut` |
| XC-4 | `holdWhileTargetInside` | While the target is inside the keep-out zone, Tandem shall hold position. | Test | 1 | `FilmTarget::holdForKeepOut` |
| XC-5 | `stayInsideGeofence` | Tandem shall not move the drone outside the geofence. | Test | 1 | `KeepPersonInView::stopAtGeofence` |
| XC-6 | `alertAtGeofence` | When the drone reaches the geofence, Tandem shall alert the operator within 1s [TBR]. | Test | 1 | `KeepPersonInView::stopAtGeofence` |
| XC-7 | `lowBatteryReturn` | When the remaining battery reaches 25% [TBR], Tandem shall return to launch. | Test | 1 | `KeepPersonInView::returnOnLowBattery` |
| XC-8 | `criticalBatteryLand` | When the remaining battery level reaches 10% [TBR], Tandem shall land in place. | Test | 1 | `KeepPersonInView::landOnCriticalBattery` |
| XC-9 | `groundLinkLossHold` | When the ground link is lost, Tandem shall hold position. | Test | 1 | `KeepPersonInView::holdOnGroundLinkLoss` |
| XC-10 | `groundLinkLossReturn` | If ground link is not re-established within 10s [TBR] of loss, Tandem shall return to launch. | Test | 1 | `KeepPersonInView::holdOnGroundLinkLoss` |
| XC-11 | `rcLinkLossReturn` | When RC connection is lost, Tandem shall return to launch. | Test | 2 | `KeepPersonInView::returnOnRcLoss`<br>`TakeManualControl::returnOnRcLoss` |
| XC-12 | `gpsLossLand` | While flying autonomously, when GPS position is lost, Tandem shall land in place. | Test | 2 | `KeepPersonInView::landOnGpsLoss`<br>`EndFlight::abandonReturn` |
| XC-13 | `gpsLossAdviseTakeover` | When GPS position is lost, Tandem shall advise the operator to take manual control. | Demonstration | 2 | `KeepPersonInView::landOnGpsLoss`<br>`EndFlight::abandonReturn` |
| XC-14 | `alertOnFailsafe` | When a failsafe triggers, Tandem shall alert the operator within 1s [TBR], stating which failsafe. | Test | 5 | `KeepPersonInView::returnOnLowBattery`<br>`KeepPersonInView::landOnCriticalBattery`<br>`KeepPersonInView::holdOnGroundLinkLoss`<br>`KeepPersonInView::returnOnRcLoss`<br>`KeepPersonInView::landOnGpsLoss` |
| XC-15 | `holdAfterLinkRestored` | When the ground link is restored after a loss, Tandem shall hold position until the operator commands resume. | Demonstration | 1 | `KeepPersonInView::holdOnGroundLinkLoss` |

## 2. Scenarios to requirements

### PrepareForFlight

| Action | Step | # | Covered by |
|---|---|---|---|
| `powerOn` | 1. Operator powers on the drone, ground station, and RC. | 0 | - |
| `connectToGroundStation` | 2. Ground station connects to Tandem. | 1 | PRE-1 |
| `runPrechecks` | 3. Tandem runs its prechecks (see PRE-1 definition) and reports ready when all pass. | 1 | PRE-1 |
| `showSettings` | 4. Tandem shows the current follow settings. | 1 | PRE-4 |
| `confirmSettings` | 5. Operator changes them if needed and confirms. | 1 | PRE-4 |
| `requestArm` | 6. Operator commands arm. | 0 | - |
| `arm` | 7. Tandem arms (motors enabled). Ready for LaunchDrone. | 2 | PRE-2, PRE-4 |
| `noConnection` | A. Ground station cannot connect: operator told; Tandem does not report ready. | 1 | PRE-1 |
| `notReady` | B. Something not ready (e.g. GPS still acquiring, camera not found): Tandem shows what, and waits. | 2 | PRE-1, PRE-3 |
| `invalidSetting` | C. Setting out of range: not accepted; allowed range shown. | 2 | FLW-13, FLW-14 |
| `prechecksFail` | D. Prechecks fail (e.g. battery too low): arming refused; failures shown. | 2 | PRE-2, PRE-3 |

### LaunchDrone

| Action | Step | # | Covered by |
|---|---|---|---|
| `triggerLaunch` | 1. Operator triggers launch. | 1 | LCH-1 |
| `climb` | 2. Drone climbs. | 2 | LCH-1, LCH-2 |
| `hoverAtAltitude` | 3. Drone hovers at launch altitude. | 1 | LCH-2 |
| `handOverToPilot` | A. Any time: pilot takeover -> TakeManualControl. | 1 | MAN-1 |
| `altitudeNotReached` | B. Launch altitude not reached within 10 s [TBR]: drone holds; operator alerted. | 1 | LCH-3 |

### AcquireTarget

| Action | Step | # | Covered by |
|---|---|---|---|
| `holdPosition` | Throughout: drone holds position, rotating in place only to scan. | 1 | ACQ-13 |
| `aimCamera` | Throughout: camera sweeps to scan; drone turns when the camera reaches its limit. | 1 | ACQ-2 |
| `scanForPersons` | 1. Scan until persons are in view. | 2 | ACQ-2, PRF-1 |
| `showPersons` | 2. Show all persons to the operator. | 1 | ACQ-3 |
| `proposePerson` | 3. Propose one person. | 1 | ACQ-4 |
| `operatorApproves` | 4. Operator approves. | 1 | ACQ-1 |
| `checkApproval` | 5. Tandem checks the approved person is still in view. | 1 | ACQ-11 |
| `targetSet` | 6. Target is set. | 2 | ACQ-7, ACQ-8 |
| `reject` | A. At 4, operator rejects -> propose another, or scan if none left in view. | 2 | ACQ-5, ACQ-6 |
| `otherPick` | B. At 4, operator selects a different person -> approve that one. | 1 | ACQ-7 |
| `noneFound` | C. Full scan finds no one -> keep scanning and alert operator. | 1 | ACQ-9 |
| `personLeaves` | D. Person walks out of view before the operator decides -> removed from display; carry on. | 1 | ACQ-10 |
| `noResponse` | E. Operator does not respond -> keep waiting (never auto-approve). | 1 | ACQ-1 |
| `explainRefusal` | F. Approved person no longer in view: approval refused; operator told why. | 1 | ACQ-12 |
| `handOverToPilot` | G. Any time: pilot takeover -> TakeManualControl. | 1 | MAN-1 |

### FilmTarget

| Action | Step | # | Covered by |
|---|---|---|---|
| `trackTarget` | 1. Tandem tracks the target's position and direction of travel. | 1 | PRF-1 |
| `stayInZone` | 2. Drone stays within the framing zone around the offset (default 8m, 180deg, 6m height). | 3 | CON-2, FLW-1, FLW-2 |
| `keepCentered` | 3. Camera keeps the target centered. | 1 | FLW-5 |
| `holdWhileStationary` | A. Target stands still: drone holds its current position. | 1 | FLW-7 |
| `holdForKeepOut` | B. Target walks into the keep-out zone: drone holds position until they leave. | 2 | XC-3, XC-4 |
| `reportTargetLost` | C. Target not seen for 2 s [TBR]: target lost; operator alerted; drone holds; exit to AcquireTarget. | 3 | FLW-8, FLW-9, FLW-10 |
| `reportFallingBehind` | D. Target outruns the drone: drone keeps chasing at top speed; if too far for more than 3 s, operator alerted it is falling behind; if no longer seen -> C. | 1 | FLW-11 |
| `reportOverlap` | E. Another person overlaps the target: return to AcquireTarget. | 1 | FLW-12 |
| `handOverToPilot` | F. Any time: pilot takeover -> TakeManualControl. | 1 | MAN-1 |
| `repeatUntilStopped` | Repeats until the operator ends the flight, or the target is lost or overlapped. | 1 | FLW-6 |

### AdjustFraming

| Action | Step | # | Covered by |
|---|---|---|---|
| `selectChange` | 1. Operator selects change settings. | 0 | - |
| `showCurrentSettings` | 2. Tandem shows the current follow settings. | 1 | FLW-3 |
| `enterValues` | 3. Operator enters and submits new values. | 1 | FLW-3 |
| `confirmReceived` | 4. Tandem confirms the new values were received. | 2 | PRF-2, XC-1 |
| `trackTarget` | 5. Tandem keeps tracking the target during the move. | 1 | PRF-1 |
| `moveGradually` | 6. Drone moves gradually to the new position. | 1 | FLW-17 |
| `keepCentered` | 7. Camera keeps the target centred during the move; 5-7 repeat until the drone is in position. | 1 | FLW-5 |
| `settle` | 8. Drone settles at the new position; following continues. | 1 | FLW-1 |
| `rejectOutOfRange` | A. Values out of range: not accepted; allowed range shown; nothing sent. | 3 | FLW-4, FLW-13, FLW-14 |
| `reportNotReceived` | B. No confirmation (link problem): operator told the change was not received; settings unchanged. | 1 | XC-2 |
| `routeAroundKeepOut` | C. Path to the new position crosses the keep-out zone: drone goes around the target at >= 5 m. | 1 | XC-3 |
| `stopMoveOnTargetLost` | D. Target lost during the move: move stops -> FilmTarget handles the loss. | 2 | FLW-8, FLW-9 |
| `switchToNewest` | E. Operator submits new values mid-move: they are checked and confirmed like any change; the drone abandons the old move and heads for the newest. | 1 | FLW-18 |
| `handOverToPilot` | F. Any time: pilot takeover -> TakeManualControl. | 1 | MAN-1 |
| `stopMoveOnOverlap` | G. Another person overlaps the target during the move: move stops -> FilmTarget handles the overlap. | 1 | FLW-12 |

### PauseFollowing

| Action | Step | # | Covered by |
|---|---|---|---|
| `selectPause` | 1. Operator selects pause. | 1 | FLW-19 |
| `confirmPaused` | 2. Tandem confirms following is paused. | 2 | PRF-2, XC-1 |
| `trackTarget` | 3. Tandem keeps tracking the target. | 1 | PRF-1 |
| `holdPosition` | 4. Drone holds position. | 1 | FLW-19 |
| `keepCentered` | 5. Camera keeps the target centred; drone rotates when the camera reaches its limit. | 1 | FLW-5 |
| `selectResume` | 6. Operator selects resume. | 1 | FLW-20 |
| `confirmResumed` | 7. Tandem confirms following is resumed. | 2 | PRF-2, XC-1 |
| `returnToZone` | 8. Drone returns gradually to the framing zone; following continues. | 2 | FLW-17, FLW-20 |
| `reportPauseNotConfirmed` | A. Pause not confirmed (link problem): operator told; drone keeps following. | 1 | XC-2 |
| `reportResumeNotConfirmed` | B. Resume not confirmed (link problem): operator told; drone stays paused. | 1 | XC-2 |
| `endPauseOnTargetLost` | C. Target not seen for 2 s [TBR]: pause ends -> FilmTarget handles the loss. | 2 | FLW-8, FLW-9 |
| `endPauseOnOverlap` | D. Another person overlaps the target: pause ends -> FilmTarget handles the overlap. | 1 | FLW-12 |
| `routeAroundKeepOut` | E. On resume, path back crosses the keep-out zone: drone goes around the target at >= 5 m. | 1 | XC-3 |
| `handOverToPilot` | F. Any time: pilot takeover -> TakeManualControl. | 1 | MAN-1 |

### EndFlight

| Action | Step | # | Covered by |
|---|---|---|---|
| `selectEndFlight` | 1. Operator selects end flight: return to launch or land here. | 2 | END-1, END-2 |
| `confirmEnd` | 2. Tandem confirms the command. | 2 | PRF-2, XC-1 |
| `releaseTarget` | 3. Tandem stops following the target. | 1 | END-3 |
| `returnToLaunch` | 4a. Return to launch: drone flies to the launch point at return altitude (6 m [TBR]). | 2 | CON-2, END-1 |
| `stopInPlace` | 4b. Land here: drone stops and holds where it is. | 1 | END-2 |
| `showLandingSpot` | 5. During descent, Tandem shows the operator the area beneath the drone. | 2 | END-5, PRF-5 |
| `checkLandingSpot` | 6. Operator watches the landing spot; takes over if it is not clear. | 0 | - |
| `descend` | 7. Drone descends. | 1 | CON-1 |
| `disarm` | 8. Drone disarms once landed. | 1 | END-4 |
| `reportNotConfirmed` | A. No confirmation (link problem): operator told; pilot can command return or land on the RC. | 1 | XC-2 |
| `stopDescent` | B. Person detected beneath the drone: descent stops; drone holds. | 1 | END-6 |
| `alertPersonBelow` | C. Operator alerted that a person is beneath the drone. | 1 | END-7 |
| `abandonReturn` | D. Position lost: commanded ending abandoned; emergency landing in place without person-below check -> KeepPersonInView gpsLost. | 2 | XC-12, XC-13 |
| `handOverToPilot` | E. Any time: pilot takeover -> TakeManualControl. | 1 | MAN-1 |

### TakeManualControl

| Action | Step | # | Covered by |
|---|---|---|---|
| `selectManual` | 1. Pilot selects manual control on the RC. | 1 | MAN-1 |
| `stopAutonomy` | 2. Tandem stops all autonomous movement. | 1 | MAN-1 |
| `confirmManual` | 3. Tandem shows the operator that manual control is active. | 1 | XC-1 |
| `holdPosition` | 4. Drone holds position until the pilot gives stick inputs. | 1 | MAN-2 |
| `pilotFlies` | 5. Pilot flies the drone by RC. | 0 | - |
| `followStickInput` | 6. Tandem moves the drone only as the stick commands. | 1 | MAN-3 |
| `returnOnRcLoss` | A. RC link lost during manual flight: Tandem returns to launch (RC-loss failsafe). | 1 | XC-11 |
| `handBack` | B. Pilot hands control back to Tandem -> AcquireTarget (operator re-approves the target). | 0 | - |
| `confirmHandBack` | C. Tandem shows the operator that control is back with Tandem. | 1 | XC-1 |
| `resumeAcquisition` | D. Tandem returns to target acquisition (operator reapproves the target). | 1 | MAN-4 |

### KeepPersonInView

Whole use case: CON-3, PRF-3, PRF-4, PRF-5

| Action | Step | # | Covered by |
|---|---|---|---|
| `returnToAcquisition` | A. Target lost or overlapped during FilmTarget -> back to AcquireTarget, then FilmTarget again (repeat as needed). | 2 | FLW-9, FLW-12 |
| `handOverToPilot` | B. Any time: pilot takeover -> TakeManualControl. | 1 | MAN-1 |
| `stopAtGeofence` | C. Any time: drone reaches the geofence -> stops at the edge, keeps the target in view; operator alerted. Following continues if the target comes back inside. | 2 | XC-5, XC-6 |
| `returnOnLowBattery` | D. Any time: low battery -> return to launch and land (no person-below check); operator alerted. | 2 | XC-7, XC-14 |
| `landOnCriticalBattery` | E. Any time: critical battery -> land in place (no person-below check); operator alerted. | 2 | XC-8, XC-14 |
| `holdOnGroundLinkLoss` | F. Any time: ground link lost -> hold; return to launch and land (no person-below check) if not restored within 10 s. If restored, keep holding until the operator resumes. | 4 | XC-9, XC-10, XC-14, XC-15 |
| `returnOnRcLoss` | G. Any time: RC link lost -> return to launch and land (no person-below check); operator alerted. | 2 | XC-11, XC-14 |
| `landOnGpsLoss` | H. Any time: GPS lost -> land in place (no person-below check); operator alerted and advised to take over. | 3 | XC-12, XC-13, XC-14 |

## 3. Gaps

### Requirements with no trace

None.

### Actions not covered by any requirement

Some are deliberate (operator steps or references to other use cases).

- `PrepareForFlight::powerOn`: 1. Operator powers on the drone, ground station, and RC.
- `PrepareForFlight::requestArm`: 6. Operator commands arm.
- `AdjustFraming::selectChange`: 1. Operator selects change settings.
- `EndFlight::checkLandingSpot`: 6. Operator watches the landing spot; takes over if it is not clear.
- `TakeManualControl::pilotFlies`: 5. Pilot flies the drone by RC.
- `TakeManualControl::handBack`: B. Pilot hands control back to Tandem -> AcquireTarget (operator re-approves the target).

### Broken references

None.

### Tandem steps with no function

Steps in a Tandem lane that are not typed by a function. Expected only for mode changes (realized by state transitions) and steps that need no function; anything else is a gap.

- `LaunchDrone::handOverToPilot`
- `AcquireTarget::noResponse`
- `AcquireTarget::handOverToPilot`
- `FilmTarget::handOverToPilot`
- `AdjustFraming::settle`
- `AdjustFraming::stopMoveOnTargetLost`
- `AdjustFraming::stopMoveOnOverlap`
- `AdjustFraming::handOverToPilot`
- `PauseFollowing::endPauseOnTargetLost`
- `PauseFollowing::endPauseOnOverlap`
- `PauseFollowing::handOverToPilot`
- `EndFlight::abandonReturn`
- `EndFlight::handOverToPilot`
- `TakeManualControl::stopAutonomy`
- `TakeManualControl::resumeAcquisition`
- `KeepPersonInView::returnToAcquisition`
- `KeepPersonInView::handOverToPilot`
