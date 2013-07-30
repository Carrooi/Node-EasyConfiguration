(function () {

	var should = require('should');
	var EasyConfiguration = require('../lib/EasyConfiguration');
	var Extension = require('../lib/Extension');

	var configuration = new EasyConfiguration(__dirname + '/data/config.json');

	describe('EasyConfiguration', function() {

		beforeEach(function() {
			configuration.invalidate();
		});

		describe('#expandParameters', function() {
			it('should return expanded and flattened parameters', function() {
				configuration.expandParameters({
					one: 'one',
					two: '%one%',
					three: {
						four: '%one%, %two%',
						five: '%three.four%'
					},
					six: '%seven%',
					seven: '%three.five%'
				}).should.eql({
						one: 'one',
						two: 'one',
						'three.four': 'one, one',
						'three.five': 'one, one',
						six: 'one, one',
						seven: 'one, one'
					});
			});
		});

		describe('#loadConfig()', function() {
			it('should return parsed json file', function() {
				configuration.loadConfig(configuration.fileName).should.eql({
					includes: ['./other.json'],
					parameters: {
						base: './www',
						paths: {
							lang: '%base%/lang',
							translator: '%paths.lang%/translator.js',
							images: '%base%/images',
							videos: '%base%/videos'
						},
						cached: ['%paths.translator%']
					}
				});
			});
		});

		describe('#parse()', function() {
			it('should return expanded configuration', function() {
				var data = configuration.loadConfig(configuration.fileName);
				configuration.parse(data).should.eql({
					files: ["./other.json"],
					parameters: {
						base: './www',
						'paths.lang': './www/lang',
						'paths.translator': './www/lang/translator.js',
						'paths.images': './www/images',
						'paths.videos': './www/videos',
						cached: ['./www/lang/translator.js']
					},
					sections: {}
				});
			});

			it('should throw error if there is unregistered section', function() {
				var data = configuration.loadConfig(configuration.fileName);
				data.unregistered = {};
				(function() { configuration.parse(data); }).should.throw();
				delete data.unregistered;
			});

			it('should return object with data of newly registered section', function() {
				var data = {
					parameters: {},
					newSection: {something: 'hello'}
				};
				configuration.addSection('newSection');
				configuration.parse(data).should.eql({
					files: [],
					parameters: {},
					sections: {
						newSection: {something: 'hello'}
					}
				});
				configuration.removeExtension('newSection');
			});
		});

		describe('#load()', function() {
			it('should return loaded configuration without parameters', function() {
				configuration.load().should.eql({});
			});
		});

		describe('#addSection()', function() {
			it('should return instance of newly registered section', function() {
				configuration.addSection('newSection').should.be.an.instanceof(Extension);
			});

			it('should throw exception if section with reserved name is trying to register', function() {
				(function() {
					configuration.addSection('includes');
					configuration.addSection('parameters');
				}).should.throw();
			});
		});

	});

})();