assert = require 'assert'
buildCio = require '../../lib'

describe 'test client', ->

  describe 'with empty options', ->

    it 'should create net.connect() default'
