# Tandem - Requirements Traceability Matrix

Generated 2026-10-30 by `tools/trace_matrix.py` from `model_v2/`. Do not edit by hand; change the model and re-run.

## Summary

| | Count |
|---|---|
| Requirements | 72 |
| Requirements with at least one trace | 72 |
| Scenario actions | 100 |
| Actions covered by a requirement | 94 |
| Trace links | 135 |
| Broken references | 0 |

## 1. Requirements to scenarios


### Acquire

| ID | Name | Requirement | Verify | Traces to |
|---|---|---|---|---|
| ACQ-1 | `noFollowWithoutApproval` | Tandem shall not begin following a person until the operator has approved that person. | Test | `AcquireTarget::operatorApproves`<br>`AcquireTarget::noResponse` |
| ACQ-2 | `fullCircleSearch` | When no persons are in view, Tandem shall scan for persons through a full circle within 30 s [TBR]. | Test | `AcquireTarget::scanForPersons` |
| ACQ-3 | `detectedPersonDisplay` | During target acquisition, Tandem shall display every person in view to the operator as selectable within 1s [TBR] of the person entering view. | Test | `AcquireTarget::showPersons` |
| ACQ-4 | `proposeOnePerson` | During target acquisition, Tandem shall propose one displayed person [selection rule TBD, e.g. nearest; after an overlap, the person Tandem judges most likely to be the previous target] for operator approval. | Test | `AcquireTarget::proposePerson` |
| ACQ-5 | `noReproposeRejected` | When the operator rejects a proposed person, Tandem shall not propose that person again during the current acquisition. | Test | `AcquireTarget::reject` |
| ACQ-6 | `proposeNextAfterReject` | When the operator rejects a proposed person, Tandem shall propose another person in view, or scan for persons (ACQ-2) if no other person is in view. | Test | `AcquireTarget::reject` |
| ACQ-7 | `approvedPersonBecomesTarget` | When the operator approves any displayed person, Tandem shall make that person the target. | Test | `AcquireTarget::targetSet`<br>`AcquireTarget::otherPick` |
| ACQ-8 | `confirmNewTarget` | Tandem shall confirm a new target to the operator within 1s [TBR] of approval. | Test | `AcquireTarget::targetSet` |
| ACQ-9 | `alertNoPersonsFound` | If a full scan finds no persons, Tandem shall alert the operator. | Test | `AcquireTarget::noneFound` |
| ACQ-10 | `removeDepartedPerson` | Tandem shall remove a person from the operator's display within 1s [TBR] of them leaving view. | Test | `AcquireTarget::personLeaves` |
| ACQ-11 | `refuseOutOfViewApproval` | Tandem shall refuse an approval of a person who is no longer in view. | Test | `AcquireTarget::approvedPersonLeaves` |
| ACQ-12 | `explainRefusedApproval` | When Tandem refuses an approval, it shall tell the operator why. | Demonstration | `AcquireTarget::approvedPersonLeaves` |
| ACQ-13 | `holdPositionWhileAcquiring` | During target acquisition, Tandem shall hold position, moving only to rotate in place for scanning. | Test | `AcquireTarget::holdPosition` |

### Constraints

| ID | Name | Requirement | Verify | Traces to |
|---|---|---|---|---|
| CON-1 | `limitDescentRate` | When landing, Tandem shall descend at no more than 0.6 m/s [TBR]. | Test | `EndFlight::descend` |
| CON-2 | `limitHorizontalSpeed` | While flying autonomously, Tandem shall not exceed a horizontal speed of 5 m/s [TBR]. | Test | `FilmTarget::stayInZone`<br>`EndFlight::returnToLaunch` |
| CON-3 | `broadcastRemoteID` | Tandem shall broadcast Remote ID from takeoff to shutdown. | Demonstration | `KeepPersonInView` |

### End

