package TandemViews {
    private import StandardViewDefinitions::*;   // the built-in view types
    private import TandemRequirements::*;

    view requirementsView : GeneralView {
        expose TandemRequirements::**;  
        expose TandemTraceability::**;          // show everything in the requirements package
    }
    view traceMatrix : GridView {
        expose TandemTraceability::*;
    }
}