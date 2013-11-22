merge = require 'recursive-merge'

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


module.exports = Helpers