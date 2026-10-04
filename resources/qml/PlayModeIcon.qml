import QtQuick

Canvas {
    id: root
    width: 18
    height: 18

    property int mode: 0 // 0: Sequential, 1: Loop, 2: Single, 3: Random
    property color iconColor: "#CBD5E1"

    onModeChanged: requestPaint()
    onIconColorChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        ctx.reset()
        ctx.strokeStyle = root.iconColor
        ctx.fillStyle = root.iconColor
        ctx.lineWidth = 1.6
        ctx.lineCap = "round"
        ctx.lineJoin = "round"

        var w = width
        var h = height

        if (mode === 0) {
            // 顺序播放: 3 horizontal list bars + right small arrow
            ctx.beginPath()
            ctx.moveTo(3, 4.5); ctx.lineTo(11, 4.5)
            ctx.moveTo(3, 9); ctx.lineTo(15, 9)
            ctx.moveTo(3, 13.5); ctx.lineTo(11, 13.5)
            ctx.stroke()

            // Arrow head on middle line
            ctx.beginPath()
            ctx.moveTo(12.5, 6.5)
            ctx.lineTo(15.5, 9)
            ctx.lineTo(12.5, 11.5)
            ctx.stroke()
        }
        else if (mode === 1) {
            // 列表循环: Circular loop arrows
            ctx.beginPath()
            ctx.moveTo(13, 5); ctx.lineTo(6, 5)
            ctx.arcTo(3, 5, 3, 9, 3)
            ctx.arcTo(3, 13, 6, 13, 3)
            ctx.stroke()

            // Bottom to top arrow
            ctx.beginPath()
            ctx.moveTo(5, 13); ctx.lineTo(12, 13)
            ctx.arcTo(15, 13, 15, 9, 3)
            ctx.arcTo(15, 5, 12, 5, 3)
            ctx.stroke()

            // Top arrow head
            ctx.beginPath()
            ctx.moveTo(11, 3); ctx.lineTo(14, 5); ctx.lineTo(11, 7)
            ctx.stroke()

            // Bottom arrow head
            ctx.beginPath()
            ctx.moveTo(7, 11); ctx.lineTo(4, 13); ctx.lineTo(7, 15)
            ctx.stroke()
        }
        else if (mode === 2) {
            // 单曲循环: Loop arrows with "1" in the center
            ctx.beginPath()
            ctx.moveTo(13, 5); ctx.lineTo(6, 5)
            ctx.arcTo(3, 5, 3, 9, 3)
            ctx.arcTo(3, 13, 6, 13, 3)
            ctx.stroke()

            ctx.beginPath()
            ctx.moveTo(5, 13); ctx.lineTo(12, 13)
            ctx.arcTo(15, 13, 15, 9, 3)
            ctx.arcTo(15, 5, 12, 5, 3)
            ctx.stroke()

            ctx.beginPath()
            ctx.moveTo(11, 3); ctx.lineTo(14, 5); ctx.lineTo(11, 7)
            ctx.stroke()

            // Draw "1" in center
            ctx.font = "bold 8px sans-serif"
            ctx.textAlign = "center"
            ctx.textBaseline = "middle"
            ctx.fillText("1", 9, 9)
        }
        else if (mode === 3) {
            // 随机播放: Shuffle crossed arrows
            ctx.beginPath()
            ctx.moveTo(3, 5); ctx.bezierCurveTo(7, 5, 11, 13, 15, 13)
            ctx.stroke()

            ctx.beginPath()
            ctx.moveTo(3, 13); ctx.bezierCurveTo(7, 13, 8.5, 10, 9.5, 9)
            ctx.moveTo(10.5, 7.5); ctx.bezierCurveTo(11.5, 6.5, 13, 5, 15, 5)
            ctx.stroke()

            // Arrow head top right
            ctx.beginPath()
            ctx.moveTo(12.5, 3.5); ctx.lineTo(15.5, 5); ctx.lineTo(12.5, 6.5)
            ctx.stroke()

            // Arrow head bottom right
            ctx.beginPath()
            ctx.moveTo(12.5, 11.5); ctx.lineTo(15.5, 13); ctx.lineTo(12.5, 14.5)
            ctx.stroke()
        }
    }
}
