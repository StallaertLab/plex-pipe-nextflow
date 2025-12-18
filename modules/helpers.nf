nextflow.enable.dsl=2

def opt(name, value) {
    if( value == null || value == false ) return ""
    if( value == true ) return "--${name}"            // flag
    return "--${name} ${value}"                       // argument with value
}

workflow Helpers {}  // required placeholder for DSL2 modules