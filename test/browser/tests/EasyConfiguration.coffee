EasyConfiguration = require '/lib/EasyConfiguration'
Extension = require '/lib/Extension'

#dir =

configuration = null

describe 'EasyConfiguration', ->

	beforeEach( ->
		configuration = new EasyConfiguration("#{dir}/config.json")
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
					cache: './www/temp/cache'
			)