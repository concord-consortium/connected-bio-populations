Environment = require 'models/environment'
Rule        = require 'models/rule'

env = new Environment
  columns:  90
  rows:     45
  imgPath: "images/environments/lab_combo.png"
  wrapEastWest: false
  wrapNorthSouth: false
  barriers: [
    [0, 100, 900, 50],
    [425, 0, 50, 450]
  ]

# env.getView().showingBarriers = true

require.register "environments/combo", (exports, require, module) ->
  module.exports = env
