import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
pragma Singleton

Singleton {
    id: root

    property string hostname: ""
    property string username: ""
    property string osIcon: ""
    property string osName: ""
    property string kernelVersion: ""
    property string architecture: ""
    property string uptime: ""
    property int pacmanUpdates: 0
    property int aurUpdates: 0
    property string packageUpdateSummary: "0 pacman | 0 AUR"
    property string qsVersion: ""
    property string swapUsage: "—"
    property real swapPercent: 0
    property string ipAddress: "—"
    property int runningProcesses: 0
    property int loggedInUsers: 0
    property string ramUsage: "—"
    property real ramPercent: 0
    property string cpuLoad: "—"
    property real cpuPercent: 0
    property string diskUsage: "—"
    property real diskPercent: 0
    property string cpuTemp: "—"
    property string keyboardLayout: "none"
    property real cpuTempPercent: 0
    property int prevIdle: -1
    property int prevTotal: -1


    readonly property var osIcons: ({
        "almalinux": "",
        "alpine": "",
        "arch": "󰣇",
        "archcraft": "",
        "arcolinux": "",
        "artix": "",
        "centos": "",
        "debian": "",
        "devuan": "",
        "elementary": "",
        "endeavouros": "",
        "fedora": "",
        "freebsd": "",
        "garuda": "",
        "gentoo": "",
        "hyperbola": "",
        "kali": "",
        "linuxmint": "󰣭",
        "mageia": "",
        "openmandriva": "",
        "manjaro": "",
        "neon": "",
        "nixos": "",
        "opensuse": "",
        "suse": "",
        "sles": "",
        "sles_sap": "",
        "opensuse-tumbleweed": "",
        "parrot": "",
        "pop": "",
        "raspbian": "",
        "rhel": "",
        "rocky": "",
        "slackware": "",
        "solus": "",
        "steamos": "",
        "tails": "",
        "trisquel": "",
        "ubuntu": "",
        "vanilla": "",
        "void": "",
        "zorin": "",
        "opensuse": "",

    })


    FileView { id: cpuStat; path: "/proc/stat" }
    FileView { id: memInfo; path: "/proc/meminfo" }
    FileView { id: uptimeFile; path: "/proc/uptime" }

    Timer {
        interval: 1800000
        running: true
        repeat: true

        onTriggered: updateCheckProc.running = true
    }


    Timer {
        interval: 1000
        running: true
        repeat: true

        onTriggered: {

            cpuStat.reload()
            memInfo.reload()
            uptimeFile.reload()

            /* CPU */

            const cpuLine = cpuStat.text().split("\n")[0].trim().split(/\s+/)

            const cpuUser = parseInt(cpuLine[1])
            const cpuNice = parseInt(cpuLine[2])
            const cpuSystem = parseInt(cpuLine[3])
            const cpuIdle = parseInt(cpuLine[4])
            const cpuIowait = parseInt(cpuLine[5])
            const cpuIrq = parseInt(cpuLine[6])
            const cpuSoftirq = parseInt(cpuLine[7])

            const cpuIdleAll = cpuIdle + cpuIowait
            const cpuTotal =
                cpuUser + cpuNice + cpuSystem + cpuIrq + cpuSoftirq + cpuIdleAll

            if (root.prevTotal >= 0) {

                const totalDiff = cpuTotal - root.prevTotal
                const idleDiff = cpuIdleAll - root.prevIdle

                if (totalDiff > 0)
                    root.cpuPercent = (totalDiff - idleDiff) / totalDiff
            }

            root.prevTotal = cpuTotal
            root.prevIdle = cpuIdleAll

            root.cpuLoad = Math.round(root.cpuPercent * 100) + "%"


            /* RAM */

            const memLines = memInfo.text().split("\n")

            let memTotal = 0
            let memAvailable = 0

            for (let line of memLines) {

                if (line.startsWith("MemTotal"))
                    memTotal = parseInt(line.match(/\d+/)[0])

                if (line.startsWith("MemAvailable"))
                    memAvailable = parseInt(line.match(/\d+/)[0])
            }

            if (memTotal > 0) {

                const memUsed = memTotal - memAvailable

                root.ramPercent = memUsed / memTotal
                root.ramUsage =
                    `${Math.round(memUsed/1024)}/${Math.round(memTotal/1024)} MB`
            }


            /* Uptime */

            const uptimeSeconds =
                parseFloat(uptimeFile.text().split(" ")[0])

            const d = Math.floor(uptimeSeconds / 86400)
            const h = Math.floor((uptimeSeconds % 86400) / 3600)
            const m = Math.floor((uptimeSeconds % 3600) / 60)

            let upString = "Up "

            if (d > 0) upString += d + "d "
            if (h > 0) upString += h + "h "

            upString += m + "m"

            root.uptime = upString


            cpuTempProc.running = true
            diskProc.running = true
            ipProc.running = true
            procCountProc.running = true
            swapProc.running = true
            keyboardLayoutProc.running = true
            loggedUsersProc.running = true
        }
    }

    Process {
        id: updateCheckProc
        running: true
        command: [
            "sh", "-c",
            "pacman_count=0; "
            + "aur_count=0; "
            + "if command -v checkupdates >/dev/null 2>&1; then "
            + "pacman_count=$(checkupdates 2>/dev/null | wc -l); "
            + "fi; "
            + "if command -v paru >/dev/null 2>&1; then "
            + "aur_count=$(paru -Qua 2>/dev/null | wc -l); "
            + "elif command -v yay >/dev/null 2>&1; then "
            + "aur_count=$(yay -Qua 2>/dev/null | wc -l); "
            + "fi; "
            + "printf '%s|%s\\n' \"$pacman_count\" \"$aur_count\""
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split("|")
                const pacmanCount = parseInt(parts[0])
                const aurCount = parseInt(parts[1])

                root.pacmanUpdates = isNaN(pacmanCount) ? 0 : pacmanCount
                root.aurUpdates = isNaN(aurCount) ? 0 : aurCount
                root.packageUpdateSummary = `${root.pacmanUpdates} pacman | ${root.aurUpdates} AUR`
            }
        }
    }


    /* CPU Temperature */

    Process {
        id: cpuTempProc
        command: [
            "sh","-c",
            "for f in /sys/class/hwmon/hwmon*/temp*_input; do cat $f && exit; done"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const raw = parseInt(text.trim())
                if (isNaN(raw)) return

                const c = raw / 1000
                root.cpuTemp = `${Math.round(c)}°C`

                const min = 30
                const max = 95

                root.cpuTempPercent =
                    Math.max(0, Math.min(1,(c-min)/(max-min)))
            }
        }
    }


    /* Disk */

    Process {
        id: diskProc
        command: ["df","-h","/"]

        stdout: StdioCollector {
            onStreamFinished: {

                const lines = text.trim().split("\n")
                if (lines.length < 2) return

                const parts = lines[1].split(/\s+/)

                const used = parts[2]
                const total = parts[1]
                const percent = parseInt(parts[4]) / 100

                root.diskPercent = percent
                root.diskUsage = `${used}/${total}`
            }
        }
    }


    /* Swap */

    Process {
        id: swapProc
        command: ["sh","-c","free -m | grep Swap"]

        stdout: StdioCollector {
            onStreamFinished: {

                const parts = text.trim().split(/\s+/)
                if (parts.length < 3) return

                const total = parseInt(parts[1])
                const used = parseInt(parts[2])

                root.swapPercent = used / total
                root.swapUsage = `${used}/${total} MB`
            }
        }
    }


    /* IP */

    Process {
        id: ipProc
        command: ["sh","-c","hostname -I | awk '{print $1}'"]

        stdout: StdioCollector {
            onStreamFinished: root.ipAddress = text.trim()
        }
    }


    /* Process Count */

    Process {
        id: procCountProc
        command: ["sh","-c","ps -e --no-headers | wc -l"]

        stdout: StdioCollector {
            onStreamFinished: root.runningProcesses = parseInt(text.trim())
        }
    }


    /* Logged Users */

    Process {
        id: loggedUsersProc
        command: ["who","-q"]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                if (lines.length > 0)
                    root.loggedInUsers =
                        parseInt(lines[lines.length-1].replace("# users=",""))
            }
        }
    }


    /* Keyboard Layout */

    Process {
        id: keyboardLayoutProc
        command: [
            "sh","-c",
            "hyprctl devices -j | jq -r '.keyboards[] | .layout' | head -n1"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const layout = text.trim()
                if (layout)
                    root.keyboardLayout = layout
            }
        }
    }


    /* OS Info */

    Process {
        running: true
        command: [
            "sh","-c",
            "source /etc/os-release && echo \"$PRETTY_NAME|$ID\""
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split("|")
                root.osName = parts[0]
                root.osIcon = root.osIcons[parts[1]] || ""
            }
        }
    }


    /* Quickshell Version */

    Process {
        running: true
        command: ["qs","--version"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.qsVersion =
                    text.trim().split(',')[0]
                    .replace("quickshell ","")
            }
        }
    }


    /* Static system info */

    Process {
        running: true
        command: ["whoami"]

        stdout: StdioCollector {
            onStreamFinished: root.username = text.trim()
        }
    }

    Process {
        running: true
        command: ["hostname"]

        stdout: StdioCollector {
            onStreamFinished: root.hostname = text.trim()
        }
    }

    Process {
        running: true
        command: ["uname","-r"]

        stdout: StdioCollector {
            onStreamFinished: root.kernelVersion = text.trim()
        }
    }

    Process {
        running: true
        command: ["uname","-m"]

        stdout: StdioCollector {
            onStreamFinished: root.architecture = text.trim()
        }
    }

}
