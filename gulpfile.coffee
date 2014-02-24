# Make preparations
gulp = require 'gulp'
gulpLoadPlugins = require 'gulp-load-plugins'
plugins = gulpLoadPlugins()

log = plugins.util.log
colors = plugins.util.colors

http = require 'http'
connect = require 'connect'

# Clean dist and test
gulp.task 'clean', ->
  gulp.src('./dist', read: false).pipe plugins.clean force: true
  gulp.src('./test', read: false).pipe plugins.clean force: true

# Lint the coffee sources
gulp.task 'lint', ->
  gulp.src(['./src/**/*.coffee', '!./src/tests', '!./src/templates'])
    .pipe(plugins.cache('linting'))
    .pipe(plugins.coffeelint())
    .pipe(plugins.coffeelint.reporter())

# Lint the coffee test-sources
gulp.task 'lint-tests', ->
  gulp.src('./src/test/**/*.coffee')
    .pipe(plugins.cache('linting-tests'))
    .pipe(plugins.coffeelint())
    .pipe(plugins.coffeelint.reporter())

# Compile coffee sources
gulp.task 'compile', ['lint'], ->
  gulp.src(['./src/**/*.coffee', '!./src/test', '!./src/templates'])
    .pipe(plugins.cache('compiling'))
    .pipe(plugins.coffee(bare: true).on 'error', plugins.util.log)
    .pipe(gulp.dest 'dist')

# Compile coffee test-sources
gulp.task 'compile-tests', ['lint-tests'], ->
  gulp.src('./src/test/*.coffee')
    .pipe(plugins.cache('compiling-tests'))
    .pipe(plugins.coffee(bare: true).on 'error', plugins.util.log)
    .pipe(gulp.dest 'test')

# Copy templates
gulp.task 'templates', ->
  gulp.src(['./src/templates/**/*.*'])
    .pipe(plugins.cache('templating'))
    .pipe gulp.dest 'dist'

# Run mocha tests
gulp.task 'test', ['compile-tests'], ->
  return gulp.src(['./test/test-*.js'], read: false)
    .pipe(plugins.cache('testing'))
    .pipe plugins.mocha
      reporter: 'spec'
      globals:
        should: require 'should'

# Watch for the changes
gulp.task 'watch', ->
  gulp.watch ['./src/**/*.coffee', '!./src/test', '!./src/templates'], ['compile']
  gulp.watch './src/templates/**/*/*', ['template']

# Start Dev Server
gulp.task 'server', ['watch'], (cb) ->
  dev = connect().use(connect.logger 'dev').use(connect.static 'dist')
  server = http.createSever(dev).listen 1337

  server.on 'error', (error) ->
    log colors.underline "#{colors.red 'ERROR'} Failed to start server!"
    cb error

  server.on 'listening', ->
    addr = server.address()
    host = if addr.address is '0.0.0.0' then 'localhost' else addr.address
    url = "http://#{host}:#{addr.port}/index.html}"
    log ''
    log "Server started at #{colors.magenta url}\n"
    cb()

# Default gulp task
gulp.task 'default', ['clean', 'compile', 'compile-tests', 'templates', 'test'], -> true

