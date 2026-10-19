package TandemUseCases {
    private import Tandem::*;     // use everything defined in package Tandem

    use case def LaunchDrone {
        doc /* Operator commands launch; the flight controller takes off and hovers at alunch altitude.*/
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
        subject tandem : TandemSystem;
        actor operator : OperatorPilot;
        actor target : Target;
        objective {
            doc /*Drone settles at new distance and angle.*/
        }
    }

    use case def PauseFollowing {
            doc /* while filming target, operator can command to hold position. Gimbal still follows target and drone rotates as gimbal hits limit. Resume follow can be initiated manually by operator. */
            subject tandem : TandemSystem;
            actor operator : OperatorPilot;
            actor target : Target;
            objective {
                doc /* Drone holds position. Gimbal and drone rotating to follow target as necessary */
            }
    }
    
    use case def EndFlight {
        doc /* While drone is in guided mode, during any action or state, the operator can command to end flight and return home or land in place. */
        subject tandem : TandemSystem;
        actor operator : OperatorPilot;
        objective {
            doc /* Drone returns to home and safely lands or lands in place. */
        }

    }

    use case def TakeManualControl {
        doc /* While drone is in guided mode, during any action or state, the operator can exit guided mode and take over via RC. */
        subject tandem : TandemSystem;
        actor operator : OperatorPilot;
        objective {
            doc /* Drone is controlled by RC; all autonomous movement has stopped. The drone moves only in response to the pilot’s inputs. */
        }
    }

    use case def KeepPersonInView {
    doc /* Keep a person I choose in view and follow them, with me approving every target decision. Pilot takeover (TakeManualControl) can interrupt at any time; not part of a normal session. */
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