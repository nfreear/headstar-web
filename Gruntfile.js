/*!
  E-Access Bulletin task-runner | © 2016 Nick Freear.
*/

var INDEX_JSON = './eab/index.json';

module.exports = function (grunt) {
  'use strict';

  grunt.log.subhead('# Running E-Access Bulletin build and tests.');

  grunt.initConfig({
    exec: {
      bulletins_perl: 'perl perl/bulletins.pl',
      build_site: 'perl perl/e-access.pl',
      index_json: 'perl/index-json.php',
      php_lint: 'php -l **/i*.php',
      semistandard: 'node_modules/.bin/semistandard'
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
      badge_svg: {
        files: { 'eab/badge.svg': 'eab/badge.svg' },
        options: {
          replacements: [{
            pattern: /class="COUNT">(\d+)<\//ig,
            replacement: 'class="COUNT"><%= bulletinCount %></'
          }]
        }
      },
      package_json: {
        files: { 'package.json': 'package.json' },
        options: {
          replacements: [{
            pattern: /"x-bulletin-count": ?(\d+)/,
            replacement: '"x-bulletin-count": <%= bulletinCount %>'
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

  grunt.registerTask('default', [ 'exec', 'jshint', 'htmlhint', 'validate_xml', 'issue-count' ]);

  grunt.registerTask('issue-count', [ 'set-issue-count', 'string-replace' ]);

  grunt.registerTask('set-issue-count', function () {
    var issueCount = require(INDEX_JSON).issue_count;

    grunt.config.set('bulletinCount', issueCount);

    grunt.log.oklns('Bulletin issue count:', issueCount);
  });
};

// End.
