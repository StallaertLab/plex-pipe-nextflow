/*
 * Helpers for building plexpipe command lines.
 */

// "--name value", "--name" for true, or "" for null/false
def opt(name, value) {
    if( value == null || value == false || value == '' ) return ""
    if( value == true ) return "--${name}"
    return "--${name} '${value}'"
}

// Globus options, only when a Globus config is given
def globusArgs() {
    if( !params.globus_config ) return ""
    def gc = file(params.globus_config)
    return "--globus_config '${gc}' ${opt('from_collection', params.from_collection)} ${opt('to_collection', params.to_collection)}"
}
