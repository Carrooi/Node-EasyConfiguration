expect = require('chai').expect
path = require 'path'

EasyConfiguration = require '../../lib/EasyConfiguration'
Extension = require '../../lib/Extension'

file = path.resolve(__dirname + '/../data/config.json')
configuration = null

describe 'EasyConfiguration', ->

	beforeEach( ->
		configuration = new EasyConfiguration(file)
	)

	describe '#load()', ->
		it 'should return loaded configuration without parameters', ->
			expect(configuration.load()).to.be.eql({})

	describe '#addSection()', ->
		it 'should return instance of newly registered section', ->
			expect(configuration.addSection('newSection')).to.be.an.instanceof(Extension)

		it 'should throw exception if section with reserved name is trying to register', ->
			expect( ->
				configuration.addSection('includes')
				configuration.addSection('parameters')
			).to.throw(Error)