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

    property var commandBus: (typeof uiCommandBus !== "undefined" && uiCommandBus) ? uiCommandBus : qmlFallbackBus

    QtObject {
        id: qmlFallbackBus
        signal createNewTableRequested(point pos)
        signal deleteTableRequested(int tableID)
        signal changeTableNameRequested(int tableID, string newName)
        signal tablePositionChangeRequested(int tableID, point newPos)
        signal createNewRelationRequested(int sourceTableID, int destinationTableID)
        signal changeRelationshipRequested(int ID, string relationship)
        signal deleteRelationRequested(int ID)
    }

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
                id: overlayRoot
                anchors.fill: parent

                MouseArea {
                    id: previewTracker
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton
                    enabled: links && links.creatingRelation
                    z: 5000

                    onPositionChanged: function(mouse) {
                        if (!enabled)
                            return
                        var world = zoomLayer.toContent(Qt.point(mouse.x, mouse.y))
                        links.setPreviewEndWorld(world)
                        previewCanvas.requestPaint()
                    }

                    onReleased: function(mouse) {
                        if (!enabled)
                            return
                        var world = zoomLayer.toContent(Qt.point(mouse.x, mouse.y))
                        links.finishPreview(world)
                        previewCanvas.requestPaint()
                    }
                }

                Canvas {
                    id: previewCanvas
                    anchors.fill: parent
                    z: 4000
                    visible: links && links.creatingRelation

                    onVisibleChanged: {
                        if (visible)
                            requestPaint()
                    }

                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.save()
                        ctx.clearRect(0, 0, width, height)

                        if (!links || !links.creatingRelation) {
                            ctx.restore()
                            return
                        }

                        var contentItem = null
                        for (var i = 0; i < zoomLayer.children.length; ++i) {
                            if (zoomLayer.children[i] && zoomLayer.children[i].scale === zoomLayer.zoom) {
                                contentItem = zoomLayer.children[i]
                                break
                            }
                        }
                        if (!contentItem) {
                            console.warn("[Main][PreviewCanvas] contentItem not found")
                            ctx.restore()
                            return
                        }

                        function worldToOverlay(pWorld) {
                            var p = overlayRoot.mapFromItem(contentItem, pWorld.x, pWorld.y)
                            return Qt.point(p.x, p.y)
                        }

                        var p1 = worldToOverlay(links.previewStartWorld)
                        var p2 = worldToOverlay(links.previewEndWorld)

                        ctx.lineWidth = 3
                        ctx.strokeStyle = "#2d8cff"
                        ctx.lineCap = "round"
                        ctx.lineJoin = "round"
                        ctx.setLineDash([8, 6])

                        var curvatureFactor = 0.7
                        var dx = (p2.x - p1.x) * curvatureFactor
                        var cp1x = p1.x + dx
                        var cp1y = p1.y
                        var cp2x = p2.x - dx
                        var cp2y = p2.y

                        ctx.beginPath()
                        ctx.moveTo(p1.x, p1.y)
                        ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, p2.x, p2.y)
                        ctx.stroke()

                        ctx.setLineDash([])
                        var arrowLength = 15
                        var arrowAngle = Math.PI / 7
                        var vx = p2.x - cp2x
                        var vy = p2.y - cp2y
                        var len = Math.sqrt(vx * vx + vy * vy)
                        if (len > 0) {
                            vx /= len
                            vy /= len
                            var angle = Math.atan2(vy, vx)
                            var x1 = p2.x - arrowLength * Math.cos(angle - arrowAngle)
                            var y1 = p2.y - arrowLength * Math.sin(angle - arrowAngle)
                            var x2 = p2.x - arrowLength * Math.cos(angle + arrowAngle)
                            var y2 = p2.y - arrowLength * Math.sin(angle + arrowAngle)

                            ctx.beginPath()
                            ctx.moveTo(p2.x, p2.y)
                            ctx.lineTo(x1, y1)
                            ctx.moveTo(p2.x, p2.y)
                            ctx.lineTo(x2, y2)
                            ctx.stroke()
                        }

                        ctx.restore()
                    }
                }

                MouseArea {
                    id: backgroundRightClickArea
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    z: 100

                    onPressed: function(mouse) {
                        if (mouse.button !== Qt.RightButton)
                            return

                        if (links && links.creatingRelation) {
                            links.cancelPreview()
                            mouse.accepted = true
                            return
                        }

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
                            onTriggered: commandBus.createNewTableRequested(zoomLayer.lastRightClickPos)
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

        ConnectionsLayer {
            id: links
            anchors.fill: parent
            z: -1
            relations: tableController.relations
            tableRepeater: tableRepeater
        }

        Connections {
            target: links

            function onCreateNewRelationRequested(sourceTableID, destinationTableID) {
                commandBus.createNewRelationRequested(sourceTableID, destinationTableID)
            }

            function onChangeRelationshipRequested(ID, relationship) {
                commandBus.changeRelationshipRequested(ID, relationship)
            }

            function onDeleteRelationRequested(ID) {
                commandBus.deleteRelationRequested(ID)
            }

            function onPreviewTrackingRequested(enabled) {
                previewCanvas.requestPaint()
            }
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

                onXChanged: { links.updateWorldBounds(); links.requestRedraw() }
                onYChanged: { links.updateWorldBounds(); links.requestRedraw() }

                onDeleteTableRequested: function(id) { commandBus.deleteTableRequested(id) }
                onChangeTableNameRequested: function(id, newName) { commandBus.changeTableNameRequested(id, newName) }
                onTablePositionChangeRequested: function(id, pos) { commandBus.tablePositionChangeRequested(id, pos) }
            }
        }

        Component.onCompleted: {
            links.updateWorldBounds()
            links.requestRedraw()
        }
    }
}
