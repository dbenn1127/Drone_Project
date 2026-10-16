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

    }
    
    use case def EndFlight {

    }

    use case def TakeManualControl {

    }

}