import QtQuick
import QtQuick.Shapes
import "../../core"
import "GlyphPaths.js" as Icons

Item {
    id: root

    property string name: ""
    property color color: Theme.text
    property real thickness: 1.8

    implicitWidth: Theme.iconMd
    implicitHeight: Theme.iconMd

    readonly property var icon: Icons.paths[name] ?? null
    readonly property bool hasStroke: icon !== null && icon.mode !== "fill"
    readonly property bool hasFill: icon !== null && icon.mode !== "stroke"

    Shape {
        visible: root.icon !== null
        width: root.icon ? root.icon.w : 1
        height: width
        scale: Math.min(root.width, root.height) / width
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.hasStroke ? root.color : "transparent"
            strokeWidth: root.hasStroke ? root.thickness : -1
            fillColor: root.hasFill ? root.color : "transparent"
            fillRule: ShapePath.WindingFill
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathSvg { path: root.icon ? root.icon.d : "" }
        }
    }

    Loader {
        active: root.icon === null
        anchors.fill: parent
        sourceComponent: Component {
            GlyphLegacy {
                anchors.fill: parent
                name: root.name
                color: root.color
                thickness: root.thickness
            }
        }
    }
}
