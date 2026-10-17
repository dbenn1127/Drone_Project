package TandemUseCases {
    private import Tandem::*;     // use everything defined in package Tandem

    use case def LaunchDrone {
        doc /* Operator commands launch; the flight controller takes off and hovers.*/
        subject tandem: TandemSystem;
        actor operator : OperatorPilot;
        objective {
            doc /* Drone is hovering, ready to search */ 
        }
    
    }

    use case def AcquireTarget{
        doc /* drone hovering, search triggered, target identified, target rejected or approved. Runs at start or when target is lost. */
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
}