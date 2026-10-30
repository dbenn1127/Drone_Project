package TandemUseCases {
    private import Tandem::*;     // use everything defined in package Tandem

    use case def PrepareForFlight {
        doc /* Operator powers on and sets up Tandem; Tandem confirms it is ready and is armed for launch. */
        subject tandem : TandemSystem;
        actor operator : OperatorPilot;
        objective                       { doc /* Tandem is armed and ready to launch, with the following settings the operator chose. */}
        // --- main flow ---
        action powerOn                  { doc /* 1. Operator powers on the drone, ground station, and RC. */}
        action connectToGroundStation   { doc /* 2. Ground station connects to Tandem. */}
        action runPrechecks             { doc /* 3. Tandem runs its prechecks (see PRE-1 definition) and reports ready when all pass. */ }
        action showSettings             { doc /* 4. Tandem shows the current follow settings */ }
        action confirmSettings          { doc /* 5. Operator changes them if needed and confirms. */}
        action requestArm               { doc /* 6. Operator commands arm. */ }
        action arm                      { doc /* 7. Tandem arms (motors enabled). Ready for LaunchDrone. */ }
        // --- alternates ---
        action noConnection             { doc /* A. Ground station cannot connect: operator told; Tandem does not report ready. */}
        action notReady                 { doc /* B. Something not ready (e.g. GPS still acquiring, camera not found): Tandem shows what, and waits. */}
        action invalidSetting           { doc /* C. Setting out of range: not accepted; allowed range shown. */}
        action prechecksFail            { doc /* D. Prechecks fail (e.g. battery too low): arming refused; failures shown. */}

        // --- attributes ---
        attribute connected         : ScalarValues::Boolean;
        attribute allReady          : ScalarValues::Boolean;
        attribute faultFound        : ScalarValues::Boolean;
        attribute settingsConfirmed : ScalarValues::Boolean;
        attribute settingsValid     : ScalarValues::Boolean;

        //--- behavior ---
        first start;
        then powerOn;
        then loop action connecting {
            perform connectToGroundStation;
            then if not connected { perform noConnection; }
        } until connected;
        then loop action precheck {
            perform runPrechecks;
            then if faultFound { perform prechecksFail; }
            else if not allReady { perform notReady; }
        } until allReady;
        then loop action settingUp {
            perform showSettings;
            then perform confirmSettings; 
            then if not settingsValid { perform invalidSetting; }
        } until settingsConfirmed;
        then requestArm;
        then arm;
        then done;
    }

        part prepareLanes {
            use case prepare : PrepareForFlight;
            part tandem : TandemSystem {
                perform prepare.connectToGroundStation;
                perform prepare.runPrechecks;
                perform prepare.showSettings;
                perform prepare.arm;
                perform prepare.noConnection;
                perform prepare.notReady;
                perform prepare.invalidSetting;
                perform prepare.prechecksFail;
            }
            part operator : OperatorPilot {
                perform prepare.powerOn;
                perform prepare.confirmSettings;
                perform prepare.requestArm;
            }
        }
    
    use case def LaunchDrone {
        doc /* Operator commands launch; Tandem takes off and hovers at launch altitude. */
        comment Preconditions /* PrepareForFlight complete (drone armed). */
        comment Assumptions /* A-3: Launch site is clear overhead and around the drone (operator responsibility). */
        subject tandem : TandemSystem;
        actor operator : OperatorPilot;
        objective                       { doc /* Drone is hovering at launch altitude, ready to search. */}

        // --- main flow ---
        action triggerLaunch            { doc /* 1. Operator triggers launch. */ }
        action climb                    { doc /* 2. Drone climbs. */ }
        action hoverAtAltitude          { doc /* 3. Drone hovers at launch altitude. */ }

        // --- alternates ---
        action handOverToPilot          { doc /* A. Any time: pilot takeover -> TakeManualControl. */ }
        action altitudeNotReached       { doc /* B. Launch altitude not reached within 10 s [TBR]: drone holds; operator alerted. */ }

        // --- attributes ---
        attribute altitudeReached   : ScalarValues::Boolean;
        attribute climbTimedOut     : ScalarValues::Boolean;    // 10s [TBR], see LCH-3

        // --- behavior ---
        first start;
        then triggerLaunch;
        then loop action climbing {
            perform climb;
        } until altitudeReached or climbTimedOut;
        then if climbTimedOut { perform altitudeNotReached; }
            else { perform hoverAtAltitude; }
        then done;
    }

        part launchLanes {
            use case launch : LaunchDrone;
            part tandem : TandemSystem {
                perform launch.climb;
                perform launch.hoverAtAltitude;
                perform launch.altitudeNotReached;
            }
            part operator : OperatorPilot {
                perform launch.triggerLaunch;
            }
        }

    use case def AcquireTarget {
        doc /* Tandem finds persons, proposes one, and the operator approves a target. Runs at the start and whenever the target is lost. */
        subject tandem : TandemSystem;
        actor operator : OperatorPilot;
        actor target : Target;
        objective                   { doc /* Target approved. */}

        // --- rule for the whole use case ---
        action holdPosition         { doc /* Throughout: drone holds position, rotating in place only to scan. */ }

        // --- main flow ---
        action scanForPersons       { doc /* 1. Scan until persons are in view. */ }
        action showPersons          { doc /* 2. Show all persons to the operator. */ }
        action proposePerson        { doc /* 3. Propose one person. */ }
        action operatorApproves     { doc /* 4. Operator approves. */ }
        action targetSet            { doc /* 5. Target is set. */ }

        // --- alternates ---
        action reject               { doc /* A. At 4, operator rejects -> propose another, or scan if none left in view. */ }
        action otherPick            { doc /* B. At 4, operator selects a different person -> approve that one. */ }
        action noneFound            { doc /* C. Full scan finds no one -> keep scanning and alert operator. */ }
        action personLeaves         { doc /* D. Person walks out of view before the operator decides -> removed from display; carry on. */ }
        action noResponse           { doc /* E. Operator does not respond -> keep waiting (never auto-approve). */ }
        action approvedPersonLeaves { doc /* F. Person walks out of view at the moment of approval -> approval refused; operator told why. */ }
        action handOverToPilot      { doc /* G. Any time: pilot takeover -> TakeManualControl. */ }

        // --- attributes ---
        attribute personsInView : ScalarValues::Boolean; 
        attribute approved      : ScalarValues::Boolean;
        attribute stillInView   : ScalarValues::Boolean;
        attribute pickedOther   : ScalarValues::Boolean;   // picking another person also counts as approved

        // --- behavior ---
        first start;
        then loop action acquiring {
            loop action searching {
                perform scanForPersons;
                then if not personsInView { perform noneFound; }
            } until personsInView;
            then perform showPersons;
            then loop action asking {
                perform proposePerson;
                then if pickedOther { perform otherPick; }
                then if approved and not pickedOther { perform operatorApproves; }
                then if not approved { perform reject; }
            } until approved;
            then if not stillInView { perform approvedPersonLeaves; }
        } until approved and stillInView;
        then targetSet;
        then done;
    }

        part acquireLanes {
            use case acquire : AcquireTarget;
            part tandem : TandemSystem {
                perform acquire.holdPosition;     // throughout, not sequenced
                perform acquire.scanForPersons;
                perform acquire.showPersons;
                perform acquire.proposePerson;
                perform acquire.targetSet;
                perform acquire.noneFound;
                perform acquire.personLeaves;
                perform acquire.noResponse;
                perform acquire.approvedPersonLeaves;
            }
            part operator : OperatorPilot {
                perform acquire.operatorApproves;
                perform acquire.otherPick;
                perform acquire.reject;
            }
        }

    use case def FilmTarget{
        doc /* Follow target and film based on commanded offsets until commanded to stop or target lost.*/
        comment Preconditions /* Person approved as target.*/
        subject tandem : TandemSystem;
        actor operator : OperatorPilot;
        actor target : Target;
        objective                   { doc /* Drone follows target and films until commanded to stop or target is lost.*/}
        include use case adjust : AdjustFraming {
            actor :>> operator = FilmTarget::operator;
            actor :>> target   = FilmTarget::target;
            attribute :>> lost = FilmTarget::lost;
            attribute :>> overlapped = FilmTarget::overlapped;
        }
        include use case pause : PauseFollowing {
            actor :>> operator = FilmTarget::operator;
            actor :>> target   = FilmTarget::target;
            attribute :>> lost       = FilmTarget::lost;
            attribute :>> overlapped = FilmTarget::overlapped;
        }

        // --- main flow ---
        action trackTarget          { doc /* 1. Tandem tracks the target's position and direction of travel. */}
        action stayInZone           { doc /* 2. Drone stays within the framing zone around the offset (default 8m, 180deg, 6m height). */}
        action keepCentered         { doc /* 3. Camera keeps the target centered. */}
       
        // --- alternates ---
        action holdWhileStationary  { doc /* A. Target stands still: drone holds its current position. */ }
        action holdForKeepOut       { doc /* B. Target walks into the keep-out zone: drone holds position until they leave. */ }
        action reportTargetLost     { doc /* C. Target not seen for 2 s [TBR]: target lost; operator alerted; drone holds; exit to AcquireTarget. */ }
        action reportFallingBehind  { doc /* D. Target outruns the drone: drone keeps chasing at top speed; if too far for more than 3 s, operator alerted it is falling behind; if no longer seen -> C. */ }
        action reportOverlap        { doc /* E. Another person overlaps the target: return to AcquireTarget. */ }
        action handOverToPilot      { doc /* H. Any time: pilot takeover -> TakeManualControl. */ }

        // --- attributes ---
        attribute lost              : ScalarValues::Boolean;   // FLW-8
        attribute overlapped        : ScalarValues::Boolean;   // FLW-12
        attribute targetInKeepOut   : ScalarValues::Boolean;   // XC-3
        attribute targetStationary  : ScalarValues::Boolean;   // FLW-7
        attribute behindTooLong     : ScalarValues::Boolean;   // FLW-11
        attribute adjustRequested   : ScalarValues::Boolean;
        attribute pauseRequested    : ScalarValues::Boolean;
        attribute endRequested      : ScalarValues::Boolean;

        // ---behavior ---
        first start;
        then loop action repeatUntilStopped {
            doc /* Repeats until the operator ends the flight, or the target is lost or overlapped. */
            perform trackTarget;
            then if targetInKeepOut { perform holdForKeepOut; }
            else if targetStationary { perform holdWhileStationary; }
            else { perform stayInZone; }
            then perform keepCentered;
            then if behindTooLong { perform reportFallingBehind; }
            then if adjustRequested { perform adjust; }     // Valid per SysML v2.1 §8.3.17.14 / §8.3.25.2; Spec42 currently flags it (tool limitation).
            then if pauseRequested  { perform pause; }      // Valid per SysML v2.1 §8.3.17.14 / §8.3.25.2; Spec42 currently flags it (tool limitation).
        } until lost or overlapped or endRequested;
        then if lost { perform reportTargetLost; }
             else if overlapped { perform reportOverlap; }
        then done;
    }

        part filmLanes {
            use case film : FilmTarget;
            part tandem : TandemSystem {
                perform film.trackTarget;
                perform film.holdForKeepOut;
                perform film.holdWhileStationary;
                perform film.stayInZone;
                perform film.keepCentered;
                perform film.reportFallingBehind;
                perform film.reportTargetLost;
                perform film.reportOverlap;
            }
        }

    use case def AdjustFraming {
        doc /* While following, the operator changes the follow settings; the drone moves gradually to the new position without entering the keep-out zone. */
        comment Preconditions /* Tandem is following a target. */
        subject tandem : TandemSystem;
        actor operator : OperatorPilot;
        actor target : Target;
        objective                   { doc /* Drone settles at the new distance and angle; following continues. */}

        // --- main flow ---
        action selectChange         { doc /* 1. Operator selects change settings. */ }
        action showCurrentSettings  { doc /* 2. Tandem shows the current follow settings. */ }
        action enterValues          { doc /* 3. Operator enters and submits new values. */ }
        action confirmReceived      { doc /* 4. Tandem confirms the new values were received. */ }
        action trackTarget          { doc /* 5. Tandem keeps tracking the target during the move. */ }
        action moveGradually        { doc /* 6. Drone moves gradually to the new position. */ }
        action keepCentered         { doc /* 7. Camera keeps the target centred during the move; 5-7 repeat until the drone is in position. */ }
        action settle               { doc /* 8. Drone settles at the new position; following continues. */ }

                // --- alternates ---
        action rejectOutOfRange     { doc /* A. Values out of range: not accepted; allowed range shown; nothing sent. */ }
        action reportNotReceived    { doc /* B. No confirmation (link problem): operator told the change was not received; settings unchanged. */ }
        action routeAroundKeepOut   { doc /* C. Path to the new position crosses the keep-out zone: drone goes around the target at >= 5 m. */ }
        action stopMoveOnTargetLost { doc /* D. Target lost during the move: move stops -> FilmTarget handles the loss. */ }
        action switchToNewest       { doc /* E. Operator submits new values mid-move: they are checked and confirmed like any change; the drone abandons the old move and heads for the newest. */ }
        action handOverToPilot      { doc /* F. Any time: pilot takeover -> TakeManualControl. */ }
        action stopMoveOnOverlap    { doc /* G. Another person overlaps the target during the move: move stops -> FilmTarget handles the overlap. */ }

        // --- attributes ---
        attribute valuesValid      : ScalarValues::Boolean;   // FLW-13
        attribute received         : ScalarValues::Boolean;   // XC-1 / XC-2
        attribute pathBlocked      : ScalarValues::Boolean;   // XC-3
        attribute newValuesEntered : ScalarValues::Boolean;   // FLW-18
        attribute atNewPosition    : ScalarValues::Boolean;
        attribute lost             : ScalarValues::Boolean;   // FLW-8
        attribute overlapped       : ScalarValues::Boolean;   // FLW-12

        // --- behavior ---
        first start;
        then selectChange;
        then showCurrentSettings;
        then loop action changing {
            loop action entering {
                perform enterValues;
                then if not valuesValid { perform rejectOutOfRange; }
            } until valuesValid;
            then if not received { perform reportNotReceived; }
                 else {
                     perform confirmReceived;
                     then loop action moving {
                        perform trackTarget;
                        then if pathBlocked { perform routeAroundKeepOut; }
                            else { perform moveGradually; }
                        then perform keepCentered;
                     } until atNewPosition or lost or overlapped or newValuesEntered;
                     then if newValuesEntered { perform switchToNewest; }
                 }
        } until not newValuesEntered;
        then if lost { perform stopMoveOnTargetLost; }
            else if overlapped { perform stopMoveOnOverlap; }
            else if received { perform settle; }
        then done;
    }

    part adjustLanes {
        use case adjust : AdjustFraming;
        part tandem : TandemSystem {
            perform adjust.showCurrentSettings;
            perform adjust.rejectOutOfRange;    // ground station is inside Tandem
            perform adjust.confirmReceived;
            perform adjust.reportNotReceived;
            perform adjust.trackTarget;
            perform adjust.moveGradually;
            perform adjust.keepCentered;
            perform adjust.routeAroundKeepOut;
            perform adjust.switchToNewest;
            perform adjust.settle;
            perform adjust.stopMoveOnTargetLost;
            perform adjust.stopMoveOnOverlap;
        }
        part operator : OperatorPilot {
            perform adjust.selectChange;
            perform adjust.enterValues;
        }
    }

    use case def PauseFollowing {
        doc /* While filming target, operator can command to hold position. Camera keeps following the target and drone rotates as camera hits limit. Resume follow can be initiated manually by operator. */
        comment Preconditions /* Drone is filming target. */
        subject tandem : TandemSystem;
        actor operator : OperatorPilot;
        actor target : Target;
        objective                       { doc /* Drone holds position. Camera and drone rotating to follow target as necessary */}
        
        // --- main flow ---
        action selectPause              { doc /* 1. Operator selects pause. */ }
        action confirmPaused            { doc /* 2. Tandem confirms following is paused. */ }
        action trackTarget              { doc /* 3. Tandem keeps tracking the target. */ }
        action holdPosition             { doc /* 4. Drone holds position. */ }
        action keepCentered             { doc /* 5. Camera keeps the target centred; drone rotates when the camera reaches its limit. */ }
        action selectResume             { doc /* 6. Operator selects resume. */ }
        action confirmResumed           { doc /* 7. Tandem confirms following is resumed. */ }
        action returnToZone             { doc /* 8. Drone returns gradually to the framing zone; following continues. */ }

        // --- alternates ---
        action reportPauseNotConfirmed  { doc /* A. Pause not confirmed (link problem): operator told; drone keeps following. */ }
        action reportResumeNotConfirmed { doc /* B. Resume not confirmed (link problem): operator told; drone stays paused. */ }
        action endPauseOnTargetLost     { doc /* C. Target not seen for 2 s [TBR]: pause ends -> FilmTarget handles the loss. */ }
        action endPauseOnOverlap        { doc /* D. Another person overlaps the target: pause ends -> FilmTarget handles the overlap. */ }
        action routeAroundKeepOut       { doc /* E. On resume, path back crosses the keep-out zone: drone goes around the target at >= 5 m. */ }
        action handOverToPilot          { doc /* F. Any time: pilot takeover -> TakeManualControl. */ }

        // --- attributes ---
        attribute pauseConfirmed    : ScalarValues::Boolean;   // XC-1 / XC-2
        attribute operatorResumes   : ScalarValues::Boolean;   // operator's choice to resume
        attribute resumeConfirmed   : ScalarValues::Boolean;   // XC-1 / XC-2
        attribute lost              : ScalarValues::Boolean;   // FLW-8
        attribute overlapped        : ScalarValues::Boolean;   // FLW-12
        attribute pathBlocked       : ScalarValues::Boolean;   // XC-3
        attribute inZone            : ScalarValues::Boolean;   // FLW-1

        // --- behavior ---
        first start; 
        then selectPause;
        then if not pauseConfirmed { perform reportPauseNotConfirmed; }
             else {
                perform confirmPaused;
                then loop action paused {
                    perform trackTarget;
                    then perform holdPosition;
                    then perform keepCentered;
                    then if operatorResumes {
                        perform selectResume;
                        then if resumeConfirmed { perform confirmResumed; }
                             else { perform reportResumeNotConfirmed; }
                         }
                } until resumeConfirmed or lost or overlapped;
                then if lost { perform endPauseOnTargetLost; }
                     else if overlapped { perform endPauseOnOverlap; } 
                     else {
                        loop action returning {
                            perform trackTarget;
                            then if pathBlocked { perform routeAroundKeepOut; }
                            else { perform returnToZone; }
                        } until inZone or lost;
                     }
             }
        then done;
    }

    part pauseLanes {
        use case pause : PauseFollowing;
        part tandem : TandemSystem {
            perform pause.confirmPaused;
            perform pause.holdPosition;
            perform pause.trackTarget;
            perform pause.keepCentered;
            perform pause.confirmResumed;
            perform pause.returnToZone;
            perform pause.reportPauseNotConfirmed;
            perform pause.reportResumeNotConfirmed;
            perform pause.endPauseOnTargetLost;
            perform pause.endPauseOnOverlap;
            perform pause.routeAroundKeepOut;
        }
        part operator : OperatorPilot {
            perform pause.selectPause;
            perform pause.selectResume;
        }
    }
    
    use case def EndFlight {
        doc /* While Tandem is flying autonomously, the operator commands it to return to launch or land in place. */
        comment Assumptions /*
            A-4: Operator ensures the landing area is clear (Tandem has no downward obstacle sensing).
            A-5: Tandem operates in open areas with no obstacles taller than the height it is flying at (the follow height, or the return altitude during return to launch).
        */
        subject tandem : TandemSystem;
        actor operator : OperatorPilot;
        objective                   { doc /* Drone landed and disarmed, at the launch point or in place. */}

        // --- main flow ---
        action selectEndFlight      { doc /* 1. Operator selects end flight: return to launch or land here. */ }
        action confirmEnd           { doc /* 2. Tandem confirms the command. */ }
        action releaseTarget        { doc /* 3. Tandem stops following the target. */ }
        action returnToLaunch       { doc /* 4a. Return to launch: drone flies to the launch point at return altitude (6 m [TBR]). */ }
        action stopInPlace          { doc /* 4b. Land here: drone stops and holds where it is. */ }
        action showLandingSpot      { doc /* 5. During descent, Tandem shows the operator the area beneath the drone. */ }
        action checkLandingSpot     { doc /* 6. Operator watches the landing spot; takes over if it is not clear. */ }
        action descend              { doc /* 7. Drone descends. */ }
        action disarm               { doc /* 8. Drone disarms once landed. */ }

        // --- alternates ---
        action reportNotConfirmed   { doc /* A. No confirmation (link problem): operator told; pilot can command return or land on the RC. */ }
        action stopDescent          { doc /* B. Person detected beneath the drone: descent stops; drone holds. */ }
        action alertPersonBelow     { doc /* C. Operator alerted that a person is beneath the drone. */ }
        action abandonReturn        { doc /* D. Position lost: commanded ending abandoned; emergency landing in place without person-below check -> KeepPersonInView gpsLost. */ }
        action handOverToPilot      { doc /* E. Any time: pilot takeover -> TakeManualControl. */ }

        // --- attributes ---
        attribute received      : ScalarValues::Boolean;   // XC-1 / XC-2
        attribute returnChosen  : ScalarValues::Boolean;   // operator chose return to launch (else land here)
        attribute atLaunchPoint : ScalarValues::Boolean;   // END-1
        attribute gpsLost       : ScalarValues::Boolean;   // XC-12
        attribute personBeneath : ScalarValues::Boolean;   // END-6
        attribute landed        : ScalarValues::Boolean;   // END-4

        // --- behavior ---
        first start;
        then selectEndFlight;
        then if not received { perform reportNotConfirmed; }
             else {
                perform confirmEnd;
                then perform releaseTarget;
                then if returnChosen {
                        loop action returning {
                            perform returnToLaunch;
                        } until atLaunchPoint or gpsLost;
                      }
                      else { perform stopInPlace; }
                 then if gpsLost { perform abandonReturn; }
                      else {
                          loop action landing {
                              perform showLandingSpot;
                              then perform checkLandingSpot;
                              then if personBeneath { perform stopDescent; then perform alertPersonBelow; }
                                   else { perform descend; }
                          } until landed;
                          then perform disarm;
                      }
            }
        then done;
        //---
    }

    part endLanes {
        use case endFlight : EndFlight;
        part tandem : TandemSystem {
            perform endFlight.confirmEnd;
            perform endFlight.releaseTarget;
            perform endFlight.returnToLaunch;
            perform endFlight.stopInPlace;
            perform endFlight.showLandingSpot;
            perform endFlight.descend;
            perform endFlight.disarm;
            perform endFlight.reportNotConfirmed;
            perform endFlight.stopDescent;
            perform endFlight.alertPersonBelow;
            perform endFlight.abandonReturn;
        }
        part operator : OperatorPilot {
            perform endFlight.selectEndFlight;
            perform endFlight.checkLandingSpot;
        }
    }

    use case def TakeManualControl {
        doc /* At any time, the pilot selects manual control on the RC and flies the drone; all autonomous movement stops. */
        comment Preconditions /* Pilot holding the RC; drone flying under Tandem's autonomous control. */
        subject tandem : TandemSystem;
        actor operator : OperatorPilot;
        objective                   { doc /* Drone is controlled by RC; all autonomous movement has stopped. The drone moves only in response to the pilot's inputs. */}

        // --- main flow ---
        action selectManual         { doc /* 1. Pilot selects manual control on the RC. */ }
        action stopAutonomy         { doc /* 2. Tandem stops all autonomous movement. */ }
        action confirmManual        { doc /* Tandem shows the operator that manual control is active. */}
        action holdPosition         { doc /* 3. Drone holds position until the pilot gives stick inputs. */ }
        action pilotFlies           { doc /* 4. Pilot flies the drone by RC. */ }
        action followStickInput     { doc /* 5. Tandem moves the drone only as the stick commands. */}

        // --- alternates ---
        action returnOnRcLoss       { doc /* A. RC link lost during manual flight: Tandem returns to launch (RC-loss failsafe). */ }
        action handBack             { doc /* B. Pilot hands control back to Tandem -> AcquireTarget (operator re-approves the target). */ }
        action confirmHandBack      { doc /* C. Tandem shows the operator that control is back with Tandem. */}
        action resumeAcquisition    { doc /* d. Tandem returns to target acquisition (operator reapproves the target). */}

        // --- attributes ---
        attribute sticksMoved       : ScalarValues::Boolean;
        attribute pilotHandsBack    : ScalarValues::Boolean;
        attribute rcLost            : ScalarValues::Boolean;

        // --- behavior ---
        first start;
        then selectManual;
        then stopAutonomy;
        then confirmManual;
        then loop action manualFlight{
            if not sticksMoved { perform holdPosition; }
            else {
                perform PilotFlies;
                then perform followStickInput;
            }
        } until pilotHandsBack or rcLost;
        then if rcLost { perform returnOnLoss; }
            else {
                perform handBack;
                then perform confirmHandBack;
                then perform resumeAcquisition;
            }
        then done;

    }

    part manualLanes {
        use case manual : TakeManualControl;
        part tandem : TandemSystem {
            perform manual.stopAutonomy;
            perform manual.holdPosition;
            perform manual.followStickInput;
            perform manual.returnOnRcLoss;
            perform manual.confirmHandBack;
            perform manual.resumeAcquisition;
        }
        part pilot : OperatorPilot {
            perform manual.selectManual;
            perform manual.pilotFlies;
            perform manual.handBack;
        }
    }

    use case def KeepPersonInView {
        doc /* Keep a person I choose in view and follow them, with me approving every target decision. Main flow: PrepareForFlight -> LaunchDrone -> AcquireTarget -> FilmTarget (operator may adjust or pause) -> EndFlight. */
        subject tandem : TandemSystem;
        actor operator : OperatorPilot;
        actor target : Target;
        objective                   { doc /* The approved person stayed in view and was followed; Tandem never switched to anyone the operator didn't approve; the flight ended with the drone safely landed. */}
        include use case prepare : PrepareForFlight {
            actor :>> operator = KeepPersonInView::operator;
        }
        include use case launch : LaunchDrone {
            actor :>> operator = KeepPersonInView::operator;
        }
        include use case acquire : AcquireTarget {
            actor :>> operator = KeepPersonInView::operator;
            actor :>> target = KeepPersonInView::target;
        }
        include use case film : FilmTarget {
            actor :>> operator = KeepPersonInView::operator;
            actor :>> target = KeepPersonInView::target;
            attribute :>> endRequested = KeepPersonInView::endRequested;
        }
        include use case endFlight : EndFlight {
            actor :>> operator = KeepPersonInView::operator;
        }

        // --- alternates ---
        action returnToAcquisition      { doc /* A. Target lost or overlapped during FilmTarget -> back to AcquireTarget, then FilmTarget again (repeat as needed). */ }
        action handOverToPilot          { doc /* B. Any time: pilot takeover -> TakeManualControl. */ }
        action stopAtGeofence           { doc /* C. Any time: drone reaches the geofence -> stops at the edge, keeps the target in view; operator alerted. Following continues if the target comes back inside. */ }
        action returnOnLowBattery       { doc /* D. Any time: low battery -> return to launch and land (no person-below check); operator alerted. */ }
        action landOnCriticalBattery    { doc /* E. Any time: critical battery -> land in place (no person-below check); operator alerted. */ }
        action holdOnGroundLinkLoss     { doc /* F. Any time: ground link lost -> hold; return to launch and land (no person-below check) if not restored within 10 s. If restored, keep holding until the operator resumes. */ }
        action returnOnRcLoss           { doc /* G. Any time: RC link lost -> return to launch and land (no person-below check); operator alerted. */ }
        action landOnGpsLoss            { doc /* H. Any time: GPS lost -> land in place (no person-below check); operator alerted and advised to take over. */ }

        // --- attributes ---
        attribute endRequested : ScalarValues::Boolean;     // the operator's choice to end the flight. 

        // --- behavior ---
        first start;
        then prepare;
        then launch;
        then loop action mission {
            perform acquire;
            then perform film;
            then if not endRequested { perform returnToAcquisitionl }
        } until endRequested;
        then endFlight;
        then done;
    }

    part missionLanes {
        use case mission : KeepPersonInView;
        part tandem : TandemSystem {
            perform mission.returnToAcquisition;
            perform mission.stopAtGeoFence;
            perform mission.returnOnLowBattery;
            perform mission.landOnCriticalBattery;
            perform mission.holdOnGroundLinkLoss;
            perform mission.returnonRcLoss;
            perform mission landOnGpsLoss;
        }
    }