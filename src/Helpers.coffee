class Helpers


	@dirName: (path) ->
		num = path.lastIndexOf('/')
		return path.substr(0, num)


	@normalizePath: (path) ->
		parts = path.split('/')

		result = []
		prev = null

		for part in parts
			if part == '.' || part == ''
				continue
			else if part == '..' && prev
				result.pop()
			else
				result.push(part)

			prev = part

		return '/' + result.join('/')


	@arrayIndexOf: (array, search) ->
		if typeof Array.prototype.indexOf != 'undefined'
			return array.indexOf(search)

		if array.length == 0
			return -1

		for element, i in array
			if element == search
				return i

		return -1


	@clone: (obj) ->
		_type = Object.prototype.toString

		switch _type.call(obj)
			when '[object Array]'
				result = []
				for value, key in obj
					if _type.call(value) in ['[object Array]', '[object Object]']
						result[key] = Helpers.clone(value)
					else
						result[key] = value
			when '[object Object]'
				result = {}
				for key, value of obj
					if _type.call(value) in ['[object Array]', '[object Object]']
						result[key] = Helpers.clone(value)
					else
						result[key] = value
			else
				return obj

		return result


module.exports = Helpers