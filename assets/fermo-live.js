console.log('fermo-live')
const socketPath = 'ws://' + location.host + '/__fermo/ws/live-reload'
const socket = new WebSocket(socketPath)

socket.onopen = e => {
  console.log('onopen')
  socket.send('subscribe:live-reload:' + location.pathname)
}

socket.onmessage = ({data}) => {
  console.log('onmessage: ', event)
  if (data === 'reload') {
    location.reload()
  }
}

socket.onclose = event => {
  if (event.wasClean) {
    console.log('onclose clean event:', event)
  } else {
    // TODO: Poll to try to reconnect
    console.log('onclose died event:', event)
  }
}

socket.onerror = error => {
  console.log('onerror error:', error)
}
