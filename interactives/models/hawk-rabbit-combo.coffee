helpers     = require 'helpers'

Environment = require 'models/environment'
Species     = require 'models/species'
Agent       = require 'models/agent'
Rule        = require 'models/rule'
Trait       = require 'models/trait'
Interactive = require 'ui/interactive'
Events      = require 'events'
ToolButton  = require 'ui/tool-button'
BasicAnimal = require 'models/agents/basic-animal'

plantSpecies  = require 'species/fast-plants-roots'
rabbitSpecies = require 'species/white-brown-rabbits'
hawkSpecies   = require 'species/hawks'
env           = require 'environments/combo'
getURLParams  = require 'utils/getURLParams'

ToolButton.prototype._states['carry-tool'].mousedown = (evt) ->
  agent = @getAgentAt(evt.envX, evt.envY)
  return unless agent?
  return unless agent.canBeCarried()
  @pickUpAgent agent
  @_agent = agent
  @_origin = {x: evt.envX, y: evt.envY}
  @_agentOrigin = agent.getLocation()

Agent.prototype.canBeCarried = () ->
  return true;

Environment.prototype.randomLocationWithin = (left, top, width, height, avoidBarriers=false)->
  point = {x: ExtMath.randomInt(width)+left, y: ExtMath.randomInt(height)+top}
  while avoidBarriers and @isInBarrier(point.x, point.y)
    point = {x: ExtMath.randomInt(width)+left, y: ExtMath.randomInt(height)+top}
  return point

