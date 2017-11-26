#!/usr/bin/env php
<?php
/**
 * CLI. Output a JSON file, listing E-Access Bulletin issues, grouped by year.
 *
 * @copyright Nick Freear, 26-November-2017.
 */

define( 'START_YEAR', 2000 );
define( 'END_YEAR', 2017 );
define( 'DIR', __DIR__ . '/../eab/issues/' );
define( 'INDEX_JSON', __DIR__ . '/../eab/index.json' );
define( 'ISSUE_REGEX', '/\n([\*-] )?ISSUE (?P<issue>\d+),/s' );

$archive = [];
$count = 0;

for ($year = START_YEAR; $year <= END_YEAR; $year++) {

  $directory = DIR . $year;
  $files = scandir( $directory );

  $year_archive = [];

  foreach ($files as $file) {
    if ( ! preg_match( '/.+20\d\d\.txt/', $file ) ) {
      continue;
    }

    $bulletin_text = file_get_contents( $directory . '/' . $file );

    if (preg_match( ISSUE_REGEX, $bulletin_text, $matches )) {
      $issue_num = $matches[ 'issue' ];
      echo '.';
    }
    elseif ($year === 2000) {
      $issue_num = 1;
      echo '1';
    }
    else {
      $issue_num = -1;
      echo 'E' . $year;
    }

    $year_archive[ $issue_num ] = [
      'issue' => (int) $issue_num,
      'text_file' => $file,
      'html_file' => str_replace( '.txt', '.html', $file ),
    ];

    $count++;
  }

  $archive[ $year ] = $year_archive;
}

$archive = [
  'title' => 'E-Access Bulletin archive.',
  'time' => date( 'c' ),
  'base_url' => 'http://headstar.com/eab/issues/{year}/{file}',
  'issue_count' => $count,
  'issues' => $archive,
];

$bytes = file_put_contents( INDEX_JSON, json_encode( $archive , JSON_PRETTY_PRINT ));

echo "\n$bytes bytes written\n";

// End.
