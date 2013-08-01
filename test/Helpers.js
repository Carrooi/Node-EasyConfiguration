(function () {

	var should = require('should');
	var Helpers = require('../lib/Helpers');

	describe('Helpers', function() {

		describe('#dirName()', function() {
			it('should return name of file\'s directory', function() {
				Helpers.dirName('/var/www/data/something.js').should.equal('/var/www/data');
			});
		});

		describe('#normalizePath()', function() {
			it('should return normalized and resolved path', function() {
				Helpers.normalizePath('/var/www/../www/data/././../../www/data/something.js').should.equal('/var/www/data/something.js');
			});
		});

		describe('#stringifyParameters()', function() {
			it('should return flattened object', function() {
				Helpers.stringifyParameters({
					one: {
						two: 'two',
						three: 'three',
						four: {
							five: 'five',
							six: 'six'
						},
						seven: 'seven'
					}
				}).should.eql({
					'one.two': 'two',
					'one.three': 'three',
					'one.four.five': 'five',
					'one.four.six': 'six',
					'one.seven': 'seven'
				});
			});
		});

		describe('#expandParameters()', function() {
			it('should expand variables in flattened object', function() {
				Helpers.expandParameters({
					one: 'one',
					two: '%one%',
					'three.one': '%two%',
					four: '%three.one%'
				}).should.eql({
					one: 'one',
					two: 'one',
					'three.one': 'one',
					four: 'one'
				});
			});
		});

		describe('#expandWithParameters()', function() {
			it('should expand configuration section with flattened parameters', function() {
				Helpers.expandWithParameters({
					someVariableInSection: '%one.two.three%'
				}, {
					'one.two.three': 'hello'
				}).should.eql({
					someVariableInSection: 'hello'
				});
			});
		});

		describe.skip('#objectifyParameters()', function() {
			it('should transform flattened object to normal state', function() {

			});
		});

	});

})();