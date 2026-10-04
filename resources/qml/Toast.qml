import QtQuick

Rectangle {
    id: root
    width: Math.min(600, messageText.implicitWidth + 60)
    height: 44
    radius: 22
    color: isError ? "#DC2626" : "#1F2937"
    border.color: isError ? "#EF4444" : "#374151"
    border.width: 1
    opacity: 0
    visible: opacity > 0
    z: 9999

    property string message: ""
    property bool isError: false

    anchors.horizontalCenter: parent.horizontalCenter
    y: 20

    Behavior on opacity {
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }
    Behavior on y {
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }

    Row {
        anchors.centerIn: parent
        spacing: 10

        Text {
            text: isError ? "⚠️" : "✓"
            font.pixelSize: 14
            color: isError ? "#FFFFFF" : "#10B981"
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            id: messageText
            text: root.message
            color: "#FFFFFF"
            font.pixelSize: 13
            font.weight: Font.Medium
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Timer {
        id: hideTimer
        interval: 2800
        onTriggered: {
            root.opacity = 0
            root.y = 10
        }
    }

    function show(msg, err = false) {
        root.message = msg
        root.isError = err
        root.y = 28
        root.opacity = 1
        hideTimer.restart()
    }
}
