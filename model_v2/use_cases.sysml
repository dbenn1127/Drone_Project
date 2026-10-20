package TandemUseCases {
    private import Tandem::*;     // use everything defined in package Tandem

    use case def LaunchDrone {
        doc /* Operator commands launch; Tandem takes off and hovers at alunch altitude.*/
        comment Preconditions /* prechecks passed and drone armed. */
        comment MainFlow /*
            1. Operator triggers launch.
            2. Drone climbs.
            3. Drone hovers at launch altitude.
        */
        comment AltFlows /*
            A. Prechecks fail, arming refused and launch prevented, failures displayed to operator.
            B. Any time: pilot takeover -> TakeManualControl
        */
        comment Assumptions /* A-3: Launch site is clear overhead and around the drone (operator responsibility)*/
        subject tandem: TandemSystem;
        actor operator : OperatorPilot;
        objective {
            doc /* Drone is hovering, ready to search */ 
        }
    
    }

    use case def AcquireTarget{
        doc /* drone hovering, search triggered, target identified, target rejected or approved. Runs at start or when target is lost. */
        comment MainFlow /*
            1. Scan until persons are in view.
            2. Show all persons to the operator.
            3. Propose one person.
            4. Operator approves.
            5. Target is set.
        */
        comment AltFlows /*
            A. Reject at 4, operator rejects -> propose another, or scan if none left in view.
            B. Other pick: at 4, operator selects a different person -> approve that one.
            C. None found: full scan finds no one -> keep scanning and alert operator.
            D. Person walks out of view before operator decides -> Disappear as detected person; carry on.
            E. Operator does not respond -> Keep waiting (never auto approve)
            F. Approved person walks out of view at moment selection is made -> Treat as lost. Back to step 1.
            G. Any time: pilot takeover -> TakeManualControl
        */

        subject tandem : TandemSystem;
        actor operator : OperatorPilot;
        actor target : Target;
        objective {
            doc /* Target approved.*/
        }

    }

    use case def FilmTarget{
        doc /* follow target and film based on commanded offsets until commanded to stop or target lost.*/
        comment Preconditions /* Person approved as target.*/
        comment MainFlow /*
            1. Tandem tracks the target's position and direction of travel.
            2. Drone stays within the framing zone around the offset (default 8m, 180deg, 6m height).
            3. Camera keeps the target centered.
            4. Repeats until the operator pauses or ends the flight.
        */
        comment AltFlows /*
            A. Target stands still: drone holds its current position.
            B. Target approaches the drone: keep-out zone applies (system-wide rule).
            C. Target not seen for 2 s [TBR]: target lost; operator alerted; drone holds; exit to AcquireTarget.
            D. Target outruns the drone: drone keeps chasing at top speed; if too far for more than 3 s,
            operator alerted it is falling behind; if no longer seen -> C.
            E. Another person overlaps the target: hold, highlight best guess, ask operator to re-confirm.
            Confirm -> resume; other pick -> that person becomes target; no answer -> keep holding.
            F. Operator adjusts framing -> AdjustFraming.
            G. Operator pauses -> PauseFollowing.
            H. Any time: pilot takeover -> TakeManualControl.
        */
        subject tandem : TandemSystem;
        actor operator : OperatorPilot;
        actor target : Target;
        objective {
            doc /* Drone follows target and films until commanded to stop or target is lost.*/
        }
        include use case adjust : AdjustFraming;
        include use case pause : PauseFollowing;
    }

    use case def AdjustFraming {
        doc /* While filming, operator can command a change to the offset. The drone gradually moves there without invading keepout zone.*/
        comment Preconditions /* Tandem is filming target. */
        comment MainFlow /*
            1. Operator selects change offset/angle
            2. Operator enters new values
            3. Tandem confirms the new values were received
            4. Drone moves gradually to the new offset
            5. Drone settles at the new offset; following continues*/
        comment AltFlows /*
            A. Values out of range: not accepted; operator shown the allowed range; nothing sent
            B. No confirmation (link problem) operator told the change was not received; offset unchanged
            C. Target not seen for 2 s [TBR]: lost; drone holds; exit to AcquireTarget.
            D. Target outruns the drone: drone keeps chasing at top speed; operator alerted it is falling behind; if no longer seen -> C.
            E. Operator changes valuea again mid-move: newest command wins.
            F. Any time: pilot takeover -> TakeManualControl.
        */
        subject tandem : TandemSystem;
        actor operator : OperatorPilot;
        actor target : Target;
        objective {
            doc /*Drone settles at new distance and angle.*/
        }
    }

    use case def PauseFollowing {
            doc /* while filming target, operator can command to hold position. Camera keeps following the target and drone rotates as camera hits limit. Resume follow can be initiated manually by operator. */
            comment Preconditions /* Drone is filming target. */
            comment MainFlow /*
                1. Operator selects pause follow.
                2. Tandem confirms follow paused.
                3. Drone hovers in place while camera follows target; drone rotates as necessary.
                4. Operator selects resume.
                5. Drone gradually returns to the offset; following continues.
            */
            comment AltFlows /*
                A. Pause not confirmed (link problem): operator told; drone keeps following.
                B. Target not seen for 2 s [TBR]: lost; operator alerted → AcquireTarget.
                C. Target walks toward the drone: keep-out zone applies (system-wide rule).
                D. Another person overlaps the target: hold, ask operator to reconfirm (as FilmTarget E).
                E. On resume, path back to the offset crosses the keep-out zone: drone goes around at >= 5m.
                F. Any time: pilot takeover -> TakeManualControl.
            */
            subject tandem : TandemSystem;
            actor operator : OperatorPilot;
            actor target : Target;
            objective {
                doc /* Drone holds position. Camera and drone rotating to follow target as necessary */
            }
    }
    
    use case def EndFlight {
        doc /* While Tandem is flying autonomously, during any action or state, the operator can command to end flight and return home or land in place. */
        comment MainFlow /*
            1. Operator selects end flight: RTL or land here.
            2. Tandem confirms; the target is released.
            3a. RTL: drone flies to the launch point at return altitude (6m [TBR]).
            3b. Land here : (no travel)
            4. Drone descends and lands.
            5. Drone disarms.
        */
        comment AltFlows /*
            A. No confirmation (link problem): operator told; select manual control on the RC and take over.
            B. Land here: camera points down during descent so the operator can see the landing spot; operator takes over if the spot is not celar.
            C. GPS lost during RTL: Tandem lands in place.
            D. Any time: pilot takeover -> TakeManualControl.
        */
        comment Assumptions /* 
            A-4: Operator ensures the landing area is clear (Tandem has no downward obstacles sensing).
            A-5: Tandem operates in open areas with no obstacles above follow height (6m).
        */
        subject tandem : TandemSystem;
        actor operator : OperatorPilot;
        objective {
            doc /* Drone returns to home and safely lands or lands in place. */
        }

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