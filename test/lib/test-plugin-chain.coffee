assert = require 'assert'
corepath = require 'path'

testPluginPath = corepath.resolve __dirname, '..', 'helpers', 'plugin'

pluginChain = require '../../lib/plugin-chain'

describe 'test plugin-chain', ->

  describe 'without options', ->

    result = pluginChain()

    it 'should return a chain with an empty array', ->

      assert.equal result.array.length, 0


  describe 'without plugins property', ->

    result = pluginChain {}

    it 'should return a chain with an empty array', ->

      assert.equal result.array.length, 0


  describe 'with empty plugins array', ->

    result = pluginChain plugins:[]

    it 'should return a chain with an empty array', ->

      assert.equal result.array.length, 0


  describe 'with string plugin', ->

    result = pluginChain plugins:[ testPluginPath ]

    it 'should return a chain with a single array element', ->

      assert.equal result.array.length, 1

    it 'should be the test plugin', ->

      assert.equal result.array[0].isPlugin, true


  describe 'with plugin builder function', ->

    result = pluginChain plugins:[ require(testPluginPath) ]

    it 'should return a chain with a single array element', ->

      assert.equal result.array.length, 1

    it 'should be the test plugin', ->

      assert.equal result.array[0].isPlugin, true


  describe 'with object plugin', ->

    options = plugins:[ { plugin: testPluginPath } ]
    result = pluginChain options

    it 'should return a chain with a single array element', ->

      assert.equal result.array.length, 1

    it 'should be the test plugin', ->

      assert.equal result.array[0].isPlugin, true

    it 'should have the builder options', ->

      assert.deepEqual result.array[0].buildOptions, options


  describe 'with object plugin and options', ->

    result = pluginChain plugins:[
      { plugin: testPluginPath, options: { some: 'options' } }
    ]

    it 'should return a chain with a single array element', ->

      assert.equal result.array.length, 1

    it 'should be the test plugin', ->

      assert.equal result.array[0].isPlugin, true

    it 'should NOT have the builder options', ->

      assert.equal result.array[0].buildOptions.plugins, undefined

    it 'should have the plugin options', ->

      assert.equal result.array[0].buildOptions.some, 'options'


  describe 'with object plugin and options to combine', ->

    result = pluginChain builder:true, plugins:[
      { plugin: testPluginPath, options: { some: 'options' } }
    ]

    it 'should return a chain with a single array element', ->

      assert.equal result.array.length, 1

    it 'should be the test plugin', ->

      assert.equal result.array[0].isPlugin, true

    it 'should have the builder options', ->

      assert.equal result.array[0].buildOptions.builder, true

    it 'should have the plugin options', ->

      assert.equal result.array[0].buildOptions.some, 'options'

  describe 'with invalid type', ->

    result = pluginChain plugins:[ false ]

    it 'should return an error', ->

      assert.equal result.error, 'Plugin 0 is an invalid type: boolean'
