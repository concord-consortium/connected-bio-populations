helpers     = require 'helpers'

window.onload = ->
  params = {}
  env1 = document.getElementById("env-1")
  env2 = document.getElementById("env-2")
  showSwitch = document.getElementById("switch")
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
    url = "https://concord-consortium.github.io/connected-bio-populations/hawk-rabbit-combo.html?"
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

  setSwitch = () ->
    params["switch"] = showSwitch.checked
    updateUrl()
  showSwitch.onchange = setSwitch

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

  updateUrl()
