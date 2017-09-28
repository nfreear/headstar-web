/*!
  E-Access Bulletin task-runner | © 2016 Nick Freear.
*/

var COUNT_CMD = 'find eab/issues/ -type f | grep ".txt" | wc -l';
var exec = require('child_process').execSync;
// var exec = require('child_process').exec;

module.exports = function (grunt) {
  'use strict';

  grunt.log.subhead('## Running EAB build and tests.');
  grunt.log.writeln();

  var bulletinCount = (exec(COUNT_CMD) + '').replace(/\s+/g, '');

  grunt.log.oklns('Bulletin count:', bulletinCount);
  // bulletinCount(bcount);

  grunt.initConfig({
    exec: {
      // count: COUNT_CMD,
      // build: 'perl perl/bulletins.pl && perl perl/e-access.pl',
      bulletins: 'perl perl/bulletins.pl',
      build_site: 'perl perl/e-access.pl'
    },
    jshint: {
      options: {
        bitwise: true,
        curly: true,
        eqeqeq: true,
        futurehostile: true,
        laxcomma: true,
        undef: true,
        // https://github.com/jshint/jshint/blob/master/src/messages.js#L80
        '-W033': true,      // Ignore Missing semicolon;
        // '-W030': true,    // Ignore Expected an assignment or function call and instead saw an expression;
        // '-W069': true,    // Ignore {a} is better written in dot notation;
        globals: { window: false, ga: false }
      },
      eab: [ 'eab/includes/**/*.js', '!eab/**/*BAK.js' ],
      grunt: {
        options: { node: true },
        files: { src: 'Gruntfile.js' }
      }
    },
    htmlhint: {
      base: [ 'eab_base/*__.html' ],
      site: [ 'eab/*.html', '!eab/archive.html', '!eab/search.html' ],
      search: {
        src: 'eab/search.html',
        options: { 'attr-lowercase': false }
      },
      bulletins: {
        src: 'eab/issues/**/*.html',
        options: { 'attr-value-double-quotes': false }
      },
      ten: {
        src: 'ten/*.html'
        //, options: { 'tag-pair': false }
      }
    },
    validate_xml: {
      labels_rdf: 'eab/*.rdf',
      opensearch_xml: 'eab/*.xml'
    },
    'string-replace': {
      badgesvg: {
        files: { 'eab/badge.svg': 'eab/badge.svg' },
        options: {
          replacements: [{
            pattern: /class="COUNT">(\d+)<\//ig,
            replacement: 'class="COUNT">' + bulletinCount + '</'
          }]
        }
      },
      packagejson: {
        files: { 'package.json': 'package.json' },
        options: {
          replacements: [{
            pattern: /"x-bulletin-count": ?(\d+)/,
            replacement: '"x-bulletin-count": ' + bulletinCount
          }]
        }
      }
    },
    notify: {
      watch: {
        options: { title: 'EAB watcher', message: 'Re-build & test ran OK.' }
      }
    },
    notify_hooks: {
      options: { duration: 2, /* Seconds */ title: 'EAB', success: true }
    },
    watch: {
      eab: { files: '<%= dir %>/less/**/*.less', tasks: [ 'less:eab', 'notify' ] }
    }
  });

  grunt.loadNpmTasks('grunt-exec');
  grunt.loadNpmTasks('grunt-string-replace');
  grunt.loadNpmTasks('grunt-contrib-jshint');
  grunt.loadNpmTasks('grunt-htmlhint');
  // 'grunt-contrib-validate-xml' gives MUCH better feedback than 'grunt-xml-validator'!
  grunt.loadNpmTasks('grunt-contrib-validate-xml');

  // grunt.loadNpmTasks('grunt-notify');
  // grunt.task.run('notify_hooks');


  grunt.registerTask('default', [ 'exec', 'jshint', 'htmlhint', 'validate_xml', 'string-replace' ]);
};

/*
function bulletinCount (bcount) {
  //var bcount = 999; // 204!

  exec(COUNT_CMD, function (err, stdout, stderr) {
    if (err) {
      console.error(err);
      return;
    }

    bcount = stdout;

    console.log('Bulletin count: ', stdout);
  });
}
*/