| ID | Name | Requirement | Verify | Traces to |
|---|---|---|---|---|
| END-1 | `returnToLaunchPoint` | When the operator commands return to launch, Tandem shall fly to within 2m [TBR] of the launch point at the return altitude (6m [TBR]). | Test | `EndFlight::selectEndFlight`<br>`EndFlight::returnToLaunch` |
| END-2 | `landInPlace` | When the operator commands land here, Tandem shall land within 10m [TBR] horizontally of its position at the time of the command. | Test | `EndFlight::selectEndFlight`<br>`EndFlight::stopInPlace` |
| END-3 | `releaseTargetOnEnd` | When the operator commands end flight, Tandem shall stop following the target. | Test | `EndFlight::releaseTarget` |
| END-4 | `disarmAfterLanding` | When the drone has landed, Tandem shall disarm within 3s [TBR]. | Test | `EndFlight::disarm` |
| END-5 | `showLandingSpot` | During descent, Tandem shall show the operator a live view of the area beneath the drone. | Demonstration | `EndFlight::showLandingSpot` |
| END-6 | `holdIfPersonBelow` | During an operator-commanded descent, if a person is detected beneath the drone, Tandem shall stop descending and hold its position. | Test | `EndFlight::stopDescent` |
| END-7 | `alertPersonBelow` | When Tandem stops a descent because a person is beneath it, Tandem shall alert the operator within 1s [TBR]. | Test | `EndFlight::alertPersonBelow` |

### Follow

| ID | Name | Requirement | Verify | Traces to |
|---|---|---|---|---|
| FLW-1 | `stayInFramingZone` | While following a target moving at up to 3 m/s [TBR], Tandem shall keep the drone within the configured framing zone (distance ±2 m [TBR]). | Test | `FilmTarget::stayInZone`<br>`AdjustFraming::settle` |
| FLW-2 | `holdInsideZone` | While the drone is inside the framing zone, Tandem shall not move it to correct its offset. | Test | `FilmTarget::stayInZone` |
| FLW-3 | `configurableFollowSettings` | Tandem shall allow the operator to set distance, angle, zone width and height within the ranges in [the table]. | Demonstration | `AdjustFraming::enterValues`<br>`AdjustFraming::showCurrentSettings` |
| FLW-4 | `limitCameraToTargetDistance` | Tandem shall not accept settings whose combined camera-to-target distance exceeds 20m [TBR]. | Test | `AdjustFraming::rejectOutOfRange` |
| FLW-5 | `keepTargetCentered` | While following or paused, with the target moving at up to 3 m/s [TBR], Tandem shall keep the target within ±10° [TBR] of the centre of the camera view. | Test | `FilmTarget::keepCentered`<br>`PauseFollowing::keepCentered`<br>`AdjustFraming::keepCentered` |
| FLW-6 | `noUnplannedFollowStop` | Tandem shall not stop or suspend following unless the target is lost or overlapped by another person, the operator pauses or ends the flight, the pilot takes manual control, or a failsafe triggers. | Test | `FilmTarget::repeatUntilStopped` |
| FLW-7 | `freezeZoneWhenStationary` | While the target is stationary, Tandem shall keep the framing zone fixed relative to the target's last direction of travel. | Test | `FilmTarget::holdWhileStationary` |
| FLW-8 | `lostAfterNotSeen` | Tandem shall treat the target as lost when it has not been seen for 2s [TBR]. | Test | `FilmTarget::reportTargetLost`<br>`PauseFollowing::endPauseOnTargetLost`<br>`AdjustFraming::stopMoveOnTargetLost` |
| FLW-9 | `returnToAcquisitionWhenLost` | When the target is lost, Tandem shall return to target acquisition. | Test | `FilmTarget::reportTargetLost`<br>`PauseFollowing::endPauseOnTargetLost`<br>`AdjustFraming::stopMoveOnTargetLost`<br>`KeepPersonInView::returnToAcquisition` |
| FLW-10 | `alertOperatorWhenLost` | When the target is lost, Tandem shall alert the operator within 1s [TBR]. | Test | `FilmTarget::reportTargetLost` |
| FLW-11 | `alertFallingBehind` | When the drone has been farther than the configured distance plus 2m [TBR] for more than 3s [TBR], Tandem shall alert the operator it is falling behind. | Test | `FilmTarget::reportFallingBehind` |
| FLW-12 | `reacquireOnOverlap` | When another person overlaps the target in view, Tandem shall return to target acquisition. | Test | `FilmTarget::reportOverlap`<br>`PauseFollowing::endPauseOnOverlap`<br>`KeepPersonInView::returnToAcquisition`<br>`AdjustFraming::stopMoveOnOverlap` |
| FLW-13 | `rejectOutOfRangeSettings` | Tandem shall not accept a follow setting outside its allowed range. | Test | `AdjustFraming::rejectOutOfRange`<br>`PrepareForFlight::invalidSetting` |
| FLW-14 | `showAllowedRange` | When Tandem refuses a follow setting, it shall show the operator the allowed range. | Demonstration | `AdjustFraming::rejectOutOfRange`<br>`PrepareForFlight::invalidSetting` |
| FLW-17 | `gradualRepositioning` | When the follow settings change or following resumes, Tandem shall move the drone to the new position at no more than 2 m/s [TBR] relative to the target. | Test | `AdjustFraming::moveGradually`<br>`PauseFollowing::returnToZone` |
| FLW-18 | `newestSettingsWins` | When the operator changes the follow settings during a move from a previous change, Tandem shall move toward the newest settings. | Test | `AdjustFraming::switchToNewest` |
| FLW-19 | `holdOnPause` | When the operator commands pause, Tandem shall hold the drone's position. | Test | `PauseFollowing::selectPause`<br>`PauseFollowing::holdPosition` |
| FLW-20 | `resumeSameTarget` | When the operator commands resume, Tandem shall resume following the current target without re-approval. | Test | `PauseFollowing::selectResume`<br>`PauseFollowing::returnToZone` |

