
build-dir         = "./build"
deploy-client-dir = "./public"

path = require('path')
fs = require('fs')
_ = require('underscore')

npm-tasks = [
    'grunt-livescript'
    'grunt-contrib-copy'
    'grunt-contrib-clean'
    'grunt-contrib-concat'
    'grunt-contrib-uglify'
    'grunt-contrib-less'
    'grunt-contrib-coffee'
    'grunt-contrib-jade'
    'grunt-contrib-imagemin'
    'grunt-contrib-connect'
    'grunt-contrib-compress'
    'grunt-exec'
    'grunt-concurrent'
    'grunt-cafe-mocha'
    'grunt-contrib-watch'
    'grunt-notify'
    'grunt-nodemon'
    'grunt-browserify'
    ]

load-npm-tasks = (grunt) ->
    for t in npm-tasks
        grunt.loadNpmTasks t

destination-curried = (destext, name, extension) -->
    "#{build-dir}/#{path.basename(name, extension)}#destext"

destination      = destination-curried(\js)
destination-css  = destination-curried(\css)
destination-html = destination-curried(\html)

deploy-rel-path = (name, extension, subdir) ->
    "#{path.basename(name, extension)}js"

get-config-target = (f, config) ->
    | f.type == \ls     => config.livescript.build
    | f.type == \coffee => config.coffeescript.build
    | f.type == \js     => config.copy.buildjs
    | f.type == \less   => config.less.build
    | f.type == \css    => config.copy.buildcss
    | f.type == \html   => config.copy.buildcss
    | f.type == \jade   => config.jade.build
    | otherwise         => throw "Unknown type!"

add-it-to-js = (f, config) ->
    cc = get-config-target(f, config) 
    cc.files[destination(f.name,f.type)] = f.name

add-it-to-css = (f, config) ->
    cc = get-config-target(f, config) 
    cc.files[destination-css(f.name,f.type)] = f.name

add-it-to-html = (f, config) ->
    cc = get-config-target(f, config) 
    cc.files[destination-html(f.name,f.type)] = f.name

sub-targets = -> 
    x = { }
    args = arguments
    for y in args 
        x[y] = { files: { } }
    return x


init-local-config = (files, pkg) ->

        config = {}

        # livescript 
        config.livescript = sub-targets \build
        config.copy       = sub-targets \build, \buildjs, \buildcss, \deploy, \fonts, \browserified
        config.concat     = sub-targets \build, \buildjs, \buildcss
        config.uglify     = sub-targets \build
        config.less       = sub-targets \build

        config.uglify.options = 
                report: \min 

        # less 
        config.less.options = 
                report: \min
                compress: true

        # concat
        config.jade = sub-targets \build

        config.exec = {}

        config.imagemin = {}

        if files.options?.deploy-client-dir?
            deploy-client-dir := files.options?.deploy-client-dir

        if files.options?.build-dir?
            build-dir := files.options?.build-dir

        _.extend(config, files.options)

        return config

concat-js-into = (files, dest, config) ->
        if files?
            c = []
            for f in files
                if (not f.brfy? or not f.brfy) and (not f.brfy-dep? or not f.brfy-dep)
                    c.push(destination(f.name, f.type))
            config.concat.buildjs.files[dest] = c

concat-css-into = (files, dest, config) ->
        if files?
            config.concat.buildcss.files[dest] = [ destination-css(f.name, f.type) for f in files ]

uglify-js-into = (files, dest, config) ->
        if files?
            config.uglify.build.files[dest] = [ destination(f.name, f.type) for f in files ]


