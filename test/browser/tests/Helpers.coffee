Helpers = require '/lib/Helpers'


describe 'Helpers', ->

	describe '#dirName()', ->

		it 'should return name of file\'s directory', ->
			expect(Helpers.dirName('/var/www/data/something.js')).to.be.equal('/var/www/data')

	describe '#normalizePath()', ->
		it 'should return normalized and resolved path', ->
			expect(Helpers.normalizePath('/var/www/../www/data/././../../www/data/something.js')).to.be.equal('/var/www/data/something.js')