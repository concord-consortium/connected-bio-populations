// Generated by CoffeeScript 1.12.5
(function() {
  var helpers;

  helpers = require('helpers');

  window.onload = function() {
    var authorControl, colorControl, colorControls, env1, env2, forceCheck, genotypeControl, genotypeControls, params, percentBB, percentBb, percentBrown, setColors, setControlType, setEnvs, setGenotypes, setPopControl, setSwitch, showSwitch, updateUrl, userControl;
    params = {};
    env1 = document.getElementById("env-1");
    env2 = document.getElementById("env-2");
    showSwitch = document.getElementById("switch");
    authorControl = document.getElementById("author-control");
    userControl = document.getElementById("user-control");
    colorControl = document.getElementById("color-control");
    genotypeControl = document.getElementById("genotype-control");
    colorControls = document.getElementById("color-controls");
    percentBrown = document.getElementById("percent-brown");
    genotypeControls = document.getElementById("genotype-controls");
    percentBB = document.getElementById("percentBB");
    percentBb = document.getElementById("percentBb");
    updateUrl = function() {
      var i, key, len, ref, strParams, url;
      url = "https://concord-consortium.github.io/connected-bio-populations/hawk-rabbit-combo.html?";
      strParams = [];
      ref = Object.keys(params);
      for (i = 0, len = ref.length; i < len; i++) {
        key = ref[i];
        strParams.push(key + "=" + params[key]);
      }
      url = url + strParams.join("&");
      return document.getElementById("url").value = url;
    };
    forceCheck = function(elem, check) {
      elem.checked = check;
      return elem.onchange();
    };
    setEnvs = function() {
      var envs;
      envs = env1.value;
      if (env2.value === "none") {
        showSwitch.disabled = false;
      } else {
        envs += "," + env2.value;
        forceCheck(showSwitch, false);
        showSwitch.disabled = true;
      }
      params["envs"] = envs;
      return updateUrl();
    };
    env1.onchange = setEnvs;
    env2.onchange = setEnvs;
    setSwitch = function() {
      params["switch"] = showSwitch.checked;
      return updateUrl();
    };
    showSwitch.onchange = setSwitch;
    setPopControl = function(e) {
      var controller;
      controller = e.target.value;
      params["popControl"] = controller;
      if (controller === "user") {
        percentBrown.disabled = true;
        percentBB.disabled = true;
        percentBb.disabled = true;
      } else {
        percentBrown.disabled = false;
        percentBB.disabled = false;
        percentBb.disabled = false;
      }
      return updateUrl();
    };
    authorControl.onchange = setPopControl;
    userControl.onchange = setPopControl;
    setControlType = function(e) {
      var controlType;
      controlType = e.target.value;
      params["controlType"] = controlType;
      if (controlType === "color") {
        colorControls.hidden = false;
        genotypeControls.hidden = true;
      } else {
        genotypeControls.hidden = false;
        colorControls.hidden = true;
      }
      return updateUrl();
    };
    colorControl.onchange = setControlType;
    genotypeControl.onchange = setControlType;
    setColors = function(e) {
      params["percentBrown"] = e.target.value;
      return updateUrl();
    };
    percentBrown.onkeyup = setColors;
    setGenotypes = function(e) {
      params["percentBB"] = percentBB.value;
      params["percentBb"] = percentBb.value;
      return updateUrl();
    };
    percentBB.onkeyup = setGenotypes;
    percentBb.onkeyup = setGenotypes;
    return updateUrl();
  };

}).call(this);