module.exports = (grunt) ->

        data = fs.readFileSync '.grunt/config.json', 'utf-8'

        # console.log data

        files = JSON.parse(data)

        # console.log files.client-css

        pack = require("../package.json")
        load-npm-tasks(grunt) 

        config = init-local-config(files, pack)

        if files.client-js?
            for f in files.client-js
                f `add-it-to-js` config 
       
        if files.vendor-js? 
            for f in files.vendor-js
                f `add-it-to-js` config 

        if files.client-css?
            for f in files.client-css
                f `add-it-to-css` config 

        if files.client-html
            for f in files.client-html
                f `add-it-to-html` config 

        concat-js-into(files.client-js,   "#{build-dir}/client.js", config)
        concat-js-into(files.vendor-js,   "#{build-dir}/vendor.js", config)
        concat-css-into(files.client-css, "#{build-dir}/client.css", config)

        uglify-js-into(files.client-js,   "#{build-dir}/client.min.js", config)
        uglify-js-into(files.vendor-js,   "#{build-dir}/vendor.min.js", config)

        config.clean = {
                build: [ build-dir ]
                deploy: [ build-dir, deploy-client-dir ]
                } 

        config.copy.js = 
            * files: 
                "#{deploy-client-dir}/js/client.js"     : "#{build-dir}/client.js"
                "#{deploy-client-dir}/js/client.min.js" : "#{build-dir}/client.min.js"
                "#{deploy-client-dir}/js/vendor.js"     : "#{build-dir}/vendor.js"
                "#{deploy-client-dir}/js/vendor.min.js" : "#{build-dir}/vendor.min.js"
                "#{deploy-client-dir}/css/client.css"   : "#{build-dir}/client.css"

         
        config.copy.views = 
            * expand: true
              cwd: "#{build-dir}/"
              src: [ "*.html" ]
              dest: "#{deploy-client-dir}/html/"

        config.copy.root  =
            * expand: true
              cwd: "#{build-dir}/"
              src: [ "index.html" ]
              dest: "#{deploy-client-dir}/"

        config.copy.fonts = {}

        config.copy.fonts.files = 
            [ { expand: true, cwd: "#{f.in}/", src: ["*.#{f.files-of-type}"], dest: "#{deploy-client-dir}/fonts/" } for f in files.client-fonts ]

        config.imagemin.assets = {}
        config.imagemin.assets.files = 
            [ { expand: true, cwd: "#{f.in}/", src: ["*.#{f.files-of-type}"], dest: "#{deploy-client-dir}/img/" } for f in files.client-img ]

        if files.favicon?
            config.copy.favicon = {}
            config.copy.favicon.files = { "#{deploy-client-dir}/favicon.ico": files.favicon.name }


        config.watch = sub-targets \clientjs, \clientcss, \livereload

        config.watch.clientjs.files = []
        config.watch.clientjs.tasks = [ 'compile', 'copy:assets' ]

        for f in files.client-js
            config.watch.clientjs.files.push(f.name)

        config.watch.clientcss.files = []
        config.watch.clientcss.tasks = [ 'compile', 'copy:assets' ]

        # console.log files.client-css

        for f in (files.client-css ++ files.client-html)
            config.watch.clientcss.files.push(f.name)

        config.watch.livereload.options = { livereload: 1973, interval: 3000 }
        config.watch.livereload.files = [ "#{deploy-client-dir}/js/client.js", "#{deploy-client-dir}/js/vendor.js", "#{deploy-client-dir}/**/*.html" ]

        config.connect = {}
            ..server = 
                options: 
                    port: 9000
                    base: 'public'

        b = []
        for f in (files.client-js)
            if f.brfy? and f.brfy == true
                b.push(destination(f.name, f.type))

        config.browserify = sub-targets \build
        config.browserify.build.files = 
            "#{build-dir}/browserified.js": b

        config.copy.browserified.files = [ "#{deploy-client-dir}/js/browserified.js": "#{build-dir}/browserified.js"]

        config.copy.json = 
           files: [
                    { expand: true , src: "data/*.json" , dest: "#{deploy-client-dir}/" }
                    ]


        config.compress = 
            main:
                options: 
                    mode: 'gzip'
                files: [
                            { expand: true , src: [ "#{deploy-client-dir}/js/*.js" ]   , dest: [ "#{deploy-client-dir}/js" ]}
                            { expand: true , src: [ "#{deploy-client-dir}/css/*.css" ] , dest: [ "#{deploy-client-dir}/css" ]}
                            ]

        grunt.init-config(config)

        x = grunt.register-task

        x 'compile:js'        , [ 'livescript'        , 'copy:buildjs'   , 'concat:buildjs' ]
        x 'compile:views'     , [ 'jade'              , 'less'           , 'copy:buildcss'    , 'concat:buildcss' ]
        x 'compile'           , [ 'compile:js'        , 'compile:views']
        x 'copy:assets'       , [ 'copy:js'           , 'copy:views'     , 'copy:root'        , 'copy:fonts'        , 'imagemin'           , 'copy:json' ]
        x 'deploy'            , [ 'clean'             , 'compile'        , 'copy:assets'      , 'browserify'        , 'copy:browserified']
        x 'deploy-production' , [ 'clean'             , 'compile'        , 'uglify'           , 'copy:assets'       , 'browserify'         , 'copy:browserified' , 'compress']
        x 'default'           , [ 'deploy']
        x 'dev'               , [ 'deploy'            , 'connect:server' , 'watch' ]
        x 'test-production'   , [ 'deploy-production' , 'connect:server' , 'watch' ]







