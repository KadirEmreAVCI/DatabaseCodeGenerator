import QtQuick
import QtQuick.Window
import QtQuick.Controls

Window {
    visible: true
    width: 800
    height: 600
    title: ""

    DatabaseTable {
        id: databaseTable
        anchors.centerIn: parent
    }
}
