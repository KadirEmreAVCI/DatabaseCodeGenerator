// ZoomableCanvas.qml
import QtQuick
import QtQuick.Controls
import DatabaseCodeGenerator 1.0

Item {
    id: root

    //
    // ───────────────────── Public API ─────────────────────
    //
    property real zoom: 1.0
    property real minZoom: 0.3
    property real maxZoom: 3.0

    // internal: starting position for panning
    property real panStartX: 0
    property real panStartY: 0

    // All visual children that should be zoomed/panned live under "content"
    default property alias contentChildren: content.data

    // Children that must NOT be zoomed (overlays, menus, mouse areas) live under "overlay"
    property alias overlayChildren: overlay.data

    // Emitted when user taps on the canvas (used by DatabaseTable to cancel name editing)
    signal workspaceClicked()

    clip: true   // keep drawing inside bounds

    //
    // ───────────────────── Coordinate helpers ─────────────────────
    //

    // Convert a point in root/view coordinates into content (world) coordinates
    function toContent(point) {
        var p = content.mapFromItem(root, point.x, point.y)
        return Qt.point(p.x, p.y)
    }

    // Fit a given bounding rect (in content/world coordinates) into the viewport
    function fitToScreen(rect) {
        if (!rect || rect.width <= 0 || rect.height <= 0)
            return;

        // Compute scale factors for width and height
        var scaleX = root.width  / rect.width;
        var scaleY = root.height / rect.height;

        // Preserve aspect ratio: choose smaller scale
        var newZoom = Math.min(scaleX, scaleY);

        // Respect min/max zoom limits
        newZoom = Math.max(root.minZoom, Math.min(root.maxZoom, newZoom));

        root.zoom = newZoom;

        // Center the rect in the viewport after scaling
        content.x = -rect.x * newZoom + (root.width  - rect.width  * newZoom) / 2;
        content.y = -rect.y * newZoom + (root.height - rect.height * newZoom) / 2;
    }

    //
    // ───────────────────── Zoomed content layer ─────────────────────
    //
    // This item is the "world" that gets zoomed and panned. All tables, links, etc.
    // are children of this item (via contentChildren alias).
    Item {
        id: content
        width: root.width
        height: root.height

        transformOrigin: Item.TopLeft
        scale: root.zoom
        x: 0
        y: 0
    }

    //
    // ───────────────────── Overlay (non-zoomed) layer ─────────────────────
    //
    // Anything that should stay fixed relative to the window (context menus,
    // full-screen mouse areas, HUD, etc.) goes here (via overlayChildren alias).
    Item {
        id: overlay
        anchors.fill: parent
        z: 1000
    }

    //
    // ───────────────────── Input handlers ─────────────────────
    //

    // Mouse wheel zoom (around the viewport center; not mouse position)
    WheelHandler {
        id: wheelHandler
        target: root

        onWheel: (event) => {
            const oldZoom = root.zoom;
            const delta = event.angleDelta.y;
            if (!delta)
                return;

            // gentle zoom: ~4% per wheel step
            const steps = delta / 120.0;   // 120 = one wheel notch
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

    // Drag anywhere (background) to pan the whole scene
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
            } else {
                cursorShape = Qt.ArrowCursor;
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

    // Tap handling (single tap -> workspaceClicked, double tap -> reset view)
    TapHandler {
        acceptedButtons: Qt.LeftButton
        gesturePolicy: TapHandler.DragThreshold

        // Single tap → notify listeners (e.g., to cancel editing)
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
}
