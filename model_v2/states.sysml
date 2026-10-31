package TandemStates {
    private import ScalarValues::Boolean;
    private import SI::s;

    // --- events from the operator or pilot ---
    attribute def ArmCommand;
    attribute def LaunchCommand;
    attribute def ResumeCommand;
    attribute def PilotTakeover;
    attribute def PilotHandBack;
    attribute def PauseCommand;
    attribute def ReturnCommand;
    attribute def LandHereCommand;

    state def TandemModes {
        // --- conditions Tandem works out itself ---
        attribute prechecksPassed       : Boolean;  // PRE-1
        attribute settingsConfirmed     : Boolean;  // PRE-4
        attribute touchedDown           : Boolean;
        attribute lowBattery            : Boolean;  // XC-7 : 25% [TBR]
        attribute criticalBattery       : Boolean;  // XC-8 : 10% [TBR]
        attribute gpsLost               : Boolean;  // XC-12 : no valid position
        attribute groundLinkLost        : Boolean;  // XC-9 : no data for 5s [TBR]
        attribute groundLinkRestored    : Boolean;  // XC-15
        attribute rcLinkLost            : Boolean;  // XC-11 : no RC signal for 1s [TBR]
        attribute atLaunchAltitude      : Boolean;  // LCH-2
        attribute targetLost            : Boolean;  // FLW-8
        attribute targetOverlapped      : Boolean;  // FLW-12
        attribute atLaunchPoint         : Boolean;  // END-1
        attribute personBeneath         : Boolean;  // END-6
        attribute targetApproved        : Boolean;  // ACQ-7

        entry;
        then preparing;

        state preparing;
        accept ArmCommand if prechecksPassed and settingsConfirmed
            then armed;

        state armed;
        accept LaunchCommand
            then autonomous;

        state autonomous {
            entry;
            then launching;

            state launching;                                        // LaunchDrone
            accept when atLaunchAltitude
                then acquiring;
            accept after 10 [s] if not atLaunchAltitude             // LCH-3
                then launchStalled;

            state launchStalled;
            accept when atLaunchAltitude
                then acquiring;

            state acquiring;                                        // AcquireTarget
            accept when targetApproved
                then following;

            state following;                                        // FilmTarget
            accept when targetLost or targetOverlapped
                then acquiring;
            accept PauseCommand
                then paused;
            accept ReturnCommand
                then commandedEnding.returning;
            accept LandHereCommand
                then commandedEnding.landing;

            state paused;                                           // PauseFollowing
            accept ResumeCommand
                then following;
            accept when targetLost or targetOverlapped
                then acquiring;
            accept ReturnCommand
                then commandedEnding.returning;
            accept LandHereCommand
                then commandedEnding.landing;

            state commandedEnding {
                entry;
                then returning;

                state returning;
                accept when atLaunchPoint
                    then landing;
                
                state landing;
                accept when personBeneath
                    then holdingForPerson;

                state holdingForPerson;                       // END-6
                accept when not personBeneath
                    then landing;
            }    
        }
        accept PilotTakeover
            then manual;
        accept when criticalBattery or gpsLost
            then emergencyLanding;
        accept when lowBattery or rcLinkLost
            then failsafeReturn;
        accept when groundLinkLost
            then linkLossHold;
        accept when touchedDown
            then onGround;

        state linkLossHold;                                 // XC-9
        accept PilotTakeover
            then manual;
        accept after 10 [s] if not groundLinkRestored       // XC-10
            then failsafeReturn;
        accept ResumeCommand if groundLinkRestored          // XC-15
            then autonomous.acquiring;
        accept when criticalBattery or gpsLost
            then emergencyLanding;
        accept when lowBattery or rcLinkLost
            then failsafeReturn;
        
        
        state manual;
        accept PilotHandBack
            then autonomous.acquiring;                      // MAN-4
        accept when lowBattery or rcLinkLost
            then failsafeReturn;
        accept when criticalBattery
            then emergencyLanding;
        accept when touchedDown
            then onGround;

        state failsafeReturn;                           // XC-7, XC-10, XC-11
        accept PilotTakeover
            then manual;
        accept when criticalBattery or gpsLost
            then emergencyLanding;
        accept when touchedDown
            then onGround;

        state emergencyLanding;                         // XC-8, XC-12
        accept PilotTakeover
            then manual;
        accept when touchedDown
            then onGround;
        

        state onGround;
    }
}