### Launch

| ID | Name | Requirement | Verify | Traces to |
|---|---|---|---|---|
| LCH-1 | `takeOffWhenArmed` | When the operator commands launch while armed, Tandem shall take off. | Test | `LaunchDrone::triggerLaunch`<br>`LaunchDrone::climb` |
| LCH-2 | `reachLaunchAltitude` | Tandem shall reach a launch altitude of 6m [TBR] +/- 1m [TBR] within 10s [TBR] of takeoff. | Test | `LaunchDrone::climb`<br>`LaunchDrone::hoverAtAltitude` |
| LCH-3 | `alertAltitudeNotReached` | When launch altitude is not reached within 10s [TBR] Tandem shall alert the operator. | Test | `LaunchDrone::altitudeNotReached` |

### ManualControl

| ID | Name | Requirement | Verify | Traces to |
|---|---|---|---|---|
| MAN-1 | `manualOverrideStopsAutonomy` | In any flight state, when the pilot selects manual control on the RC, Tandem shall stop all autonomous movement within 0.5s [TBR]. | Test | `TakeManualControl::selectManual`<br>`TakeManualControl::stopAutonomy`<br>`KeepPersonInView::handOverToPilot`<br>`PauseFollowing::handOverToPilot`<br>`LaunchDrone::handOverToPilot`<br>`AcquireTarget::handOverToPilot`<br>`FilmTarget::handOverToPilot`<br>`AdjustFraming::handOverToPilot`<br>`EndFlight::handOverToPilot` |
| MAN-2 | `holdUntilStickInput` | After the pilot takes manual control, Tandem shall hold position until it receives stick input from the RC. | Test | `TakeManualControl::holdPosition` |
| MAN-3 | `manualControlOnly` | While under manual control, Tandem shall move the drone only in response to pilot input, except when a failsafe triggers. | Test | `TakeManualControl::followStickInput` |
| MAN-4 | `reacquireAfterHandBack` | When the pilot hands control back to Tandem, Tandem shall return to target acquisition. | Test | `TakeManualControl::resumeAcquisition` |

