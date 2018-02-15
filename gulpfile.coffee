browser_sync = require("browser-sync").create()
del = require "del"
gulp = require "gulp"
gulp_autoprefixer = require "gulp-autoprefixer"
gulp_coffee = require "gulp-coffee"
gulp_concat = require "gulp-concat"
gulp_notify = require "gulp-notify"
gulp_rename = require "gulp-rename"
gulp_replace = require "gulp-replace"
gulp_sass = require "gulp-sass"


# CONFIG ##########################################################################################


paths =
  csv: "source/data/*.csv"
  coffee: ["source/lib/**/*.coffee", "source/**/*.coffee"]
  index: "source/index.html"
  scss: "source/**/*.scss"


gulp_notify.logLevel(0)


# HELPER FUNCTIONS ################################################################################


logAndKillError = (err)->
  console.log "\n## Error ##"
  console.log err.toString() + "\n"
  gulp_notify.onError(
    emitError: true
    icon: false
    message: err.message
    title: "👻"
    wait: true
    )(err)
  @emit "end"


# TASKS: APP COMPILATION ##########################################################################


gulp.task "csv", ()->
  gulp.src paths.csv
    .pipe gulp_replace /"\w+?",/g, "[" # Remove first field, start each line with a [
    .pipe gulp_replace /\n/g, "],\n" # End each line with a ]
    .pipe gulp_replace /"Station.+/, "" # Remove the top line
    .pipe gulp_concat "data.js"
    .pipe gulp_replace /^/, "window.weatherData = [" # start of file
    .pipe gulp_replace /,\n$/, "\n];" # end of file
    .pipe gulp.dest "public"


gulp.task "coffee", ()->
  gulp.src paths.coffee
    .pipe gulp_concat "index.coffee"
    .pipe gulp_coffee()
    .on "error", logAndKillError
    .pipe gulp.dest "public"
    .pipe browser_sync.stream
      match: "**/*.js"


gulp.task "del:public", ()->
  del "public"


gulp.task "index", ()->
  gulp.src paths.index
    .pipe gulp.dest "public"
    .pipe browser_sync.stream
      match: "**/*.html"


gulp.task "scss", ()->
  gulp.src paths.scss
    .pipe gulp_concat "index.scss"
    .pipe gulp_sass
      errLogToConsole: true
      outputStyle: "compressed"
      precision: 2
    .on "error", logAndKillError
    .pipe gulp_autoprefixer
      browsers: "last 2 Chrome versions, last 2 ff versions, IE >= 11, Safari >= 10, iOS >= 10"
      cascade: false
      remove: false
    .pipe gulp.dest "public"
    .pipe browser_sync.stream
      match: "**/*.css"


gulp.task "serve", ()->
  browser_sync.init
    ghostMode: false
    online: true
    server:
      baseDir: "public"
    ui: false


gulp.task "watch", (cb)->
  gulp.watch paths.coffee, gulp.series "coffee"
  gulp.watch paths.index, gulp.series "index"
  gulp.watch paths.scss, gulp.series "scss"
  cb()


gulp.task "default", gulp.series "del:public", gulp.parallel("csv", "coffee", "index", "scss"), "watch", "serve"
