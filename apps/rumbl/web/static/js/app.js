// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
import "phoenix_html"

import socket from "./socket"
import Video from "./video"
import Player from "./player"

var videoElement = document.getElementById("video")
Video.init(socket, videoElement)

const helloDiv = document.getElementById('elm-hello')
const helloApp = Elm.Hello.embed(helloDiv)

const annotDiv = document.getElementById('elm-container')
if (annotDiv) {
  var annot = Elm.AnnotPane.embed(annotDiv)
  annot.ports.initSocket.send(`ws://localhost:4000/socket/websocket?token=${window.userToken}`)

  let videoId = videoElement.getAttribute("data-id")
  annot.ports.joinChannel.send(`videos:${videoId}`)

  annot.ports.reportPlaytime.subscribe(_ => {
    if (Player.player && Player.player.getCurrentTime) {
      annot.ports.playtime.send(Player.getCurrentTime())
    }
  })

  annot.ports.seek.subscribe(time => {
    Player.seekTo(time)
  })
}

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

// import socket from "./socket"