### PreFlight

| ID | Name | Requirement | Verify | Traces to |
|---|---|---|---|---|
| PRE-1 | `readyOnlyWhenPrechecksPass` | Tandem shall not report ready unless all prechecks pass. | Test | `PrepareForFlight::connectToGroundStation`<br>`PrepareForFlight::runPrechecks`<br>`PrepareForFlight::noConnection`<br>`PrepareForFlight::notReady` |
| PRE-2 | `noArmOnFailedPrechecks` | When prechecks fail, Tandem shall refuse to arm. | Test | `PrepareForFlight::prechecksFail`<br>`PrepareForFlight::arm` |
| PRE-3 | `showPrecheckFailures` | When prechecks fail, Tandem shall display precheck failures to the operator. | Demonstration | `PrepareForFlight::prechecksFail`<br>`PrepareForFlight::notReady` |
| PRE-4 | `confirmSettingsBeforeArming` | Tandem shall not arm until the operator has confirmed the follow settings. | Test | `PrepareForFlight::showSettings`<br>`PrepareForFlight::confirmSettings`<br>`PrepareForFlight::arm` |

### Performance

| ID | Name | Requirement | Verify | Traces to |
|---|---|---|---|---|
| PRF-1 | `detectionRange` | Under nominal conditions, Tandem shall detect a person at a distance of up to 20m [TBR] camera-to-target in at least 90% [TBR] of video frames. | Test | `AdjustFraming::trackTarget`<br>`PauseFollowing::trackTarget`<br>`AcquireTarget::scanForPersons`<br>`FilmTarget::trackTarget` |
| PRF-2 | `commandResponseTime` | Anywhere inside the geofence, Tandem shall begin acting on an operator command within 0.5s [TBR] of the operator sending it. | Test | `AdjustFraming::confirmReceived`<br>`PauseFollowing::confirmPaused`<br>`PauseFollowing::confirmResumed`<br>`EndFlight::confirmEnd` |
| PRF-3 | `followEndurance` | Under nominal conditions, starting from a full battery, Tandem shall be able to follow a target for at least 8 minutes [TBR] before the low-battery return (XC-7) triggers. | Analysis, Test | `KeepPersonInView` |
| PRF-4 | `videoRange` | Under nominal conditions, Tandem shall provide usable video to the operator at up to 150m [TBR] from the ground control station. | Test | `KeepPersonInView` |
| PRF-5 | `videoLatency` | Under nominal conditions, within video range (PRF-4), Tandem shall provide video to the operator with a latency of no more than 500ms. | Test (short range), Analysis (at range) | `KeepPersonInView`<br>`EndFlight::showLandingSpot` |

### CrossCutting

