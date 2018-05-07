require.register "species/white-brown-rabbits", (exports, require, module) ->

  Species = require 'models/species'
  BasicAnimal = require 'models/agents/basic-animal'
  Trait   = require 'models/trait'

  biologicaSpecies = require 'species/biologica/rabbits'

  class Rabbit extends BasicAnimal
    label: 'Mouse'
    moving: false

    step: ->
      @_closestAgents = null
      @_setSpeedAppropriateForAge()
      @_depleteEnergy()
      if (@get('age') > @species.defs.MATURITY_AGE && Math.random() < @get('mating chance'))
        this.mate()
      else
        this.wander()
      this._incrementAge();
      return this._checkSurvival();

    makeNewborn: ->
      super()

      # Ensure there's always at least one rabbit of each sex
      sex = if model.env.agents.length and
        model.env.agents[model.env.agents.length-1].species.speciesName is "rabbits" and
        model.env.agents[model.env.agents.length-1].get("sex") is "female" then "male" else "female"

      @set 'sex', sex
      @set 'age', Math.round(Math.random() * 5)

    mate: ->
      nearest = @_nearestMate()
      if nearest?
        @chase(nearest)
        if nearest.distanceSq < Math.pow(@get('mating distance'), 2) and (not @species.defs.CHANCE_OF_MATING? or Math.random() < @species.defs.CHANCE_OF_MATING)
          @reproduce(nearest.agent)
          @set 'max offspring', 0 # Each rabbit just reproduces once in its life
      else
        @wander(@get('speed') * Math.random() * 0.75)

    resetGeneticTraits: ()->
      super()
      @set 'genome', @_genomeButtonsString()

    _genomeButtonsString: ()->
      alleles = @organism.getAlleleString().replace(/a:/g,'').replace(/b:/g,'').replace(/,/g, '')
      return alleles

  module.exports = new Species
    speciesName: "rabbits"
    agentClass: Rabbit
    geneticSpecies: biologicaSpecies
    defs:
      MAX_HEALTH: 1
      MATURITY_AGE: 9
      CHANCE_OF_MUTATION: 0
      INFO_VIEW_SCALE: 2.5
      INFO_VIEW_PROPERTIES:
        "Fur color: ": 'color'
        "Genotype: ": 'genome'
        "Sex: ": 'sex'
    traits: [
      new Trait {name: 'speed', default: 60 }
      new Trait {name: 'predator', default: [{name: 'hawks'},{name: 'foxes'}] }
      new Trait {name: 'color', possibleValues: [''], isGenetic: true, isNumeric: false }
      new Trait {name: 'vision distance', default: 200 }
      new Trait {name: 'mating distance', default:  50 }
      new Trait {name: 'max offspring',   default:  3 }
      new Trait {name: 'min offspring',   default:  2 }
      new Trait {name: 'metabolism', default: 0 }
    ]
    imageRules: [
      {
        name: 'rabbit'
        contexts: ['environment','carry-tool']
        rules: [
          {
            image:
              path: "images/agents/rabbits/sandrat-light.png"
              scale: 0.3
              anchor:
                x: 0.8
                y: 0.47
            useIf: (agent)-> agent.get('color') is 'white'
          }
          {
            image:
              path: "images/agents/rabbits/sandrat-dark.png"
              scale: 0.3
              anchor:
                x: 0.8
                y: 0.47
            useIf: (agent)-> agent.get('color') is 'brown'
          }
        ]
      }
      {
        name: 'sex'
        contexts: ['environment']
        rules: [
          {
            image:
              path: "images/overlays/male-stack.png"
              scale: 0.4
              anchor:
                x: 0.75
                y: 0.5
            useIf: (agent)-> model.showSex and agent.get('sex') is 'male'
          }
          {
            image:
              path: "images/overlays/female-stack.png"
              scale: 0.4
              anchor:
                x: 0.75
                y: 0.5
            useIf: (agent)-> model.showSex and agent.get('sex') is 'female'
          }
        ]
      }
      {
        name: 'genotype'
        contexts: ['environment']
        rules: [
          {
            image:
              path: "images/overlays/heterozygous-stack.png"
              scale: 0.4
              anchor:
                x: 0.75
                y: 0.5
            useIf: (agent)-> model.showHetero and (agent.alleles.color is 'a:B,b:b' or agent.alleles.color is 'a:b,B:B')
          }
        ]
      }
      {
        name: 'rabbit info tool'
        contexts: ['info-tool']
        rules: [
          {
            image:
              path: "images/agents/rabbits/sandrat-light.png"
              scale: 0.4
              anchor:
                x: 0.4
                y: 0.5
            useIf: (agent)-> agent.get('color') is 'white'
          }
          {
            image:
              path: "images/agents/rabbits/sandrat-dark.png"
              scale: 0.4
              anchor:
                x: 0.4
                y: 0.5
            useIf: (agent)-> agent.get('color') is 'brown'
          }
        ]
      }
    ]
