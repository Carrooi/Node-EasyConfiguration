path = require 'path'
fs = require 'fs'
Extension = require './Extension'

class EasyConfiguration


	fileName: null

	reserved: ['includes', 'parameters']

	extensions: {}

	_parameters: {}

	parameters: {}

	data: null


	constructor: (fileName) ->
		@fileName = path.resolve(fileName)


	addSection: (name) ->
		return @addExtension(name, new Extension)


	addExtension: (name, extension) ->
		if @reserved.indexOf(name) != -1
			throw new Error 'Extension\'s name ' + name + ' is reserved.'

		extension.setConfigurator(@)

		@extensions[name] = extension
		return @extensions[name]


	load: ->
		if @data == null
			config = @loadConfig(@fileName)

			@_parameters = config._parameters
			@parameters = config.parameters

			config.data = @parse(config.data)

			@data = config.data

		return @data


	loadConfig: (file) ->
		if !fs.existsSync(file)
			throw new Error 'Config file ' + file + ' does not exists.'

		data =
			includes: []
			_parameters: {}
			parameters: {}
			data: JSON.parse(fs.readFileSync(file))

		if typeof data.data.includes != 'undefined'
			data.includes = data.data.includes
			delete data.data.includes

		if typeof data.data.parameters != 'undefined'
			data.parameters = data.data.parameters
			data._parameters = @parseParameters(data.parameters)
			delete data.data.parameters

		data = @prepare(data, file)

		return data


	parseParameters: (parameters, parent = null) ->
		result = {}

		if Object.prototype.toString.call(parameters) == '[object Object]'
			for name, value of parameters
				result = @merge(result, @parseParameters(value, if parent == null then name else parent + '.' + name))
		else
			result[parent] = parameters

		return result


	prepare: (data, parent) ->
		for file in data.includes
			file = path.resolve(path.dirname(parent), file)

			config = @loadConfig(file)

			data.includes = @merge(config.includes, data.includes)
			data.parameters = @merge(config.parameters, data.parameters)
			data._parameters = @merge(config._parameters, data._parameters)
			data.data = @merge(config.data, data.data)

		return data


	parse: (data) ->
		for name, section of @extensions
			if typeof data[name] == 'undefined' then data[name] = {}

		for name, section of data
			if typeof @extensions[name] == 'undefined'
				throw new Error 'Found section ' + name + ' but there is no coresponding extension.'

			@extensions[name].setData(section)

			data[name] = @extensions[name].loadConfiguration()
			data[name] = @expand(data[name])

		return data


	expand: (data) ->
		switch Object.prototype.toString.call(data)
			when '[object String]' then data = @expandParameter(data)
			when '[object Array]'
				for value, i in data
					data[i] = @expand(value)
			when '[object Object]'
				for i, value of data
					data[i] = @expand(value)

		return data


	expandParameter: (parameter) ->
		parameter = parameter.replace(/%([a-zA-Z\.]+)%/g, (match, param, offset, s) =>
			if typeof @_parameters[param] == 'undefined'
				throw new Error 'Parameter ' + param + ' is not defined.'

			return @_parameters[param]
		)
		return parameter


	merge: (left, right) ->
		type = Object.prototype.toString

		if type.call(left) != type.call(right)
			throw new Error 'Can not merge two different objects.'

		switch type.call(left)
			when '[object Array]'
				for value, i in right
					if left.indexOf(value) == -1
						left.push(value)
					else if type.call(value) == '[object Array]' || type.call(value) == '[object Object]'
						left[i] = @merge(left[i], value)
			when '[object Object]'
				for name, value of right
					if typeof left[name] == 'undefined'
						left[name] = value
					else if type.call(value) == '[object Array]' || type.call(value) == '[object Object]'
						left[name] = @merge(left[name], value)

		return left


module.exports = EasyConfiguration