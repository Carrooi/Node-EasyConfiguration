[![NPM version](https://badge.fury.io/js/easy-configuration.png)](http://badge.fury.io/js/easy-configuration)
[![Dependency Status](https://gemnasium.com/sakren/node-easy-configuration.png)](https://gemnasium.com/sakren/node-easy-configuration)
[![Build Status](https://travis-ci.org/sakren/node-easy-configuration.png?branch=master)](https://travis-ci.org/sakren/node-easy-configuration)

# Easy Configuration

Simply extensible loader for json config files. This package is inspired by configuration in PHP framework [Nette](http://nette.org/en/).

## Installing

```
$ npm install easy-configuration
```

## Loading config

```
var Configuration = require('easy-configuration');
var config = new Configuration('./my/config.json');

var data = config.load();
```

**Relative paths to config files are supported only on node (not in browser)!!!**

## Parameters

In default, this configurator contains two basic sections: parameters and includes.
Parameters section can holds all your variables which you will need in other sections

```
{
	"parameters": {
		"basePath": "./www",
		"shared": {
			"styles": "%basePath%/css",
			"scripts": "%basePath%/js",
			"translations": "%basePath%/lang"
		}
	}
}
```

## Including other config files

If you will add section includes, you can set list of files, which you want to merge with main config file.
Paths to these config files must be relative to main config file.

```
{
	"includes": [
		"./packages.json"
	]
}
```

## Different environments

You may need different configuration for different environments (like production or development). First think you need to
do, is put your current configuration into `common` section.

**This feature is applied only to main config files, not to files included from `includes` section.**
**It will be automatically turned on when there will be `common` section or section with name of current environment.**

```
{
	"common": {
		"parameters": {
			"database": {}
		}
	}
}
```

Common section is base section for all environments. But other environments can rewrite everything in `common` section.

```
{
	"common": {
		"parameters": {
			"database": {
				"host": "127.0.0.1",
				"user": "root",
				"database": "my-db"
			}
		}
	},
	"production": {
		"parameters": {
			"database": {
				"password": "qwerty12345"
			}
		}
	},
	"development": {
		"parameters": {
			"database": {
				"password": "root"
			}
		}
	}
}
```

Now we have got configuration with two different setups for database.

```
process.env.NODE_ENV = 'production';

var config = new Configuration;
config.addConfig('./some-config.json', process.env.NODE_ENV);		// or new Configuration('./some-config.json', process.env.NODE_ENV);

var data = config.load()

console.log(config.parameters.database.password);		// output: qwerty12345
```

With this setup, configurator will load data `production` section merged with `common` section.

## Own sections - main feature

When you will try to add own section, Easy Configuration will tell you, that section was found,
but there is no corresponding extension.
There is example of registration a new one.

```
var Configuration = require('easy-configuration');
var config = new Configuration('./config.json');

config.addSection('packages');

var data = config.load();
```

Now you will be able to add new section with name "packages"

## Parameters in own sections

In your sections, you can use parameters from section "parameters".

```
{
	"packages": {
		"application": "%basePath%/application.js",
		"translator": {
			"translations": "%shared.translations%",
			"script": "%basePath%/translator.js"
		},
		"items": [
			{
				"name": "one",
				"title": "First"
			},
			{
				"name": "two",
				"allowed": false
			},
			{
				"name": "three"
			}
		]
	}
}
```

## Customize packages

Sometimes you may want to customize output of your package. Most simple way is to rewrite method loadConfiguration
of default Extension class.
For example we always want some other data in our section, even if they are not in config file - let's say "defaults".

```
var Configuration = require('easy-configuration');
var config = new Configuration('./config.json');

var section = config.addSection('packages');

var defaults = {
	applications: "",
	styles: "",
	translator: {
		translations: "",
		script: ""
	}
};

section.loadConfiguration = function() {
	return this.getConfig(defaults);
};

var data = config.load();
```

Method getConfig has got one optional argument and it is your defaults variable. This method will return configuration
only of your section merged with defaults argument (if any).
Of course, there can be more complex code.

EasyConfiguration class has got one other useful method and it is merge (using [recursive-merge](https://npmjs.org/package/recursive-merge) package).

```
var Configuration = require('easy-configuration');
var config = new Configuration('./config.json');

var section = config.addSection('packages');

var defaults = {
	applications: "",
	styles: "",
	translator: {
		translations: "",
		script: ""
	},
	items: []
};

var defaultsItems = {
	name: "",
	title: "",
	allowed: true
};

section.loadConfiguration = function() {
	var config = this.getConfig(defaults);

	for (var i = 0; i < config.items.length; i++) {
		config.items[i] = this.configurator.merge(config.items[i], defaultsItems);
	}

	return config;
};

var data = config.load();
```

### After compile

All data in loadConfiguration are the same like in your json files - parameters are not yet expanded. If you want to work
somehow with expanded data, you will need to rewrite afterCompile method.

But even if you use this method, setup styles for your configuration should be set in loadConfiguration method, not in afterCompile.

This method accept one parameter - data which you returned in loadConfiguration method. You also need to return your updated
data.

```
section.afterCompile = function(config) {
	return doSomething(config);
};
```

## Accessing parameters from outside

```
var Configuration = require('easy-configuration');
var config = new Configuration('./config.json');

var data = config.load();
var parameters = config.parameters;

// or

var parameter = config.getParameter('path.to.some.variable');
```

## Tests

```
$ npm test
```

## Changelog

* 2.0.0
	+ Optimized tests
	+ Tests frameworks does not need to be installed globally (are in devDependencies)
	+ Added badges
	+ Added support for different environments
	+ Loading config files with relative paths in node.js

* 1.6.3 - 1.6.6
	+ Bugs in IE8

* 1.6.2
	+ Throwing error if there is some circular reference

* 1.6.1
	+ Removed dependency on clone module

* 1.6.0
	+ Added many tests + tests for browser
	+ Updated docs
	+ Rewritten parameters parsing (now much better)

* 1.5.7
	+ Support for Internet Explorer 8

* 1.5.4 - 1.5.6
	+ Some optimizations
	+ Optimized tests

* 1.5.3
	+ Preparations for new version
	+ Loaded data are cloned (from require method)

* 1.5.2
	+ Previous version broke support for browser

* 1.5.0
	+ Optimized dependencies
	+ Refactoring tests
	+ Removed some useless methods

* 1.4.3
	+ Extension: added afterCompile method
	+ Some typos in readme

* 1.4.2
	+ Merging uses [recursive-merge](https://npmjs.org/package/recursive-merge) package

* 1.4.1
	+ Written rest of this changelog

* 1.4.0
	+ Added changelog to readme
	+ Created tests
	+ Tests can be run with `npm test` command
	+ Added removeExtension method

* 1.3.3
	+ Removed forgotten dependency on merging module

* 1.3.2
	+ External merging module removed
	+ Own old merging function added back

* 1.3.1
	+ Repaired some bugs with merging

* 1.3.0
	+ Whole module is rewritten

* 1.2.0
	+ Trying other external modules for merging
	+ Removed dependencies on fs and path
	+ Module can be run also in browser

* 1.1.3
	+ Added MIT license

* 1.1.2
	+ GIT repository renamed from Easy-Configuration to node-easy-configuration

* 1.1.1
	+ Added function for remove loaded data from memory

* 1.1.0
	+ Storing loaded data in memory
	+ Empty sections returns empty object and not undefined

* 1.0.4
	+ Renaming from EasyConfiguration to easy-configuration

* 1.0.3
	+ Corrected mistakes in readme
	+ Added link to Nette framework

* 1.0.2
	+ Corrected mistakes in readme

* 1.0.1
	+ Corrected mistakes in readme

* 1.0.0
	+ Initial commit