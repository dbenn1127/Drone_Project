// Tandem — SysML v2 model

package Tandem {

part def TandemSystem {
    doc /* drone + ground station + RC */
}
part def OperatorPilot {
    doc /* runs the ground station, RC backup */
}
part def Target {
    doc /* the person being filmed */
}
part def Bystander {
    doc /* people nearby who are not part of the flight */
}
part def PublicObservers {
    doc /* anyone nearby who receives the Remote ID broadcast */
}
part def GPSSatellites {
    doc /* provide position signals */
}
part def Environment {
    doc /* wind, light, obstacles, temperature */
}

// --- what crosses the boundary ---

item def OperatorCommand {
doc /* 	launch, approve/reject target, offsets, stop/hover, land, RTL */
}
item def RCInput {
doc /* pilot sticks and mode switch; takeover */
}
item def GroundDisplay {
doc /* live video, proposed target, status */
}
item def PhysicalHazard {
doc /* proximity, downwash: unintended */
}
item def Noise {
doc /* motor and propeller noise, unintended */
}
item def RemoteIDBroadcast {
doc /* ID, position, velocity, takeoff location */
}
item def GNSSSignal {
doc /* satellite position signals */
}
item def EnvironmentalConditions {
doc /* wind, ambient light, obstacles, temperature */
}
item def PersonAppearance{
    doc /* light reflected from a person: shape and motion as seen by the camera. */
}

// --- system context: who exchanges what with Tandem ---

part def TandemContext {
    part tandem : TandemSystem;
    part operator : OperatorPilot;
    part target : Target;
    part bystander : Bystander;
    part observers : PublicObservers;
    part gps : GPSSatellites;
    part environment : Environment;

    flow of OperatorCommand from operator to tandem;
    flow of RCInput from operator to tandem;
    flow of GroundDisplay from tandem to operator;
    flow of PhysicalHazard from tandem to target;
    flow of PhysicalHazard from tandem to bystander;
    flow of Noise from tandem to target;
    flow of Noise from tandem to bystander;
    flow of RemoteIDBroadcast from tandem to observers;
    flow of GNSSSignal from gps to tandem;
    flow of EnvironmentalConditions from environment to tandem;
    flow of PersonAppearance from target to tandem;
    flow of PersonAppearance from bystander to tandem;
}





}