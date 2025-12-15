// Main.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Window
import QtQml.Models
import DatabaseCodeGenerator 1.0

Window {
    id: mainWindow
    visible: true
    width: 1600
    height: 1200

    GridBackground {
        id: dotGrid
        anchors.fill: parent
        gridSize: 20
        dotSize: 1
        dotColor: "#808080"
        backgroundColor: "#f3f3f3"
    }

    ZoomableCanvas {
        id: zoomLayer
        anchors.fill: parent

        minZoom: 0.4
        maxZoom: 2.5
        zoom: 1.0

        property point lastRightClickPos: Qt.point(0, 0)

        overlayChildren: [
            Item {
                anchors.fill: parent

                //
                // Window-level tracker for preview (works outside content rectangle),
                // but coordinates are converted using mapFromItem to links (no toContent needed).
                //
                MouseArea {
                    id: previewTracker
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: false
                    acceptedButtons: Qt.LeftButton
                    propagateComposedEvents: true

                    onPositionChanged: function(mouse) {
                        if (!links || !links.creatingRelation)
                            return

                        // Overlay(view) -> links(world/content) conversion
                        var pWorld = links.mapFromItem(previewOverlayCanvas, mouse.x, mouse.y)
                        links.setPreviewEndWorld(pWorld)
                        previewOverlayCanvas.requestPaint()
                    }

                    onReleased: function(mouse) {
                        if (!links || !links.creatingRelation)
                            return

                        var pWorld = links.mapFromItem(previewOverlayCanvas, mouse.x, mouse.y)
                        links.finishPreview(pWorld)
                        previewOverlayCanvas.requestPaint()
                    }
                }

                //
                // Preview overlay canvas (not clipped by content rectangle)
                //
                Canvas {
                    id: previewOverlayCanvas
                    anchors.fill: parent
                    z: 9999

                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.save()
                        ctx.clearRect(0, 0, width, height)

                        if (!links || !links.creatingRelation) {
                            ctx.restore()
                            return
                        }

                        // links(world/content) -> overlay(view) conversion
                        var p1View = links.mapToItem(previewOverlayCanvas,
                                                     links.previewStartWorld.x,
                                                     links.previewStartWorld.y)
                        var p2View = links.mapToItem(previewOverlayCanvas,
                                                     links.previewEndWorld.x,
                                                     links.previewEndWorld.y)

                        // Styling
                        ctx.lineWidth = 3
                        ctx.strokeStyle = "#2d8cff"
                        ctx.lineCap = "round"
                        ctx.lineJoin = "round"

                        var curvatureFactor = 0.7
                        var arrowLength = 15
                        var arrowAngle = Math.PI / 7
                        var sourceRadius = 10

                        var dx = (p2View.x - p1View.x) * curvatureFactor
                        var cp1x = p1View.x + dx
                        var cp1y = p1View.y
                        var cp2x = p2View.x - dx
                        var cp2y = p2View.y

                        // Dashed curve
                        ctx.setLineDash([7, 6])
                        ctx.beginPath()
                        ctx.moveTo(p1View.x, p1View.y)
                        ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, p2View.x, p2View.y)
                        ctx.stroke()
                        ctx.setLineDash([])

                        // Source circle
                        ctx.beginPath()
                        ctx.arc(p1View.x, p1View.y, sourceRadius, 0, Math.PI * 2, false)
                        ctx.stroke()

                        // Arrow at cursor
                        var vx = p2View.x - cp2x
                        var vy = p2View.y - cp2y
                        if (vx === 0 && vy === 0) {
                            vx = p2View.x - p1View.x
                            vy = p2View.y - p1View.y
                        }

                        var len = Math.sqrt(vx * vx + vy * vy)
                        if (len > 0) {
                            vx /= len
                            vy /= len
                            var angle = Math.atan2(vy, vx)

                            var x1 = p2View.x - arrowLength * Math.cos(angle - arrowAngle)
                            var y1 = p2View.y - arrowLength * Math.sin(angle - arrowAngle)
                            var x2 = p2View.x - arrowLength * Math.cos(angle + arrowAngle)
                            var y2 = p2View.y - arrowLength * Math.sin(angle + arrowAngle)

                            ctx.beginPath()
                            ctx.moveTo(p2View.x, p2View.y)
                            ctx.lineTo(x1, y1)
                            ctx.moveTo(p2View.x, p2View.y)
                            ctx.lineTo(x2, y2)
                            ctx.stroke()
                        }

                        ctx.restore()
                    }
                }

                // Background right-click area (unchanged)
                MouseArea {
                    id: backgroundRightClickArea
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton

                    onPressed: function(mouse) {
                        if (mouse.button !== Qt.RightButton)
                            return

                        var overTable = false
                        for (var i = 0; i < tableRepeater.count; ++i) {
                            var t = tableRepeater.itemAt(i)
                            if (!t)
                                continue

                            var p = t.mapFromItem(zoomLayer, mouse.x, mouse.y)
                            if (p.x >= 0 && p.x <= t.width &&
                                p.y >= 0 && p.y <= t.height) {
                                overTable = true
                                break
                            }
                        }

                        if (overTable) {
                            mouse.accepted = true
                            return
                        }

                        // Keep your original logic for creating a new table
                        var viewPos = Qt.point(mouse.x, mouse.y)
                        zoomLayer.lastRightClickPos = zoomLayer.toContent(viewPos)

                        backgroundMenu.x = mouse.x
                        backgroundMenu.y = mouse.y
                        backgroundMenu.open()
                    }
                }

                Menu {
                    id: backgroundMenu

                    Menu {
                        id: newSubMenu
                        title: qsTr("New")

                        MenuItem {
                            text: qsTr("Table")
                            onTriggered: {
                                tableController.onCreateNewTable(zoomLayer.lastRightClickPos)
                            }
                        }
                    }

                    Menu {
                        id: zoomSubMenu
                        title: qsTr("Zoom")

                        MenuItem {
                            text: qsTr("Zoom In")
                            onTriggered: {
                                const step = 0.1
                                zoomLayer.zoom = Math.min(zoomLayer.zoom + step, zoomLayer.maxZoom)
                            }
                        }

                        MenuItem {
                            text: qsTr("Zoom Out")
                            onTriggered: {
                                const step = 0.1
                                zoomLayer.zoom = Math.max(zoomLayer.zoom - step, zoomLayer.minZoom)
                            }
                        }

                        MenuItem {
                            text: qsTr("Reset Zoom")
                            onTriggered: {
                                zoomLayer.zoom = 1.0
                            }
                        }

                        MenuItem {
                            text: qsTr("Fit to Screen")
                            onTriggered: {
                                const rect = tableController.GetBoundingRect()
                                zoomLayer.fitToScreen(rect)
                            }
                        }
                    }
                }
            }
        ]

        // Zoomed content
        ConnectionsLayer {
            id: links
            anchors.fill: parent
            z: -1

            relations: relationController.relations
            tableRepeater: tableRepeater

            onPreviewTrackingRequested: function(enabled) {
                previewTracker.enabled = enabled
                previewOverlayCanvas.requestPaint()
            }

            onPreviewStartWorldChanged: previewOverlayCanvas.requestPaint()
            onPreviewEndWorldChanged: previewOverlayCanvas.requestPaint()
            onCreatingRelationChanged: previewOverlayCanvas.requestPaint()
        }

        Connections {
            target: tableController
            function onTablesChanged() {
                Qt.callLater(function() {
                    links.updateWorldBounds()
                    links.requestRedraw()
                })
            }
        }

        Repeater {
            id: tableRepeater
            model: tableController.tables

            delegate: DatabaseTable {
                id: tableItem
                required property var modelData

                canvas: zoomLayer
                connectionsLayer: links

                tableID:     modelData.ID
                x:           modelData.point.x
                y:           modelData.point.y
                tableName:   modelData.name
                columnModel: modelData.columnListModel

                onXChanged: {
                    links.updateWorldBounds()
                    links.requestRedraw()
                }
                onYChanged: {
                    links.updateWorldBounds()
                    links.requestRedraw()
                }
            }
        }

        Component.onCompleted: {
            links.updateWorldBounds()
            links.requestRedraw()
        }
    }
}
