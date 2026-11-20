pragma Singleton

import QtQuick
import Quickshell
import "../settings"

// macmono design tokens: type, spacing, color, motion and shared layout.
Singleton {
    readonly property string font: {
        const fams = Qt.fontFamilies();
        for (const f of ["Inter", "Inter Variable", "Inter Var", "Inter Display"])
            if (fams.indexOf(f) >= 0) return f;
        return "Inter";
    }
    readonly property string fontMono: font

    readonly property int fontXs: 11
    readonly property int fontSm: 12
    readonly property int fontMd: 14
    readonly property int fontLg: 16
    readonly property int fontXl: 22
    readonly property int font2xl: 28

    readonly property int weightRegular: Font.Normal
    readonly property int weightMedium: Font.Medium
    readonly property int weightSemibold: Font.DemiBold

    readonly property real trackTight: -0.9
    readonly property real trackSnug: -0.2
    readonly property real trackCaps: 2.2
    readonly property real lineProse: 1.45

    readonly property int space2: 2
    readonly property int space4: 4
    readonly property int space8: 8
    readonly property int space12: 12
    readonly property int space16: 16
    readonly property int space24: 24
    readonly property int space32: 32

    readonly property int radiusPanel: 20
    readonly property int radiusBar: 10
    readonly property int radiusCard: 12
    readonly property int radiusControl: 8
    readonly property int borderThin: 1
    readonly property int borderStrong: 1

    readonly property int iconSm: 14
    readonly property int iconMd: 16
    readonly property int iconLg: 20
    readonly property int iconXl: 24

    readonly property color ink: "#101010"
    readonly property color charcoal: "#1C1C1C"
    readonly property color graphite: "#343434"
    readonly property color stone: "#B8B8B8"
    readonly property color paper: "#F2F2F2"
    readonly property color white: "#FFFFFF"

    readonly property color panel: Qt.rgba(0, 0, 0, Math.max(0.25, Math.min(1, Settings.panelOpacity)))
    readonly property color scrim: Qt.rgba(0, 0, 0, 0.45)
    readonly property color transparent: "transparent"
    readonly property color tile: Qt.rgba(1, 1, 1, 0.08)
    readonly property color tileHover: Qt.rgba(1, 1, 1, 0.15)
    readonly property color tileFocus: Qt.rgba(1, 1, 1, 0.12)
    readonly property color tileFocusLine: Qt.rgba(1, 1, 1, 0.20)
    readonly property color tilePress: Qt.rgba(1, 1, 1, 0.22)
    readonly property color line: Qt.rgba(1, 1, 1, 0.08)
    readonly property color lineFocus: Qt.alpha(accent, 0.45)
    readonly property color glassSheen: Qt.rgba(1, 1, 1, 0.07)
    readonly property color glassRim: Qt.rgba(1, 1, 1, 0.04)

    readonly property color text: white
    readonly property color dim: Qt.rgba(1, 1, 1, 0.60)
    readonly property color faint: Qt.rgba(1, 1, 1, 0.40)

    readonly property color accent: paper
    readonly property color accentHover: Qt.alpha(accent, 0.85)
    readonly property color textOnAccent: ink
    readonly property color recordRed: "#FF453A"
    readonly property color inverse: white
    readonly property color inverseText: ink

    readonly property real opacityDisabled: 0.4
    readonly property real opacityDim: 0.72
    readonly property real opacityHover: 0.7

    readonly property int durFast: 110
    readonly property int durBase: 180
    readonly property int durSlow: 300
    readonly property int durPulse: 600
    readonly property int durOrbit: 160000
    readonly property real pressScale: 0.97

    readonly property int easeOut: Easing.OutCubic
    readonly property int easeIn: Easing.InCubic
    readonly property int easeInOut: Easing.InOutCubic

    readonly property real revealOpenStiff: 420
    readonly property real revealCloseStiff: 420
    readonly property real revealOpenDamp: 0.78
    readonly property real revealCloseDamp: 1.0
    readonly property real revealSceneOpenStiff: 190
    readonly property real revealSceneCloseStiff: 300
    readonly property real drawerGap: 2
    readonly property real revealOvershootMax: 8
    readonly property real staggerStep: 0.06
    readonly property real staggerSpan: 0.45
    readonly property int staggerMaxRows: 6
    readonly property real staggerRise: 8
    readonly property real islandAnticipate: 0.06
    readonly property int islandAnticipateMs: 70
    readonly property int islandBlurMax: 20
    readonly property real islandLaneBlur: 0.2
    readonly property real islandSlotBlur: 0.45
    readonly property real islandWidthOpenStiff: 520
    readonly property real islandWidthOpenDamp: 0.82
    readonly property real islandWidthCloseStiff: 360
    readonly property real islandWidthCloseDamp: 1.0
    readonly property real islandHeightOpenStiff: 360
    readonly property real islandHeightOpenDamp: 0.74
    readonly property real islandHeightCloseStiff: 480
    readonly property real islandHeightCloseDamp: 1.0
    readonly property real morphStiff: 380
    readonly property real morphDamp: 0.74

    readonly property int wallpaperFadeMs: 620
    readonly property real wallZoomIn: 0.0
    readonly property real wallZoomOut: 0.05
    readonly property real wallSlide: 1.0
    readonly property real wallDip: 0.4

    readonly property int barHeight: 36
    readonly property int barMargin: 6

    readonly property int islandCompactMinWidth: 112
    readonly property int islandSidePad: space16
    readonly property int islandZoneGap: space12
    readonly property int islandFillet: 16

    readonly property int cheatsheetKeycapHeight: 22
    readonly property int cheatsheetKeycapMinWidth: 22
    readonly property int cheatsheetKeycapPadding: 12

    readonly property int listHeaderHeight: 34
    readonly property int listSubheaderHeight: 26
    readonly property int listRowHeight: 46
    readonly property int listFooterHeight: 40
    readonly property int listActionHeight: 28

    function drawerOffset(distance, travel) {
        if (travel <= 1) return -distance * (1 - travel);
        return Math.min(distance * (travel - 1), revealOvershootMax);
    }

    function radiusInside(inset) {
        return Math.max(0, radiusPanel - inset);
    }
}
