#!/usr/bin/perl -w
use constant VERSION => 'v1.12';
use constant AUTHOR  => 'N.D.Freear';
#
# Convert a set of Text Email Newsletters to HTML/ RSS and archive page.
#   http://www.headstar.com/ten
#
# Example TEN:  http://www.headstar.com/eab/issues/2002/dec2002.txt
#
# Copyright N.D.Freear, 16 July 2003.
# ==============================================================================
# Force, $OUTPUT_AUTOFLUSH.
$| = 1;
use strict;
use warnings;
&log_to_file();

# Parsers.
my $tens2html="perl -w tens2html.pl";
# Pre-TENS only.
my $txt2html ="perl -w ..\\..\\txt2html\\perl\\txt2html.pl -l ..\\..\\txt2html\\perl\\txt2html.dict";
my $tidy = "\"/_e/apps/tidy/tidy.exe\" -access 1 -language en -utf8 -asxhtml";

my $idx_file="../eab_base/archive.html";
my $url_stem="http://www.headstar.com/eab";
my $url_issues="$url_stem/issues";

my $b_parse = 1;
#use constant B_PARSE => 1;
use constant START_YEAR => 2000; #!2000!
use constant START_ISSUE=> 149; #149 jun 2012; #128 mar 2011; #127; #119; #109 Jan2009; #95; #84; #77;   #25 Jan 2002. 13 Jan 2001. 61 Jan 2005. 70 Oct 2005.
#my $end_issue=55;    #53, May 2004; 63, Mar 2005
use constant TENS_ISSUE => 36;   #36, Dec 2002.
# Release day about 20th of the month, 18.
use constant RELEASE_MDAY => 25;  #16; #7;
my @months=("January","February","March","April","May","June",
            "July","August","September","October","November","December");

my $this_year=&this_year();
my $this_mon=&this_month() - 0;
# Release day about 20th of the month, 18.
if (&this_mday() < RELEASE_MDAY)
{
  $this_mon--;
}
# Set the issue from the month (49, Jan 2004) (61, Jan 2005).
my $this_year_start = 12 * ($this_year - START_YEAR) + 1; #49
warn "> This year start: $this_year_start\n";
my $end_issue = $this_year_start + $this_mon;
my $this_month=$months[$this_mon];

#open(LOG, ">bulletins.log") or die "Failed to open: bulletins.log\n";
open(OFILE, ">$idx_file") or die "Failed to open file: $!\n  $idx_file\n";
select(OFILE);
&prn_html_open("Bulletin Archive");
warn "Archive file: $idx_file\n";

# Links to current issue, and each year.
print("<ul id=\"notes\">\n");
print("<li>Current issue;  <a href=\"#current\">$this_month $this_year</a>.</li>\n");
warn "Current issue, $end_issue:  $this_month $this_year.\n";
print("<li>Years;");
# Print <a> on new lines so that 'tabindex' will be defined for each.
for (my $year = START_YEAR; $year <= $this_year; ++$year) {
  print("  <a href=\"#a$year\">$year</a>,\n");
}
print("</li>\n");
print("<li>Note; <a href=\"http://www.headstar.com/ten\">\n  <abbr title=\"Text Email Newsletter Standard\">TENS</abbr></a>");
print(" introduced issue ". TENS_ISSUE .", December 2002.</li>\n");
print("</ul>\n\n");

# Reverse chronological archive.
my $mon=$this_mon;   #$start_mon;
my $year=$this_year; #$start_year;
print("<h3 id=\"a$year\">$year</h3>\n<ul class=\"Archive\">\n");
warn "Archive for new year: $year  (reverse chronological).\n";

