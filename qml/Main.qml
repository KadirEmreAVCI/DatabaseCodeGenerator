import QtQuick
import QtQuick.Controls
import DatabaseCodeGenerator 1.0
import QtQuick.Window
import QtQml.Models

Window {
    id: mainWindow
    visible: true
    width: 800
    height: 600

    GridBackground {
        id: dotGrid
        anchors.fill: parent
        gridSize: 20
        dotSize: 1
        dotColor: "#808080"
        backgroundColor: "#f3f3f3"
    }

    ListModel {
        id: tournamentColumnsModel
        ListElement { columnName: "ID";        columnType: "INT";   enabled: false; isPrimaryKey: true; isRelationSource: true }
        ListElement { columnName: "Season";    columnType: "TEXT";  enabled: true;  isPrimaryKey: false; isRelationSource: false }
        ListElement { columnName: "Category";  columnType: "TEXT";  enabled: true ; isPrimaryKey: false; isRelationSource: false}
    }

    ListModel {
        id: matchColumnsModel
        ListElement { columnName: "ID";             columnType: "INT";   enabled: false; isPrimaryKey: true; isRelationSource: false }
        ListElement { columnName: "TournamentID";   columnType: "INT";   enabled: false; isPrimaryKey: false; isRelationSource: true }
        ListElement { columnName: "Date";         columnType: "REAL";  enabled: true; isPrimaryKey: false; isRelationSource: false }
        ListElement { columnName: "Time";         columnType: "TEXT";  enabled: true; isPrimaryKey: false; isRelationSource: false}
    }

    ZoomableCanvas {
        id: zoomLayer
        anchors.fill: parent

        minZoom: 0.4
        maxZoom: 2.5
        zoom: 1.0

        // 🔹 Lines layer (same zoomed space as tables)
        ConnectionsLayer {
            id: links
            anchors.fill: parent
            z: -1  // or 1, depending if you want lines behind or on top of tables
        }

        DatabaseTable {
            id: table1
            x: tournamentTableModel.x
            y: tournamentTableModel.y
            tableName: tournamentTableModel.name
            columnModel: tournamentColumnsModel

            onXChanged: links.requestRedraw()
            onYChanged: links.requestRedraw()
        }

        DatabaseTable {
            id: table2
            x: matchTableModel.x
            y: matchTableModel.y
            tableName: matchTableModel.name
            columnModel: matchColumnsModel

            onXChanged: links.requestRedraw()
            onYChanged: links.requestRedraw()
        }

        Component.onCompleted: {
            links.connections = [
                {
                    sourceTable: table2,
                    sourceRow: 1,

                    destinationTable: table1,
                    destinationRow: 0,

                    // NEW: single relationship parameter
                    // allowed values: "1..1" or "1..*"
                    relationship: "1..*"
                }
            ];
            links.requestRedraw();
        }
    }
}
