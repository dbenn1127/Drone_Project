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
    dependency from readyOnlyWhenPrechecksPass  to PrepareForFlight::connectToGroundStation;
    dependency from readyOnlyWhenPrechecksPass  to PrepareForFlight::runPrechecks;
    dependency from readyOnlyWhenPrechecksPass  to PrepareForFlight::noConnection;
    dependency from readyOnlyWhenPrechecksPass  to PrepareForFlight::notReady;
    dependency from noArmOnFailedPrechecks      to PrepareForFlight::prechecksFail;
    dependency from showPrecheckFailures        to PrepareForFlight::prechecksFail;
    dependency from showPrecheckFailures        to PrepareForFlight::notReady;
    dependency from confirmSettingsBeforeArming to PrepareForFlight::showSettings;
    dependency from confirmSettingsBeforeArming to PrepareForFlight::confirmSettings;
    dependency from noArmOnFailedPrechecks      to PrepareForFlight::arm;
    dependency from confirmSettingsBeforeArming to PrepareForFlight::arm;

    // ---- Launch ----
    dependency from takeOffWhenArmed            to LaunchDrone::triggerLaunch;
    dependency from reachLaunchAltitude         to LaunchDrone::climb;
    dependency from takeOffWhenArmed            to LaunchDrone::climb;
    dependency from reachLaunchAltitude         to LaunchDrone::hoverAtAltitude;
    dependency from alertAltitudeNotReached     to LaunchDrone::altitudeNotReached;

    // ---- Acquire ----
    dependency from noFollowWithoutApproval     to AcquireTarget::operatorApproves;
    dependency from noFollowWithoutApproval     to AcquireTarget::noResponse;
    dependency from fullCircleSearch            to AcquireTarget::scanForPersons;
    dependency from detectedPersonDisplay       to AcquireTarget::showPersons;
    dependency from proposeOnePerson            to AcquireTarget::proposePerson;
    dependency from noReproposeRejected         to AcquireTarget::reject;
    dependency from proposeNextAfterReject      to AcquireTarget::reject;
    dependency from approvedPersonBecomesTarget to AcquireTarget::targetSet;
    dependency from approvedPersonBecomesTarget to AcquireTarget::otherPick;
    dependency from confirmNewTarget            to AcquireTarget::targetSet;
    dependency from alertNoPersonsFound         to AcquireTarget::noneFound;
    dependency from removeDepartedPerson        to AcquireTarget::personLeaves;
    dependency from refuseOutOfViewApproval     to AcquireTarget::approvedPersonLeaves;
    dependency from explainRefusedApproval      to AcquireTarget::approvedPersonLeaves;
    dependency from holdPositionWhileAcquiring  to AcquireTarget::holdPosition;

    // ---- Follow ----
    dependency from stayInFramingZone           to FilmTarget::stayInZone;
    dependency from holdInsideZone              to FilmTarget::stayInZone;
    dependency from stayInFramingZone           to AdjustFraming::settle;
    dependency from configurableFollowSettings  to AdjustFraming::enterValues;
    dependency from limitCameraToTargetDistance to AdjustFraming::rejectOutOfRange;
    dependency from keepTargetCentered          to FilmTarget::keepCentered;
    dependency from keepTargetCentered          to PauseFollowing::keepCentered;
    dependency from noUnplannedFollowStop       to FilmTarget::repeatUntilStopped;   // Valid per SysML v2.1 (named loop = owned ActionUsage); Spec42 currently can't resolve (tool limitation).
    dependency from freezeZoneWhenStationary    to FilmTarget::holdWhileStationary;
    dependency from lostAfterNotSeen            to FilmTarget::reportTargetLost;
    dependency from returnToAcquisitionWhenLost to FilmTarget::reportTargetLost;
    dependency from lostAfterNotSeen            to PauseFollowing::endPauseOnTargetLost;
    dependency from returnToAcquisitionWhenLost to PauseFollowing::endPauseOnTargetLost;
    dependency from lostAfterNotSeen            to AdjustFraming::stopMoveOnTargetLost;
    dependency from returnToAcquisitionWhenLost to AdjustFraming::stopMoveOnTargetLost;
    dependency from returnToAcquisitionWhenLost to KeepPersonInView::targetLost;
    dependency from alertOperatorWhenLost       to FilmTarget::reportTargetLost;
    dependency from alertFallingBehind          to FilmTarget::reportFallingBehind;
    dependency from reacquireOnOverlap          to FilmTarget::reportOverlap;
    dependency from reacquireOnOverlap          to PauseFollowing::endPauseOnOverlap;
    dependency from reacquireOnOverlap          to KeepPersonInView::targetLost;
    dependency from rejectOutOfRangeSettings    to AdjustFraming::rejectOutOfRange;
    dependency from rejectOutOfRangeSettings    to PrepareForFlight::invalidSetting;
    dependency from showAllowedRange            to AdjustFraming::rejectOutOfRange;
    dependency from showAllowedRange            to PrepareForFlight::invalidSetting;
    dependency from gradualRepositioning        to AdjustFraming::moveGradually;
    dependency from gradualRepositioning        to PauseFollowing::returnToZone;
    dependency from newestSettingsWins          to AdjustFraming::switchToNewest;
    dependency from holdOnPause                 to PauseFollowing::selectPause;
    dependency from holdOnPause                 to PauseFollowing::holdPosition;
    dependency from resumeSameTarget            to PauseFollowing::selectResume;
    dependency from resumeSameTarget            to PauseFollowing::returnToZone;
    dependency from configurableFollowSettings  to AdjustFraming::showCurrentSettings;
    dependency from reacquireOnOverlap          to AdjustFraming::stopMoveOnOverlap;
    dependency from keepTargetCentered          to AdjustFraming::keepCentered;
    dependency from detectionRange              to AdjustFraming::trackTarget;
    dependency from detectionRange              to PauseFollowing::trackTarget;

    // ---- End ----
    dependency from returnToLaunchPoint         to EndFlight::selectEndFlight;
    dependency from returnToLaunchPoint         to EndFlight::returnToLaunch;
    dependency from landInPlace                 to EndFlight::selectEndFlight;
    dependency from landInPlace                 to EndFlight::stopInPlace;
    dependency from releaseTargetOnEnd          to EndFlight::releaseTarget;
    dependency from disarmAfterLanding          to EndFlight::disarm;
    dependency from showLandingSpot             to EndFlight::showLandingSpot;
    dependency from holdIfPersonBelow           to EndFlight::stopDescent;
    dependency from alertPersonBelow            to EndFlight::alertPersonBelow;

    // ---- ManualControl ----
    dependency from manualOverrideStopsAutonomy to TakeManualControl::selectManual;
    dependency from manualOverrideStopsAutonomy to TakeManualControl::stopAutonomy;
    dependency from manualOverrideStopsAutonomy to KeepPersonInView::pilotTakeover;
    dependency from holdUntilStickInput         to TakeManualControl::holdUntilSticks;
    dependency from manualControlOnly           to TakeManualControl::pilotFlies;
    dependency from reacquireAfterHandBack      to TakeManualControl::handBack;
    dependency from manualOverrideStopsAutonomy to PauseFollowing::handOverToPilot;
    dependency from manualOverrideStopsAutonomy to LaunchDrone::pilotTakeover;
    dependency from manualOverrideStopsAutonomy to AcquireTarget::pilotTakeover;
    dependency from manualOverrideStopsAutonomy to FilmTarget::pilotTakeover;
    dependency from manualOverrideStopsAutonomy to AdjustFraming::handOverToPilot;
    dependency from manualOverrideStopsAutonomy to EndFlight::handOverToPilot;

    // ---- CrossCutting ----
    // XC-1/2: command confirmation
    dependency from confirmOperatorCommands     to AdjustFraming::confirmReceived;
    dependency from confirmOperatorCommands     to PauseFollowing::confirmPaused;
    dependency from confirmOperatorCommands     to PauseFollowing::confirmResumed;
    dependency from confirmOperatorCommands     to EndFlight::confirmEnd;
    dependency from alertCommandNotApplied      to AdjustFraming::reportNotReceived;
    dependency from alertCommandNotApplied      to PauseFollowing::reportPauseNotConfirmed;
    dependency from alertCommandNotApplied      to PauseFollowing::reportResumeNotConfirmed;
    dependency from alertCommandNotApplied      to EndFlight::reportNotConfirmed;
    dependency from holdAfterLinkRestored       to KeepPersonInView::groundLinkLost;

    // XC-3/4: keep-out zone
    dependency from respectKeepOutZone          to FilmTarget::holdForKeepOut;
    dependency from respectKeepOutZone          to AdjustFraming::routeAroundKeepOut;
    dependency from respectKeepOutZone          to PauseFollowing::routeAroundKeepOut;
    dependency from holdWhileTargetInside       to FilmTarget::holdForKeepOut;

    // XC-5/6: geofence
    dependency from stayInsideGeofence          to KeepPersonInView::reachesGeofence;
    dependency from alertAtGeofence             to KeepPersonInView::reachesGeofence;

    // XC-7..14: failsafes
    dependency from lowBatteryReturn            to KeepPersonInView::lowBattery;
    dependency from criticalBatteryLand         to KeepPersonInView::criticalBattery;
    dependency from groundLinkLossHold          to KeepPersonInView::groundLinkLost;
    dependency from groundLinkLossReturn        to KeepPersonInView::groundLinkLost;
    dependency from rcLinkLossReturn            to KeepPersonInView::rcLinkLost;
    dependency from rcLinkLossReturn            to TakeManualControl::rcLinkLost;
    dependency from gpsLossLand                 to KeepPersonInView::gpsLost;
    dependency from gpsLossLand                 to EndFlight::abandonReturn;
    dependency from gpsLossAdviseTakeover       to KeepPersonInView::gpsLost;
    dependency from gpsLossAdviseTakeover       to EndFlight::abandonReturn;
    dependency from alertOnFailsafe             to KeepPersonInView::lowBattery;
    dependency from alertOnFailsafe             to KeepPersonInView::criticalBattery;
    dependency from alertOnFailsafe             to KeepPersonInView::groundLinkLost;
    dependency from alertOnFailsafe             to KeepPersonInView::rcLinkLost;
    dependency from alertOnFailsafe             to KeepPersonInView::gpsLost;

    // ---- Constraints ----
    dependency from limitDescentRate            to EndFlight::descend;
    dependency from limitHorizontalSpeed        to FilmTarget::stayInZone;
    dependency from limitHorizontalSpeed        to EndFlight::returnToLaunch;
    dependency from broadcastRemoteID           to KeepPersonInView;

    // --- Performance ---
    dependency from detectionRange              to AcquireTarget::scanForPersons;
    dependency from detectionRange              to FilmTarget::trackTarget;
    dependency from commandResponseTime         to AdjustFraming::confirmReceived;
    dependency from commandResponseTime         to PauseFollowing::confirmPaused;
    dependency from commandResponseTime         to PauseFollowing::confirmResumed;
    dependency from commandResponseTime         to EndFlight::confirmEnd;
    dependency from followEndurance             to KeepPersonInView;
    dependency from videoRange                  to KeepPersonInView;
    dependency from videoLatency                to KeepPersonInView;
    dependency from videoLatency                to EndFlight::showLandingSpot;
}