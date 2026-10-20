package TandemViews {
    private import StandardViewDefinitions::*;   // the built-in view types
    private import TandemRequirements::*;

    view requirementsView : GeneralView {
        expose TandemRequirements::*;            // show everything in the requirements package
    }
}