merge = require 'recursive-merge'

Extension = require './Extension'
Helpers = require './Helpers'

isWindow = typeof window != 'undefined'

if !isWindow
	callsite = require 'callsite'
	path = require 'path'

class EasyConfiguration


	@PARAMETER_REGEXP: /%([a-zA-Z.-_]+)%/g


	fileName: null

	reserved: null

	env: null

	extensions: null

	files: null

	_parameters: null

	parameters: null

	data: null


	constructor: (@fileName) ->
		@reserved = ['includes', 'parameters', 'common']
		@extensions = {}
		@files = []
		@_parameters = {}
		@parameters = {}

		if @fileName[0] == '.' && isWindow
			throw new Error 'Relative paths to config files are not supported in browser.'

		if @fileName[0] == '.'
			stack = callsite()
			@fileName = path.join(path.dirname(stack[1].getFileName()), @fileName)


	getEnvironment: ->
		if @env == null
			@env = if process?env?NODE_ENV? then process.env.NODE_ENV else 'production'

		return @env


	setEnvironment: (@env) ->
		@reserved.push(@env)


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
			config = @loadConfig(@fileName, true)
			data = @parse(config)

			@files = data.files
			@parameters = data.parameters
			@data = data.sections

		return @data


	loadConfig: (file, main = false) ->
		data = require(file)
		data = Helpers.clone(data, false)

		env = @getEnvironment()

		if main && (typeof data[env] != 'undefined' || typeof data.common != 'undefined')
			if typeof data.common != 'undefined'
				_data = data.common
				if typeof data[env] != 'undefined'
					_data = @merge(data[env], _data)
			else
				_data = data[env]

			data = _data

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
					parameters[name] = param.replace(EasyConfiguration.PARAMETER_REGEXP, (match, variable) =>
						return @_getParameter(variable, [name])
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


	_getParameter: (parameter, previous = []) ->
		parts = parameter.split('.')
		actual = @_parameters
		for part in parts
			if typeof actual[part] == 'undefined'
				throw new Error "Parameter #{parameter} is not defined."

			actual = actual[part]

		if Helpers.arrayIndexOf(previous, parameter) != -1
			s = if previous.length == 1 then '' else 's'
			previous = previous.join(', ')
			throw new Error "Found circular reference in parameter#{s} #{previous}."

		previous.push(parameter)

		actual = actual.replace(EasyConfiguration.PARAMETER_REGEXP, (match, param) =>
			return @_getParameter(param, previous)
		)

		return actual


	getParameter: (parameter) ->
		return @_getParameter(parameter)


	merge: (left, right) ->
		right = Helpers.clone(right, false)
		return merge(left, right)


module.exports = EasyConfiguration