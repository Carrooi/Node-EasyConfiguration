class Extension


	configurator: null

	data: null


	getConfig: (defaults = null) ->
		if @data == null
			@configurator.load()

		if defaults != null
			@data = @configurator.merge(@data, defaults)

		return @data


	loadConfiguration: ->
		return @getConfig()


	afterCompile: (data) ->
		return data


module.exports = Extension