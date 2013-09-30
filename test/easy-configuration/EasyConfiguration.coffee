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

	describe '#expandParameters()', ->
		it 'should return expanded and flattened parameters', ->
			expect(configuration.expandParameters(
				one: 'one'
				two: '%one%'
				three:
					four: '%one%, %two%'
					five: '%three.four%'
				six: '%seven%'
				seven: '%three.five%'
			)).to.be.eql(
				one: 'one'
				two: 'one'
				'three.four': 'one, one'
				'three.five': 'one, one'
				six: 'one, one'
				seven: 'one, one'
			)

	describe '#loadConfig()', ->
		it 'should return parsed json file', ->
			expect(configuration.loadConfig(configuration.fileName)).to.be.eql(
				includes: ['./other.json']
				parameters:
					base: './www'
					paths:
						lang: '%base%/lang'
						translator: '%paths.lang%/translator.js'
						images: '%base%/images'
						videos: '%base%/videos'
					cached: ['%paths.translator%']
			)

	describe '#parse()', ->
		it 'should return expanded configuration', ->
			data = configuration.loadConfig(configuration.fileName)
			expect(configuration.parse(data)).to.be.eql(
				files: ["./other.json"]
				parameters:
					base: './www'
					'paths.lang': './www/lang'
					'paths.translator': './www/lang/translator.js'
					'paths.images': './www/images'
					'paths.videos': './www/videos'
					cached: ['./www/lang/translator.js']
				sections: {}
			)

		it 'should throw error if there is unregistered section', ->
			data = configuration.loadConfig(configuration.fileName)
			data.unregistered = {}
			expect( -> configuration.parse(data) ).to.throw(Error)
			delete data.unregistered

		it 'should return object with data of newly registered section', ->
			data =
				parameters: {}
				newSection: {something: 'hello'}

			configuration.addSection('newSection')
			expect(configuration.parse(data)).to.be.eql(
				files: []
				parameters: {}
				sections:
					newSection: {something: 'hello'}
			)

			configuration.removeExtension('newSection')

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