const FERMO_LIVE = {
  socketPath: 'ws://' + window.location.host + '/__fermo/ws/live-reload'
}
FERMO_LIVE.socket = new window.WebSocket(FERMO_LIVE.socketPath)

const reloadPage = () => {
  window.location.reload()
}

FERMO_LIVE.socket.onopen = e => {
  FERMO_LIVE.socket.send('subscribe:live-reload:' + window.location.pathname)
}

FERMO_LIVE.socket.onmessage = (event) => {
  console.log('onmessage: ', event)
  if (event.data === 'reload') {
    reloadPage()
  }
}

FERMO_LIVE.socket.onclose = event => {
  if (event.wasClean) {
    console.log('onclose clean event:', event)
  } else {
    // TODO: Poll to try to reconnect
    console.log('onclose died event:', event)
  }
}

FERMO_LIVE.socket.onerror = error => {
  console.log('onerror error:', error)
}
