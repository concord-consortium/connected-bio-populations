window.onload = ->
  params = {}
  env1 = document.getElementById("env-1")
  env2 = document.getElementById("env-2")
  showSwitch = document.getElementById("switch")
  showCarryTool = document.getElementById("carryTool")
  showInfoTool = document.getElementById("infoTool")
  showNeutral = document.getElementById("showNeutral")
  showHetero = document.getElementById("hetero")
  showNumHawks = document.getElementById("showNumHawks")
  authorControl = document.getElementById("author-control")
  userControl = document.getElementById("user-control")
  colorControl = document.getElementById("color-control")
  genotypeControl = document.getElementById("genotype-control")
  colorControls = document.getElementById("color-controls")
  percentBrown = document.getElementById("percent-brown")
  genotypeControls = document.getElementById("genotype-controls")
  percentBB = document.getElementById("percentBB")
  percentBb = document.getElementById("percentBb")

  updateUrl = () ->
    url = "https://concord-consortium.github.io/cb-populations/?"
    strParams = []
    for key in Object.keys(params)
      strParams.push(key + "=" + params[key])
    url = url + strParams.join("&")
    document.getElementById("url").value = url

  forceCheck = (elem, check) ->
    elem.checked = check
    elem.onchange()

  setEnvs = () ->
    envs = env1.value
    if env2.value == "none"
      showSwitch.disabled = false
    else
      envs += "," + env2.value
      forceCheck(showSwitch, false)
      showSwitch.disabled = true
    params["envs"] = envs
    updateUrl()
  env1.onchange = setEnvs
  env2.onchange = setEnvs

  showSwitch.onchange = () ->
    params.switch = showSwitch.checked
    updateUrl()
  carryTool.onchange = () ->
    params.carryTool = showCarryTool.checked
    updateUrl()
  showInfoTool.onchange = () ->
    params.hideInfoTool = !showInfoTool.checked
    updateUrl()
  hetero.onchange = () ->
    params.hideHeteroCheck = !hetero.checked
    updateUrl()
  showNeutral.onchange = () ->
    params.showNeutral = showNeutral.checked
    updateUrl()
  showNumHawks.onchange = () ->
    params.showNumHawks = showNumHawks.checked
    updateUrl()

  setPopControl = (e) ->
    controller = e.target.value
    params["popControl"] = controller
    if controller == "user"
      percentBrown.disabled = true
      percentBB.disabled = true
      percentBb.disabled = true
    else
      percentBrown.disabled = false
      percentBB.disabled = false
      percentBb.disabled = false
    updateUrl()
  authorControl.onchange = setPopControl
  userControl.onchange = setPopControl

  setControlType = (e) ->
    controlType = e.target.value
    params["controlType"] = controlType
    if controlType == "color"
      colorControls.hidden = false
      genotypeControls.hidden = true
    else
      genotypeControls.hidden = false
      colorControls.hidden = true
    updateUrl()
  colorControl.onchange = setControlType
  genotypeControl.onchange = setControlType

  setColors = (e) ->
    params["percentBrown"] = e.target.value
    updateUrl()
  percentBrown.onkeyup = setColors

  setGenotypes = (e) ->
    params["percentBB"] = percentBB.value
    params["percentBb"] = percentBb.value
    updateUrl()
  percentBB.onkeyup = setGenotypes
  percentBb.onkeyup = setGenotypes

  showColorGraphs = document.getElementById("show-color-graphs")
  showGenotypeGraphs = document.getElementById("show-genotype-graphs")
  showAlleleGraphs = document.getElementById("show-allele-graphs")
  setGraphs = (e) ->
    param = []
    if (showColorGraphs.checked)
      param.push("graph-colors")
    if (showGenotypeGraphs.checked)
      param.push("graph-genotypes")
    if (showAlleleGraphs.checked)
      param.push("graph-alleles")
    params["hideGraphs"] = param.join(",")
    updateUrl()
  showColorGraphs.onchange = setGraphs
  showGenotypeGraphs.onchange = setGraphs
  showAlleleGraphs.onchange = setGraphs

  updateUrl()
