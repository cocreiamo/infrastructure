# shellcheck shell=bash
# Shared by the tasks of the pipeline; sourced, never run.
#
# Nothing OpenTofu prints reaches the terminal or a job log (ADR-0008): its
# output goes to a file, the file is encrypted with the key of the state, and
# what is printed is the result of each unit and nothing else.

root="$(git rev-parse --show-toplevel)"
out="$root/.cache/pipeline"

# On a runner the sign-in is the federated identity of the job (ADR-0006). On
# the maintainer's machine it is their own, taken from gcloud for the length
# of the command. No credential file is written by this.
sign_in() {
    if [ -z "${GOOGLE_APPLICATION_CREDENTIALS:-}" ] && [ -z "${GOOGLE_OAUTH_ACCESS_TOKEN:-}" ]; then
        GOOGLE_OAUTH_ACCESS_TOKEN="$(gcloud auth print-access-token)"
        export GOOGLE_OAUTH_ACCESS_TOKEN
    fi
}

# seal <name>: encrypt .cache/pipeline/log/<name>.log into the artifact, with
# the key .sops.yaml gives to that path. A log that cannot be encrypted is
# not kept in clear anywhere.
seal() {
    mkdir -p "$out/artifact"
    (cd "$root" && sops encrypt --filename-override ".cache/pipeline/log/$1.log" \
        --input-type binary --output-type json "$out/log/$1.log" >"$out/artifact/$1.log.enc.json") ||
        { rm -f "$out/artifact/$1.log.enc.json" && echo "the log could not be encrypted and is not kept" >&2; }
    rm -f "$out/log/$1.log"
}

# The result of each unit, from Terragrunt's own report: names and outcomes.
results() {
    if [ -s "$out/report.json" ]; then
        jq -r '.[] | "\(.Name): \(.Result)\(if .Reason then " (\(.Reason))" else "" end)"' "$out/report.json"
    else
        echo "no unit was run"
    fi
}
