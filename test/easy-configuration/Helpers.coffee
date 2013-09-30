expect = require('chai').expect

Helpers = require '../../lib/Helpers'


describe 'Helpers', ->

	describe '#stringifyParameters()', ->
		it 'should return flattened object', ->
			expect(Helpers.stringifyParameters(
				one:
					two: 'two'
					three: 'three'
					four:
						five: 'five'
						six: 'six'
					seven: 'seven'
			)).to.be.eql(
				'one.two': 'two'
				'one.three': 'three'
				'one.four.five': 'five'
				'one.four.six': 'six'
				'one.seven': 'seven'
			)

	describe '#expandParameters()', ->
		it 'should expand variables in flattened object', ->
			expect(Helpers.expandParameters(
				one: 'one'
				two: '%one%'
				'three.one': '%two%'
				four: '%three.one%'
			)).to.be.eql(
				one: 'one'
				two: 'one'
				'three.one': 'one'
				four: 'one'
			)

	describe '#expandWithParameters()', ->
		it 'should expand configuration section with flattened parameters', ->
			expect(Helpers.expandWithParameters(
				someVariableInSection: '%one.two.three%'
			,
				'one.two.three': 'hello'
			)).to.be.eql(
				someVariableInSection: 'hello'
			)