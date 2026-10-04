pragma Singleton
import QtQuick

QtObject {
    id: root

    // 0: 深邃暗夜 (Dark Night), 1: QQ音乐绿 (QQ Green), 2: 网易云红 (NetEase Red), 3: 简约晨曦 (Light)
    property int themeMode: 3

    readonly property var themeNames: ["深邃暗夜", "QQ音乐绿", "网易云红", "简约晨曦"]

    // Backgrounds
    readonly property color bgDark: {
        switch (themeMode) {
            case 1: return "#0C1412" // QQ Green dark
            case 2: return "#160F12" // NetEase Red dark
            case 3: return "#F8FAFC" // Light mode
            default: return "#0B0F19" // Default dark
        }
    }

    readonly property color bgSidebar: {
        switch (themeMode) {
            case 1: return "#101D19"
            case 2: return "#1F1418"
            case 3: return "#FFFFFF"
            default: return "#0F172A"
        }
    }

    readonly property color bgCard: {
        switch (themeMode) {
            case 1: return "#152621"
            case 2: return "#27191F"
            case 3: return "#FFFFFF"
            default: return "#1E293B"
        }
    }

    readonly property color bgCardHover: {
        switch (themeMode) {
            case 1: return "#1C332C"
            case 2: return "#332128"
            case 3: return "#F1F5F9"
            default: return "#283548"
        }
    }

    readonly property color bgCardAlt: {
        switch (themeMode) {
            case 1: return "#101D19"
            case 2: return "#1F1418"
            case 3: return "#F8FAFC"
            default: return "#111827"
        }
    }

    readonly property color bgHeader: {
        switch (themeMode) {
            case 1: return "#13231E"
            case 2: return "#24171D"
            case 3: return "#F1F5F9"
            default: return "#162032"
        }
    }

    readonly property color bgPlayer: {
        switch (themeMode) {
            case 1: return "#0E1815"
            case 2: return "#1B1215"
            case 3: return "#FFFFFF"
            default: return "#0F172A"
        }
    }

    readonly property color bgInput: {
        switch (themeMode) {
            case 3: return "#F1F5F9"
            default: return "#111827"
        }
    }

    // Accents
    readonly property color accent: {
        switch (themeMode) {
            case 1: return "#10B981" // QQ Green
            case 2: return "#EF4444" // NetEase Red
            case 3: return "#2563EB" // Tech Blue
            default: return "#3B82F6"
        }
    }

    readonly property color accentHover: {
        switch (themeMode) {
            case 1: return "#34D399"
            case 2: return "#F87171"
            case 3: return "#3B82F6"
            default: return "#60A5FA"
        }
    }

    readonly property color accentGradientStart: {
        switch (themeMode) {
            case 1: return "#10B981"
            case 2: return "#EF4444"
            case 3: return "#3B82F6"
            default: return "#3B82F6"
        }
    }

    readonly property color accentGradientEnd: {
        switch (themeMode) {
            case 1: return "#059669"
            case 2: return "#DC2626"
            case 3: return "#6366F1"
            default: return "#6366F1"
        }
    }

    // Borders
    readonly property color border: {
        switch (themeMode) {
            case 1: return "#1F3830"
            case 2: return "#3B252E"
            case 3: return "#E2E8F0"
            default: return "#334155"
        }
    }

    readonly property color borderSubtle: {
        switch (themeMode) {
            case 1: return "#172A24"
            case 2: return "#2C1B22"
            case 3: return "#F1F5F9"
            default: return "#1E293B"
        }
    }

    // Texts
    readonly property color textPrimary: {
        switch (themeMode) {
            case 3: return "#0F172A"
            default: return "#F8FAFC"
        }
    }

    readonly property color textSecondary: {
        switch (themeMode) {
            case 3: return "#475569"
            default: return "#94A3B8"
        }
    }

    readonly property color textMuted: {
        switch (themeMode) {
            case 3: return "#94A3B8"
            default: return "#64748B"
        }
    }

    // Platform Brand Colors (Fixed)
    readonly property color colorQQ: "#10B981"
    readonly property color colorNetEase: "#EF4444"
    readonly property color colorKuGou: "#3B82F6"
    readonly property color colorKuwo: "#F59E0B"
    readonly property color colorAll: "#8B5CF6"

    function nextTheme() {
        themeMode = (themeMode + 1) % 4
    }

    function setTheme(mode) {
        if (mode >= 0 && mode < 4) {
            themeMode = mode
        }
    }
}
