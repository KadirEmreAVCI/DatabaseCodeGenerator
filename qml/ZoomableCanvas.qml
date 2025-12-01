// ZoomableCanvas.qml
import QtQuick
import QtQuick.Controls
import DatabaseCodeGenerator 1.0

Item {
    id: root

    // public API
    property real zoom: 1.0
    property real minZoom: 0.3
    property real maxZoom: 3.0

    // internal: starting position for panning
    property real panStartX: 0
    property real panStartY: 0

    // All visual children of ZoomableCanvas go into "content"
    default property alias contentChildren: content.data

    // 🔹 Emitted when user taps on the canvas
    signal workspaceClicked()

    clip: true   // keep drawing inside bounds

    // This is the item we actually zoom & pan
    Item {
        id: content
        width: root.width
        height: root.height

        // IMPORTANT: no anchors here, we move x/y ourselves
        transformOrigin: Item.TopLeft
        scale: root.zoom
        x: 0
        y: 0
    }

    // 🔍 Simple zoom (not based on mouse position)
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
            const base = 1.04;
            const factor = Math.pow(base, steps);

            const newZoom = Math.max(root.minZoom,
                                     Math.min(root.maxZoom, oldZoom * factor));
            if (newZoom === oldZoom)
                return;

            root.zoom = newZoom;
            event.accepted = true;
        }
    }

    // 🧭 Drag anywhere (background) to pan the whole scene
    DragHandler {
        id: panHandler
        target: null
        acceptedButtons: Qt.LeftButton

        onActiveChanged: {
            if (active) {
                // remember where content was when pan started
                root.panStartX = content.x;
                root.panStartY = content.y;
                cursorShape = Qt.ClosedHandCursor;
            }
        }

        onTranslationChanged: {
            if (active) {
                // translation is read-only; we just use it
                content.x = root.panStartX + translation.x;
                content.y = root.panStartY + translation.y;
                cursorShape = Qt.ClosedHandCursor;
            }
        }
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        gesturePolicy: TapHandler.DragThreshold

        // 🔹 Single tap → notify listeners
        onTapped: function(point, button) {
            root.workspaceClicked()
        }

        // Double-tap → reset view
        onDoubleTapped: {
            root.zoom = 1.0;
            content.x = 0;
            content.y = 0;
        }
    }

    // Fit all content into the visible area while preserving aspect ratio
    function fitToScreen(rect) {
        if (!rect || rect.width <= 0 || rect.height <= 0)
            return;

        // Calculate scale needed horizontally and vertically
        const scaleX = root.width / rect.width;
        const scaleY = root.height / rect.height;

        // Choose the smaller (preserves aspect ratio)
        let newZoom = Math.min(scaleX, scaleY);

        // Respect minZoom & maxZoom constraints
        newZoom = Math.max(root.minZoom, Math.min(root.maxZoom, newZoom));

        // Center content on the screen
        root.zoom = newZoom;

        // After scaling, we need to reposition content.x/y
        // so that the bounding rect appears centered
        content.x = -rect.x * newZoom + (root.width - rect.width * newZoom) / 2;
        content.y = -rect.y * newZoom + (root.height - rect.height * newZoom) / 2;
    }
}
