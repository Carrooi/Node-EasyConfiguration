Helpers = require '/lib/Helpers'

dir = '/test/data'

describe 'Helpers', ->

	describe '#dirName()', ->

		it 'should return name of file\'s directory', ->
			expect(Helpers.dirName('/var/www/data/something.js')).to.be.equal('/var/www/data')

	describe '#normalizePath()', ->

		it 'should return normalized and resolved path', ->
			expect(Helpers.normalizePath('/var/www/../www/data/././../../www/data/something.js')).to.be.equal('/var/www/data/something.js')

	describe '#arrayIndexOf()', ->

		it 'should return index of needed item', ->
			expect(Helpers.arrayIndexOf([
				'one', 'two', 'three', 'four', 'five'
			], 'four')).to.be.equal(3)

		it 'should return minus one for not found item', ->
			expect(Helpers.arrayIndexOf(['one'], 'two')).to.be.equal(-1)

	describe '#clone()', ->

		it 'should clone array', ->
			original = ['one', 'two', 'three', 'four', 'five']
			cloned = Helpers.clone(original)
			expect(cloned).to.be.eql([
				'one', 'two', 'three', 'four', 'five'
			]).and.not.equal(original)

		it 'should clone object', ->
			original = {one: 'one', two: 'two', three: 'three', four: 'four', five: 'five'}
			cloned = Helpers.clone(original)
			expect(cloned).to.be.eql(
				one: 'one', two: 'two', three: 'three', four: 'four', five: 'five'
			).and.not.equal(original)
			original.three = 'test'
			expect(cloned.three).to.be.equal('three')

		it 'should clone advanced object', ->
			original = require("#{dir}/advanced.json")
			cloned = Helpers.clone(original)
			expect(cloned).to.be.eql(
				includes: ['./config.json']
				application:
					path: '%base%'
					data: [
						'%paths.cdn%'
						'%paths.lang%'
						'%paths.translator%'
						'%paths.images%'
						'%paths.videos%'
					]
			).and.not.equal(original)
			original.application.path = '/app'
			expect(cloned.application.path).to.be.equal('%base%')