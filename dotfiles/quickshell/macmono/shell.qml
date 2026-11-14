import Quickshell
import "core/shortcuts"
import "shared/services"
import "features/lock"
import "features/menubar"
import "features/notifications"
import "features/regionSelector"
import "features/wallpaper"

ShellRoot {
    Ipc {}

    Wallpaper {}
    WallpaperPreview {}
    MenuBar {}
    Notifs {}
    RegionSelector {}
    Shortcuts {}
    LockScreen {}
}