window.model =
  brownness: 0
  run: ->
    @interactive = new Interactive
      environment: env
      speedSlider: true
      addOrganismButtons: [
        {
          species: rabbitSpecies
          imagePath: "images/agents/rabbits/sandrat-light.png"
          traits: [
            new Trait {name: "mating desire bonus", default: -20}
            new Trait {name: "age", default: 3}
          ]
          limit: -1
          scatter: true
        }
        {
          species: hawkSpecies
          imagePath: "images/agents/owls/owl_button.png"
          traits: [
            new Trait {name: "mating desire bonus", default: -40}
          ]
          limit: -1
          scatter: true
        }
      ]
      toolButtons: [
        {
          type: ToolButton.INFO_TOOL
        },
        {
          type: ToolButton.CARRY_TOOL
        }
      ]

    document.getElementById('environment').appendChild @interactive.getEnvironmentPane()

    @env = env
    @plantSpecies = plantSpecies
    @hawkSpecies = hawkSpecies
    @rabbitSpecies = rabbitSpecies

    @locations =
      all: {x: 0, y: 0, width: @env.width, height: @env.height }
      lab_snow: {x: 0, y: 0, width: Math.round(@env.width/2), height: Math.round(@env.height/4) }
      snow: {x: 0, y: Math.round(@env.height/4), width: Math.round(@env.width/2), height: Math.round(@env.height/4)*3}
      lab_dirt: {x: Math.round(@env.width/2), y: 0, width: Math.round(@env.width/2), height: Math.round(@env.height/4) }
      dirt: {x: Math.round(@env.width/2), y: Math.round(@env.height/4), width: Math.round(@env.width/2), height: Math.round(@env.height/4)*3}
    @setupEnvironment()

    env.addRule new Rule
      action: (agent) =>
        if agent.species is rabbitSpecies
          brownness = if agent._x < @env.width/2 then 0 else 1
          if agent.get('color') is 'brown'
            agent.set 'chance of being seen', (0.6 - (brownness*0.6))
          else
            agent.set 'chance of being seen', (brownness*0.6)

    env.addRule new Rule
      action: (agent) =>
        if agent.species is rabbitSpecies
          if agent._y < @env.height/4
            agent.set("is immortal", true)
            agent.set("min offspring", 2)
            population = if agent._x < @env.width/2 then @current_counts.lab_snow else @current_counts.lab_dirt
            overcrowded =population > 10
            if overcrowded
              agent.set("mating desire bonus", -40)
            else
              agent.set("mating desire bonus", 0)
            if overcrowded and agent.get('age') > 30 and Math.random() < 0.2
              agent.die()
          else
            agent.set("is immortal", false)

    Events.addEventListener Environment.EVENTS.STEP, =>
      model.countRabbitsInAreas()

  setupEnvironment: ->
    console.log(getURLParams('color'))
    @current_counts =
      all: {total: 0}
      lab: {total: 0}
      field: {total: 0}
    buttons = [].slice.call($('.button img'))
    that = @
    buttons[0].onclick = () ->
      # Scale assuming sum is 100%
      whiteInput = $('#starting-white')[0]
      brownInput = $('#starting-brown')[0]
      givenWhite = parseFloat(whiteInput.value)
      givenBrown = parseFloat(brownInput.value)
      percentBrown = givenBrown / (givenBrown + givenWhite)
      brownInput.value = Math.round(percentBrown * 100)
      whiteInput.value = Math.round((1 - percentBrown) * 100)
      for i in [0...30]
        that.addAgent(rabbitSpecies, [], [
          new Trait {name: "mating desire bonus", default: -20}
          new Trait {name: "age", default: 3}
          that.createRandomColorTrait(percentBrown)
        ], that.locations.snow)
        that.addAgent(rabbitSpecies, [], [
          new Trait {name: "mating desire bonus", default: -20}
          new Trait {name: "age", default: 3}
          that.createRandomColorTrait(percentBrown)
        ], that.locations.dirt)
      buttons[0].onclick = null
    buttons[1].onclick = () ->
      that.addAgents(2, hawkSpecies, [], [
        new Trait {name: "mating desire bonus", default: -40}
      ], that.locations.snow)
      that.addAgents(2, hawkSpecies, [], [
        new Trait {name: "mating desire bonus", default: -40}
      ], that.locations.dirt)
      buttons[1].onclick = null

  setupGraphs: ->
    outputOptions =
      title:  "Number of rabbits"
      xlabel: "Time (s)"
      ylabel: "Number of rabbits"
      xmax:   100
      xmin:   0
      ymax:   50
      ymin:   0
      xTickCount: 10
      yTickCount: 10
      xFormatter: "2d"
      yFormatter: "2d"
      realTime: false
      fontScaleRelativeToParent: true
      sampleInterval: (Environment.DEFAULT_RUN_LOOP_DELAY/1000)
      dataType: 'samples'
      dataColors: [
        [153, 153, 153]
        [153,  85,   0]
        [255,   0,   0]
      ]

    @outputGraph = LabGrapher '#graph', outputOptions
    @outputGraph2 = LabGrapher '#graph2', outputOptions

    Events.addEventListener Environment.EVENTS.RESET, =>
      model.setupEnvironment()
      @addedHawks = false
      @addedRabbits = false
      @outputGraph.reset()
      @outputGraph2.reset()

    Events.addEventListener Environment.EVENTS.STEP, =>
      @outputGraph.addSamples @graphRabbits(@locations.snow)
      @outputGraph2.addSamples @graphRabbits(@locations.dirt)

  agentsOfSpecies: (species)->
    set = []
    for a in @env.agents
      set.push a if a.species is species
    return set

  agentsOfSpeciesInRect: (species, rectangle)->
    set = []
    for a in @env.agentsWithin(rectangle)
      set.push a if a.species is species
    return set

  countRabbitsInAreas: ->
      @current_counts.all = @countRabbitsInArea(@locations.all)
      @current_counts.snow  = @countRabbitsInArea(@locations.snow)
      @current_counts.dirt = @countRabbitsInArea(@locations.dirt)
      @current_counts.lab_snow  = @countRabbitsInArea(@locations.lab_snow)
      @current_counts.lab_dirt = @countRabbitsInArea(@locations.lab_dirt)

  countRabbitsInArea: (rectangle) ->
    rabbits = (a for a in @env.agentsWithin(rectangle) when a.species is @rabbitSpecies)
    return rabbits.length

  graphRabbits:(location) ->
    whiteRabbits = 0
    brownRabbits = 0
    for a in @agentsOfSpeciesInRect(@rabbitSpecies, location)
      whiteRabbits++ if a.get('color') is 'white'
      brownRabbits++ if a.get('color') is 'brown'
    return [whiteRabbits, brownRabbits]

  showMessage: (message, callback) ->
    helpers.showMessage message, @env.getView().view.parentElement, callback

  setupPopulationControls: ->
    Events.addEventListener Environment.EVENTS.STEP, =>
      @checkRabbits(@locations.snow)
      @checkRabbits(@locations.dirt)
      @checkHawks(@locations.snow)
      @checkHawks(@locations.dirt)

  setProperty: (agents, prop, val)->
    for a in agents
      a.set prop, val

  addAgents: (number, species, properties=[], traits=[], location)->
    for i in [0...number]
      @addAgent(species, properties, traits, location)

  addAgent: (species, properties=[], traits=[], location)->
    agent = species.createAgent(traits)
    coords = @env.randomLocation()
    if location
      coords = @env.randomLocationWithin(location.x, location.y, location.width, location.height, true)
    agent.setLocation coords
    for prop in properties
      agent.set prop[0], prop[1]
    @env.addAgent agent

  addedRabbits: false
  addedHawks: false
  numRabbits: 0
  checkRabbits: (location)->
    allRabbits = @agentsOfSpeciesInRect(@rabbitSpecies, location)
    allPlants  = @agentsOfSpecies(@plantSpecies)

    @numRabbits = allRabbits.length

    if @numRabbits is 0
      if @addedRabbits and not @addedHawks
        @env.stop()
        @showMessage "Uh oh, all the rabbits have died!<br/>Did you add any plants? Reset the model and try it again."
        return
    numPlants = allPlants.length

    if not @addedRabbits and @numRabbits > 0
      @addedRabbits = true

    if @addedRabbits and numPlants > 0 and @numRabbits < 9
      @addAgent(@rabbitSpecies, [], [@copyRandomColorTrait(allRabbits)])
      @addAgent(@rabbitSpecies, [], [@copyRandomColorTrait(allRabbits)])
      @addAgent(@rabbitSpecies, [], [@copyRandomColorTrait(allRabbits)])
      @addAgent(@rabbitSpecies, [], [@copyRandomColorTrait(allRabbits)])

    if @numRabbits < 16
      @setProperty(allRabbits, "min offspring", 2)
      @setProperty(allRabbits, "speed", 70)
    else
      @setProperty(allRabbits, "mating desire bonus", -20)
      @setProperty(allRabbits, "min offspring", 1)
      @setProperty(allRabbits, "speed", 50)

    if @numRabbits > 50
      @setProperty(allRabbits, "mating desire bonus", -40)

  # Returns a random color trait, selecting from rabbits currently on screen
  copyRandomColorTrait: (allRabbits) ->
    randomRabbit = allRabbits[Math.floor(Math.random() * allRabbits.length)]
    alleleString = randomRabbit.organism.alleles
    return new Trait {name: "color", default: alleleString, isGenetic: true}

  createRandomColorTrait: (percentBrown) ->
    alleleString = ""
    if Math.random() < percentBrown
      genotypeNum = Math.random()
      if genotypeNum < 1/3
        alleleString = "a:B,b:b"
      else if genotypeNum < 2/3
        alleleString = "a:b,b:B"
      else
        alleleString = "a:B,b:B"
    else
      alleleString = "a:b,b:b"
    return new Trait {name: "color", default: alleleString, isGenetic: true}

  checkHawks: (location)->
    allHawks = @agentsOfSpeciesInRect(@hawkSpecies, location)
    numHawks = allHawks.length

    if numHawks is 0
      if @addedHawks
        if @addedRabbits
          @env.stop()
          @showMessage "Uh oh, all the animals have died!<br/>Was there any food for the rabbits to eat? Reset the model and try it again."
        else
          @env.stop()
          @showMessage "Uh oh, all the hawks have died!<br/>Were there any rabbits for them to eat? Reset the model and try it again."
      return

    if not @addedHawks and numHawks > 0
      @addedHawks = true

    if @addedHawks and @numRabbits > 0 and numHawks < 2
      @addAgent @hawkSpecies

    @setProperty(allHawks, "is immortal", true)
    @setProperty(allHawks, "mating desire bonus", -40)
    @setProperty(allHawks, "hunger bonus", 5)

  preload: [
    "images/agents/grass/tallgrass.png",
    "images/agents/rabbits/rabbit2.png",
    "images/agents/owls/owl.png",
    "images/environments/lab_combo.png"
  ]

window.onload = ->
  helpers.preload [model, env, plantSpecies, rabbitSpecies, hawkSpecies, getURLParams], ->
    model.run()
    model.setupGraphs()
    model.setupPopulationControls()
