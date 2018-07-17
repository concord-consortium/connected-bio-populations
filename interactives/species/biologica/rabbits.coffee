require.register "species/biologica/rabbits", (exports, require, module) ->

  BioLogica.Genetics.prototype.getRandomAllele = (exampleOfGene) ->
    for own gene of @species.geneList
      _allelesOfGene = @species.geneList[gene].alleles
      _weightsOfGene = @species.geneList[gene].weights || []
      if exampleOfGene in _allelesOfGene
        allelesOfGene = _allelesOfGene
        break

    if _weightsOfGene.length
      _weightsOfGene[_weightsOfGene.length] = 0 while _weightsOfGene.length < allelesOfGene.length # Fill missing allele weights with 0
    else
      _weightsOfGene[_weightsOfGene.length] = 1 while _weightsOfGene.length < allelesOfGene.length # Equally weighted for all alleles

    totWeights = _weightsOfGene.reduce ((prev, cur)-> prev + cur), 0
    rand = Math.random() * totWeights
    curMax = 0
    for weight,i in _weightsOfGene
      curMax += weight
      if rand <= curMax
        return allelesOfGene[i]

    console.error('somehow did not pick one: ' + allelesOfGene[0]) if console.error?
    return allelesOfGene[0]

  module.exports =

    name: 'Rabbit'

    chromosomeNames: ['1', '2', 'XY']

    chromosomeGeneMap:
      '1': ['B']
      '2': []
      'XY': []

    chromosomesLength:
      '1': 100000000
      '2': 100000000
      'XY': 70000000

    geneList:
      'color':
        alleles: ['B', 'b']
        weights: [.5, .5]
        start: 10000000
        length: 10584

    alleleLabelMap:
      'B': 'Brown'
      'b': 'White'
      ''  : ''

    traitRules:
      'color':
        'white': [['b','b']]
        'brown': [['B','b'],['B','B']]

    ###
      Images are handled via the populations.js species
    ###
    getImageName: (org) ->
      undefined

    ###
      no lethal characteristics
    ###
    makeAlive: (org) ->
      undefined
