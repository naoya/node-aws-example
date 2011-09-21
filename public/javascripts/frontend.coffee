$ ->
  $('img#loader').hide()

  $('#results a').live 'click', ->
    location.href = '#asin'
    item = $(this).data 'item'
    $('#asin h1').text item.asin
    $('#asin #content h2').text item.title
    $('#asin #content img').attr 'src', item.image

  socket = io.connect 'http://localhost:3000'
  socket.on 'items', (items) ->
    ul = $('#results')
    ul.children().remove()
    $('img#loader').hide()
    for item in items
      json = JSON.stringify item
      ul.append("<li><a data-item='#{json}'>#{item.title}</a></li>")
    ul.listview 'refresh'

  preword = ""
  setInterval ->
    w = $('#search').val()
    if w isnt preword
      preword = w
      $('img#loader').show()
      socket.emit 'query', w
  , 2000
