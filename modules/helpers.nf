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

// Shell lines that stop the job unless `plexpipe --version` is params.plexpipe_version
def versionCheck() {
    if( !params.plexpipe_version ) return ""
    def want = params.plexpipe_version
    return """
    found=\$(${params.plexpipe} --version)
    if [ "\$found" != "${want}" ]; then
        echo "This pipeline needs PlexPipe ${want}, but ${params.plexpipe} is version \$found." >&2
        echo "Install it with: pip install \\"plex_pipe[all]==${want}\\"  (or run with --plexpipe_version '' to skip this check)" >&2
        exit 1
    fi
    """.stripIndent()
}
