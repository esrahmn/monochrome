#!/usr/bin/env bash
# Usage: kb-layout.sh <active_keymap> <layouts> <variants>
set -u
active="${1:-}"; layouts="${2:-}"; variants="${3:-}"
lst="${XKB_CONFIG_ROOT:-/usr/share/X11/xkb}/rules/evdev.lst"

code=""
if [ -r "$lst" ] && [ -n "$active" ] && [ -n "$layouts" ]; then
    code="$(awk -v act="$active" -v lays="$layouts" -v vars="$variants" '
        BEGIN { n = split(lays, L, ","); split(vars, V, ",") }
        /^! / { sec = $2; next }
        sec == "layout" && NF >= 2 {
            d = $0; sub(/^[ \t]*[^ \t]+[ \t]+/, "", d); LD[$1] = d; next
        }
        sec == "variant" && NF >= 3 {
            lc = $2; sub(/:$/, "", lc)
            d = $0; sub(/^[ \t]*[^ \t]+[ \t]+[^ \t]+[ \t]+/, "", d); VD[lc SUBSEP $1] = d; next
        }
        END {
            for (i = 1; i <= n; i++) {
                l = L[i]; v = V[i]
                gsub(/ /, "", l); gsub(/ /, "", v)
                desc = (v == "") ? LD[l] : VD[l SUBSEP v]
                if (desc != "" && desc == act) { print l; exit }
            }
        }' "$lst")"
fi
[ -n "$code" ] || code="$(printf '%s' "$active" | cut -c1-2)"
printf '%s\n' "$code" | tr '[:lower:]' '[:upper:]'
