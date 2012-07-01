express = require 'express'
faye = require 'faye'
stylus = require 'stylus'
fs = require 'fs'
glob = require 'glob'
converter = new (require('showdown').converter)()

app = module.exports = express.createServer()
app.configure ->
	this.set 'view engine', 'jade'
	this.use express.bodyParser()
	this.use express.methodOverride()
	this.use stylus.middleware src: __dirname + '/public'
	this.use express.static __dirname + '/public'

app.configure 'development', ->
	this.use express.errorHandler dumpExceptions: true, showStack: true

app.configure 'production', () ->
	this.use express.errorHandler()

bayeux = new faye.NodeAdapter
	mount: '/faye',
	timeout: 45

app.get '/', (req, res) ->
	glob 'docsrc/*.md', (err, files) ->
		items = files.map (file) ->
			file.replace(/^docsrc\//, '').replace /\.md$/, ''
		res.render 'index', {items: items}

app.get '/show/:name', (req, res) ->
	content = converter.makeHtml fs.readFileSync "docsrc/#{req.params.name}.md", 'utf-8'
	res.render 'show', content: content


fs.watch './docsrc', {persistent: false}, (evt, filename) ->
	console.log arguments
	bayeux.getClient().publish '/messages',
		event: evt,
		filename: filename.replace /\.md$/, ''

bayeux.attach app
app.listen 3000
