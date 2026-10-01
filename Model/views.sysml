package FollowMeDroneViews {
    private import StandardViewDefinitions::*;
    private import FollowMeDrone::*;

    // System context: air vehicle and ground segment with the RF links between them
    view systemContext : InterconnectionView {
        expose Physical::FollowMeDroneSystem::**;
    }

    // Physical: subsystems, parts, ports, and wiring of the air vehicle (like a v1 IBD)
    view airVehicleInterconnection : InterconnectionView {
        expose Physical::AirVehicle::**;
    }

    // Physical breakdown: all hardware definitions (like a v1 BDD)
        view hardwareBreakdown : GeneralView {
        expose Architecture::droneSystem;
        filter @SysML::PartUsage or @SysML::PartDefinition
            or @SysML::PortUsage or @SysML::PortDefinition;
    }

    // Requirements index: collapsible tree of packages and requirements
    view requirementsIndex : BrowserView {
        expose Requirements;
    }


    // Logical: the follow chain, capture -> detect -> track -> estimate -> control
        view followChainFlow : ActionFlowView {
        expose Architecture::followTarget::*;
        filter @SysML::ActionUsage;
    }

    // Behavior: idle / searching / tracking / lost / hover
    view followModeStates : StateTransitionView {
        expose Behavior::FollowModeController;
    }
    
}
