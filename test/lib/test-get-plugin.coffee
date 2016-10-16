assert = require 'assert'
corepath = require 'path'

getPlugin = require '../../lib/get-plugin'

testPluginPath = corepath.resolve __dirname, '..', 'helpers', 'plugin'

describe 'test getPlugin', ->

  describe 'with no options', ->

    describe 'and string', ->

      pluginFn = getPlugin testPluginPath

      context = socket:{}
      pluginFn.call context, 'control', context

      it 'should provide the plugin function', ->

        assert typeof pluginFn, 'function'
        assert.equal pluginFn.isPlugin, true

      it 'should set some test values on the context', ->
        assert.equal context.socket.testPlugin, true
        assert.equal context.socket.testPlugin2, true

    describe 'and function', ->

      pluginFn = getPlugin require testPluginPath

      context = socket:{}
      pluginFn.call context, 'control', context

      it 'should provide the plugin function', ->

        assert typeof pluginFn, 'function'
        assert.equal pluginFn.isPlugin, true

      it 'should set some test values on the context', ->
        assert.equal context.socket.testPlugin, true
        assert.equal context.socket.testPlugin2, true

    describe 'and invalid arg', ->

      pluginFn = getPlugin false

      it 'should provide an error', ->

        assert.equal pluginFn.error, 'Plugin must be a require()\'able string or a function. Was: boolean'

    describe 'and invalid string', ->

      pluginFn = getPlugin '/invalid/path'

      it 'should provide an error', ->

        assert.equal pluginFn.error, 'Unable to require plugin: /invalid/path'



  describe 'with options', ->

    describe 'and string', ->

      options = { some: 'options' }
      pluginFn = getPlugin testPluginPath, options

      context = socket:{}
      pluginFn.call context, 'control', context

      it 'should provide the plugin function', ->

        assert typeof pluginFn, 'function'
        assert.equal pluginFn.isPlugin, true

      it 'should set some test values on the context', ->
        assert.equal context.socket.testPlugin, true
        assert.equal context.socket.testPlugin2, true

      it 'should have the options', ->
        assert.equal pluginFn.buildOptions, options

    describe 'and function', ->

      options = { some: 'options' }
      pluginFn = getPlugin require(testPluginPath), options

      context = socket:{}
      pluginFn.call context, 'control', context

      it 'should provide the plugin function', ->

        assert typeof pluginFn, 'function'
        assert.equal pluginFn.isPlugin, true

      it 'should set some test values on the context', ->
        assert.equal context.socket.testPlugin, true
        assert.equal context.socket.testPlugin2, true

      it 'should have the options', ->
        assert.equal pluginFn.buildOptions, options

    describe 'and invalid arg', ->

      pluginFn = getPlugin false, { some: 'options' }

      it 'should provide an error', ->

        assert.equal pluginFn.error, 'Plugin must be a require()\'able string or a function. Was: boolean'

    describe 'and invalid string', ->

      pluginFn = getPlugin '/invalid/path', { some: 'options' }

      it 'should provide an error', ->

        assert.equal pluginFn.error, 'Unable to require plugin: /invalid/path'
