helpers     = require 'helpers'

Environment = require 'models/environment'
EnvironmentView = require 'views/environment-view'
Species     = require 'models/species'
Agent       = require 'models/agent'
Rule        = require 'models/rule'
Trait       = require 'models/trait'
Interactive = require 'ui/interactive'
Events      = require 'events'
ToolButton  = require 'ui/tool-button'
BasicAnimal = require 'models/agents/basic-animal'

rabbitSpecies = require 'species/white-brown-rabbits'
hawkSpecies   = require 'species/hawks'
env_single    = require 'environments/snow'
env_double    = require 'environments/combo'

# Adding patches to make certain animals (e.g. hawks) uninteractable
Agent.prototype.canBeCarried = () ->
  return true;

ToolButton.prototype._states['carry-tool'].mousedown = (evt) ->
  agent = @getAgentAt(evt.envX, evt.envY)
  return unless agent?
  return unless agent.canBeCarried()
  @pickUpAgent agent
  @_agent = agent
  @_origin = {x: evt.envX, y: evt.envY}
  @_agentOrigin = agent.getLocation()

Environment.prototype.randomLocationWithin = (left, top, width, height, avoidBarriers=false)->
  point = {x: ExtMath.randomInt(width)+left, y: ExtMath.randomInt(height)+top}
  # Patching for this line - the genetics version of populations.js left in a bug that calls
  # @isInBarrier with the incorrect parameters
  while avoidBarriers and @isInBarrier(point.x, point.y)
    point = {x: ExtMath.randomInt(width)+left, y: ExtMath.randomInt(height)+top}
  return point

EnvironmentView.prototype.addMouseHandlers = () ->
  for eventName in ["click", "mousedown", "mouseup", "mousemove", "touchstart", "touchmove", "touchend"]
    @view.addEventListener eventName,  (evt) =>
      if evt instanceof TouchEvent
        # touch events get their coordinates from a different place
        evt.envX = evt.changedTouches[0].pageX - @view.offsetLeft
        evt.envY = evt.changedTouches[0].pageY - @view.offsetTop
      else
        # This is the patched change - scaling the click location by the scale factor
        scale = document.querySelector("body").style.transform
        # Hack to pull scale factor out of the css
        scale = parseFloat(scale.slice(scale.indexOf(",") + 1))
        evt.envX = (1 / scale) * (evt.pageX - @view.offsetLeft)
        evt.envY = (1 / scale) * (evt.pageY - @view.offsetTop)
      @environment.send evt.type, evt

