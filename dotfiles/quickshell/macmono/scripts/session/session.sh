#!/bin/sh
# Log out of Hyprland; log: ~/.local/state/macmono/session.log

log="$HOME/.local/state/macmono/session.log"
mkdir -p "$(dirname "$log")"
[ -f "$log" ] && [ "$(wc -c <"$log")" -gt 200000 ] && : >"$log"
exec >>"$log" 2>&1

if [ -z "$MACMONO_SESSION_SCOPED" ] && command -v systemd-run >/dev/null 2>&1; then
    export MACMONO_SESSION_SCOPED=1
    exec systemd-run --user --scope --quiet --collect --slice=app.slice -- sh "$0" "$@"
fi

say() { echo "[$(date +%T)] $*"; }

alive() {
    for p in $(pgrep -x Hyprland 2>/dev/null); do
        read -r _ _ state _ <"/proc/$p/stat" 2>/dev/null || continue
        [ "$state" != "Z" ] && return 0
    done
    return 1
}

wait_exit() {
    n=$(($1 * 5))
    while [ "$n" -gt 0 ]; do
        alive || return 0
        sleep 0.2
        n=$((n - 1))
    done
    alive && return 1 || return 0
}

say "=== logout ==="
say "HYPRLAND_INSTANCE_SIGNATURE=$HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY=$WAYLAND_DISPLAY"

if command -v hyprshutdown >/dev/null 2>&1; then
    say "step 1: hyprshutdown"
    hyprshutdown --no-fork &
    hs=$!
    if wait_exit 10; then
        say "hyprland exited via hyprshutdown"
        exit 0
    fi
    say "hyprshutdown timed out, forcing"
    kill "$hs" 2>/dev/null
fi

say "step 2: close windows"
hyprctl clients -j 2>&1 | jq -r '.[].address' 2>&1 | while read -r a; do
    [ -n "$a" ] && hyprctl dispatch "hl.dsp.window.close({ window = \"address:$a\" })"
done
sleep 1

say "step 3: hl.dsp.exit()"
hyprctl dispatch 'hl.dsp.exit()'
if wait_exit 4; then
    say "hyprland exited"
    exit 0
fi

say "step 4: SIGTERM"
pkill -x Hyprland
if wait_exit 3; then
    say "hyprland terminated"
    exit 0
fi

say "step 5: SIGKILL"
pkill -9 -x Hyprland
wait_exit 2
say "done, alive=$(alive && echo yes || echo no)"
