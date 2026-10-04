// Follow-Me Drone — SysML v2 model (draft 0.3)
// Owner: Derek Bennett.
// 0.3: air vehicle grouped into subsystems (avionics, autonomy, power, propulsion);
//      added power distribution, motor chain, GPS, Remote ID, and RF links to the ground.
//
// Layout: Requirements -> Interfaces -> Logical -> Behavior -> Physical -> Allocation -> Traceability
// Values marked TBR are first-pass. PER-3 and SAF-2 confirmed 2026-10-01.
// SAF-8 (open-area operation; no obstacle avoidance in v1) added 2026-10-03.

package FollowMeDrone {
    private import ScalarValues::*;
    private import ISQ::*;
    private import SI::*;

    // =====================================================================
    // 1. REQUIREMENTS
    // =====================================================================
    package Requirements {

        package Needs {
            requirement <'N-1'> followByCamera {
                doc /* The drone follows a person using its own camera, without the person
                       carrying a device or transmitting their position. */
            }
            requirement <'N-2'> operatorOverride {
                doc /* The operator can take back control or abort at any time. */
            }
            requirement <'N-3'> safeAndLegal {
                doc /* The system flies safely and within FAA recreational rules. */
            }
            requirement <'N-4'> openAffordable {
                doc /* The system uses affordable, open components (ArduPilot, MAVLink,
                       commodity compute) so it can be studied, modified, and shown. */
            }
        }

        package Perception {
            requirement <'PER-1'> detectionRange {
                doc /* Detect persons in camera imagery at ranges from 3 m to 20 m. [TBR] */
            }
            requirement <'PER-2'> identityPersistence {
                doc /* Maintain the designated target's identity through viewpoint changes
                       (front, side, rear) and occlusions of up to 1.0 s. [TBR] */
            }
            requirement <'PER-3'> operatorDesignationOnly {
                doc /* Acquire a target only by operator designation; do not transfer to a
                       different person during flight without operator action. */
            }
            requirement <'PER-4'> frameRate {
                doc /* Process frames for detection and tracking at >= 10 Hz on the companion. */
            }
        }

        package Estimation {
            requirement <'EST-1'> bearingAccuracy {
                doc /* Estimate horizontal bearing to target within ±3° over the detection range. [TBR] */
            }
            requirement <'EST-2'> rangeAccuracy {
                doc /* Estimate range to target within ±20% over the detection range. [TBR] */
            }
            requirement <'EST-3'> velocityAccuracy {
                doc /* Estimate target horizontal velocity within ±0.5 m/s for feedforward. [TBR] */
            }
            requirement <'EST-4'> attitudeCompensation {
                doc /* Compensate target estimates for vehicle attitude and heading using
                       flight controller telemetry. */
            }
        }

        package Control {
            requirement <'CTL-1'> keepCentered {
                doc /* Keep target within ±10° of camera centerline while target walks at up to 2 m/s. [TBR] */
            }
            requirement <'CTL-2'> holdStandoff {
                doc /* Hold operator-set standoff (default 8 m, settable 5–20 m) within ±2 m. [TBR] */
            }
            requirement <'CTL-3'> commandLimits {
                doc /* Command horizontal velocity and yaw rate only, at >= 10 Hz,
                       limited to 5 m/s and 60°/s. [TBR] */
            }
            requirement <'CTL-4'> noAltitudeCommands {
                doc /* Follow function shall not command altitude changes; vehicle holds operator-set altitude. */
            }
        }

        package Safety {
            requirement <'SAF-1'> guidedOnly {
                doc /* Companion sends motion commands only in Guided mode; operator mode change
                       out of Guided returns full control immediately. */
            }
            requirement <'SAF-2'> noArmTakeoffLandModeChange {
                doc /* Companion shall not arm, take off, land, or change flight mode. */
            }
            requirement <'SAF-3'> lostTargetHover {
                doc /* If target lost > 2 s, command zero velocity (hover) and alert operator via GCS. [TBR] */
            }
            requirement <'SAF-4'> keepOutZone {
                doc /* Never command motion within 5 m horizontally of the target; never fly directly over people. */
            }
            requirement <'SAF-5'> commandTimeout {
                doc /* If motion commands stop for > 3 s, vehicle stops and holds position. [TBR] */
            }
            requirement <'SAF-6'> failsafesAndGeofence {
                doc /* RTL on RC loss, low battery, or geofence breach. Geofence 150 m radius,
                       30 m AGL. All failsafes verified before first flight. [TBR] */
            }
            requirement <'SAF-7'> emergencyStop {
                doc /* RC transmitter provides a motor emergency stop switch. */
            }
            requirement <'SAF-8'> openAreaOperation {
                doc /* Operate only in open areas with no obstacles within 15 m horizontally of the
                       operator's planned route. No obstacle avoidance in version 1; the operator
                       selects the site and keeps the vehicle in sight. [TBR] */
            }
        }

        package InterfacesPerfReg {
            requirement <'INT-1'> mavlinkSerial {
                doc /* Companion communicates with FC using MAVLink 2 over serial (TELEM2). */
            }
            requirement <'INT-2'> independentRC {
                doc /* Operator RC link is independent of the companion and the GCS. */
            }
            requirement <'INT-3'> gcsDisplay {
                doc /* GCS displays flight mode, battery, position, tracking status
                       (searching, tracking, lost), bearing, and range over 915 MHz telemetry. */
            }
            requirement <'PRF-1'> latency {
                doc /* Frame capture to motion command latency <= 200 ms. [TBR] */
            }
            requirement <'PRF-2'> endurance {
                doc /* Fly at least 10 min with full payload. [TBR] */
            }
            requirement <'PRF-3'> environment {
                doc /* Operate in daylight, dry conditions, wind up to 5 m/s. [TBR] */
            }
            requirement <'REG-1'> faaRecreational {
                doc /* Registered, Remote ID compliant, TRUST certificate, VLOS, <= 400 ft AGL. */
            }
        }
    }

    // =====================================================================
    // 2. INTERFACES — items that flow, ports, and interface definitions
    // =====================================================================
    package Interfaces {

        // --- Data items ---
        item def ImageFrame { attribute timestamp : Real; }
        item def PersonDetections {
            doc /* Bounding boxes + confidence for all persons in a frame. */
        }
        item def TargetTrack {
            doc /* The designated target's box, track ID, and age; empty if not seen. */
            attribute trackId : Integer;
            attribute visible : Boolean;
        }
        item def TargetEstimate {
            attribute bearing : Real;     // deg, relative to vehicle heading
            attribute range : Real;       // m
            attribute velocityN : Real;   // m/s
            attribute velocityE : Real;   // m/s
        }
        item def VehicleState {
            doc /* Attitude, heading, position, flight mode from FC telemetry (ATTITUDE, GLOBAL_POSITION_INT, HEARTBEAT). */
        }
        item def VelocityYawCommand {
            doc /* SET_POSITION_TARGET_LOCAL_NED with velocity + yaw-rate fields only (CTL-3, CTL-4). */
            attribute vx : Real;
            attribute vy : Real;
            attribute yawRate : Real;
        }
        item def TrackingStatus {
            doc /* searching / tracking / lost, plus bearing and range, for the GCS (INT-3). */
        }
        item def OperatorDesignation {
            doc /* Operator's choice of target person, sent from the GCS (PER-3). */
        }
        item def StickCommands;
        item def MotorCommand;
        item def GNSSData;
        item def HeadingData;

        // --- Energy and mechanical items ---
        item def ElectricalPower;
        item def BatteryStatus { doc /* Voltage and current sensed by the power module. */ }
        item def ThreePhaseCurrent;
        item def ShaftTorque;

        // --- Data ports (original = sending side; ~ = receiving side) ---
        port def MAVLinkPort {
            doc /* MAVLink 2 over UART. Flight-controller side is the original; companion side conjugated. */
            out item telemetry : VehicleState;
            out item designation : OperatorDesignation;
            in item command : VelocityYawCommand;
            in item status : TrackingStatus;
        }
        port def CSICameraPort { out item image : ImageFrame; }
        port def RCPort { out item sticks : StickCommands; }
        port def TelemetryRFPort {
            doc /* FC serial port to the air telemetry radio. */
            out item telemetry : VehicleState;
            out item status : TrackingStatus;
            in item designation : OperatorDesignation;
        }
        port def GPSCompassPort {
            doc /* Combined GPS connector: UART for GNSS, I2C for the compass. */
            out item fix : GNSSData;
            out item heading : HeadingData;
        }
        port def RemoteIDPort {
            doc /* FC to Remote ID module, serial or DroneCAN [TBD]. Module powered from this connector. */
            out item position : VehicleState;
        }
        port def MotorPort { in item cmd : MotorCommand; }

        // --- RF ports (air <-> ground) ---
        port def RFControlLinkPort {
            doc /* ELRS control link, transmitter side is the original (INT-2). */
            out item sticks : StickCommands;
        }
        port def RFTelemetryLinkPort {
            doc /* 915 MHz telemetry link, air radio side is the original. */
            out item telemetry : VehicleState;
            out item status : TrackingStatus;
            in item designation : OperatorDesignation;
        }

        // --- Power and mechanical ports (original = receiving side; ~ = supplying side) ---
        port def PowerPort { in item power : ElectricalPower; }
        port def FCPowerPort {
            doc /* Pixhawk POWER connector: regulated 5 V plus battery voltage/current sensing. */
            in item power : ElectricalPower;
            in item sense : BatteryStatus;
        }
        port def MotorPhasePort { in item current : ThreePhaseCurrent; }
        port def ShaftPort { out item torque : ShaftTorque; }

        // --- Interface definitions ---
        interface def MAVLinkSerialLink {
            doc /* INT-1: TELEM2 serial link, Pixhawk 6C <-> Jetson. */
            end fcEnd : MAVLinkPort;
            end companionEnd : ~MAVLinkPort;
        }
        interface def CSILink {
            doc /* 22-pin CSI ribbon, Arducam IMX219 -> Jetson Orin Nano. */
            end cameraEnd : CSICameraPort;
            end computerEnd : ~CSICameraPort;
        }
    }

    // =====================================================================
    // 3. LOGICAL ARCHITECTURE — what the system does, no hardware named
    // =====================================================================
    package Logical {
        private import Interfaces::*;

        // Follow-chain functions (non-flight-critical by design)
        action def CaptureImagery     { out image : ImageFrame; }
        action def DetectPersons      { in image : ImageFrame; out detections : PersonDetections; }
        action def TrackDesignatedTarget {
            doc /* Keeps the operator-designated track ID; never re-assigns on its own (PER-3). */
            in detections : PersonDetections;
            out track : TargetTrack;
        }
        action def EstimateTarget {
            doc /* Bearing from box center, range from box height, filtered (moving avg -> Kalman). */
            in track : TargetTrack;
            in vehicle : VehicleState;
            out estimate : TargetEstimate;
        }
        action def ComputeFollowCommand {
            doc /* Yaw to center target; velocity to hold standoff; enforce 5 m keep-out and limits. */
            in estimate : TargetEstimate;
            out command : VelocityYawCommand;
        }
        action def ReportStatus {
            in estimate : TargetEstimate;
            out status : TrackingStatus;
        }

        // Flight-critical functions (owned by the autopilot; shown for completeness)
        action def EstimateVehicleState { out vehicle : VehicleState; }
        action def ExecuteGuidedCommand { in command : VelocityYawCommand; out motors : MotorCommand; }
        action def ApplyFailsafes {
            doc /* RC loss, low battery, geofence, command timeout (SAF-5, SAF-6). */
        }

        // The follow chain, wired as a data flow
        action def FollowTarget {
            action capture  : CaptureImagery;
            action detect   : DetectPersons;
            action track    : TrackDesignatedTarget;
            action estimate : EstimateTarget;
            action control  : ComputeFollowCommand;
            action report   : ReportStatus;
            action vehicleState : EstimateVehicleState;
            action execute  : ExecuteGuidedCommand;

            flow capture.image        to detect.image;
            flow detect.detections    to track.detections;
            flow track.track          to estimate.track;
            flow vehicleState.vehicle to estimate.vehicle;
            flow estimate.estimate    to control.estimate;
            flow estimate.estimate    to report.estimate;
            flow control.command      to execute.command;
        }
    }

    // =====================================================================
    // 4. BEHAVIOR — follow-mode state machine (runs on the companion)
    // =====================================================================
    package Behavior {
        private import Logical::*;

        // Events
        attribute def GuidedEntered;      // operator switched to Guided
        attribute def GuidedExited;       // operator switched out of Guided (SAF-1)
        attribute def TargetDesignated;   // operator picked a person (PER-3)
        attribute def TargetNotSeen;      // designated track ID missing this frame
        attribute def TargetReacquired;   // SAME track ID seen again (PER-2, PER-3)

        state def FollowModeController {
            doc /* The companion never arms, takes off, lands, or changes mode (SAF-2).
                   It only sends velocity/yaw commands while in Guided (SAF-1). */

            entry; then idle;

            state idle {
                doc /* Not in Guided. Companion sends no motion commands. */
            }
            state searching {
                doc /* In Guided, no target yet. Hover; show candidates on GCS; wait for designation. */
                entry action holdStill;   // zero velocity
            }
            state tracking {
                doc /* Following the designated target. */
                do action follow : FollowTarget;
            }
            state lost {
                doc /* Target not seen. Coast on last estimate, no new person accepted. */
            }
            state hover {
                doc /* Target lost > 2 s: zero velocity and alert operator (SAF-3).
                       Only operator re-designation resumes following (PER-3). */
                entry action holdAndAlert;
            }

            transition first idle accept GuidedEntered then searching;
            transition first searching accept TargetDesignated then tracking;
            transition first tracking accept TargetNotSeen then lost;
            transition first lost accept TargetReacquired then tracking;
            transition first lost accept after 2 [s] then hover;               // SAF-3 [TBR]
            transition first hover accept TargetDesignated then tracking;

            // SAF-1: leaving Guided from any active state hands control back immediately
            transition first searching accept GuidedExited then idle;
            transition first tracking  accept GuidedExited then idle;
            transition first lost      accept GuidedExited then idle;
            transition first hover     accept GuidedExited then idle;
        }

        action holdStill;
        action holdAndAlert;
    }

    // =====================================================================
    // 5. PHYSICAL ARCHITECTURE — what hardware does it
    // =====================================================================
    package Physical {
        private import Interfaces::*;

        // --- Avionics components ---
        part def Pixhawk6C {
            doc /* Flight controller running ArduPilot. Owns all flight-critical functions. */
            port telem1 : TelemetryRFPort;      // to 915 MHz radio
            port telem2 : MAVLinkPort;          // to Jetson (INT-1)
            port gps1 : ~GPSCompassPort;        // GPS + compass connector
            port remoteIdOut : RemoteIDPort;    // to Remote ID module
            port rcIn : ~RCPort;
            port motorOut : ~MotorPort[4];
            port power : FCPowerPort;           // from power module
        }
        part def GPSCompass {
            doc /* u-blox M9/M10 class GPS with compass, mast-mounted. Powered from FC connector. */
            port conn : GPSCompassPort;
        }
        part def ELRSReceiver {
            doc /* Powered from FC connector. */
            port rcOut : RCPort;
            port rf : ~RFControlLinkPort;
        }
        part def TelemetryRadio915 {
            doc /* Air side of a SiK 915 MHz pair. Powered from FC connector. */
            port fcSide : ~TelemetryRFPort;
            port rf : RFTelemetryLinkPort;
        }
        part def RemoteIDModule {
            doc /* Standalone broadcast module (REG-1). */
            port fcIn : ~RemoteIDPort;
        }

        // --- Autonomy payload components ---
        part def JetsonOrinNanoSuper {
            doc /* Companion computer, 8 GB, NVMe SSD. Runs perception, estimation, follow control. */
            port csi : ~CSICameraPort;
            port mavlink : ~MAVLinkPort;
            port power : PowerPort;
        }
        part def ArducamIMX219 {
            doc /* CSI camera, 80–120° FOV, 22-pin cable. */
            port csi : CSICameraPort;
        }
        part def CompanionRegulator {
            doc /* DC-DC converter from battery voltage to the Jetson's input voltage. Rating TBD. */
            port vin : PowerPort;
            port vout : ~PowerPort;
        }

        // --- Power components ---
        part def LiPoBattery {
            doc /* 3S or 4S LiPo; size TBD after weight is known. */
            port out : ~PowerPort;
        }
        part def PowerModule {
            doc /* Battery in; ESC bus out; 5 V + V/I sensing to FC; aux tap for the companion. */
            port batteryIn : PowerPort;
            port escOut : ~PowerPort;
            port fcOut : ~FCPowerPort;
            port auxOut : ~PowerPort;
        }

        // --- Propulsion components ---
        part def ESC {
            port cmdIn : MotorPort;
            port power : PowerPort;
            port phaseOut : ~MotorPhasePort;
        }
        part def BrushlessMotor {
            port phaseIn : MotorPhasePort;
            port shaft : ShaftPort;
        }
        part def Propeller {
            port hub : ~ShaftPort;
        }

        part def Airframe {
            doc /* 450 mm class quad frame; structure only. */
        }

        // --- Ground segment ---
        part def RCTransmitter {
            doc /* EdgeTX/ELRS. Mode switch, arm/disarm, motor emergency stop (SAF-7). Independent link (INT-2). */
            port rf : RFControlLinkPort;
        }
        part def GroundControlStation {
            doc /* QGroundControl / Mission Planner on a laptop + 915 MHz ground radio. */
            port rf : ~RFTelemetryLinkPort;
        }

        // =================================================================
        // Subsystems — each groups related parts and wires them internally
        // =================================================================
        part def Avionics {
            doc /* Flight controller and everything that plugs directly into it. */
            part fc : Pixhawk6C;
            part gps : GPSCompass;
            part rcRx : ELRSReceiver;
            part telemRadio : TelemetryRadio915;
            part remoteId : RemoteIDModule;

            connect gps.conn to fc.gps1;
            connect rcRx.rcOut to fc.rcIn;
            connect fc.telem1 to telemRadio.fcSide;
            connect fc.remoteIdOut to remoteId.fcIn;
        }

        part def AutonomyPayload {
            doc /* Companion computer, camera, and its power regulator. Non-flight-critical by design. */
            part companion : JetsonOrinNanoSuper;
            part camera : ArducamIMX219;
            part regulator : CompanionRegulator;

            interface : CSILink connect
                cameraEnd ::> camera.csi to computerEnd ::> companion.csi;
            connect regulator.vout to companion.power;
        }

        part def PowerSystem {
            part battery : LiPoBattery;
            part powerModule : PowerModule;

            connect battery.out to powerModule.batteryIn;
        }

        part def PropulsionUnit {
            doc /* One arm: ESC -> motor -> propeller. The vehicle has four. */
            part esc : ESC;
            part motor : BrushlessMotor;
            part prop : Propeller;

            connect esc.phaseOut to motor.phaseIn;
            connect motor.shaft to prop.hub;
        }

        // =================================================================
        // Air vehicle — subsystems plus the connections between them
        // =================================================================
        part def AirVehicle {
            part airframe : Airframe;
            part avionics : Avionics;
            part autonomy : AutonomyPayload;
            part powerSystem : PowerSystem;
            part propulsion : PropulsionUnit[4];

            // Data: FC <-> companion (INT-1)
            interface : MAVLinkSerialLink connect
                fcEnd ::> avionics.fc.telem2 to companionEnd ::> autonomy.companion.mavlink;

            // Motor commands: FC -> each ESC
            connect avionics.fc.motorOut to propulsion.esc.cmdIn;

            // Power distribution
            connect powerSystem.powerModule.fcOut  to avionics.fc.power;
            connect powerSystem.powerModule.escOut to propulsion.esc.power;
            connect powerSystem.powerModule.auxOut to autonomy.regulator.vin;
        }

        part def GroundSegment {
            part rcTx : RCTransmitter;
            part gcs : GroundControlStation;
        }

        part def FollowMeDroneSystem {
            part air : AirVehicle;
            part ground : GroundSegment;

            // RF links (INT-2: control link independent of telemetry and companion)
            connect ground.rcTx.rf to air.avionics.rcRx.rf;
            connect air.avionics.telemRadio.rf to ground.gcs.rf;
        }
    }

    // =====================================================================
    // 6. SYSTEM INSTANCE AND ALLOCATION — logical -> physical
    // =====================================================================
    package Architecture {
        private import Logical::*;
        private import Physical::*;
        private import Behavior::*;

        part droneSystem : FollowMeDroneSystem;
        action followTarget : FollowTarget;
        state followMode : FollowModeController;

        // Non-flight-critical functions -> autonomy payload
        allocate followTarget.capture  to droneSystem.air.autonomy.camera;
        allocate followTarget.detect   to droneSystem.air.autonomy.companion;
        allocate followTarget.track    to droneSystem.air.autonomy.companion;
        allocate followTarget.estimate to droneSystem.air.autonomy.companion;
        allocate followTarget.control  to droneSystem.air.autonomy.companion;
        allocate followTarget.report   to droneSystem.air.autonomy.companion;
        allocate followMode            to droneSystem.air.autonomy.companion;

        // Flight-critical functions -> flight controller (ArduPilot)
        allocate followTarget.vehicleState to droneSystem.air.avionics.fc;
        allocate followTarget.execute      to droneSystem.air.avionics.fc;
    }

    // =====================================================================
    // 7. TRACEABILITY — which element satisfies which requirement
    // =====================================================================
    package Traceability {
        private import Architecture::*;
        private import Requirements::*;

        satisfy Perception::'PER-1'   by droneSystem.air.autonomy.companion;
        satisfy Perception::'PER-2'   by droneSystem.air.autonomy.companion;
        satisfy Perception::'PER-3'   by followMode;
        satisfy Perception::'PER-4'   by droneSystem.air.autonomy.companion;
        satisfy Estimation::'EST-1'   by droneSystem.air.autonomy.companion;
        satisfy Estimation::'EST-2'   by droneSystem.air.autonomy.companion;
        satisfy Estimation::'EST-3'   by droneSystem.air.autonomy.companion;
        satisfy Estimation::'EST-4'   by droneSystem.air.autonomy.companion;
        satisfy Control::'CTL-1'      by droneSystem.air.autonomy.companion;
        satisfy Control::'CTL-2'      by droneSystem.air.autonomy.companion;
        satisfy Control::'CTL-3'      by droneSystem.air.autonomy.companion;
        satisfy Control::'CTL-4'      by droneSystem.air.autonomy.companion;
        satisfy Safety::'SAF-1'       by followMode;
        satisfy Safety::'SAF-2'       by followMode;
        satisfy Safety::'SAF-3'       by followMode;
        satisfy Safety::'SAF-4'       by droneSystem.air.autonomy.companion;
        satisfy Safety::'SAF-5'       by droneSystem.air.avionics.fc;
        satisfy Safety::'SAF-6'       by droneSystem.air.avionics.fc;
        satisfy Safety::'SAF-7'       by droneSystem.ground.rcTx;
        satisfy Safety::'SAF-8'       by droneSystem;
        satisfy InterfacesPerfReg::'INT-1' by droneSystem.air;
        satisfy InterfacesPerfReg::'INT-2' by droneSystem;
        satisfy InterfacesPerfReg::'INT-3' by droneSystem.ground.gcs;
        satisfy InterfacesPerfReg::'PRF-1' by droneSystem.air;
        satisfy InterfacesPerfReg::'PRF-2' by droneSystem.air;
        satisfy InterfacesPerfReg::'PRF-3' by droneSystem;
        satisfy InterfacesPerfReg::'REG-1' by droneSystem.air.avionics.remoteId;

        // Next: add verification cases (bench, SITL, flight) with `verify` links
        // as each roadmap step produces evidence.
    }
}
