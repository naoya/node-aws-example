aws = require 'aws-lib'
confy = require 'confy'
express = require "express"

app = module.exports = express.createServer()

app.configure ->
  app.set "views", __dirname + "/views"
  app.set "view engine", "ejs"
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use express.compiler(
    src: __dirname + "/public"
    enable: [ "sass" ]
  )
  app.use app.router
  app.use express.static(__dirname + "/public")

app.configure "development", ->
  app.use express.errorHandler
    dumpExceptions: true
    showStack: true

app.configure "production", ->
  app.use express.errorHandler()

app.get "/", (req, res) ->
  res.render "index", title: "Amazon Search"

app.listen 3000
console.log "Express server listening on port %d in %s mode", app.address().port, app.settings.env

confy.get 'ecs.amazonaws.jp', (err, config) ->
  api = aws.createProdAdvClient(
    config.access_key,
    config.secret_key,
    config.associate_id,
    {
      region: "JP",
      host: 'ecs.amazonaws.jp'
    }
  )

  io = require('socket.io').listen app
  io.sockets.on 'connection', (socket) ->
    socket.on 'query', (query) ->
      api.call "ItemSearch",
        SearchIndex: "Books"
        Title: query
        ItemPage: 1
        ResponseGroup: 'Medium'
        (result) ->
          if result.Items.TotalResults == 1
            # FIXME
          else if result.Items.TotalResults > 1
            items = result.Items.Item.map (i) ->
              asin: i.ASIN
              title: i.ItemAttributes.Title
              image: i.LargeImage?.URL
            socket.emit 'items', items
          else
            socket.emit 'items', []
