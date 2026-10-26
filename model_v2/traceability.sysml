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

    // ---- PreFlight ----
    dependency from readyOnlyWhenPrechecksPass  to PrepareForFlight::runPrechecks;
    dependency from readyOnlyWhenPrechecksPass  to PrepareForFlight::noConnection;
    dependency from readyOnlyWhenPrechecksPass  to PrepareForFlight::notReady;
    dependency from noArmOnFailedPrechecks      to PrepareForFlight::prechecksFail;
    dependency from showPrecheckFailures        to PrepareForFlight::prechecksFail;
    dependency from showPrecheckFailures        to PrepareForFlight::notReady;
    dependency from confirmSettingsBeforeArming to PrepareForFlight::setSettings;

    // ---- Launch ----
    dependency from takeOffWhenArmed            to LaunchDrone::triggerLaunch;
    dependency from reachLaunchAltitude         to LaunchDrone::climb;
    dependency from reachLaunchAltitude         to LaunchDrone::hoverAtAltitude;

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
    dependency from keepTargetCentered          to FilmTarget::keepCentered;
    dependency from noUnplannedFollowStop       to FilmTarget::repeatUntilStopped;
    dependency from freezeZoneWhenStationary    to FilmTarget::targetStill;
    dependency from lostAfterNotSeen            to FilmTarget::targetLost;
    dependency from returnToAcquisitionWhenLost to FilmTarget::targetLost;
    dependency from alertOperatorWhenLost       to FilmTarget::targetLost;
    dependency from alertFallingBehind          to FilmTarget::fallingBehind;
    dependency from reacquireOnOverlap          to FilmTarget::overlap;

    dependency from configurableFollowSettings  to AdjustFraming::enterValues;
    dependency from limitCameraToTargetDistance to AdjustFraming::outOfRange;
    dependency from rejectOutOfRangeSettings    to AdjustFraming::outOfRange;
    dependency from showAllowedRange            to AdjustFraming::outOfRange;
    dependency from gradualRepositioning        to AdjustFraming::moveGradually;
    dependency from newestSettingsWins          to AdjustFraming::newestWins;

    dependency from rejectOutOfRangeSettings    to PrepareForFlight::invalidSetting;
    dependency from showAllowedRange            to PrepareForFlight::invalidSetting;

    dependency from resumeSameTarget            to PauseFollowing::selectResume;
    dependency from resumeSameTarget            to PauseFollowing::returnToZone;
    dependency from keepTargetCentered          to PauseFollowing::holdAndTrack;
    dependency from gradualRepositioning        to PauseFollowing::returnToZone;
    dependency from holdOnPause                 to PauseFollowing::selectPause;
    dependency from holdOnPause                 to PauseFollowing::holdAndTrack;
    dependency from reacquireOnOverlap          to PauseFollowing::overlap;

    // ---- End ----
    dependency from returnToLaunchPoint         to EndFlight::selectEndFlight;
    dependency from returnToLaunchPoint         to EndFlight::returnToLaunch;
    dependency from landInPlace                 to EndFlight::selectEndFlight;
    dependency from landInPlace                 to EndFlight::landHere;
    dependency from releaseTargetOnEnd          to EndFlight::confirmEnd;
    dependency from disarmAfterLanding          to EndFlight::disarm;
    dependency from showLandingSpot             to EndFlight::watchLandingSpot;
    dependency from holdIfPersonBelow           to EndFlight::personBelow;
    dependency from alertPersonBelow            to EndFlight::personBelow;
    dependency from landIfPositionLost          to EndFlight::positionLost;
    dependency from alertPositionLost           to EndFlight::positionLost;

    // ---- ManualControl ----
    dependency from manualOverrideStopsAutonomy to TakeManualControl::selectManual;
    dependency from manualOverrideStopsAutonomy to TakeManualControl::stopAutonomy;
    dependency from holdUntilStickInput         to TakeManualControl::holdUntilSticks;
    dependency from manualControlOnly           to TakeManualControl::pilotFlies;
    dependency from reacquireAfterHandBack      to TakeManualControl::handBack;

    // ---- CrossCutting ----
    dependency from confirmOperatorCommands     to AdjustFraming::confirmReceived;
    dependency from confirmOperatorCommands     to PauseFollowing::confirmPaused;
    dependency from alertCommandNotApplied      to AdjustFraming::notReceived;
    dependency from alertCommandNotApplied      to PauseFollowing::pauseNotConfirmed;
    dependency from confirmOperatorCommands     to EndFlight::confirmEnd;
    dependency from alertCommandNotApplied      to EndFlight::notConfirmed;

    // ---- Constraints ----
    dependency from limitDescentRate            to EndFlight::descendAndLand;

}