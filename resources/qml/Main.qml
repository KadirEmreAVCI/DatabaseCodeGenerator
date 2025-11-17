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
        x: 100  // initial position of x
        y: 100  // initial position of y
    }
}
