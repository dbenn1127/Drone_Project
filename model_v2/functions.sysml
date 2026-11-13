package TandemFunctions {
    private import Tandem::*;                 // context items (PersonAppearance, OperatorCommand, GroundDisplay…)
    private import ScalarValues::Boolean;

    // ===================== internal items =====================
    // Things that flow BETWEEN functions, inside Tandem.
    item def VideoFrame;          // one camera image
    item def PersonDetections;    // the people found in a frame (boxes)
    item def TargetTrack;         // the target's position and direction of travel
    item def DronePosition;       // where the drone is: position, height, heading
    item def DroneVelocity;       // how fast and which way the drone is moving
    item def DroneAttitude;       // how the drone is tilted: roll, pitch (from the IMU)
    item def HeadingRequest;     // which way the drone should face
    item def MotionSetpoint;      // where/how fast the drone should go next
    item def FollowSettings;      // distance, angle, zone width, height (FLW-3; ranges in step 7)
    item def Waypoint;            // a point to fly to: position and height
    item def CameraPointing;      // where the camera is pointing: pan, tilt
    item def TargetProposal;      // the one person Tandem suggests as the target
    item def TargetDesignation;   // which person is the target (or none)
    item def ApprovedPerson;      // a person the operator approved who is confirmed in view


    // ===================== seeing =====================
    action def DetectPersons {
        doc /* Find every person in the camera image. */
        in item image : VideoFrame;
        out item detections : PersonDetections;
        out attribute personsInView : Boolean;       // ACQ-2
    }

    action def TrackTarget {
        doc /* Follow the approved target from frame to frame and work out where it is and where it is going. */
        in item detections : PersonDetections;
        in item designation : TargetDesignation;     // which person to follow
        in item pointing    : CameraPointing;        // where the camera is aimed
        in item position    : DronePosition;         // where the drone is: together they place the target in the world
        out item track : TargetTrack;
        out attribute targetLost       : Boolean;    // FLW-8
        out attribute targetOverlapped : Boolean;    // FLW-12
        out attribute targetStationary : Boolean;    // FLW-7
    }

    action def PointCamera {
        doc /* Aim the camera: keep the target centred (FLW-5: within ±10° [TBR]), or sweep to scan when there is no target; when the gimbal reaches its limit, ask the drone to turn. */
        in item track     : TargetTrack;
        in item position  : DronePosition;      // the drone's heading: the camera aims relative to it
        out item pointing : CameraPointing;     // to the camera mount
        out item turn     : HeadingRequest;     // to HoldPosition: face this way
    }

    action def CaptureVideo {
        doc /* Turn what the camera sees into a stream of video frames. */
        in item appearance : PersonAppearance;     // context item: light from the people in view
        out item image     : VideoFrame;           // to DetectPersons and StreamVideo
    }

    // ===================== moving the drone =====================
    action def HoldPosition {
        doc /* Keep the drone at its current position and height, facing the requested heading (or its current heading if none is requested). */
        in item position  : DronePosition;
        in item turn      : HeadingRequest;     // from PointCamera
        out item setpoint : MotionSetpoint;
    }

    action def FollowTarget {
        doc /* Move the drone to stay within the configured framing zone around the target, correcting only when it drifts outside the zone. */
        in item position  : DronePosition;
        in item track     : TargetTrack;
        in item settings  : FollowSettings;
        out item setpoint : MotionSetpoint;
        out attribute fallingBehind : Boolean;        // FLW-11
    
        // --- made of: compute where to be, then fly there ---
        action compute : ComputeFramingPosition {
            in item  :>> track    = FollowTarget::track;
            in item  :>> settings = FollowTarget::settings;
            in item  :>> position = FollowTarget::position;
            out item :>> destination;
            out attribute :>> fallingBehind = FollowTarget::fallingBehind;
        }

        flow from compute.destination to fly.destination;

        action fly : FlyToPosition {
            in item :>> position = FollowTarget::position;
            in item :>> destination;
            in attribute :>> speedLimit;                      // top speed while following (CON-2)
            out item :>> setpoint = FollowTarget::setpoint;
            out attribute :>> arrived;
        }
    }

    action def ComputeFramingPosition {
        doc /* Work out where in the framing zone the drone should be, given the target and the follow settings. While the drone is already inside the zone, the answer is where it already is (no correction, FLW-2). */
        in item track    : TargetTrack;
        in item settings : FollowSettings;
        in item position : DronePosition;
        out item destination : Waypoint;
        out attribute fallingBehind : Boolean;        // FLW-11
    }

    action def FlyToPosition {
        doc /* Fly the drone to a given point at no more than a given speed, and report arrival. Always heads for the latest destination given; a new destination replaces the old one immediately (FLW-18). */
        in item position    : DronePosition;
        in item destination : Waypoint;
        in attribute speedLimit : ISQ::SpeedValue;    // FLW-17 repositioning, CON-2 top speed
        out item setpoint   : MotionSetpoint;
        out attribute arrived : Boolean;
    }

    action def Land {
        doc /* Descend at no more than the landing rate until touchdown; works with or without a position fix. */
        in attribute descentLimit : ISQ::SpeedValue;    // CON-1
        out item setpoint : MotionSetpoint;
        out attribute touchedDown : Boolean;
    }

    action def FlyByStick {
        doc /* Turn the pilot's RC stick inputs into drone motion; works with or without a position fix. */
        in item sticks : RCInput;                   // context item: from the pilot
        out item setpoint : MotionSetpoint;
        out attribute sticksMoved : Boolean;        // MAN-2: hold until the sticks move
    }

    action def ControlArming {
        doc /* Enable the motors on the operator's arm command, and disable them once the drone has landed (END-4: within 3 s [TBR]). Arming is only accepted when prechecks pass and settings are confirmed (state machine guard; PRE-2, PRE-4). */
        in item command : OperatorCommand;          // the operator's arm request (context item)
        in attribute touchedDown : Boolean;         // from Land
        out attribute motorsEnabled : Boolean;      // to FlyTheDrone: no thrust unless armed
    }

    action def EnforceGeofence {
        doc /* Stop any requested motion at the geofence edge, in every flight mode including manual. */
        in item requested : MotionSetpoint;     // from HoldPosition / FlyToPosition / Land / FlyByStick
        in item position  : DronePosition;
        in item home      : Waypoint;           // fence centre = launch point, from RecordLaunchPoint
        out item limited  : MotionSetpoint;     // to FlyTheDrone
        out attribute atGeofence : Boolean;     // XC-6
    }

    action def FlyTheDrone {
        doc /* Keep the drone stable and drive the motors so it moves as the setpoint asks; no thrust unless the motors are enabled. Its effect is the drone's motion, sensed again by EstimateDroneState. */
        in item setpoint : MotionSetpoint;          // limited, from EnforceGeofence
        in item velocity : DroneVelocity;           // to follow a speed setpoint
        in item attitude : DroneAttitude;           // to stay level
        in attribute motorsEnabled : Boolean;       // from ControlArming
    }

    // ===================== talking to the operator =====================

    action def ShowPersons {
        doc /* Show every person in view to the operator as selectable, and remove anyone who leaves view (ACQ-3, ACQ-10: within 1 s [TBR]). */
        in item detections : PersonDetections;      // from DetectPersons
        out item display : GroundDisplay;           // context item: to the operator
    }

    action def ProposeTarget {
        doc /* Pick one displayed person to suggest as the target (ACQ-4: selection rule TBD, e.g. nearest; after an overlap the person most likely to be the previous target), never re-proposing someone rejected in this acquisition (ACQ-5). */
        in item detections : PersonDetections;      // who is in view
        in item lastTrack : TargetTrack;            // the previous target, for the after overlap best guess
        out item proposal : TargetProposal;
    }

    action def ShowSettings {
        doc /* Show the operator the current follow settings (distance, angle, zone width, height), before arming and whenever they ask to change them (PRE-4, FLW-3). */
        in item settings : FollowSettings;
        out item display : GroundDisplay;           // context item: to the operator
    }

    action def StreamVideo {
        doc /* Send live video to the operator: usable at up to 150 m from the ground station (PRF-4), with no more than 500 ms of delay (PRF-5); during descent it shows the area beneath the drone (END-5). */
        in item image   : VideoFrame;
        out item display : GroundDisplay;          // context item: to the operator
    }

    action def MaintainLinks {
        doc /* Establish the ground-station link, and watch it and the RC link (XC-9: ground link lost after 5 s [TBR] without data; XC-11: RC link lost after 1 s [TBR]; XC-15: report when the ground link is restored). */
        in item rc : RCInput;                       // context item: the RC signal being watched
        out attribute groundLinkUp : Boolean;
        out attribute rcLinkUp     : Boolean;
    }

    action def AcknowledgeCommand {
        doc /* Reply to every command the operator or pilot sends: confirm it was received and acted on, or say it was not received, or refused and why (XC-1, XC-2). */
        in item command : OperatorCommand;          // context item: pause, resume, end, approve, settings…
        in item rc      : RCInput;                  // context item: pilot takeover / hand-back switch
        in attribute accepted : Boolean;            // whether Tandem acted on it (e.g. stillInView, state guard)
        out attribute acknowledged : Boolean;       // XC-1/XC-2: confirmation got through in time
        out item display : GroundDisplay;           // context item: the confirmation, or what failed and why
    }

    action def AlertOperator {
        doc /* Tell the operator about anything they need to know but didn't ask for, by priority: warnings (act now) over cautions over advisories. Each alert stays up until its condition clears. */
        in attribute launchStalled   : Boolean;     // LCH-3: altitude not reached
        in attribute personsInView   : Boolean;     // none found (acquiring); person below (descent)
        in attribute targetLost      : Boolean;     // FLW-8
        in attribute targetOverlapped: Boolean;     // FLW-12
        in attribute fallingBehind   : Boolean;     // FLW-11
        in attribute atGeofence      : Boolean;     // XC-6
        in attribute lowBattery      : Boolean;     // XC-7
        in attribute criticalBattery : Boolean;     // XC-8
        in attribute rcLinkUp        : Boolean;     // XC-11
        in attribute groundLinkUp    : Boolean;     // XC-9 / XC-15: shown once the link is back
        in attribute gpsLost         : Boolean;     // XC-12: advise taking over
        out item display : GroundDisplay;           // context item: to the operator
    }

    // ===================== deciding and checking =====================

    action def ValidateSettings {
        doc /* Check the follow settings the operator enters against their allowed ranges (FLW-13) and the 20 m camera-to-target limit (FLW-4). Accepted values become the current settings; rejected values change nothing, and the allowed range is shown (FLW-14). Keeps the last accepted settings between flights (PRE-4). */
        in item requested  : OperatorCommand;      // the values the operator typed (context item)
        out item settings  : FollowSettings;       // the current, accepted settings
        out attribute valuesValid : Boolean;       // FLW-13: ends AdjustFraming's entering loop
        out item display   : GroundDisplay;        // FLW-14: the allowed range, when rejected
    }

    action def CheckApproval {
        doc /* Accept the operator's approval only if that person is still in view (ACQ-11); otherwise refuse it. */
        in item approval   : OperatorCommand;      // approve, or pick another person
        in item proposal   : TargetProposal;       // who "approve" refers to
        in item detections : PersonDetections;     // who is in view right now
        out item approved  : ApprovedPerson;       // only when the check passes
        out attribute stillInView : Boolean;       // ACQ-11
    }

    action def DesignateTarget {
        doc /* Make the approved person the target (ACQ-7), and release the target when the flight ends (END-3). */
        in item approved     : ApprovedPerson;
        out item designation : TargetDesignation;  // to TrackTarget
    }
    
    action def RunPrechecks {
        doc /* Check everything needed for a safe flight is ready (PRE-1: ground link, RC link, GPS position, camera, battery above minimum [TBR], flight-safety checks), report ready only when all pass, and show what is not ready or has failed (PRE-3). */
        in attribute groundLinkUp : Boolean;          // from MaintainLinks
        in attribute rcLinkUp     : Boolean;          // from MaintainLinks
        in attribute gpsLost      : Boolean;          // from EstimateDroneState
        in item image             : VideoFrame;       // from CaptureVideo: are frames arriving?
        in attribute batteryOk    : Boolean;          // from MonitorBattery
        out attribute prechecksPassed : Boolean;      // PRE-1
        out attribute faultFound      : Boolean;      // PRE-2: a real fault, not just "not ready yet"
        out item display : GroundDisplay;             // PRE-3: what is not ready, or failed
    }

    action def AvoidKeepOut {
        doc /* Keep the drone at least 5 m from the target: if the straight path to the destination crosses the keep-out zone, replace it with a waypoint that goes around. */
        in item position    : DronePosition;
        in item track       : TargetTrack;
        in item destination : Waypoint;
        out item routed     : Waypoint;              // to FlyToPosition
        out attribute pathBlocked     : Boolean;     // XC-3
        out attribute targetInKeepOut : Boolean;     // XC-3
    }

    // ===================== hidden (no use case step, but needed) =====================
    
    action def EstimateDroneState {
        doc /* Work out where the drone is, how it is moving and how it is tilted, from GPS and its own sensors. */
        in item gnss : GNSSSignal;                   // context item: from the satellites
        out item position : DronePosition;
        out item velocity : DroneVelocity;
        out item attitude : DroneAttitude;
        out attribute gpsLost : Boolean;             // XC-12
    }

    action def MonitorBattery {
        doc /* Track the battery's remaining charge by counting energy used (not voltage), and flag when it is below the arming minimum, low, or critical (PRE-1; XC-7: 25% [TBR]; XC-8: 10% [TBR]). */
        out attribute batteryOk       : Boolean;    // PRE-1: enough to arm
        out attribute lowBattery      : Boolean;    // XC-7: return to launch
        out attribute criticalBattery : Boolean;    // XC-8: land now
    }

    action def BroadcastRemoteID {
        doc /* Broadcast the drone's identity, position, altitude, velocity, takeoff location, time and emergency status for the whole flight (CON-3; 14 CFR 89.315 broadcast-module elements). */
        in item position  : DronePosition;          // position, altitude; GPS time
        in item velocity  : DroneVelocity;          // required broadcast element
        in item home      : Waypoint;               // takeoff location, from RecordLaunchPoint
        in attribute emergency : Boolean;           // failsafe active: from the state machine (failsafeReturn, emergencyLanding)
        out item broadcast : RemoteIDBroadcast;     // context item: to public observers
    }

    action def RecordLaunchPoint {
        doc /* When the motors are enabled, store where the drone is as the home point for returns, the geofence and Remote ID (END-1, XC-5). */
        in item position : DronePosition;
        in attribute motorsEnabled : Boolean;       // from ControlArming: record on arming
        out item home    : Waypoint;
    }
}