| ID | Name | Requirement | Verify | Traces to |
|---|---|---|---|---|
| XC-1 | `confirmOperatorCommands` | Tandem shall confirm each operator command to the operator within 1 s [TBR]. | Test | `AdjustFraming::confirmReceived`<br>`PauseFollowing::confirmPaused`<br>`PauseFollowing::confirmResumed`<br>`EndFlight::confirmEnd`<br>`TakeManualControl::confirmManual`<br>`TakeManualControl::confirmHandBack` |
| XC-2 | `alertCommandNotApplied` | When an operator command is not confirmed within 1 s [TBR], Tandem shall tell the operator it was not applied. | Test | `AdjustFraming::reportNotReceived`<br>`PauseFollowing::reportPauseNotConfirmed`<br>`PauseFollowing::reportResumeNotConfirmed`<br>`EndFlight::reportNotConfirmed` |
| XC-3 | `respectKeepOutZone` | Tandem shall not move the drone into the target's keep-out zone. | Test | `FilmTarget::holdForKeepOut`<br>`AdjustFraming::routeAroundKeepOut`<br>`PauseFollowing::routeAroundKeepOut` |
| XC-4 | `holdWhileTargetInside` | While the target is inside the keep-out zone, Tandem shall hold position. | Test | `FilmTarget::holdForKeepOut` |
| XC-5 | `stayInsideGeofence` | Tandem shall not move the drone outside the geofence. | Test | `KeepPersonInView::stopAtGeofence` |
| XC-6 | `alertAtGeofence` | When the drone reaches the geofence, Tandem shall alert the operator within 1s [TBR]. | Test | `KeepPersonInView::stopAtGeofence` |
| XC-7 | `lowBatteryReturn` | When the remaining battery reaches 25% [TBR], Tandem shall return to launch. | Test | `KeepPersonInView::returnOnLowBattery` |
| XC-8 | `criticalBatteryLand` | When the remaining battery level reaches 10% [TBR], Tandem shall land in place. | Test | `KeepPersonInView::landOnCriticalBattery` |
| XC-9 | `groundLinkLossHold` | When the ground link is lost, Tandem shall hold position. | Test | `KeepPersonInView::holdOnGroundLinkLoss` |
| XC-10 | `groundLinkLossReturn` | If ground link is not re-established within 10s [TBR] of loss, Tandem shall return to launch. | Test | `KeepPersonInView::holdOnGroundLinkLoss` |
| XC-11 | `rcLinkLossReturn` | When RC connection is lost, Tandem shall return to launch. | Test | `KeepPersonInView::returnOnRcLoss`<br>`TakeManualControl::returnOnRcLoss` |
| XC-12 | `gpsLossLand` | When GPS position is lost, Tandem shall land in place. | Test | `KeepPersonInView::landOnGpsLoss`<br>`EndFlight::abandonReturn` |
| XC-13 | `gpsLossAdviseTakeover` | When GPS position is lost, Tandem shall advise the operator to take manual control. | Demonstration | `KeepPersonInView::landOnGpsLoss`<br>`EndFlight::abandonReturn` |
| XC-14 | `alertOnFailsafe` | When a failsafe triggers, Tandem shall alert the operator within 1s [TBR], stating which failsafe. | Test | `KeepPersonInView::returnOnLowBattery`<br>`KeepPersonInView::landOnCriticalBattery`<br>`KeepPersonInView::holdOnGroundLinkLoss`<br>`KeepPersonInView::returnOnRcLoss`<br>`KeepPersonInView::landOnGpsLoss` |
| XC-15 | `holdAfterLinkRestored` | When the ground link is restored after a loss, Tandem shall hold position until the operator commands resume. | Demonstration | `KeepPersonInView::holdOnGroundLinkLoss` |

## 2. Scenarios to requirements

### PrepareForFlight

| Action | Step | Covered by |
|---|---|---|
| `powerOn` | 1. Operator powers on the drone, ground station, and RC. | - |
| `connectToGroundStation` | 2. Ground station connects to Tandem. | PRE-1 |
| `runPrechecks` | 3. Tandem runs its prechecks (see PRE-1 definition) and reports ready when all pass. | PRE-1 |
| `showSettings` | 4. Tandem shows the current follow settings | PRE-4 |
| `confirmSettings` | 5. Operator changes them if needed and confirms. | PRE-4 |
| `requestArm` | 6. Operator commands arm. | - |
| `arm` | 7. Tandem arms (motors enabled). Ready for LaunchDrone. | PRE-2, PRE-4 |
| `noConnection` | A. Ground station cannot connect: operator told; Tandem does not report ready. | PRE-1 |
| `notReady` | B. Something not ready (e.g. GPS still acquiring, camera not found): Tandem shows what, and waits. | PRE-1, PRE-3 |
| `invalidSetting` | C. Setting out of range: not accepted; allowed range shown. | FLW-13, FLW-14 |
| `prechecksFail` | D. Prechecks fail (e.g. battery too low): arming refused; failures shown. | PRE-2, PRE-3 |

