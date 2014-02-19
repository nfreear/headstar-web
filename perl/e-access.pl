#!/usr/bin/perl -w
my $version="v1.7";
my $author="N.D.Freear";
#
# E-Access Bulletin Web build script:  HTML pages from a template and content file.
#
# (c) Nick Freear, 15 September 2003.
# ==============================================================================
# Force, $OUTPUT_AUTOFLUSH.
$| = 1;
use strict;
use warnings;

# Hack for logging in Win 9x. (Append >>)
$0=~/(.*)\./;
#NDF 28 jun 2012, my $log="logs/00$1.log";
my $log="logs/00e-access.log";
open(LOG, ">$log") or die "Failed to open:  $log\n";
warn "Building, see:  $log\n";
# Install a 'warn' handler.
$SIG{'__WARN__'} = sub { print LOG @_ };
my $now_string = gmtime;
warn "__ BUILD [$0  $version] log $now_string __\n\n";

# ==============================================================================
my $dest="../eab/";
my $src="../eab_base/";

my $base="__E-ACCESS__";
my @files=("index","about","archive","contact","language1",
            "news","news-archive","private","site","subs","search");
my $ext="html";

my $B_ARCHIVE=0;  #1.
if (1==$B_ARCHIVE) {
  # Build the archive.
  my $cmd="perl -w \"bulletins.pl\" ";
  system($cmd) && die "Failed: $!\n  $cmd\n";
  warn "Archive built successfully:  $cmd\n";
}

# Build the Web site.
foreach my $file (@files)
{
  my $src_file="$src$file.$ext";
  my $base_file="$src$base.$ext";
  my $dest_file="$dest$file.$ext";
  open(IFILE, $src_file) or die "Failed to open source: $src_file\n";
  open(BASE, $base_file) or die "Failed to open base: $base_file\n";
  open(OFILE, ">$dest_file") or die "Failed to open destination: $dest_file\n";
  select(OFILE);
  
  my $score = &combine_files;

  close(OFILE);
  close(BASE);
  close(IFILE);
  warn "Output: $dest_file\n";
  warn "Score:  $score\n";
}

warn "Web site built OK.\n";
close(LOG);
# ===============================================================================

sub combine_files
{
    my $tabindex = 1;
    my $score = 5;
    my $title = "[ EMPTY ]";
  #print "<!-- 1. Find the source's [title]. -->\n";
    while (<IFILE>)
    {
      if ($_=~/title>(.*)<\/title/) {
        --$score;
        if ($1) { $title=$1; }
        last;
      }
    }
  #print "<!-- 2. Now output start of 'base'. -->\n";
    while (<BASE>)
    {
      if ($_=~/title>(.*)<\/title/) {
        --$score;
        if ($1) { $title="$title$1"; } #"$1$title";
        print "<title>$title</title>\n";
      }
      elsif ($_=~/__EMBED_PAGE__/) {
        --$score;
        last;
      }
      elsif ($_=~/(.*?)<a (.+?)>(.*)/) {
        print "$1<a $2>$3\n"; #tabindex=\"$tabindex\"
        $tabindex++;
      }
      else {
        print $_;
      }
    }
  #print "<!-- 3. Now throw away to [body]. -->\n";
    while (<IFILE>)
    {
      if ($_=~/<body/) {
        --$score;
        last;
      }
    }
  #print "<!-- 4. Now the main content. -->\n";
    print "<!-- ==================================================================== -->\n";
    while (<IFILE>)
    {
      if ($_=~/<\/body/) {
        # Note, don't print.
        --$score;
        last;
      }
      # Tabindex: only define for 1st anchor on a line.
      elsif ($_=~/(.*?)<a (.+?)>(.*)/) {  #/(.*?)<a (.+?)>(.+?)<\/a>(.*)/
        print "$1<a $2>$3\n"; #tabindex=\"$tabindex\"
        $tabindex++;
      }
      else {
        print $_;
      }
    }
    print "<!-- ==================================================================== -->\n";
  #print "<!-- 5. Now finish the 'base'. -->\n";
    while (<BASE>)
    {
      if ($_=~/(.*?)<a (.+?)>(.*)/) {
        print "$1<a $2>$3\n"; #tabindex=\"$tabindex\"
        $tabindex++;
      }
      else {
        print $_;
      }
    }
    return $score;
}

