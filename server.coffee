http = require 'http'
httpGet = require 'http-get'
socketIO = require 'socket.io'
icecast = require 'icecast-stack'
fileSystem = require 'fs'

port = process.env.PORT || 6969
ip = process.env.IP || '127.0.0.1'
streamUrl = 'http://localhost:8000/stream'
stream = icecast.createReadStream streamUrl

stream.on 'connect', ->
    console.log 'Stream connected'

stream.on 'metadata', (meta) ->
    songTitle = icecast.parseMetadata meta
        .StreamTitle
    console.log 'Playing %s', songTitle 

server = http.createServer().listen port, ip, ->
    console.log 'Server is running at %s:%s', ip, port

io = socketIO.listen server

io.sockets.on 'connection', (socket)->
    socket.emit 'welcome', 'Welcome you :D'
    clientIP = socket.request.connection.remoteAddress

    socket.on 'download-song', (songInfo) ->
        console.log 'Download song: %s with IP %s', songInfo.name, clientIP
        httpGet.get
            url : songInfo.url
        , "./downloads/#{clientIP.replace(/\./g, '')}.mp3", (err, res) ->
            if err
                socket.emit 'download-error', err

            downloadDone 
                ip: clientIP
                name : songInfo.name
                artist : songInfo.artist

            console.log 'Done'

downloadDone = (data) ->
    io.sockets.emit 'download-done', data
    fileSystem.appendFile './list.txt', "./downloads/#{data.ip.replace(/\./g, '')}.mp3", ->
        console.log 'Update playlist done.'