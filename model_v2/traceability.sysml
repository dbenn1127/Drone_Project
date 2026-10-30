package TandemTraceability {
    private import TandemUseCases::*;
    private import TandemRequirements::PreFlight::*;
    private import TandemRequirements::Launch::*;
    private import TandemRequirements::Acquire::*;
    private import TandemRequirements::Follow::*;
    private import TandemRequirements::End::*;
    private import TandemRequirements::ManualControl::*;
    private import TandemRequirements::CrossCutting::*;
    private import TandemRequirements::Constraints::*;
    private import TandemRequirements::Performance::*;

    // ---- PreFlight ----
    // PRE-1 readyOnlyWhenPrechecksPass
    dependency from readyOnlyWhenPrechecksPass  to PrepareForFlight::connectToGroundStation;
    dependency from readyOnlyWhenPrechecksPass  to PrepareForFlight::runPrechecks;
    dependency from readyOnlyWhenPrechecksPass  to PrepareForFlight::noConnection;
    dependency from readyOnlyWhenPrechecksPass  to PrepareForFlight::notReady;
    // PRE-2 noArmOnFailedPrechecks
    dependency from noArmOnFailedPrechecks      to PrepareForFlight::prechecksFail;
    dependency from noArmOnFailedPrechecks      to PrepareForFlight::arm;
    // PRE-3 showPrecheckFailures
    dependency from showPrecheckFailures        to PrepareForFlight::prechecksFail;
    dependency from showPrecheckFailures        to PrepareForFlight::notReady;
    // PRE-4 confirmSettingsBeforeArming
    dependency from confirmSettingsBeforeArming to PrepareForFlight::showSettings;
    dependency from confirmSettingsBeforeArming to PrepareForFlight::confirmSettings;
    dependency from confirmSettingsBeforeArming to PrepareForFlight::arm;

    // ---- Launch ----
    // LCH-1 takeOffWhenArmed
    dependency from takeOffWhenArmed            to LaunchDrone::triggerLaunch;
    dependency from takeOffWhenArmed            to LaunchDrone::climb;
    // LCH-2 reachLaunchAltitude
    dependency from reachLaunchAltitude         to LaunchDrone::climb;
    dependency from reachLaunchAltitude         to LaunchDrone::hoverAtAltitude;
    // LCH-3 alertAltitudeNotReached
    dependency from alertAltitudeNotReached     to LaunchDrone::altitudeNotReached;

    // ---- Acquire ----
    // ACQ-1 noFollowWithoutApproval
    dependency from noFollowWithoutApproval     to AcquireTarget::operatorApproves;
    dependency from noFollowWithoutApproval     to AcquireTarget::noResponse;
    // ACQ-2 fullCircleSearch
    dependency from fullCircleSearch            to AcquireTarget::scanForPersons;
    // ACQ-3 detectedPersonDisplay
    dependency from detectedPersonDisplay       to AcquireTarget::showPersons;
    // ACQ-4 proposeOnePerson
    dependency from proposeOnePerson            to AcquireTarget::proposePerson;
    // ACQ-5 noReproposeRejected
    dependency from noReproposeRejected         to AcquireTarget::reject;
    // ACQ-6 proposeNextAfterReject
    dependency from proposeNextAfterReject      to AcquireTarget::reject;
    // ACQ-7 approvedPersonBecomesTarget
    dependency from approvedPersonBecomesTarget to AcquireTarget::targetSet;
    dependency from approvedPersonBecomesTarget to AcquireTarget::otherPick;
    // ACQ-8 confirmNewTarget
    dependency from confirmNewTarget            to AcquireTarget::targetSet;
    // ACQ-9 alertNoPersonsFound
    dependency from alertNoPersonsFound         to AcquireTarget::noneFound;
    // ACQ-10 removeDepartedPerson
    dependency from removeDepartedPerson        to AcquireTarget::personLeaves;
    // ACQ-11 refuseOutOfViewApproval
    dependency from refuseOutOfViewApproval     to AcquireTarget::approvedPersonLeaves;
    // ACQ-12 explainRefusedApproval
    dependency from explainRefusedApproval      to AcquireTarget::approvedPersonLeaves;
    // ACQ-13 holdPositionWhileAcquiring
    dependency from holdPositionWhileAcquiring  to AcquireTarget::holdPosition;

    // ---- Follow ----
    // FLW-1 stayInFramingZone
    dependency from stayInFramingZone           to FilmTarget::stayInZone;
    dependency from stayInFramingZone           to AdjustFraming::settle;
    // FLW-2 holdInsideZone
    dependency from holdInsideZone              to FilmTarget::stayInZone;
    // FLW-3 configurableFollowSettings
    dependency from configurableFollowSettings  to AdjustFraming::enterValues;
    dependency from configurableFollowSettings  to AdjustFraming::showCurrentSettings;
    // FLW-4 limitCameraToTargetDistance
    dependency from limitCameraToTargetDistance to AdjustFraming::rejectOutOfRange;
    // FLW-5 keepTargetCentered
    dependency from keepTargetCentered          to FilmTarget::keepCentered;
    dependency from keepTargetCentered          to PauseFollowing::keepCentered;
    dependency from keepTargetCentered          to AdjustFraming::keepCentered;
    // FLW-6 noUnplannedFollowStop
    dependency from noUnplannedFollowStop       to FilmTarget::repeatUntilStopped;   // Valid per SysML v2.1 (named loop = owned ActionUsage); Spec42 currently can't resolve (tool limitation).
    // FLW-7 freezeZoneWhenStationary
    dependency from freezeZoneWhenStationary    to FilmTarget::holdWhileStationary;
    // FLW-8 lostAfterNotSeen
    dependency from lostAfterNotSeen            to FilmTarget::reportTargetLost;
    dependency from lostAfterNotSeen            to PauseFollowing::endPauseOnTargetLost;
    dependency from lostAfterNotSeen            to AdjustFraming::stopMoveOnTargetLost;
    // FLW-9 returnToAcquisitionWhenLost
    dependency from returnToAcquisitionWhenLost to FilmTarget::reportTargetLost;
    dependency from returnToAcquisitionWhenLost to PauseFollowing::endPauseOnTargetLost;
    dependency from returnToAcquisitionWhenLost to AdjustFraming::stopMoveOnTargetLost;
    dependency from returnToAcquisitionWhenLost to KeepPersonInView::returnToAcquisition;
    // FLW-10 alertOperatorWhenLost
    dependency from alertOperatorWhenLost       to FilmTarget::reportTargetLost;
    // FLW-11 alertFallingBehind
    dependency from alertFallingBehind          to FilmTarget::reportFallingBehind;
    // FLW-12 reacquireOnOverlap
    dependency from reacquireOnOverlap          to FilmTarget::reportOverlap;
    dependency from reacquireOnOverlap          to PauseFollowing::endPauseOnOverlap;
    dependency from reacquireOnOverlap          to KeepPersonInView::returnToAcquisition;
    dependency from reacquireOnOverlap          to AdjustFraming::stopMoveOnOverlap;
    // FLW-13 rejectOutOfRangeSettings
    dependency from rejectOutOfRangeSettings    to AdjustFraming::rejectOutOfRange;
    dependency from rejectOutOfRangeSettings    to PrepareForFlight::invalidSetting;
    // FLW-14 showAllowedRange
    dependency from showAllowedRange            to AdjustFraming::rejectOutOfRange;
    dependency from showAllowedRange            to PrepareForFlight::invalidSetting;
    // FLW-17 gradualRepositioning
    dependency from gradualRepositioning        to AdjustFraming::moveGradually;
    dependency from gradualRepositioning        to PauseFollowing::returnToZone;
    // FLW-18 newestSettingsWins
    dependency from newestSettingsWins          to AdjustFraming::switchToNewest;
    // FLW-19 holdOnPause
    dependency from holdOnPause                 to PauseFollowing::selectPause;
    dependency from holdOnPause                 to PauseFollowing::holdPosition;
    // FLW-20 resumeSameTarget
    dependency from resumeSameTarget            to PauseFollowing::selectResume;
    dependency from resumeSameTarget            to PauseFollowing::returnToZone;

    // ---- End ----
    // END-1 returnToLaunchPoint
    dependency from returnToLaunchPoint         to EndFlight::selectEndFlight;
    dependency from returnToLaunchPoint         to EndFlight::returnToLaunch;
    // END-2 landInPlace
    dependency from landInPlace                 to EndFlight::selectEndFlight;
    dependency from landInPlace                 to EndFlight::stopInPlace;
    // END-3 releaseTargetOnEnd
    dependency from releaseTargetOnEnd          to EndFlight::releaseTarget;
    // END-4 disarmAfterLanding
    dependency from disarmAfterLanding          to EndFlight::disarm;
    // END-5 showLandingSpot
    dependency from showLandingSpot             to EndFlight::showLandingSpot;
    // END-6 holdIfPersonBelow
    dependency from holdIfPersonBelow           to EndFlight::stopDescent;
    // END-7 alertPersonBelow
    dependency from alertPersonBelow            to EndFlight::alertPersonBelow;

    // ---- ManualControl ----
    // MAN-1 manualOverrideStopsAutonomy
    dependency from manualOverrideStopsAutonomy to TakeManualControl::selectManual;
    dependency from manualOverrideStopsAutonomy to TakeManualControl::stopAutonomy;
    dependency from manualOverrideStopsAutonomy to KeepPersonInView::handOverToPilot;
    dependency from manualOverrideStopsAutonomy to PauseFollowing::handOverToPilot;
    dependency from manualOverrideStopsAutonomy to LaunchDrone::handOverToPilot;
    dependency from manualOverrideStopsAutonomy to AcquireTarget::handOverToPilot;
    dependency from manualOverrideStopsAutonomy to FilmTarget::handOverToPilot;
    dependency from manualOverrideStopsAutonomy to AdjustFraming::handOverToPilot;
    dependency from manualOverrideStopsAutonomy to EndFlight::handOverToPilot;
    // MAN-2 holdUntilStickInput
    dependency from holdUntilStickInput         to TakeManualControl::holdPosition;
    // MAN-3 manualControlOnly
    dependency from manualControlOnly           to TakeManualControl::followStickInput;
    // MAN-4 reacquireAfterHandBack
    dependency from reacquireAfterHandBack      to TakeManualControl::resumeAcquisition;

    // ---- CrossCutting ----
    // XC-1 confirmOperatorCommands
    dependency from confirmOperatorCommands     to AdjustFraming::confirmReceived;
    dependency from confirmOperatorCommands     to PauseFollowing::confirmPaused;
    dependency from confirmOperatorCommands     to PauseFollowing::confirmResumed;
    dependency from confirmOperatorCommands     to EndFlight::confirmEnd;
    dependency from confirmOperatorCommands     to TakeManualControl::confirmManual;
    dependency from confirmOperatorCommands     to TakeManualControl::confirmHandBack;
    // XC-2 alertCommandNotApplied
    dependency from alertCommandNotApplied      to AdjustFraming::reportNotReceived;
    dependency from alertCommandNotApplied      to PauseFollowing::reportPauseNotConfirmed;
    dependency from alertCommandNotApplied      to PauseFollowing::reportResumeNotConfirmed;
    dependency from alertCommandNotApplied      to EndFlight::reportNotConfirmed;
    // XC-3 respectKeepOutZone
    dependency from respectKeepOutZone          to FilmTarget::holdForKeepOut;
    dependency from respectKeepOutZone          to AdjustFraming::routeAroundKeepOut;
    dependency from respectKeepOutZone          to PauseFollowing::routeAroundKeepOut;
    // XC-4 holdWhileTargetInside
    dependency from holdWhileTargetInside       to FilmTarget::holdForKeepOut;
    // XC-5 stayInsideGeofence
    dependency from stayInsideGeofence          to KeepPersonInView::stopAtGeofence;
    // XC-6 alertAtGeofence
    dependency from alertAtGeofence             to KeepPersonInView::stopAtGeofence;
    // XC-7 lowBatteryReturn
    dependency from lowBatteryReturn            to KeepPersonInView::returnOnLowBattery;
    // XC-8 criticalBatteryLand
    dependency from criticalBatteryLand         to KeepPersonInView::landOnCriticalBattery;
    // XC-9 groundLinkLossHold
    dependency from groundLinkLossHold          to KeepPersonInView::holdOnGroundLinkLoss;
    // XC-10 groundLinkLossReturn
    dependency from groundLinkLossReturn        to KeepPersonInView::holdOnGroundLinkLoss;
    // XC-11 rcLinkLossReturn
    dependency from rcLinkLossReturn            to KeepPersonInView::returnOnRcLoss;
    dependency from rcLinkLossReturn            to TakeManualControl::returnOnRcLoss;
    // XC-12 gpsLossLand
    dependency from gpsLossLand                 to KeepPersonInView::landOnGpsLoss;
    dependency from gpsLossLand                 to EndFlight::abandonReturn;
    // XC-13 gpsLossAdviseTakeover
    dependency from gpsLossAdviseTakeover       to KeepPersonInView::landOnGpsLoss;
    dependency from gpsLossAdviseTakeover       to EndFlight::abandonReturn;
    // XC-14 alertOnFailsafe
    dependency from alertOnFailsafe             to KeepPersonInView::returnOnLowBattery;
    dependency from alertOnFailsafe             to KeepPersonInView::landOnCriticalBattery;
    dependency from alertOnFailsafe             to KeepPersonInView::holdOnGroundLinkLoss;
    dependency from alertOnFailsafe             to KeepPersonInView::returnOnRcLoss;
    dependency from alertOnFailsafe             to KeepPersonInView::landOnGpsLoss;
    // XC-15 holdAfterLinkRestored
    dependency from holdAfterLinkRestored       to KeepPersonInView::holdOnGroundLinkLoss;

    // ---- Constraints ----
    // CON-1 limitDescentRate
    dependency from limitDescentRate            to EndFlight::descend;
    // CON-2 limitHorizontalSpeed
    dependency from limitHorizontalSpeed        to FilmTarget::stayInZone;
    dependency from limitHorizontalSpeed        to EndFlight::returnToLaunch;
    // CON-3 broadcastRemoteID
    dependency from broadcastRemoteID           to KeepPersonInView;

    // ---- Performance ----
    // PRF-1 detectionRange
    dependency from detectionRange              to AdjustFraming::trackTarget;
    dependency from detectionRange              to PauseFollowing::trackTarget;
    dependency from detectionRange              to AcquireTarget::scanForPersons;
    dependency from detectionRange              to FilmTarget::trackTarget;
    // PRF-2 commandResponseTime
    dependency from commandResponseTime         to AdjustFraming::confirmReceived;
    dependency from commandResponseTime         to PauseFollowing::confirmPaused;
    dependency from commandResponseTime         to PauseFollowing::confirmResumed;
    dependency from commandResponseTime         to EndFlight::confirmEnd;
    // PRF-3 followEndurance
    dependency from followEndurance             to KeepPersonInView;
    // PRF-4 videoRange
    dependency from videoRange                  to KeepPersonInView;
    // PRF-5 videoLatency
    dependency from videoLatency                to KeepPersonInView;
    dependency from videoLatency                to EndFlight::showLandingSpot;
}