package TandemFunctions {
    private import Tandem::*;                 // context items (PersonAppearance, OperatorCommand, GroundDisplay…)
    private import ScalarValues::Boolean;

    // ===================== internal items =====================
    // Things that flow BETWEEN functions, inside Tandem.
    item def VideoFrame;          // one camera image
    item def PersonDetections;    // the people found in a frame (boxes)
    item def TargetTrack;         // the target's position and direction of travel
    item def DronePosition;       // where the drone is: position, height, heading
    item def MotionSetpoint;      // where/how fast the drone should go next
    item def FollowSettings;      // distance, angle, zone width, height (FLW-3; ranges in step 7)
    item def Waypoint;            // a point to fly to: position and height
    item def CameraPointing;      // where the camera is pointing: pan, tilt
    item def TargetProposal;      // the one person Tandem suggests as the target


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
        out item track : TargetTrack;
        out attribute targetLost       : Boolean;    // FLW-8
        out attribute targetOverlapped : Boolean;    // FLW-12
        out attribute targetStationary : Boolean;    // FLW-7
    }

    action def PointCamera {
        doc /* Keep the target centred in the camera view (FLW-5: within ±10° [TBR]), within the camera's pan/tilt limits; when the camera reaches a limit, signal that the drone must turn. */
        in item track     : TargetTrack;
        in item position  : DronePosition;      // the drone's heading: the camera aims relative to it
        out item pointing : CameraPointing;     // to the camera mount
        out attribute atPanLimit : Boolean;     // camera can't turn further, so the drone must rotate
    }

    // ===================== moving the drone =====================
    action def HoldPosition {
        doc /* Keep the drone at its current position and height. */
        in item position  : DronePosition;
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
            in item :>> track    = FollowTarget::track;
            in item :>> settings = FollowTarget::settings;
            in item :>> position = FollowTarget::position;
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
        doc /* Descend at no more than the landing rate until touchdown; works with ot without a position fix. */
        in attribute descentLimit : ISQ::SpeedValue;    // CON-1
        out item setpoint : MotionSetpoint;
        out attribute touchedDown : Boolean;
    }

    action def LimitMotion {
        doc /* Adjust a requested setpoint so the drone never enters the target's keep-out zone, never leaves the geofence, and never exceeds the speed limit. */
        in item requested : MotionSetpoint;     // from HoldPosition / FollowTarget / FlyToPosition…
        in item position  : DronePosition;      // to know where the fence is relative to the drone
        in item track     : TargetTrack;        // to know where the target (and its keep-out) is
        out item limited  : MotionSetpoint;     // to FlyTheDrone
        out attribute atGeofence : Boolean;     // XC-6: triggers the operator alert
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

    // ===================== talking to the operator =====================

    action def ShowPersons {
        doc /* Show every person in view to the operator as selectable, and remove anyone who leaves view (ACQ-3, ACQ-10: within 1 s [TBR]). */
        in item detections : PersonDetections;      // from DetectPersons
        out item display : GroundDisplay;           // context item: to the operator
    }

    action def ProposeTarget {
        doc /* Pick one displayed person to suggest as the target (ACQ-4: selection rule TBD, e.g. nearest; after an overlap te person most likely to be the previous target), never re-proposing someone rejected in this acquisition (ACQ-5).
        in item detections : PersonDetections;      // who is in view
        in item lastTrack : TargetTrack;            // the previous target, for the after overlap best guess
        out item proposal : TaretProposal;
    }

    action def ShowSettings {
        doc /* Show the operator the current follow settings (distance, angle, zone width, height), before arming and whenever they ask to change them (PRE-4, FLW-3). */
        in item settings : FollowSettings;
        out item display : GroundDisplay;           // context item: to the operator
    }

    // ===================== deciding and checking =====================

    
    // ===================== hidden (no use case step, but needed) =====================
    action def EstimatePosition {
        doc /* Work out where the drone is from GPS and its own sensors. */
        out item position : DronePosition;
        out attribute gpsLost : Boolean;             // XC-12
    }
}