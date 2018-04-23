exports.config =
  paths:
    watched: ['interactives']

  files:
    javascripts:
      joinTo:
        'js/vendor.js': /^(bower_components)/

    stylesheets:
      joinTo:
        'css/vendor.css' : /^(bower_components)/
        'css/app.css' : /^(interactives)/

  conventions:
    assets: /assets(\/|\\)/

  plugins:
    afterBrunch: [
      'echo -n "Cleaning coffee files..." && find public/ -type f -name "*.coffee" -delete'
      'echo -n "Building interactives..." && coffee --compile --output public interactives/'
    ]
    jaded:
      jade:
        pretty: true
      staticPatterns: /^(interactives)(\/|\\)(.+)\.jade$/

  overrides:
    production:
      plugins:
        afterBrunch: [
          'echo -n "Cleaning coffee files..." && find public/ -type f -name "*.coffee" -delete'
          'echo -n "Building interactives and digesting..." && coffee --compile --output public interactives/ && ./bin/digest'
        ]
