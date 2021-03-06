expect = require('chai').expect
path = require 'path'

EasyConfiguration = require '../../../lib/EasyConfiguration'
Extension = require '../../../lib/Extension'

dir = path.normalize(__dirname + '/../../data')

configuration = null

describe 'EasyConfiguration', ->

	beforeEach( ->
		configuration = new EasyConfiguration("#{dir}/config.json")
	)

	describe '#constructor()', ->

		it 'should load configuration with relative path', ->
			configuration = new EasyConfiguration('../../data/config.json')
			configuration.load()
			expect(configuration.parameters).to.be.an.instanceof(Object)

	describe '#load()', ->

		it 'should return loaded configuration without parameters', ->
			expect(configuration.load()).to.be.eql({})

		it 'should throw an error with information about circular reference', ->
			configuration = new EasyConfiguration("#{dir}/circular.json")
			expect( -> configuration.load()).to.throw(Error, 'Found circular reference in parameters first, second, third, other.inner.fourth.')

	describe '#addSection()', ->

		it 'should return instance of newly registered section', ->
			expect(configuration.addSection('newSection')).to.be.an.instanceof(Extension)

		it 'should throw exception if section with reserved name is trying to register', ->
			expect( ->
				configuration.addSection('includes')
				configuration.addSection('parameters')
			).to.throw(Error)

	describe '#getParameter()', ->

		beforeEach( ->
			configuration.load()
		)

		it 'should throw an error for unknown parameter', ->
			expect( -> configuration.getParameter('unknown')).to.throw(Error, 'Parameter unknown is not defined.')

		it 'should return parameter', ->
			expect(configuration.getParameter('base')).to.be.equal('./www')

		it 'should return parameter from not first depth', ->
			expect(configuration.getParameter('paths.cdn')).to.be.equal('./cdn/data')

		it 'should return parameter pointing to other parameter', ->
			expect(configuration.getParameter('paths.lang')).to.be.equal('./www/lang')
			expect(configuration.getParameter('paths.translator')).to.be.equal('./www/lang/translator.js')

		it 'should return parameter pointing to other parameter from included file', ->
			expect(configuration.getParameter('paths.videos')).to.be.equal('./www/videos')

		it 'should return object of parameters', ->
			expect(configuration.getParameter('paths')).to.be.eql(
				cdn: './cdn/data'
				lang: './www/lang'
				translator: './www/lang/translator.js'
				images: './www/images'
				videos: './www/videos'
			)

		it 'should not expand parameters list in configuration', ->
			expect(configuration.getParameter('pathsToCaching')).to.be.equal('%cached%')

	describe 'sections', ->

		it 'should throw an error for unknown section', ->
			configuration = new EasyConfiguration("#{dir}/unknownSection")
			expect( -> configuration.load()).to.throw(Error, 'Found section unknown but there is no coresponding extension.')

		it 'should load data of section', ->
			configuration = new EasyConfiguration("#{dir}/advanced")
			configuration.addSection('application')
			expect(configuration.load()).to.be.eql(
				application:
					path: './www'
					data: [
						'./cdn/data'
						'./www/lang'
						'./www/lang/translator.js'
						'./www/images'
						'./www/videos'
					]
			)

		it 'should load data from section with defaults', ->
			configuration = new EasyConfiguration("#{dir}/advanced")
			section = configuration.addSection('application')
			section.loadConfiguration = ->
				config = @getConfig(
					data: []
					run: true
					favicon: null
					cache: '%base%/temp/cache'
				)
				for _path, i in config.data
					config.data[i] =
						path: _path
				return config
			expect(configuration.load()).to.be.eql(
				application:
					path: './www'
					data: [
						{path: './cdn/data'}
						{path: './www/lang'}
						{path: './www/lang/translator.js'}
						{path: './www/images'}
						{path: './www/videos'}
					]
					run: true
					favicon: null
					cache: './www/temp/cache'
			)

	describe 'environments', ->

		it 'should load data from base environment section', ->
			configuration = new EasyConfiguration("#{dir}/environments")
			configuration.load()
			expect(configuration.parameters).to.be.eql(
				database:
					host: '127.0.0.1'
					database: 'db'
					user: 'root'
					password: 'qwerty'
			)

		it 'should load data from different environment section', ->
			configuration = new EasyConfiguration("#{dir}/environments", 'development')
			configuration.load()
			expect(configuration.parameters).to.be.eql(
				database:
					host: '127.0.0.1'
					database: 'db'
					user: 'root'
					password: 'toor'
			)

		it 'should load data from local environment section without common section', ->
			configuration = new EasyConfiguration("#{dir}/environmentsNoCommon", 'local')
			configuration.load()
			expect(configuration.parameters).to.be.eql(
				database:
					password: 'toor'
			)

	describe '#addConfig()', ->

		it 'should add more config files', ->
			configuration = new EasyConfiguration

			configuration.addConfig('../../data/environmentsNoCommon', 'local')
			configuration.addConfig('../../data/environments', 'production')
			configuration.load()

			expect(configuration.parameters).to.be.eql(
				database:
					password: 'qwerty'
					host: '127.0.0.1'
					database: 'db'
					user: 'root'
			)