### LaunchDrone

| Action | Step | Covered by |
|---|---|---|
| `triggerLaunch` | 1. Operator triggers launch. | LCH-1 |
| `climb` | 2. Drone climbs. | LCH-1, LCH-2 |
| `hoverAtAltitude` | 3. Drone hovers at launch altitude. | LCH-2 |
| `handOverToPilot` | A. Any time: pilot takeover -> TakeManualControl. | MAN-1 |
| `altitudeNotReached` | B. Launch altitude not reached within 10 s [TBR]: drone holds; operator alerted. | LCH-3 |

### AcquireTarget

| Action | Step | Covered by |
|---|---|---|
| `holdPosition` | Throughout: drone holds position, rotating in place only to scan. | ACQ-13 |
| `scanForPersons` | 1. Scan until persons are in view. | ACQ-2, PRF-1 |
| `showPersons` | 2. Show all persons to the operator. | ACQ-3 |
| `proposePerson` | 3. Propose one person. | ACQ-4 |
| `operatorApproves` | 4. Operator approves. | ACQ-1 |
| `targetSet` | 5. Target is set. | ACQ-7, ACQ-8 |
| `reject` | A. At 4, operator rejects -> propose another, or scan if none left in view. | ACQ-5, ACQ-6 |
| `otherPick` | B. At 4, operator selects a different person -> approve that one. | ACQ-7 |
| `noneFound` | C. Full scan finds no one -> keep scanning and alert operator. | ACQ-9 |
| `personLeaves` | D. Person walks out of view before the operator decides -> removed from display; carry on. | ACQ-10 |
| `noResponse` | E. Operator does not respond -> keep waiting (never auto-approve). | ACQ-1 |
| `approvedPersonLeaves` | F. Person walks out of view at the moment of approval -> approval refused; operator told why. | ACQ-11, ACQ-12 |
| `handOverToPilot` | G. Any time: pilot takeover -> TakeManualControl. | MAN-1 |

### FilmTarget

| Action | Step | Covered by |
|---|---|---|
| `trackTarget` | 1. Tandem tracks the target's position and direction of travel. | PRF-1 |
| `stayInZone` | 2. Drone stays within the framing zone around the offset (default 8m, 180deg, 6m height). | CON-2, FLW-1, FLW-2 |
| `keepCentered` | 3. Camera keeps the target centered. | FLW-5 |
| `holdWhileStationary` | A. Target stands still: drone holds its current position. | FLW-7 |
| `holdForKeepOut` | B. Target walks into the keep-out zone: drone holds position until they leave. | XC-3, XC-4 |
| `reportTargetLost` | C. Target not seen for 2 s [TBR]: target lost; operator alerted; drone holds; exit to AcquireTarget. | FLW-8, FLW-9, FLW-10 |
| `reportFallingBehind` | D. Target outruns the drone: drone keeps chasing at top speed; if too far for more than 3 s, operator alerted it is falling behind; if no longer seen -> C. | FLW-11 |
| `reportOverlap` | E. Another person overlaps the target: return to AcquireTarget. | FLW-12 |
| `handOverToPilot` | H. Any time: pilot takeover -> TakeManualControl. | MAN-1 |
| `repeatUntilStopped` | Repeats until the operator ends the flight, or the target is lost or overlapped. | FLW-6 |

### AdjustFraming

