sysPath = require 'path'
{exec}  = require 'child_process'

module.exports = class AfterBrunch
  brunchPlugin: yes

  constructor: (@config) ->
    @commands = @config.plugins.afterBrunch ? []

  onCompile: (generatedFiles) ->
    for command in @commands
      exec command, (error, stdout, stderr) ->
        console.log stdout if stdout
        console.log error.message if error
        console.log stderr if stderr

    return
