fs = require('fs')
glob = require('glob')
path = require('path')


discoverAllLocalesIn = (projectName, version, benderContext) ->
  projOrDep = benderContext.getProjectOrDependency(projectName)

  fullDirPath = path.join projOrDep.path, 'lang/'
  subPath = path.join projectName, version, 'lang', '*.lyaml'
  fullPath = path.join fullDirPath, '*.lyaml'

  # Only discover locales if the <project>/<version>/lang/ folder exists
  if fs.existsSync fullDirPath

    # Look up all the *.lyaml files in the <proj>/static/lang directory
    localesAvailable = glob.sync(fullPath).map (filename) ->
      path.basename(filename, '.lyaml')

    console.log "Discovering all locale strings available from #{subPath}: #{localesAvailable}"
    localesAvailable
  else
    []

discoverAllLocaleFilesIn = (projectName, version, benderContext) ->
  for locale in discoverAllLocalesIn(projectName, version, benderContext)
    "#{projectName}/#{version}/lang/#{locale}.lyaml"


module.exports = {
  discoverAllLocaleFilesIn
  discoverAllLocalesIn
}
