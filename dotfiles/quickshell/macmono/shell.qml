import Quickshell
import "core"
import "core/shortcuts"
import "shared/services"
import "features/lock"
import "features/menubar"
import "features/notifications"
import "features/regionSelector"
import "features/settings"
import "features/wallpaper"

ShellRoot {
    Ipc {}

    Wallpaper {}
    WallpaperPreview {}
    MenuBar {}
    Notifs {}
    LazyLoader {
        active: Sys.settingsOpen
        component: SettingsWindow {}
    }
    RegionSelector {}
    Shortcuts {}
    LockScreen {}
}
