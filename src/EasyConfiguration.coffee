merge = require 'recursive-merge'

Extension = require './Extension'
Helpers = require './Helpers'

isWindow = typeof window != 'undefined'

if !isWindow
	callsite = require 'callsite'
	path = require 'path'

class EasyConfiguration


	@PARAMETER_REGEXP: /%([a-zA-Z.-_]+)%/g


	files: null

	reserved: null

	extensions: null

	includes: null

	_parameters: null

	parameters: null

	data: null


	constructor: (_path = null, section = 'production') ->
		@files = {}
		@reserved = ['includes', 'parameters', 'common']
		@extensions = {}
		@includes = {}
		@_parameters = {}
		@parameters = {}

		if _path != null
			@addConfig(_path, section)


	addConfig: (_path, section = 'production') ->
		if _path[0] == '.' && isWindow
			throw new Error 'Relative paths to config files are not supported in browser.'

		if _path[0] == '.'
			stack = callsite()
			previous = if stack[1].getFileName() == __filename then stack[2] else stack[1]		# may be called from @constructor
			_path = path.join(path.dirname(previous.getFileName()), _path)

		if Helpers.arrayIndexOf(@reserved, section) == -1
			@reserved.push(section)

		@files[_path] = section


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
			config = {}
			for _path, section of @files
				config = @merge(@loadConfig(_path, section), config)

			data = @parse(config)

			@includes = data.files
			@parameters = data.parameters
			@data = data.sections

		return @data


	loadConfig: (file, section = 'production') ->
		data = require(file)
		data = Helpers.clone(data, false)

		if typeof data[section] != 'undefined' || typeof data.common != 'undefined'
			if typeof data.common != 'undefined'
				_data = data.common
				if typeof data[section] != 'undefined'
					_data = @merge(data[section], _data)
			else
				_data = data[section]

			data = _data

		if typeof data.includes != 'undefined'
			for include in data.includes
				_path = Helpers.normalizePath(Helpers.dirName(file) + '/' + include)
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

		if typeof actual == 'string'
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