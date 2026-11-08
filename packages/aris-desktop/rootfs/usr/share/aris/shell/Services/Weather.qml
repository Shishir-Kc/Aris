pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Current weather and a three-day forecast from wttr.in. With no location set
// wttr.in places you by IP address.
Singleton {
  id: root

  property string location: ""
  property bool imperial: false

  property bool ready: false
  property string place: ""
  property string temp: ""
  property string feels: ""
  property string desc: ""
  property string glyph: "󰖐"
  property string humidity: ""
  property string wind: ""
  property var days: []

  onLocationChanged: refresh()
  onImperialChanged: refresh()

  function glyphFor(code, night) {
    var c = parseInt(code, 10)
    if (c === 113) return night ? "󰖔" : "󰖙"
    if (c === 116) return night ? "󰼱" : "󰖕"
    if (c === 119 || c === 122) return "󰖐"
    if ([143, 248, 260].indexOf(c) !== -1) return "󰖑"
    if ([200, 386, 389, 392, 395].indexOf(c) !== -1) return "󰖓"
    if ([179, 182, 185, 227, 230, 317, 320, 323, 326, 329, 332, 335, 338, 350, 362, 365, 368, 371, 374, 377].indexOf(c) !== -1) return "󰖘"
    if ([299, 302, 305, 308, 356, 359].indexOf(c) !== -1) return "󰖖"
    return "󰖗"
  }

  function parse(text) {
    try {
      var j = JSON.parse(text)
      var cur = j.current_condition[0]
      var hour = new Date().getHours()
      var night = hour < 6 || hour >= 19
      root.temp = (root.imperial ? cur.temp_F + "°F" : cur.temp_C + "°C")
      root.feels = (root.imperial ? cur.FeelsLikeF + "°F" : cur.FeelsLikeC + "°C")
      root.desc = cur.weatherDesc && cur.weatherDesc[0] ? cur.weatherDesc[0].value.trim() : ""
      root.glyph = glyphFor(cur.weatherCode, night)
      root.humidity = cur.humidity + "%"
      root.wind = root.imperial ? cur.windspeedMiles + " mph" : cur.windspeedKmph + " km/h"
      var area = j.nearest_area && j.nearest_area[0]
      root.place = area ? area.areaName[0].value + (area.country ? ", " + area.country[0].value : "") : ""
      var out = []
      for (var i = 0; i < (j.weather || []).length; i++) {
        var d = j.weather[i]
        var mid = d.hourly && d.hourly[4] ? d.hourly[4].weatherCode : 116
        out.push({
          date: d.date,
          hi: root.imperial ? d.maxtempF + "°" : d.maxtempC + "°",
          lo: root.imperial ? d.mintempF + "°" : d.mintempC + "°",
          glyph: glyphFor(mid, false)
        })
      }
      root.days = out
      root.ready = true
    } catch (e) {
      // Keep the last good reading; wttr.in is sometimes busy.
    }
  }

  function refresh() {
    if (fetcher.running) return
    var loc = encodeURIComponent(root.location.trim()).replace(/%2C/gi, ",")
    fetcher.command = ["curl", "-sf", "--max-time", "15", "https://wttr.in/" + loc + "?format=j1"]
    fetcher.running = true
  }

  Process {
    id: fetcher
    stdout: StdioCollector { onStreamFinished: root.parse(text) }
  }

  Component.onCompleted: Qt.callLater(refresh)

  Timer { interval: 20 * 60 * 1000; running: true; repeat: true; onTriggered: root.refresh() }
  // Retry soon after login, when the network may not be up yet.
  Timer { interval: 60 * 1000; running: !root.ready; repeat: true; onTriggered: root.refresh() }
}