#WAS:  for(my $issue=$start_issue; $issue<=$end_issue; ++$issue)
for (my $issue=$end_issue; $issue>=1; --$issue)
{
  my $Month=$months[$mon];
  my $mnth = lc(substr($Month, 0,3));
  #warn "$mon $Month $mnth\n";
  my $title="E-Access Bulletin- Issue $issue, $Month $year";
  my $tens_link="issues/$year/$mnth$year.txt";
  my $html_link="issues/$year/$mnth$year.html";

  my $tens_file="../eab/$tens_link";
  my $html_file="../eab/$html_link";
  
  if( 1==$b_parse && (-r $tens_file) ){
    #Ok, parse.

    # If success, and post-TENS convert to HTML.
    if ($issue >= TENS_ISSUE) {
      my $cmd="$tens2html $tens_file";

      system($cmd) && die "Failed: $cmd\n";
      warn "Parsing TENS, issue $issue:  $cmd\n";
    }
    else {
      # Pre-TENS, > $html_file
      my $stem="..\\eab_base";
      my $insert_args="-ah $stem\\__EAB_HEAD__.html -pp $stem\\_EAB_PREPEND_.html -ab $stem\\_EAB_APPEND_.html";
      #my $head_file="..\\eab_base\\__EAB_HEAD__.html";  #-ah $head_file
      my $cmd="$txt2html -o $html_file.tmp $insert_args -t \"$title\" -H \"\\*\" $tens_file ";
      
      system($cmd) && die "Failed: $!\n  $cmd\n";
      warn "Parsing pre-TENS, issue $issue:  $txt2html ... $tens_file\n";
      
      # Call the tidy app, exit=1 so don't die.
      $cmd="$tidy -o \"$html_file\" -f \"logs/tidy_errors.log\" -b \"$html_file.tmp\"";
      system($cmd);
      my $exit_value  = $? >> 8;
      my $signal_num  = $? & 127;
      my $dumped_core = $? & 128;
      warn "Tidy exit code, $exit_value:  $tidy ... \"$html_file.tmp\" \n" ;
    }

    if( 1==$b_parse && $issue <= START_ISSUE ){
      $b_parse = 0;
      warn "No longer parsing, issue: $issue ...\n";
    }
  }
  # Test HTML, add links.
  if (-r $html_file) {
    
    if ($mon == $this_mon && $year == $this_year) {
      print("<li id=\"current\">");
    } else {
      print("<li>");
    }
    # Split the 2nd <a /> so that 'tabindex' will only be defined for 1st. &#183; '·' (middle) dot.
    printf("Issue %02d", $issue);
    print(";  <a href=\"$html_link\">$Month $year HTML</a>, <a\n");
    print("  href=\"$tens_link\">$Month $year text</a>.\n</li>\n");
  } else {
    warn "Warning, cannot read: $!\n  $html_file.\n";
    #end loop.
  }
  
  if ($issue <= 1) {
    warn "Completed issue, $issue: $mnth $year.\n";
  }
  # Reverse chronological archive.  WAS: if($mon < 11) { ++$mon; }
  if ($mon > 0) {
    --$mon;
  } else { #WAS: $mon=0; ++$year;
    $mon=11;
    --$year;
    print("</ul>\n");
    if ($issue > 1) {
      print("\n<h3 id=\"a$year\">$year</h3>\n<ul class=\"Archive\">\n");
      warn "Archive for new year: $year.\n";
    }
  }
}
&prn_html_close;
my $now_string = gmtime;
warn "\n__ log $now_string __\n";
close(OFILE);
close(LOG);

# ==============================================================================
sub prn_html_open {
  my $title=$_[0];
  print("<?xml version='1.0' encoding='utf-8'?>\n");
  print("<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\"\n \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">\n");
  print("<html>\n");
	print("<head>\n<title>$title</title>\n");
	print("</head>\n<body>\n");
	
	print("<div id=\"bulletin\">\n");
	print("<h2><a class=\"Tab\">$title</a></h2>\n\n");
}
sub prn_html_close {
  my $time=&format_gmtime;
  print("<p id=\"stamp\">Last build: ",$time," <abbr title=\"Greenwich Mean Time\">GMT</abbr>.</p>\n");

  print("</div><!--id=bulletin-->\n\n<div id=\"comment\"> </div>\n");
  print("</body>\n</html>\n");
}

sub format_gmtime {
  my ($sec,$min,$hr,$mday,$mon,$yr, $wday,$yday,$isdst) = gmtime(time);
  $yr+=1900;
  return sprintf("%02d %s %02d %02d:%02d", $mday, $months[$mon], $yr, $hr, $min);
}
sub this_mday {
  my ($sec,$min,$hr,$mday,$mon,$yr, $wday,$yday,$isdst) = gmtime(time);
  return $mday;
}
sub this_month {
  my ($sec,$min,$hr,$mday,$mon,$yr, $wday,$yday,$isdst) = gmtime(time);
  return $mon;
}
sub this_year {
  my ($sec,$min,$hr,$mday,$mon,$yr, $wday,$yday,$isdst) = gmtime(time);
  $yr+=1900;
  return $yr;
}

sub log_to_file {
  my $mode = '>';
  $mode = $_[0] if (defined( $_[0] ));
  # Hack for logging in Win 9x (>> append).
  $0=~/(.*)\.(.*)/;
  my $em='';
  $em = 'em_perl' if ($2 eq 'bat');
  #NDF 28 June 2012: my $log="logs/00$1.log";
  my $log="logs/00bulletins.log";
  open( LOG, "$mode$log" ) or die "Failed to open, $!: $mode$log\n";  #"$mode$log"
  warn "Building, see:  $1.log\n";
  # Install a 'warn' handler.
  $SIG{'__WARN__'} = sub { print LOG @_ };
  my $now_string = localtime();
  warn "__ BUILD [$0  ". VERSION ." $em] log $now_string __\n\n";
}

