EasyConfiguration = require './EasyConfiguration'


config = new EasyConfiguration('../config.json')
packages = config.addSection('packages')

defaults =
	items: []

defaultsItems =
	name: ""
	allowed: true

packages.loadConfiguration = ->
	config = @getConfig(defaults)

	for value, i in config.items
		config.items[i] = this.configurator.merge(value, defaultsItems)

	return config

data = config.load().packages

console.log data