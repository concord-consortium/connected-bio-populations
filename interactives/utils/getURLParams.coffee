require.register "utils/getURLParams", (exports, require, module) ->
  getURLParams = (key) ->
    query = window.location.search.substring(1)
    raw_vars = query.split("&")

    for v in raw_vars
      [paramKey, paramVal] = v.split("=")
      if paramKey == key
        return decodeURIComponent(paramVal)

  module.exports = getURLParams
  


