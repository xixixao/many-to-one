chokidar = require 'chokidar'
escapeStringForRegex = require 'escape-string-regexp'
fs = require 'fs'
sysPath = require 'path'
timestamp = require 'time-stamp'
yargs = require 'yargs'

args = yargs
  .usage '''
      Usage: many-to-one [options] SOURCE ... TARGET

        SOURCE is a path to a file or directory, or a glob
        TARGET is a path to a file that will consist of the combined contents
          of all the files specified by SOURCEs

      The command will keep watching both the SOURCEs and the TARGET and sync
      them when either change.
    '''
  .example 'many-to-one a.js b.js c.js bundle.js',
    'Sync a, b and c to bundle.'

  .example 'many-to-one -c \'#\' src/ bundle.coffee',
    'Use different comment syntax for other languages.'

  .example 'many-to-one -c \'/*\' -t \'*/\' src/ all.as',
    'Use different token to end file headers.'

  .example 'many-to-one src/ -i src/vendor.js all.js',
    'Exclude some files from syncing.'

  .options
    comment:
      alias: 'c'
      describe: 'The comment syntax used for file headers.'
      default: '//'
      type: 'string'
    ignore:
      alias: 'i'
      describe: 'Don\'t consider these paths/globs for SOURCE files'
    mangle:
      alias: 'm'
      describe: 'Mangle the actual source file names in TARGET\'s headers.'
      type: 'boolean'
    token:
      alias: 't'
      describe: 'The end token distinguishing file headers from other comments.'
      default: '-------------'
      type: 'string'
    verbose:
      alias: 'v'
      describe: 'Log watching status.'
      type: 'boolean'
  .help()
  .describe 'help', ''
  .demandCommand 2,
    'Error: You need to supply at minimum one SOURCE and TARGET'
  .strict()
  .argv

[srcs..., target] = args._
targetPath = sysPath.relative '', target

watcher = chokidar.watch args._,
  cwd: '.'
  ignored: args.ignore

watched = {}
ready = false

watcher.on 'add', (path) ->
  watched[toWatched path] = true
  logVerbose "Added `#{path}`"
  if path isnt targetPath and ready
    syncForward()

watcher.on 'change', (path) ->
  if ready
    if path is targetPath
      syncBack()
    else
      syncForward()

watcher.on 'unlink', (path) ->
  logVerbose "Removed `#{path}`"
  if path isnt targetPath
    delete watched[toWatched path]
  syncForward()

watcher.on 'ready', () ->
  if (Object.keys watched).length > 0
    syncForward()
    ready = true

syncForward = () ->
  compiled = ''
  for w of watched when (path = fromWatched w) isnt targetPath
    content = readFile path
    compiled += fileHeader w
    compiled += content + '\n'
  compiled = compiled[...-1] # remove last new line
  try
    oldCompiled = readFile targetPath
  if oldCompiled isnt compiled
    fs.writeFileSync targetPath, compiled
    log "->"

syncBack = () ->
  compiled = readFile targetPath
  splitUp = compiled.split fileHeaderRegex
  wrote = false
  addedNewFile = false
  stopWatching = Object.assign {}, watched
  for w, i in splitUp[1...] by 2
    content = splitUp[i + 2]
    if i isnt splitUp.length - 3 # unless the last file
      content = content[...-1] # removes added new line
    if watched[w]
      path = fromWatched w
      delete stopWatching[w]
      write = (readFile path) isnt content
    else
      # Starts watching new file
      path = w
      watcher.add w
      watched[w] = true
      write = not fileExists path
      addedNewFile or= not write
      logVerbose "Started watching `#{path}`"
    if write
      fs.writeFileSync path, content
      wrote = true
  # Stops watching removed file
  for w of stopWatching when (path = fromWatched w) isnt targetPath
    watcher.unwatch path
    delete watched[w]
    logVerbose "Stopped watching `#{path}`"
  if wrote or addedNewFile
    log "<-"
  if addedNewFile
    syncForward()

fileHeader = (path) ->
  "#{args.comment} #{path} #{args.token}\n"

fileHeaderRegex = ///
  ^
  #{escapeStringForRegex args.comment}
  \s
  ([^\n]+)
  \s
  #{escapeStringForRegex args.token}
  $
  \n?
///m

readFile = (path) ->
  fs.readFileSync path, encoding: 'utf8'

fileExists = (path) ->
  try
    return (fs.statSync path).isFile()
  false

toWatched = (path) ->
  if args.mangle
    new Buffer path
      .toString 'base64'
  else
    path

fromWatched = (path) ->
  if args.mangle
    new Buffer path, 'base64'
      .toString ''
  else
    path

logVerbose = (message) ->
  if args.verbose
    log message

log = (message) ->
  console.log "#{timestamp('[HH:mm:ss]')} #{message}"
