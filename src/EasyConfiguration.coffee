merge = require 'recursive-merge'

Extension = require './Extension'
Helpers = require './Helpers'

class EasyConfiguration


	fileName: null

	reserved: ['includes', 'parameters']

	extensions: null

	files: null

	_parameters: null

	parameters: null

	data: null


	constructor: (@fileName) ->
		@extensions = {}
		@files = []
		@_parameters = {}
		@parameters = {}


	addSection: (name) ->
		return @addExtension(name, new Extension)


	addExtension: (name, extension) ->
		if Helpers.arrayIndexOf(@reserved, name) != -1
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
		data = Helpers.clone(data, false)

		if typeof data.includes != 'undefined'
			for include in data.includes
				path = Helpers.normalizePath(Helpers.dirName(file) + '/' + include)
				data = @merge(data, @loadConfig(path))

		return data


	parse: (data) ->
		result =
			files: []
			parameters: {}
			sections: {}

		if typeof data.includes != 'undefined'
			result.files = data.includes

		if typeof data.parameters != 'undefined'
			@_parameters = data.parameters
			result.parameters = @expandParameters(data.parameters)

		for name, section of @extensions
			if typeof data[name] == 'undefined' then data[name] = {}

		sections = data
		if typeof sections.parameters != 'undefined' then delete sections.parameters
		if typeof sections.includes != 'undefined' then delete sections.includes

		for name, section of sections
			if sections.hasOwnProperty(name) && name not in ['__proto__']
				if typeof @extensions[name] == 'undefined'
					throw new Error 'Found section ' + name + ' but there is no coresponding extension.'

				@extensions[name].data = section

				section = @extensions[name].loadConfiguration()
				section = @expandParameters(section)
				section = @extensions[name].afterCompile(section)

				result.sections[name] = section

		return result


	expandParameters: (parameters) ->
		_type = Object.prototype.toString

		parse = (name, param) =>
			switch _type.call(param)
				when '[object String]'
					parameters[name] = param.replace(/%([a-zA-Z.-_]+)%/g, (match, variable) =>
						return @getParameter(variable)
					)
				when '[object Object]', '[object Array]'
					parameters[name] = @expandParameters(param)
				else
					parameters[name] = param

		type = _type.call(parameters)
		switch type
			when '[object Object]'
				for name, param of parameters
					parse(name, param)
			when '[object Array]'
				for param, name in parameters
					parse(name, param)
			else
				throw new Error "Can not parse #{type} parameters."


		return parameters


	getParameter: (parameter) ->
		parts = parameter.split('.')
		actual = @_parameters
		for part in parts
			if typeof actual[part] == 'undefined'
				throw new Error "Parameter #{parameter} is not defined."

			actual = actual[part]

		return actual


	merge: (left, right) ->
		right = Helpers.clone(right, false)
		return merge(left, right)


module.exports = EasyConfiguration