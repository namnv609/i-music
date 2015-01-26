$ ->
    socket = io.connect 'http://127.0.0.1:6969'
    socket.on 'welcome', (data)->
        console.log data
    socket.on 'download-error', (err)->
        alert 'Error when download file. Please try again later!'
    socket.on 'download-done', (info)->
        songDetail = """
            <li data-client='#{info.ip}'>
                #{info.name}
                <span>#{info.artist}</span>
            </li>
                    """
        $ songDetail
            .hide().appendTo '#playlist ul'
            .slideDown 1000

        $ '#accept-btn'
            .text 'Accept'
            .prop 'disabled', false

    $ '#search'
        .on 'click', ->
            searchSong()
            false
    $ '#song-name'
        .on 'keypress', (e) ->
            searchSong() if e.keyCode is 13
    $ '#song-name'
        .on 'click focus', ->
            $ @
                .select()

    $ document
        .on 'click', '.song-item', ->
            $item = $ @
            itemUrl = $item.prop 'href'
            yqlStatement = "SELECT * FROM html WHERE url='#{itemUrl}' AND xpath='//div[@class=\"download\"]//a'"

            $.queryYQL yqlStatement, (data) ->
                if data.query.count is 1
                    $ '#player'
                        .html "<audio autoplay repeat controls><source src='#{data.query.results.a.href}' type='audio/mpeg' /></audio>"
                    $item.closest '#results'
                        .find 'p'
                        .removeClass 'playing'
                    $item.parent().addClass 'playing'
                else
                    alert 'Error. Please try again later'

            false

    $ '#accept-btn'
        .on 'click', ->
            songUrl = $ "#player audio source"
                .prop 'src'
            songName = $ '.playing a'
                .text()
            songArtist = $ '.playing span'
                .text()

            if songUrl and songUrl isnt ''
                socket.emit 'download-song', 
                    url : songUrl
                    name : songName
                    artist : songArtist

                $ @
                    .text 'Downloading...'
                    .prop "disabled", true
            else
                alert 'Please select a song to download it.'

    searchSong = ->
        songName = encodeURIComponent $('#song-name').val().trim()
        searchUrl = 'http://m.nhaccuatui.com/tim-kiem?q='
        if songName isnt ''
            yqlStatement = "SELECT * FROM html WHERE url='#{searchUrl + songName}' AND xpath='//div[@class=\"row bgmusic\"]'"
            $ '#results'
                .html 'Loading. Please wait...'

            $.queryYQL yqlStatement, (data) ->
                $ '#results'
                    .empty()

                $.each data.query.results.div, (index, item) ->
                    $ '#results'
                        .append "<p><a class='song-item' href='#{item.h3.a.href}'>#{item.h3.a.content}</a><span>#{item.p.content}</span></p>"
        else
            $ '#song-name'
                .focus()
