package TandemUseCases {
    private import Tandem::*;     // use everything defined in package Tandem

    use case def PrepareForFlight {
        doc /* Operator powers on and sets up Tandem; Tandem confirms it is ready and is armed for launch. */
        subject tandem : TandemSystem;
        actor operator : OperatorPilot;
        objective {
            doc /* Tandem is armed and ready to launch, with the following settings the operator chose. */
        }
        // --- main flow ---
        action powerOn                  { doc /* 1. Operator powers on the drone, ground station, and RC. */}
        action connectToGroundStation   { doc /* 2. Ground station connects to Tandem. */}
        action runPrechecks             { doc /* 3. Tandem runs its prechecks (see PRE-1 definition) and reports ready when all pass. */ }
        action setSettings              { doc /* 4. Tandem shows the current follow settings; operator changes them if needed and confirms. */ }
        action arm                      { doc /* 5. Operator arms. Ready for LaunchDrone. */ }

        // --- alternates ---
        action noConnection             { doc /* A. Ground station cannot connect: operator told; Tandem does not report ready. */}
        action notReady                 { doc /* B. Something not ready (e.g. GPS still acquiring, camera not found): Tandem shows what, and waits. */}
        action invalidSetting           { doc /* C. Setting out of range: not accepted; allowed range shown. */}
        action prechecksFail            { doc /* D. Prechecks fail (e.g. battery too low): arming refused; failures shown. */}
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
        action pilotTakeover            { doc /* A. Any time: pilot takeover -> TakeManualControl. */ }
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
        action pilotTakeover        { doc /* G. Any time: pilot takeover -> TakeManualControl. */ }
    }

    use case def FilmTarget{
        doc /* follow target and film based on commanded offsets until commanded to stop or target lost.*/
        comment Preconditions /* Person approved as target.*/
        subject tandem : TandemSystem;
        actor operator : OperatorPilot;
        actor target : Target;
        objective                   { doc /* Drone follows target and films until commanded to stop or target is lost.*/}
        include use case adjust : AdjustFraming;
        include use case pause : PauseFollowing;

        // --- main flow ---
        action trackTarget          { doc /* 1. Tandem tracks the target's position and direction of travel */}
        action stayInZone           { doc /* 2. Drone stays within the framing zone around the offset (default 8m, 180deg, 6m height). */}
        action keepCentered         { doc /* 3. Camera keeps the target centered. */}
        action repeatUntilStopped   { doc /* 4. Repeats until the operator pauses or ends the flight. */}

        // --- alternates ---
        action targetStill          { doc /* A. Target stands still: drone holds its current position. */ }
        action targetApproaches     { doc /* B. Target approaches the drone: keep-out zone applies (system-wide rule). */ }
        action targetLost           { doc /* C. Target not seen for 2 s [TBR]: target lost; operator alerted; drone holds; exit to AcquireTarget. */ }
        action fallingBehind        { doc /* D. Target outruns the drone: drone keeps chasing at top speed; if too far for more than 3 s, operator alerted it is falling behind; if no longer seen -> C. */ }
        action overlap              { doc /* E. Another person overlaps the target: return to AcquireTarget. */ }
        action operatorAdjusts      { doc /* F. Operator adjusts framing -> AdjustFraming. */ }
        action operatorPauses       { doc /* G. Operator pauses -> PauseFollowing. */ }
        action pilotTakeover        { doc /* H. Any time: pilot takeover -> TakeManualControl. */ }
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
        action enterValues          { doc /* 2. Operator enters new values. */ }
        action confirmReceived      { doc /* 3. Tandem confirms the new values were received. */ }
        action moveGradually        { doc /* 4. Drone moves gradually to the new position. */ }
        action settle               { doc /* 5. Drone settles at the new position; following continues. */ }

        // --- alternates ---
        action outOfRange           { doc /* A. Values out of range: not accepted; allowed range shown; nothing sent. */ }
        action notReceived          { doc /* B. No confirmation (link problem): operator told the change was not received; settings unchanged. */ }
        action pathCrossesKeepOut   { doc /* C. Path to the new position crosses the keep-out zone: drone goes around the target at >= 5 m. */ }
        action targetLost           { doc /* D. Target lost during the move -> FilmTarget targetLost. */ }
        action newestWins           { doc /* E. Operator changes values again mid-move: newest command wins. */ }
        action pilotTakeover        { doc /* F. Any time: pilot takeover -> TakeManualControl. */ }
    }

    use case def PauseFollowing {
        doc /* while filming target, operator can command to hold position. Camera keeps following the target and drone rotates as camera hits limit. Resume follow can be initiated manually by operator. */
        comment Preconditions /* Drone is filming target. */
        subject tandem : TandemSystem;
        actor operator : OperatorPilot;
        actor target : Target;
        objective                       { doc /* Drone holds position. Camera and drone rotating to follow target as necessary */}
        
        //--- main flow ---
        action selectPause              { doc /* 1. Operator selects pause. */ }
        action confirmPaused            { doc /* 2. Tandem confirms following is paused. */ }
        action holdAndTrack             { doc /* 3. Drone holds position; camera keeps tracking the target; drone rotates when the camera reaches its limit. */ }
        action selectResume             { doc /* 4. Operator selects resume. */ }
        action returnToZone             { doc /* 5. Drone returns gradually to the framing zone; following continues. */ }

        // --- alternates ---
        action pauseNotConfirmed        { doc /* A. Pause not confirmed (link problem): operator told; drone keeps following. */ }
        action targetLost               { doc /* B. Target not seen for 2 s [TBR]: lost; operator alerted -> AcquireTarget. */ }
        action targetApproaches         { doc /* C. Target walks toward the drone: keep-out zone applies (system-wide rule). */ }
        action overlap                  { doc /* D. Another person overlaps the target -> AcquireTarget. */ }
        action resumePathCrossesKeepOut { doc /* E. On resume, path back crosses the keep-out. */}
    }
    
    use case def EndFlight {
        doc /* While Tandem is flying autonomously, the operator commands it to return to launch or land in place. */
        comment Assumptions /*
            A-4: Operator ensures the landing area is clear (Tandem has no downward obstacle sensing).
            A-5: Tandem operates in open areas with no obstacles above follow height (6 m).
        */
        subject tandem : TandemSystem;
        actor operator : OperatorPilot;
        objective                   { doc /* Drone landed and disarmed, at the launch point or in place. */}

        // --- main flow ---
        action selectEndFlight      { doc /* 1. Operator selects end flight: return to launch or land here. */ }
        action confirmEnd           { doc /* 2. Tandem confirms; the target is released. */ }
        action returnToLaunch       { doc /* 3a. Return to launch: drone flies to the launch point at return altitude (6 m [TBR]). */ }
        action landHere             { doc /* 3b. Land here: no travel. */ }
        action descendAndLand       { doc /* 4. Drone descends and lands. */ }
        action disarm               { doc /* 5. Drone disarms. */ }

        // --- alternates ---
        action notConfirmed         { doc /* A. No confirmation (link problem): operator told; pilot commands return or land on the RC. */ }
        action watchLandingSpot     { doc /* B. During descent the camera shows the landing spot; operator takes over if it is not clear. */ }
        action personBelow          { doc /* C. Person detected beneath the drone during descent: descent stops; operator alerted. */ }
        action positionLost         { doc /* D. Position lost during return: drone lands in place, operator alerted. */ }
        action pilotTakeover        { doc /* E. Any time: pilot takeover -> TakeManualControl. */ }
    }

    use case def TakeManualControl {
        doc /* While drone is in guided mode, during any action or state, the operator can exit guided mode and take over via RC. */
        comment Preconditions /* Pilot holding the RC; drone flying under Tandem's control. */
        comment MainFlow /*
            1. Pilot selects manual control on RC.
            2. Flight controller changes mode; Tandem stops sending motion commands.
            3. Drone holds position until the pilot moves the sticks.
            4. Pilot flies the drone by RC.
        */
        comment AltFlows /*
            A. RC link lost during manual flight : flight controller RC fialsafe (RTL or land).
            B. Pilot hands control back to Tandem -> AcquireTarget (operator re-approves target).
        */
        subject tandem : TandemSystem;
        actor operator : OperatorPilot;
        objective {
            doc /* Drone is controlled by RC; all autonomous movement has stopped. The drone moves only in response to the pilot’s inputs. */
        }
    }

    use case def KeepPersonInView {
    doc /* Keep a person I choose in view and follow them, with me approving every target decision. Pilot takeover (TakeManualControl) can interrupt at any time; not part of a normal session. */
    comment MainFlow /*
        1. LaunchDrone
        2. AcquireTarget
        3. FilmTarget (operator may adjust framing or pause following)
        4. EndFlight
    */
    comment AltFlows /*
        A. Target lost during FilmTarget -> back to AcquireTarget, then FilmTarget again (repeat as needed).
        B. Any time: pilot takeover -> TakeManualControl (interrupts the mission).
        C. Target heads past the operating area: drone holds at the soft fence; operator alerted; following resumes if the target returns (if no longer seen -> lost, alt A).
        D. Any time: failsafe (battery, link loss, GPS) -> Tandem ends the flight.
    */
    subject tandem : TandemSystem;
    actor operator : OperatorPilot;
    actor target : Target;
    objective {
        doc /* the approved person stayed in view and followed; the system never switched to anyone the operator didn’t approve; the flight ended with the drone safely landed. */
    }
    include use case launch : LaunchDrone;
    include use case acquire : AcquireTarget;
    include use case film : FilmTarget;
    include use case endFlight: EndFlight;
    }
}