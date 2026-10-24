// PoliOS default layout: one bottom panel (Windows-like) + PoliOS wallpaper.
// Same mechanism Plasma's own Breeze look-and-feel uses; also works on Plasma 6.

var panel = new Panel
panel.location = "bottom"
panel.height = 2 * Math.floor(gridUnit * 2.5 / 2)

var kickoff = panel.addWidget("org.kde.plasma.kickoff")
kickoff.currentConfigGroup = ["Shortcuts"]
kickoff.writeConfig("global", "Alt+F1")
kickoff.currentConfigGroup = ["General"]
kickoff.writeConfig("icon", "/usr/share/polios-assets/logo.svg")

var tasks = panel.addWidget("org.kde.plasma.icontasks")
tasks.currentConfigGroup = ["General"]
tasks.writeConfig("launchers", [
    "applications:mintinstall.desktop",
    "applications:org.kde.dolphin.desktop",
    "applications:org.gnome.Terminal.desktop",
    "applications:google-chrome.desktop",
    "applications:webeep-sync.desktop"
].join(","))

panel.addWidget("org.kde.plasma.marginsseparator")
panel.addWidget("org.kde.plasma.systemtray")
panel.addWidget("org.kde.plasma.digitalclock")
panel.addWidget("org.kde.plasma.showdesktop")

var desktopsArray = desktopsForActivity(currentActivity());
for (var j = 0; j < desktopsArray.length; j++) {
    var desktop = desktopsArray[j];
    desktop.wallpaperPlugin = "org.kde.image";
    desktop.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    desktop.writeConfig("Image", "file:///usr/share/polios-assets/background.png");
}
