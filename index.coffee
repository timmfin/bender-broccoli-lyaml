Filter = require('broccoli-persistent-filter')
yaml = require('js-yaml')
path = require('path')
fs = require('fs')
glob = require("glob")

{ discoverAllLocalesIn } = require('./utils')


LOCALE_REGEX = /^[A-Za-z]{2}(?:-[A-Za-z]{2})?$/


class LYAMLFilter extends Filter

  # Default extensions to insert versions into
  extensions: ['lyaml']
  targetExtension: 'js'

  # Save the cache to disk
  cacheByContent: true

  constructor: (@inputTree, @options = {}) ->
    if !(this instanceof LYAMLFilter)
      return new LYAMLFilter(inputTree, options)

    super

    { @benderContext } = @options
    @allLocalesCacheFor = {}

    throw new Error "No benderContext passed into LYAMLFilter options" unless @benderContext?

  processFile = (srcDir, destDir, relativePath) ->
    string = fs.readFileSync srcDir + '/' + relativePath, { encoding: 'utf8' }

    output = @processString string, relativePath, srcDir
    outputPath = @getDestFilePath relativePath

    fs.writeFileSync destDir + '/' + outputPath, output, { encoding: 'utf8' }

  processString: (str, relativePath, srcDir) ->
    [projectName, version] = @benderContext.extractProjectAndVersionFromPath(relativePath)

    language = @_extractLanguageFromPath relativePath

    yamlObject = yaml.safeLoad str,
      filename: "#{srcDir}/#{relativePath}"

    result =
      translations: yamlObject

    if @_extractLanguageFromPath relativePath
      # For debugging
      result.translationSource = "#{@benderContext.staticDomainPrefix}/#{relativePath}"

      # Help the i18n JS know what tranlations have been loaded
      result.translationsLoaded = {}
      result.translationsLoaded[projectName] = {}
      result.translationsLoaded[projectName][language] = version

      # Keep track of the other locales that exist, but might not be loaded in the page
      result.translationsAvailable = {}
      result.translationsAvailable[projectName] = {}

      for locale in @_discoverAllLocalesFor(projectName, version)
        result.translationsAvailable[projectName][locale] = version

      extraTopLevelTranslationInfo = """
        if (typeof I18n === 'object' && I18n.trigger){
          I18n.trigger('loaded:#{ projectName }:#{ language }', {version: '#{ version }'});
        }
      """
    else
      extraTopLevelTranslationInfo = ''

    console.log "Compiled #{relativePath}"

    """
    hns('I18n', #{JSON.stringify(result, null, 2)});
    #{extraTopLevelTranslationInfo}
    """

  getDestFilePath: (relativePath) ->
    super if not @options.includePattern? or @options.includePattern.test(relativePath)

  _extractLanguageFromPath: (filepath) ->
    basename = path.basename(filepath, ".lyaml")

    if LOCALE_REGEX.test basename
      basename.toLowerCase()
    else
      throw new Error "Couldn't extract language from filename: #{filepath} (basename: #{basename})"

  _isTopLevelLangFile: (filepath) ->
    dirPart = path.dirname filepath
    filePart = path.basename filepath

    dirPartEndsWithLangFolder = /static(-\d+.\d+)?\/lang$/.test dirPart
    fileLooksLikeLocale = LOCALE_REGEX.test filePart

    dirPartEndsWithLangFolder and fileLooksLikeLocale

  _discoverAllLocalesFor: (projectName, version) ->
    if @allLocalesCacheFor[projectName]?[version]?
      return @allLocalesCacheFor[projectName][version]

    localesAvailable = discoverAllLocalesIn(projectName, version, @benderContext)
    localesAvailable = ['en'] unless localesAvailable?.length > 0

    @allLocalesCacheFor[projectName] ?= {}
    @allLocalesCacheFor[projectName][version] = localesAvailable



module.exports = LYAMLFilter
