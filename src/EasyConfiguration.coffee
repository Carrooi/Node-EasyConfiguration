merge = require 'recursive-merge'
path = require 'path'
Extension = require './Extension'
Helpers = require './Helpers'

class EasyConfiguration


	fileName: null

	reserved: ['includes', 'parameters']

	extensions: {}

	files: []

	parameters: {}

	data: null


	constructor: (@fileName) ->


	addSection: (name) ->
		return @addExtension(name, new Extension)


	addExtension: (name, extension) ->
		if @reserved.indexOf(name) != -1
			throw new Error 'Extension\'s name ' + name + ' is reserved.'

		extension.configurator = @

		@extensions[name] = extension
		return @extensions[name]


	removeExtension: (name) ->
		if typeof @extensions[name] == 'undefined'
			throw new Error 'Extension with name ' + name + ' was not found.'

		delete @extensions[name]
		@invalidate()
		return @


	invalidate: ->
		@data = null
		return @


	load: ->
		if @data == null
			config = @loadConfig(@fileName)
			data = @parse(config)

			@files = data.files
			@parameters = data.parameters
			@data = data.sections

		return @data



	loadConfig: (file) ->
		data = require(file)

		if typeof data.includes != 'undefined'
			for include in data.includes
				_path = path.normalize(path.dirname(file) + '/' + include)
				data = @merge(data, @loadConfig(_path))

		return data


	parse: (data) ->
		result =
			files: []
			parameters: {}
			sections: {}

		if typeof data.includes != 'undefined'
			result.files = data.includes

		if typeof data.parameters != 'undefined'
			result.parameters = @expandParameters(data.parameters)

		for name, section of @extensions
			if typeof data[name] == 'undefined' then data[name] = {}

		sections = data
		if typeof sections.parameters != 'undefined' then delete sections.parameters
		if typeof sections.includes != 'undefined' then delete sections.includes

		for name, section of sections
			if typeof @extensions[name] == 'undefined'
				throw new Error 'Found section ' + name + ' but there is no coresponding extension.'

			@extensions[name].data = section

			section = @extensions[name].loadConfiguration()
			section = Helpers.expandWithParameters(section, result.parameters)
			section = @extensions[name].afterCompile(section)

			result.sections[name] = section

		return result


	expandParameters: (parameters) ->
		parameters = Helpers.stringifyParameters(parameters)
		parameters = Helpers.expandParameters(parameters)
		parameters = Helpers.objectifyParameters(parameters)
		return parameters


	merge: (left, right) ->
		return merge(left, right)


module.exports = EasyConfiguration