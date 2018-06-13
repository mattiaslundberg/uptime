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

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

// import socket from "./socket"

const elmDiv = document.getElementById('elm-main');
const elmApp = Elm.App.embed(elmDiv);

elmApp.ports.setToken.subscribe(([token, userId]) => {
  localStorage.setItem("uptime-token", token)
  localStorage.setItem("uptime-userId", userId)
})

elmApp.ports.getToken.subscribe(() => {
  const token = localStorage.getItem("uptime-token")
  const userId = localStorage.getItem("uptime-userId")

  if (token && userId) {
    elmApp.ports.jsGetToken.send({
      token: token,
      userId: +userId,
    })
  } else {
    elmApp.ports.jsPromptAuth.send(true)
  }
})
