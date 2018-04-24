Environment = require 'models/environment'
Rule        = require 'models/rule'

env = new Environment
  columns:  45
  rows:     45
  imgPath: "images/environments/lab_snow.png"
  wrapEastWest: false
  wrapNorthSouth: false
  barriers: [
    [0, 100, 500, 50]
  ]

# env.getView().showingBarriers = true

require.register "environments/snow", (exports, require, module) ->
  module.exports = env
