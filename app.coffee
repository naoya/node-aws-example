aws = require 'aws-lib'
confy = require 'confy'
express = require "express"
EventEmitter = require('events').EventEmitter
_ = require 'underscore'

app = module.exports = express.createServer()

app.configure ->
  app.set "views", __dirname + "/views"
  app.set "view engine", "ejs"
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use express.compiler
    src: __dirname + "/public"
    enable: [ "sass" ]
  app.use app.router
  app.use express.static __dirname + "/public"

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

class Amazon extends EventEmitter
  constructor: (@accessKey, @secretKey, @associateId) ->
    @api = aws.createProdAdvClient(
      @accessKey, @secretKey, @associateId,
      region: "JP"
      host: 'ecs.amazonaws.jp'
    )

  search: (query) ->
    self = @
    @api.call "ItemSearch",
      SearchIndex: "Books"
      Title: query
      ItemPage: 1
      ResponseGroup: 'Medium'
      (result) ->
        self.emit 'response', result

confy.get 'ecs.amazonaws.jp', (err, config) ->
  io = require('socket.io').listen app

  amazon = new Amazon(
    config.access_key,
    config.secret_key,
    config.associate_id,
  )

  io.sockets.on 'connection', (socket) ->
    socket.on 'query', (query) ->
      amazon.search query

    amazon.on 'response', (result) ->
      if result.Items.TotalResults > 0
        items = result.Items.Item
        items = [ items ] if not _(items).isArray()

        socket.emit 'items', _(items).map (item) ->
          asin: item.ASIN
          title: item.ItemAttributes.Title
          image: item.LargeImage?.URL
      else
        socket.emit 'items', []