| Action | Step | Covered by |
|---|---|---|
| `selectChange` | 1. Operator selects change settings. | - |
| `showCurrentSettings` | 2. Tandem shows the current follow settings. | FLW-3 |
| `enterValues` | 3. Operator enters and submits new values. | FLW-3 |
| `confirmReceived` | 4. Tandem confirms the new values were received. | PRF-2, XC-1 |
| `trackTarget` | 5. Tandem keeps tracking the target during the move. | PRF-1 |
| `moveGradually` | 6. Drone moves gradually to the new position. | FLW-17 |
| `keepCentered` | 7. Camera keeps the target centred during the move; 5-7 repeat until the drone is in position. | FLW-5 |
| `settle` | 8. Drone settles at the new position; following continues. | FLW-1 |
| `rejectOutOfRange` | A. Values out of range: not accepted; allowed range shown; nothing sent. | FLW-4, FLW-13, FLW-14 |
| `reportNotReceived` | B. No confirmation (link problem): operator told the change was not received; settings unchanged. | XC-2 |
| `routeAroundKeepOut` | C. Path to the new position crosses the keep-out zone: drone goes around the target at >= 5 m. | XC-3 |
| `stopMoveOnTargetLost` | D. Target lost during the move: move stops -> FilmTarget handles the loss. | FLW-8, FLW-9 |
| `switchToNewest` | E. Operator submits new values mid-move: they are checked and confirmed like any change; the drone abandons the old move and heads for the newest. | FLW-18 |
| `handOverToPilot` | F. Any time: pilot takeover -> TakeManualControl. | MAN-1 |
| `stopMoveOnOverlap` | G. Another person overlaps the target during the move: move stops -> FilmTarget handles the overlap. | FLW-12 |

### PauseFollowing

| Action | Step | Covered by |
|---|---|---|
| `selectPause` | 1. Operator selects pause. | FLW-19 |
| `confirmPaused` | 2. Tandem confirms following is paused. | PRF-2, XC-1 |
| `trackTarget` | 3. Tandem keeps tracking the target. | PRF-1 |
| `holdPosition` | 4. Drone holds position. | FLW-19 |
| `keepCentered` | 5. Camera keeps the target centred; drone rotates when the camera reaches its limit. | FLW-5 |
| `selectResume` | 6. Operator selects resume. | FLW-20 |
| `confirmResumed` | 7. Tandem confirms following is resumed. | PRF-2, XC-1 |
| `returnToZone` | 8. Drone returns gradually to the framing zone; following continues. | FLW-17, FLW-20 |
| `reportPauseNotConfirmed` | A. Pause not confirmed (link problem): operator told; drone keeps following. | XC-2 |
| `reportResumeNotConfirmed` | B. Resume not confirmed (link problem): operator told; drone stays paused. | XC-2 |
| `endPauseOnTargetLost` | C. Target not seen for 2 s [TBR]: pause ends -> FilmTarget handles the loss. | FLW-8, FLW-9 |
| `endPauseOnOverlap` | D. Another person overlaps the target: pause ends -> FilmTarget handles the overlap. | FLW-12 |
| `routeAroundKeepOut` | E. On resume, path back crosses the keep-out zone: drone goes around the target at >= 5 m. | XC-3 |
| `handOverToPilot` | F. Any time: pilot takeover -> TakeManualControl. | MAN-1 |

### EndFlight

| Action | Step | Covered by |
|---|---|---|
| `selectEndFlight` | 1. Operator selects end flight: return to launch or land here. | END-1, END-2 |
| `confirmEnd` | 2. Tandem confirms the command. | PRF-2, XC-1 |
| `releaseTarget` | 3. Tandem stops following the target. | END-3 |
| `returnToLaunch` | 4a. Return to launch: drone flies to the launch point at return altitude (6 m [TBR]). | CON-2, END-1 |
| `stopInPlace` | 4b. Land here: drone stops and holds where it is. | END-2 |
| `showLandingSpot` | 5. During descent, Tandem shows the operator the area beneath the drone. | END-5, PRF-5 |
| `checkLandingSpot` | 6. Operator watches the landing spot; takes over if it is not clear. | - |
| `descend` | 7. Drone descends. | CON-1 |
| `disarm` | 8. Drone disarms once landed. | END-4 |
| `reportNotConfirmed` | A. No confirmation (link problem): operator told; pilot can command return or land on the RC. | XC-2 |
| `stopDescent` | B. Person detected beneath the drone: descent stops; drone holds. | END-6 |
| `alertPersonBelow` | C. Operator alerted that a person is beneath the drone. | END-7 |
| `abandonReturn` | D. Position lost: commanded ending abandoned; emergency landing in place without person-below check -> KeepPersonInView gpsLost. | XC-12, XC-13 |
| `handOverToPilot` | E. Any time: pilot takeover -> TakeManualControl. | MAN-1 |

