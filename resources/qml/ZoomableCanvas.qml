// ZoomableCanvas.qml
import QtQuick

Item {
    id: root

    // public API
    property real zoom: 1.0
    property real minZoom: 0.3
    property real maxZoom: 3.0

    // All visual children of ZoomableCanvas go into "content"
    default property alias contentChildren: content.data

    clip: true   // keep drawing inside bounds

    // This is the item we actually zoom
    Item {
        id: content
        width: root.width
        height: root.height

        // zoom from the center of the viewport
        anchors.centerIn: parent
        transformOrigin: Item.Center
        scale: root.zoom
    }

    // 🔍 Simple centered zoom with mouse wheel
    WheelHandler {
        id: wheelHandler
        target: root

        onWheel: (event) => {
            const oldZoom = root.zoom;
            const delta = event.angleDelta.y;

            if (!delta)
                return;

            // gentle zoom: ~4% per wheel step
            const steps = delta / 120.0;      // 120 = one wheel notch
            const base = 1.04;                // adjust to taste
            const factor = Math.pow(base, steps);

            const newZoom = Math.max(root.minZoom,
                                     Math.min(root.maxZoom, oldZoom * factor));

            if (newZoom === oldZoom)
                return;

            root.zoom = newZoom;
            event.accepted = true;
        }
    }

    // Optional: double-click to reset zoom
    TapHandler {
        acceptedButtons: Qt.LeftButton
        gesturePolicy: TapHandler.DragThreshold
        onDoubleTapped: root.zoom = 1.0
    }
}
