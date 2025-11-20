import QtQuick
import QtQuick.Window
import QtQuick.Controls
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
        id: usersColumnsModel
        ListElement { columnName: "ID";        columnType: "INT";   enabled: false }
        ListElement { columnName: "Username";  columnType: "TEXT";  enabled: true  }
        ListElement { columnName: "Email";     columnType: "TEXT";  enabled: true  }
    }

    ListModel {
        id: ordersColumnsModel
        ListElement { columnName: "OrderID";   columnType: "INT";   enabled: false }
        ListElement { columnName: "UserID";    columnType: "INT";   enabled: true  }
        ListElement { columnName: "Amount";    columnType: "REAL";  enabled: true  }
        ListElement { columnName: "Status";    columnType: "TEXT";  enabled: true  }
    }

    ZoomableCanvas {
        id: zoomLayer
        anchors.fill: parent

        minZoom: 0.4
        maxZoom: 2.5
        zoom: 1.0

        DatabaseTable {
            id: table1
            x: 100
            y: 100
            tableName: "Users"
            columnModel: usersColumnsModel
        }

        DatabaseTable {
            id: table2
            x: 450
            y: 150
            tableName: "Orders"
            columnModel: ordersColumnsModel
        }
    }
}
