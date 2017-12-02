#!/usr/bin/env php
<?php
/**
 * CLI. Output a JSON file, listing E-Access Bulletin issues, grouped by year.
 *
 * @copyright Nick Freear, 26-November-2017.
 */

define( 'IS_ASCEND', false );
define( 'START_YEAR', 2000 );
define( 'END_YEAR', 2017 );
define( 'DIR', __DIR__ . '/../eab/issues/' );
define( 'INDEX_JSON', __DIR__ . '/../eab/index.json' );
// define( 'PKG_JSON', __DIR__ . '/../package.json' );
define( 'ISSUE_REGEX', '/\n([\*-] )?ISSUE (?P<issue>\d+),/s' );
define( 'TXTFILE_REGEX', '/^(?P<month>jan|[a-z]{3})20\d\d\.txt$/' );
define( 'EMAIL_REGEX', '/.+\.email\.html' );
define( 'EDITOR_REGEX', '/Editor:[ ]+(?P<ed>Tristan Parker|Dan-J-XX)/' );
define( 'TENS_ISSUE', 36 );  // http://headstar.com/ten
define( 'TENS_DATE', '2002-12-01' );  // December 2002.
define( 'NOMINAL_PUBLISH_DAY', 20 );  // Day of month.
define( 'MONTHS', 'jan,feb,mar,apr,may,jun,jul,aug,sep,oct,nov,dec' );

require_once 'ReversibleForLoop.php';

$issue_archive = [];
$count = 0;

$for = new Nfreear\ReversibleForLoop(START_YEAR, END_YEAR + 1, IS_ASCEND);

$result = $for->loop(function ($year) use (&$count, &$issue_archive) {

  $directory = DIR . $year;
  $files = scandir( $directory );

  $year_archive = [];

  foreach ($files as $file) {
    if ( ! preg_match( TXTFILE_REGEX, $file, $matches ) ) {
      continue;
    }

    $month = $matches[ 'month' ];
    $date = date_parse( "01-$month-1970" );

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
      echo "E:$month-$year";
    }

    $email_file = str_replace( '.txt', '.email.html', $file );
    $email_exist = file_exists( $directory . '/' . $email_file );

    $editor = preg_match( EDITOR_REGEX, $bulletin_text ) ? 'TP' : 'DJ';

    $year_archive[ $issue_num ] = [
      'issue' => (int) $issue_num,
      'text_file' => $file,
      'html_file' => str_replace( '.txt', '.html', $file ),
      'email_file'=> $email_exist ? $email_file : null,
      'month'  => $date[ 'month' ],
      'editor' => $editor,
    ];

    $count++;
  }

  $s_result = IS_ASCEND ? ksort( $year_archive ) : krsort( $year_archive );

  $issue_archive[ $year ] = $year_archive;
});

// var_dump( $result );

$archive = [
  'title' => 'E-Access Bulletin archive.',
  'build_time' => date( 'c' ),
  'base_url' => 'http://headstar.com/eab/issues/{year}/{file}',
  'editors' => [
    'DJ' => 'Dan Jellinek',
    'TP' => 'Tristan Parker',
  ],
  'tens_issue' => TENS_ISSUE,
  'tens_date' => TENS_DATE,
  'issue_count' => $count,
  'order_by' => IS_ASCEND ? 'ASC' : 'DESC',
  'issues' => $issue_archive,
];

$bytes = file_put_contents( INDEX_JSON, json_encode( $archive , JSON_PRETTY_PRINT ));

echo "\n$bytes bytes written\n";

// End.