window.model =
  brownness: 0
  checkParams: ->
    envParam = @getURLParam('envs', true)
    @envColors = if envParam then envParam else ['white']

    @switch = @getURLParam('switch') == 'true'
    if (@switch)
      document.querySelector("#switch-controls").hidden = false

    @popControl = @getURLParam('popControl')
    controlTypeParam = @getURLParam('controlType')
    @controlType = if controlTypeParam then controlTypeParam else 'color'
    if (@popControl == "user")
      if (@controlType == "color")
        document.querySelector("#color-controls").hidden = false
      else
        document.querySelector("#genome-controls").hidden = false

  run: ->
    env = if @envColors.length == 1 then env_single else env_double
    @interactive = new Interactive
      environment: env
      speedSlider: false
      # These buttons appear, but their behavior is defined elsewhere by click handlers
      addOrganismButtons: [
        {
          species: rabbitSpecies
          imagePath: "images/agents/rabbits/sandrat-light.png"
          traits: []
          limit: -1
          scatter: true
        }
        {
          species: hawkSpecies
          imagePath: "images/agents/hawks/hawk.png"
          traits: []
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
    @env.setBackground("images/environments/" + @envColors.join("_") + ".png")
    @hawkSpecies = hawkSpecies
    @rabbitSpecies = rabbitSpecies

    numEnvs = @envColors.length
    labs = []
    fields = []
    for i in [0...numEnvs]
      x = Math.round((@env.width/numEnvs) * i)
      labY = 0
      fieldY = Math.round(@env.height/4)
      width = Math.round(@env.width/numEnvs)
      labHeight = Math.round(@env.height/4)
      fieldHeight = Math.round(@env.height * 3/4)
      labs.push({x: x, y: labY, width: width, height: labHeight})
      fields.push({x: x, y: fieldY, width: width, height: fieldHeight})

    @locations =
      all: {x: 0, y: 0, width: @env.width, height: @env.height }
      labs: labs
      fields: fields
    @setupEnvironment()

    env.addRule new Rule
      action: (agent) =>
        if agent.species is rabbitSpecies
          envIndex = @getAgentEnvironmentIndex(agent)
          brownness = @envColors[envIndex] == 'brown'
          if agent.get('color') is 'brown'
            agent.set 'chance of being seen', (0.6 - (brownness*0.6))
          else
            agent.set 'chance of being seen', (brownness*0.6)

    # Makes rats in the labs immortal so they don't die immediately after they're placed
    env.addRule new Rule
      action: (agent) =>
        if agent.species is rabbitSpecies
          if agent._y < @env.height/4
            agent.set("is immortal", true)
            envIndex = @getAgentEnvironmentIndex(agent)
            population = @countRabbitsInArea(@locations.labs[envIndex])
            overcrowded = population > 10
            if overcrowded
              agent.set("max offspring", 0)
              agent.set("mating chance", 0)
            else
              agent.set("max offspring", 1)
              agent.set("mating chance", 1)
            if overcrowded and agent.get('age') > 30 and Math.random() < 0.2
              agent.die()
          else
            agent.set("is immortal", false)

  getAgentEnvironmentIndex: (agent) ->
    return Math.min(Math.floor((agent._x/@env.width) * @envColors.length), @envColors.length - 1)

  setupEnvironment: ->
    # Add behaviors to the buttons with agent images on them
    buttons = [].slice.call($('.button img'))
    numMice = 30
    that = @
    buttons[0].parentNode.onclick = () ->
      colors = that.getStartingColors(numMice)
      for i in [0...that.envColors.length]
        for j in [0...numMice]
          that.addAgent(rabbitSpecies, [], [
            new Trait {name: "mating desire bonus", default: -20}
            new Trait {name: "age", default: Math.round(Math.random() * 5)}
            colors[j]
          ], that.locations.fields[i])
      buttons[0].parentNode.onclick = null
    buttons[1].parentNode.onclick = () ->
      for i in [0...that.envColors.length]
        that.addAgents(2, hawkSpecies, [], [
          new Trait {name: "mating desire bonus", default: -40}
        ], that.locations.fields[i])
      buttons[1].parentNode.onclick = null

    Events.addEventListener Environment.EVENTS.RESET, =>
      model.setupEnvironment()
      @addedHawks = false
      @addedRabbits = false

  getStartingColors: (num) ->
    colors = []

    if (@controlType == "color")
      percentBrown
      if (@popControl == "user")
        # Scale the inputs assuming sum is 100%
        whiteInput = $('#starting-white')[0]
        brownInput = $('#starting-brown')[0]
        givenWhite = parseFloat(whiteInput.value)
        givenBrown = parseFloat(brownInput.value)
        percentBrown = givenBrown / (givenBrown + givenWhite)
        brownInput.value = Math.round(percentBrown * 100)
        whiteInput.value = Math.round((1 - percentBrown) * 100)
      else
        brownParam = @getURLParam("percentBrown")
        percentBrown = if brownParam then parseInt(brownParam) / 100 else .75
      for i in [0...num]
        colors.push(@createRandomColorTraitByPhenotype(percentBrown))
    else
      percentBB
      percentBb
      if (@popControl == "user")
        inputBB = $('#starting-BB')[0]
        inputBb = $('#starting-Bb')[0]
        inputbb = $('#starting-bb')[0]
        givenBB = parseFloat(inputBB.value)
        givenBb = parseFloat(inputBb.value)
        givenbb = parseFloat(inputbb.value)
        percentBB = givenBB / (givenBB + givenBb + givenbb)
        percentBb = givenBb / (givenBB + givenBb + givenbb)
        inputBB.value = Math.round(percentBB * 100)
        inputBb.value = Math.round(percentBb * 100)
        inputbb.value = Math.round((1 - (percentBB + percentBb)) * 100)
      else
        BBParam = @getURLParam("percentBB")
        percentBB = if BBParam then parseInt(BBParam) / 100 else .38
        BbParam = @getURLParam("percentBb")
        percentBb = if BbParam then parseInt(BbParam) / 100 else .38
      for i in [0...num]
        colors.push(@createRandomColorTraitByGenotype(percentBB, percentBb))

    return colors

  getURLParam: (key, forceArray) ->
    query = window.location.search.substring(1)
    raw_vars = query.split("&")

    for v in raw_vars
      [paramKey, paramVal] = v.split("=")
      if paramKey == key
        value = decodeURIComponent(paramVal).split(',')
        if value.length == 1 and not forceArray
          return value[0]
        else
          return value

    return null

  setupGraphs: ->
    @graphData = {}

    @createGraphForEnvs(
      "Mouse Colors", 
      "Time (s)",
      "Number of Mice",
      [
        [153, 153, 153]
        [153,  85,   0]
      ]
      [
        "Light mice",
        "Dark mice"
      ]
      "color-graph",
      @graphRabbitColors
      "graph-colors",
      [
        "graph-alleles"
        "graph-genotypes"
      ]
    )

    @createGraphForEnvs(
      "Mouse Genotypes", 
      "Time (s)",
      "Number of Mice",
      [
        [242, 203, 124] #bb
        [170, 170, 170] #bB
        [85, 85, 85] #BB
      ],
      [
        "bb mice",
        "bB mice",
        "BB mice"
      ]
      "genotype-graph",
      @graphRabbitGenotypes
      "graph-genotypes",
      [
        "graph-alleles"
        "graph-colors"
      ]
    )

    @createGraphForEnvs(
      "Mouse Alleles", 
      "Time (s)",
      "Number of Alleles",
      [
        [153, 153, 153]
        [153,  85,   0]
      ]
      [
        "b alleles",
        "B alleles"
      ]
      "allele-graph",
      @graphRabbitAlleles
      "graph-alleles",
      [
        "graph-colors"
        "graph-genotypes"
      ]
    )

    document.getElementById("graph-colors").click()

  createGraphForEnvs: (title, xLabel, yLabel, colors, seriesNames, graphId, counter, showButton, hideButtons)->
    outputOptions =
      title:  title
      xlabel: xLabel
      ylabel: yLabel
      xmin: 0
      xmax: 10
      ymax: 100
      ymin: 0
      xTickCount: 10
      yTickCount: 10
      xFormatter: "2d"
      yFormatter: "2d"
      realTime: false
      fontScaleRelativeToParent: true
      sampleInterval: (Environment.DEFAULT_RUN_LOOP_DELAY/1000)
      dataType: 'samples'
      dataColors: colors

    updateWindow = (graph) =>
      # Pan the graph window every 5 seconds
      pointsPerWindow = (5 * 1000) / Environment.DEFAULT_RUN_LOOP_DELAY
      # Subtract 1 from the window since the first scroll isn't actually till 10 seconds
      windowNum = Math.max(0, Math.floor(graph.numberOfPoints() / pointsPerWindow) - 1)
      graph.xmin(windowNum * 5)
      graph.xmax(graph.xmin() + 10)
      graph.ymin(0)
      graph.ymax(100)

    @graphData[showButton] = {}
      
    for i in [0...@envColors.length]
      that = @
      # Create a closure so all the callbacks use the correct indices
      do (i) ->
        graph = null
        that.graphData[showButton][i] = []

        # Construct/destroy the graph on button clicks
        document.getElementById(showButton).addEventListener("click", () =>
          currGraph = document.getElementById("graph-container-" + i)
          if (currGraph)
            currGraph.remove()

          containerDiv = document.createElement("div")
          containerDiv.id = "graph-container-" + i
          document.getElementById("graphs").appendChild(containerDiv)

          # Construct the graph
          graphDiv = document.createElement("div")
          graphDiv.className = "graph stat-graph"
          fullId = graphId + "-" + i
          graphDiv.id = fullId
          containerDiv.appendChild(graphDiv)

          graph = LabGrapher ("#" + fullId), outputOptions

          # Add all existing data
          that.graphData[showButton][i].forEach((sample) => graph.addSamples(sample))

          # Construct the legend
          seriesNames.forEach((series, i) =>
            seriesText = document.createTextNode(series)
            seriesDiv = document.createElement("div")
            seriesDiv.className = "legend"
            seriesDiv.style.color = "rgb( " + colors[i].join(",") + ")"
            seriesDiv.appendChild(seriesText)
            containerDiv.appendChild(seriesDiv)
          )
          updateWindow(graph)
        )
        hideButtons.forEach((buttonId) => 
          document.getElementById(buttonId).addEventListener("click", () => graph = null)
        )

        Events.addEventListener Environment.EVENTS.RESET, =>
          that.graphData[showButton][i] = []
          if (graph)
            graph.reset()
            updateWindow(graph)

        Events.addEventListener Environment.EVENTS.STEP, =>
          that.graphData[showButton][i].push(counter.call(that, that.locations.fields[i]))
          if (graph)
            graph.addSamples counter.call(that, that.locations.fields[i])
            updateWindow(graph)

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

  countRabbitsInArea: (rectangle) ->
    rabbits = (a for a in @env.agentsWithin(rectangle) when a.species is @rabbitSpecies)
    return rabbits.length

  graphRabbitColors:(location) ->
    whiteRabbits = 0
    brownRabbits = 0
    for a in @agentsOfSpeciesInRect(@rabbitSpecies, location)
      whiteRabbits++ if a.get('color') is 'white'
      brownRabbits++ if a.get('color') is 'brown'
    return [whiteRabbits, brownRabbits]

  graphRabbitGenotypes:(location) ->
    bb = 0
    bB = 0
    BB = 0
    for a in @agentsOfSpeciesInRect(@rabbitSpecies, location)
      bb++ if a.alleles.color is "a:b,b:b"
      bB++ if a.alleles.color is "a:b,b:B"
      bB++ if a.alleles.color is "a:B,b:b"
      BB++ if a.alleles.color is "a:B,b:B"
    return [bb, bB, BB]

  graphRabbitAlleles:(location) ->
    count_b = 0
    count_B = 0
    for a in @agentsOfSpeciesInRect(@rabbitSpecies, location)
      if a.alleles.color.indexOf("a:b") > -1 then count_b++ else count_B++
      if a.alleles.color.indexOf("b:b") > -1 then count_b++ else count_B++
    return [count_b, count_B]

  showMessage: (message, callback) ->
    helpers.showMessage message, @env.getView().view.parentElement, callback

  setupControls: ->
    switchButton = document.getElementById('switch-env')
    switchButton.onclick = =>
      if @envColors.length == 1
        if @envColors[0] == "white"
          @envColors[0] = "brown"
          @env.setBackground("images/environments/brown.png")
        else
          @envColors[0] = "white"
          @env.setBackground("images/environments/white.png")

    document.getElementById('view-sex-check').onclick = =>
      model.showSex = document.querySelector('#view-sex-check:checked')
    document.getElementById('view-hetero-check').onclick = =>
      model.showHetero = document.querySelector('#view-hetero-check:checked')
    document.getElementById("env-controls").style.width = @envColors.length * 450 + 68 + "px"

    document.querySelector(".toolbar").style.left = @envColors.length * 450 + 10 + "px"

  setupPopulationControls: ->
    Events.addEventListener Environment.EVENTS.STEP, =>
      for i in [0...@envColors.length]
        @checkRabbits(@locations.fields[i])
        @checkHawks(@locations.fields[i])

  setupScaling: ->
    body = document.querySelector("body")
    baseSize = {
      w: @envColors.length * 450 + 100
      h: 910    
    }

    updateScale = ()->
      ww = window.innerWidth
      wh = window.innerHeight
      newScale = 1
      
      # compare ratios
      if (ww/wh < baseSize.w/baseSize.h) 
        newScale = ww / baseSize.w  #tall ratio
      else 
        newScale = wh / baseSize.h  # wide ratio   
      
      newScale = Math.min(newScale, 1)
      body.style.transform = 'scale(' + newScale + ',' +  newScale + ')'

    updateScale()
    window.addEventListener("resize", updateScale)

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

    @numRabbits = allRabbits.length

    if not @addedRabbits and @numRabbits > 0
      @addedRabbits = true

    if @addedRabbits and @numRabbits < 5
      for i in [0...4]
        @addAgent(@rabbitSpecies, [], [@copyRandomColorTrait(allRabbits)])

    # As there are more rabbits, it takes longer for rabbits to reproduce
    # Once there are 50 rabbits, they will stop reproducing entirely
    @setProperty(allRabbits, "mating chance", -.005 * @numRabbits + .25)

  # Returns a random color trait, selecting from rabbits currently on screen
  copyRandomColorTrait: (allRabbits) ->
    randomRabbit = allRabbits[Math.floor(Math.random() * allRabbits.length)]
    alleleString = randomRabbit.organism.alleles
    return new Trait {name: "color", default: alleleString, isGenetic: true}

  createRandomColorTraitByPhenotype: (percentBrown) ->
    alleleString = ""
    if Math.random() < percentBrown
      rand = Math.random()
      if rand < 1/3
        alleleString = "a:B,b:b"
      else if rand < 2/3
        alleleString = "a:b,b:B"
      else
        alleleString = "a:B,b:B"
    else
      alleleString = "a:b,b:b"
    return new Trait {name: "color", default: alleleString, isGenetic: true}

  createRandomColorTraitByGenotype: (percentBB, percentBb) ->
    alleleString = ""
    rand = Math.random()
    if rand < percentBB
      alleleString = "a:B,b:B"
    else if rand < percentBB + percentBb
      if Math.random() < .5
        alleleString = "a:B,b:b"
      else
        alleleString = "a:b,b:B"
    else
      alleleString = "a:b,b:b"

    return new Trait {name: "color", default: alleleString, isGenetic: true}

  checkHawks: (location)->
    allHawks = @agentsOfSpeciesInRect(@hawkSpecies, location)
    numHawks = allHawks.length

    if not @addedHawks and numHawks > 0
      @addedHawks = true

    @setProperty(allHawks, "is immortal", true)
    @setProperty(allHawks, "mating desire bonus", -40)
    @setProperty(allHawks, "hunger bonus", 5)

  preload: [
    "images/agents/rabbits/sandrat-dark.png",
    "images/agents/rabbits/sandrat-light.png",
    "images/agents/hawks/hawk.png",
    "images/environments/white.png",
    "images/environments/brown.png",
    "images/environments/brown_brown.png",
    "images/environments/brown_white.png",
    "images/environments/white_brown.png",
    "images/environments/white_white.png"
  ]

window.onload = ->
  helpers.preload [model, env_single, env_double, rabbitSpecies, hawkSpecies], ->
    model.checkParams()
    model.run()
    model.setupGraphs()
    model.setupControls()
    model.setupPopulationControls()
    model.setupScaling()
