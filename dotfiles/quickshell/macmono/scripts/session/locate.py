#!/usr/bin/env python3
"""Ask GeoClue where this computer is and print ONE line of JSON.

Success: {"ok": true, "lat": 0.53, "lon": 101.45, "accuracy": 25000.0, "desc": ""}
Failure: {"ok": false, "code": "missing|denied|nofix|nogi|error", "error": "..."}

It always exits 0, so macmono can show a clear message instead of a crash.
usage: locate.py [timeout_seconds]

Needs the geoclue package and python-gobject. The app id "macmono" must be allowed in
/etc/geoclue/conf.d (see the [macmono] entry in the install notes).
"""
import json
import sys
import time

try:
    import gi

    gi.require_version("Gio", "2.0")
    from gi.repository import Gio, GLib
except Exception as exc:
    print(json.dumps({"ok": False, "code": "nogi", "error": str(exc)}))
    sys.exit(0)

DESKTOP_ID = "macmono"
CITY = 4
BUS = "org.freedesktop.GeoClue2"
PROPS = "org.freedesktop.DBus.Properties"
CLIENT = BUS + ".Client"
LOCATION = BUS + ".Location"


def done(**result):
    print(json.dumps(result), flush=True)
    sys.exit(0)


def classify(err):
    text = str(err)
    if "ServiceUnknown" in text or "NameHasNoOwner" in text or "not provided by any" in text:
        return "missing"
    if "AccessDenied" in text:
        return "denied"
    return "error"


def main():
    timeout = float(sys.argv[1]) if len(sys.argv) > 1 else 25.0

    try:
        bus = Gio.bus_get_sync(Gio.BusType.SYSTEM, None)
    except GLib.Error as err:
        done(ok=False, code="error", error=str(err))

    def call(path, iface, method, params=None):
        return bus.call_sync(BUS, path, iface, method, params, None, Gio.DBusCallFlags.NONE, 10000, None)

    def get(path, iface, name):
        return call(path, PROPS, "Get", GLib.Variant("(ss)", (iface, name))).unpack()[0]

    def put(path, iface, name, value):
        call(path, PROPS, "Set", GLib.Variant("(ssv)", (iface, name, value)))

    client = None
    try:
        client = call("/org/freedesktop/GeoClue2/Manager", BUS + ".Manager", "GetClient").unpack()[0]
        put(client, CLIENT, "DesktopId", GLib.Variant("s", DESKTOP_ID))
        put(client, CLIENT, "RequestedAccuracyLevel", GLib.Variant("u", CITY))
        call(client, CLIENT, "Start")

        location = "/"
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            location = get(client, CLIENT, "Location")
            if location and location != "/":
                break
            time.sleep(0.4)
        if not location or location == "/":
            done(ok=False, code="nofix", error="GeoClue did not report a location in time.")

        info = call(location, PROPS, "GetAll", GLib.Variant("(s)", (LOCATION,))).unpack()[0]
        done(
            ok=True,
            lat=info["Latitude"],
            lon=info["Longitude"],
            accuracy=info.get("Accuracy", 0),
            desc=info.get("Description", ""),
        )
    except GLib.Error as err:
        done(ok=False, code=classify(err), error=str(err))
    except Exception as err:
        done(ok=False, code="error", error=str(err))
    finally:
        if client:
            try:
                call(client, CLIENT, "Stop")
            except Exception:
                pass


if __name__ == "__main__":
    main()