### TakeManualControl

| Action | Step | Covered by |
|---|---|---|
| `selectManual` | 1. Pilot selects manual control on the RC. | MAN-1 |
| `stopAutonomy` | 2. Tandem stops all autonomous movement. | MAN-1 |
| `confirmManual` | Tandem shows the operator that manual control is active. | XC-1 |
| `holdPosition` | 3. Drone holds position until the pilot gives stick inputs. | MAN-2 |
| `pilotFlies` | 4. Pilot flies the drone by RC. | - |
| `followStickInput` | 5. Tandem moves the drone only as the stick commands. | MAN-3 |
| `returnOnRcLoss` | A. RC link lost during manual flight: Tandem returns to launch (RC-loss failsafe). | XC-11 |
| `handBack` | B. Pilot hands control back to Tandem -> AcquireTarget (operator re-approves the target). | - |
| `confirmHandBack` | C. Tandem shows the operator that control is back with Tandem. | XC-1 |
| `resumeAcquisition` | d. Tandem returns to target acquisition (operator reapproves the target). | MAN-4 |

### KeepPersonInView

Whole use case: CON-3, PRF-3, PRF-4, PRF-5

| Action | Step | Covered by |
|---|---|---|
| `returnToAcquisition` | A. Target lost or overlapped during FilmTarget -> back to AcquireTarget, then FilmTarget again (repeat as needed). | FLW-9, FLW-12 |
| `handOverToPilot` | B. Any time: pilot takeover -> TakeManualControl. | MAN-1 |
| `stopAtGeofence` | C. Any time: drone reaches the geofence -> stops at the edge, keeps the target in view; operator alerted. Following continues if the target comes back inside. | XC-5, XC-6 |
| `returnOnLowBattery` | D. Any time: low battery -> return to launch and land (no person-below check); operator alerted. | XC-7, XC-14 |
| `landOnCriticalBattery` | E. Any time: critical battery -> land in place (no person-below check); operator alerted. | XC-8, XC-14 |
| `holdOnGroundLinkLoss` | F. Any time: ground link lost -> hold; return to launch and land (no person-below check) if not restored within 10 s. If restored, keep holding until the operator resumes. | XC-9, XC-10, XC-14, XC-15 |
| `returnOnRcLoss` | G. Any time: RC link lost -> return to launch and land (no person-below check); operator alerted. | XC-11, XC-14 |
| `landOnGpsLoss` | H. Any time: GPS lost -> land in place (no person-below check); operator alerted and advised to take over. | XC-12, XC-13, XC-14 |

## 3. Gaps

### Requirements with no trace

None.

### Actions not covered by any requirement

Some are deliberate (operator steps or references to other use cases).

- `PrepareForFlight::powerOn`: 1. Operator powers on the drone, ground station, and RC.
- `PrepareForFlight::requestArm`: 6. Operator commands arm.
- `AdjustFraming::selectChange`: 1. Operator selects change settings.
- `EndFlight::checkLandingSpot`: 6. Operator watches the landing spot; takes over if it is not clear.
- `TakeManualControl::pilotFlies`: 4. Pilot flies the drone by RC.
- `TakeManualControl::handBack`: B. Pilot hands control back to Tandem -> AcquireTarget (operator re-approves the target).

### Broken references

None.
