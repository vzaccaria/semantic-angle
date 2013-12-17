#!/usr/bin/env lsc
# options are accessed as argv.option

_       = require('underscore')
_.str   = require('underscore.string');
moment  = require 'moment'
fs      = require 'fs'
color   = require('ansi-color').set
os      = require('os')
shelljs = require('shelljs')
table   = require('ansi-color-table')

_.mixin(_.str.exports());
_.str.include('Underscore.string', 'string');

name        = "grunt-config"
description = "generates a json config for grunt"
author      = "Vittorio Zaccaria"
year        = "2013"

src = __dirname
otm = if (os.tmpdir?) then os.tmpdir() else "/var/tmp"
cwd = process.cwd()

setup-temporary-directory = ->
    name = "tmp_#{moment().format('HHmmss')}_tmp"
    dire = "#{otm}/#{name}" 
    shelljs.mkdir '-p', dire
    return dire


usage-string = """

#{color(name, \bold)}. #{description}
(c) #author, #year

Usage: #{name} [--option=V | -o V] 
"""

require! 'optimist'

argv     = optimist.usage(usage-string,
              help:
                alias: 'h', description: 'this help', default: false

                         ).boolean(\h).argv


if(argv.help)
  optimist.showHelp()
  return

files = 
  client-js: 
      { name: './assets/js/entry.ls', type: \ls }
      ...
      # Here you can have also the following options
      # 
      #  * +brfy-dep    (browserify dependency)
      #  * +brfy        (browserify root)

  vendor-js:      
      { type: 'js', name: "./assets/components/jquery/jquery.js" }
      { type: 'js', name: "./assets/components/angular/angular.js" }
      { type: 'js', name: "./assets/components/angular-route/angular-route.js" }
      { type: 'js', name: "./assets/components/moment/moment.js" }
      { type: 'js', name: "./assets/components/underscore.string/lib/underscore.string.js" }
      { type: 'js', name: "./assets/components/usable-ace/ace.js" }
      { type: 'js', name: "./assets/components/usable-ace/mode-c_cpp.js" }
      { type: 'js', name: "./assets/components/usable-ace/mode-markdown.js" }
      { type: 'js', name: "./assets/components/angular-ui-ace/ui-ace.js" }
      { type: 'js', name: "./assets/components/semantic-ui/src/modules/behavior/api.js" }
      { type: 'js', name: "./assets/components/angular-bootstrap-datetimepicker/src/js/datetimepicker.js" }
      ...


  client-css:   
      { name: "./assets/components/angular-bootstrap-datetimepicker/src/css/datetimepicker.css", type: \css }
      { name: "./assets/css/main.less", type: \less }
      ...

  client-img:
      { files-of-type: \png,  in: "./assets/img"}
      { files-of-type: \jpg,  in: "./assets/img"} 
      ...
                
  client-fonts:   
      { files-of-type: \woff, in: "./assets/fonts" } 
      { files-of-type: \otf,  in: "./assets/fonts" }
      { files-of-type: \eot,  in: "./assets/fonts" }
      { files-of-type: \svg,  in: "./assets/fonts" }
      { files-of-type: \ttf,  in: "./assets/fonts" } 
      ...

  client-html: 
      { name: "./assets/views/index.jade",      type: \jade, +root  }
      { name: "./assets/views/example-view.jade",       type: \jade } 
      ...

  # favicon:
      # { name: "./assets/favicon.ico" }
      # ...
                     
console.log JSON.stringify(files)




