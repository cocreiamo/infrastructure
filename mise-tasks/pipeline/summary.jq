# The public summary of the plan of one unit (ADR-0008): how many resources
# each action touches, and the address of each with its action. Its input is
# the plan as data, `tofu show -json`; no value, no identifier and no text of
# the plan passes. It prints nothing when the plan is empty.
#
# The address of a resource is in the public code. The key of an instance is
# part of the address, so a key never holds a value that is not public.

def actions:
  (.change.actions - ["no-op"])
  + (if .change.importing != null then ["import"] else [] end);

[
  (.resource_changes // [] | .[] | {address, actions: actions}),
  (.output_changes // {} | to_entries[] | {address: "output.\(.key)", actions: (.value.actions - ["no-op"])})
]
| map(select(.actions | length > 0))
| sort_by(.address)
| if length == 0 then empty
  else
    ([.[].actions[]] | group_by(.) | map("\(length) to \(.[0])") | join(", ")) as $counts
    | "**\($unit)**: \($counts)\n\n"
      + (map("- `\(.address)`: \(.actions | join(", "))") | join("\n"))
      + "\n"
  end
