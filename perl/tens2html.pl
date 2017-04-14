#!/usr/bin/perl -w
my $version="v1.14";
my $author="N.D.Freear";
#
# Convert a Text Email Newsletter Standard (TENS) document to XHTML 1.0.
#   http://www.headstar.com/ten
#
# Example TEN:  http://www.headstar.com/eab/issues/2003/jul2003.txt
#
# Copyright (c) Nick Freear 2003-2010.
# Copyright 2003-07-22/2010-07-03 N.D.Freear.
# ==============================================================================
# Force, $OUTPUT_AUTOFLUSH.
$| = 1;
use strict;
use warnings;

if ($#ARGV == -1) {
  die "Usage error.\n";
}
my $tens_file=$ARGV[0];

# Hack for logging in Win 9x. (Append >>)
$ARGV[0]=~/.*\/(.*?)\./;
my $log="logs/$1.log";
#$0=~/(.*)\./;
open(LOG, ">$log") or die "Failed to open:  $log\n";
warn "Building, see:  $log\n";
# Install a 'warn' handler.
$SIG{'__WARN__'} = sub { print LOG @_ };
my $now_string = gmtime;
warn "__ BUILD [$0  $version] log $now_string __\n\n";

# ==============================================================================
my $home_url="http://www.headstar.com/eab";

#while (( $#ARGV > -1 ) && ( $ARGV[0] =~ /^[-+].+/ ) )
{
  unless (-r $tens_file) {
      die "Can't find or read file: $tens_file.\n";
  }
}
warn "Input file: $tens_file\n\n";
unless ($tens_file=~/(.*)\.txt/) {
  die "Failed to find stem: $tens_file\n";
}
my $file_stem=$1;
my $html_file="$file_stem.html";
#my $url_issues= "$home_url/issues";

if (-e $html_file) {
  warn "Warning: file already exists: $html_file.\n";
}
open(IFILE, "<:utf8", "$tens_file") or die "Failed to open: $tens_file\n";  #||
open(OFILE, ">:utf8", "$html_file") or die "Failed to open: $html_file\n";
select(OFILE);

# Constants.
my $c_toc_max=99;

my $c_tens=1;
my $c_head_1=2; #Main.
my $c_head_2=4; #Section.
my $c_head_3=8; #Item.
my $c_head_toc=16;
my $c_contents=32;
my $c_para=64;
my $c_person=128;

# Globals.
    my @g_contents;

    my $idx=0;
    my $item_num=0;
    my $state=0;
    my $chunk="";
#    my $line="";

    my $toc_count=0;
    my $issue_num=0;
    my $yr=0;
    my $mname="";

    while (<IFILE>)
    {
      $idx++;
      # Ensure ASCII chars only.
      my $line=&entities($_, $idx);

# Filter main title.
      if ($_=~/\+\+(E-ACCESS BULLETIN)/) { #/^\+\+\+(.*)/)
        warn "Found +++, heading 1: $1\n";
        $state=$c_head_1;
        $line=$1;
        #warn "Warning line $idx: this came before the main title: \"\n$chunk\n\"\n";
        $chunk="";
      }
# Filter section titles.
      elsif ($_=~/^\+\+(.*)/) {
        warn "Found ++, heading 2: $1\n";
        $state=$c_head_2;
        $line=$1;
        if ($1=~/CONTENTS/i) {
          $state=$c_head_toc;  #$c_contents;
        }
        &prn_chunk;
        if ($toc_count>0) { $item_num++; }
      }
# Filter +How to Recieve
      elsif ($_=~/^\+(How to Receive the Bulletin.*)/i) {
        my $item_ttl=$1;
        $chunk="";
        print("<div id=\"subscribe\"><h3><b class=\"Ps\">+</b>$item_ttl</h3>\n");
      }
# Filter +PERSONNEL title.
      elsif ($_=~/^\+(PERSONNEL.*)/i) {
        my $item_ttl=&caps($1);
        $state=$c_person;
        $chunk="";
        print("<div id=\"personnel\"><h3><b class=\"Ps\">+</b>$item_ttl</h3>\n");
        print("<ul>");
      }
# Filter item titles WITH numbers.
      elsif ($_=~/^\+(\d*): (.*)/) {
        #warn "> FILTER:  $1 | $2 | $3 | $4\n";
        my $num = $1;
        my $item_ttl="$1: ";
        my $after = $2;
        $after=~/(.*)(:|\?)(.*)/;
        if ($3) {
         warn "> ITEM 1:  $item_ttl | $2 | $3\n";
          $item_ttl .= $1 . $2;
          print("<h3 id=\"i$issue_num-$num\"><b class=\"Ps\">+</b>$item_ttl</h3>\n");
          $state= $c_para;
          $line = $3;
        } else {
         warn "> ITEM 2:  $item_ttl | $after\n";
          $item_ttl .= $after;
          $state= $c_head_3;
          $line = $item_ttl;
        }
        &prn_chunk;
        if ($toc_count>0) { $item_num++; }
      }
# Filter item titles W/O numbers.
      elsif ($_=~/^\+([A-Z|\s]*)([:\s]?)(.*)/) {
        my $item_ttl="$1$2";
        my $item_sep=$2;
        $line=$3;
        if (length($item_sep)>0) {
          print("<h3><b class=\"Ps\">+</b>$item_ttl</h3>\n");
          $state=$c_para;
        } else {
          $state=$c_head_3;
          $line=$item_ttl;
        }
        &prn_chunk;
        if ($toc_count>0) { $item_num++; }
      }
# Filter end of section.
      elsif ($_=~/^\[(.*)\sends\.?\]/) {
        $state=$c_tens;
        if ($1=~/issue/) { $state=0; }
        print("<!--TODO: section end-->\n");
        &prn_chunk;
        $line="";
        print("<p class=\"EndMark\">[$1 ends].</p>\n");
      }
# Filter end of heading, contents-item or paragraph.
      elsif ($_=~/^\s{0,2}(\r|\n)/) {
         if ($state==$c_head_1) {
           my $ttl= $chunk; #=&caps(
           $ttl =~ s/(Access To Technology For All, Regardless Of Ability)//i; #@todo.
           $ttl = caps($ttl);
           &prn_html_open;
           &prn_html_head($ttl);
           print("<body>\n<div id=\"eab\">\n");
           &prn_switch();
           print("<h1><b class=\"Ps\">+++</b>$ttl</h1>\n");
           print("<p class=\"strap\">$1</p>");  #@todo.
           &prn_menu("menu");
           print("<div id=\"main\">");
           $chunk="";
           $state=$c_para;
         }
         elsif ($state==$c_head_2) {
           my $ttl=$chunk;  #&caps
           print("<h2><b class=\"Ps\">++</b>$ttl</h2>\n");  #id=\"i$issue_num-$item_num\"
           print("<p class=\"Goto\"><a href=\"#toc\">Contents</a>.</p>\n");
           $chunk="";
           $state=$c_para;
         }
         elsif ($state==$c_head_3) {
           my $ttl=&caps($chunk);

           if ( ($item_num=sprintf("%02d", &srch_contents($ttl))) > 0 ) {
             print("<h3 id=\"i$issue_num-$item_num\"><b class=\"Ps\">+</b>$ttl</h3>\n");
           } else {
             print("<h3 ><b class=\"Ps\">+</b>$ttl</h3>\n");
           }
           $chunk="";
           $state=$c_para;
         }
         elsif ($state==$c_head_toc) {  #$c_contents
           $chunk="";
           &prn_contents($issue_num);
           $toc_count=$#g_contents+1;
           warn "\$toc_count=$toc_count\n";
           $state=$c_para;  #$c_contents
         }
         elsif ($state==$c_para) {
           &prn_chunk;
           $state=$c_para;
         }
         elsif ($state==$c_person) {
           $chunk="";
           print("</ul></div>\n");
           $state=$c_para;
         }
         #ELSE :Catch-all caused bug.
      }
# Filter personnel item.
      elsif ($state==$c_person) {
        print("<li>$_</li>");
      }
# Filter issue_num and date
      elsif ($_=~/-\sISSUE\s(\d+),\s(.*)\s(\d+)/i) {
          $issue_num=$1;
          $mname=$2;
          $yr=$3;
      }
# Filter repeated characters
      if ($_=~/([-|=|*]){3,}/) {
        if ($state==$c_tens) {
          print("<hr /><!-- $1$1 -->\n");
          warn "Warning line $idx: a line of repeated characters is not valid for TENS - replaced with <hr />.\n";
        }
      }
# Concatenate lines.
      else {
        $line=urlify($line);
        #DEBUG
#        $chunk.="<!--$idx,$state--> $line";
        #RELEASE
        if ($state==$c_para) {
          $chunk.=" $line";
        } else {
          $chunk.=$line;
        }
      }
    }
my $time=&format_gmtime;
#print("<p id=\"stamp\">$version \$ $time \$</p>");

print("</div>\n");
&prn_foot_nav();
print("</div>\n</body>\n");
&prn_html_close;
close(IFILE);
close(OFILE);

# ==============================================================================
sub prn_html_open {
  #print("<?xml version='1.0' encoding='utf-8'?>\n");
  #print("<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\"\n \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">\n");
  #print("<html lang=\"en-GB\" xml:lang=\"en\" xmlns=\"http://www.w3.org/1999/xhtml\">\n");
  print("<!doctype html><html lang=\"en\">"); #NDF, 4 July 2010.
}
sub prn_html_close {
  print("</html>\n");
}
sub prn_html_head {
  my $title=$_[0];
  print("<title>$title</title>\n");
  #iso8859-1 --> utf-8.
  print("<meta charset=\"utf-8\" />\n");
  print("<meta name=\"generator\" content=\"$0 $version\" />\n");
  print("<meta name=\"dc:Creator\" content=\"$author\" />\n\n");

  print("<link rel=\"home\"     href=\"$home_url\" />\n");
  print("<link rel=\"help\"     href=\"$home_url/site.html#help\" />\n");
  print("<link rel=\"index\"    href=\"$home_url/archive.html\" title=\"Archive\" />\n");
  print("<link rel=\"contents\" href=\"#toc\"  title=\"Contents for this issue.\" />\n");

  (my $prev, my $next) = &prev_next($html_file);
  print("<link rel=\"prev\" href=\"$prev\" />\n");
  print("<link rel=\"next\" href=\"$next\" />\n");
  &prn_switch_links();
}
sub prn_switch_links {
  print("<link rel='stylesheet' media='all' href='../../includes/noscript.css' type='text/css' />\n");
  print("<link rel='alternate stylesheet' media='screen' href='../../includes/textonly.css' type='text/css' title='Text' />\n");
  print("<link rel='alternate stylesheet' media='screen' href='../../includes/graphic.css'  type='text/css' title='Graphic' />\n");
  print("<script src='../../includes/styleswitcher.js' type='text/javascript'></script>\n");
}
sub prn_switch {
  print("<ul id='switch'>\n");
  print("<li><a href='$home_url/site.html#access' tabindex='1' accesskey='0' class='Key' title='[0] Access key details'>Help</a></li>\n");
  print("<li><a href='#main' accesskey='S' class='Key' title='Skip navigation'>skip</a></li>\n");
  print("<li><a href='#' title='Text-only version of the page' onclick=\"EAB.setActiveStyleSheet('Text', event); return false;\">text-only</a></li>\n");
  print("<li><a href='#' title='Graphical version of the page' onclick=\"EAB.setActiveStyleSheet('Graphic', event); return false;\">graphical</a></li>\n");
  print("</ul>\n");
}
sub prn_menu {
  my $id=$_[0];
  print("<ul id='menu' role='navigation'>\n");
  print("<li><h3><a tabindex='2' class='Bookmark'>Menu</a></h3></li>\n");
  print("<li><a href='#toc' title='Contents for this issue'>Contents</a></li>\n");
  print("<li><a href='$home_url' accesskey='1' class='Key' title='Bulletin home'>Home</a></li>\n");
  print("<li><a href='$home_url/archive.html'>Archive</a></li>\n");
  print("</ul>\n");
}
sub prn_foot_nav {
  print("<ul id='totop'>\n");
  print("<li><h3>Menu</h3></li>\n");
  print("<li><a href='#toc' title='Contents for this issue'>Contents</a></li>\n");
  print("<li><a href='$home_url' title='Bulletin home'>Home</a></li>\n");
  print("<li><a href='$home_url/archive.html'>Archive</a></li>\n");
  print("</ul>\n");
}
sub prn_chunk {
  if ($chunk=~/\w/) {
    print("<p>$chunk</p>\n");
  }
  $chunk="";
}
# ==============================================================================
sub srch_contents {
  my $find=$_[0];
  if ($find=~/^\d+: (.*)/) { $find=$1; }
  for (my $idx=0; $idx<$#g_contents; ++$idx) {
#    print "<!--TITLE: $find | $g_contents[$idx]-->\n";
    if ($g_contents[$idx]=~/$find/i) {
      warn "Found 'contents' match: $idx.\n";
      return (++$idx);
    }
  }
  warn "Warning: not found a 'contents' match: $find\n";
  return 0;
}
sub prn_contents {
  my $issue=$_[0];
  print("<div id=\"contents\" role=\"navigation\">\n");
  print("<h2><b class=\"Ps\">++</b>Issue $issue Contents.</h2>\n");
  print("<ol id=\"toc\">\n");
  my $item="";
  my $t_idx=1;
  my $brief_done;
  while ($t_idx>0 && $t_idx<$c_toc_max) {
    ++$t_idx;
    my $line=<IFILE>;
# Contents: filter 'News in brief'.
    if ($line=~/(.* in brief: )(.*)/) {

      #IS LOOP REDUNDANT?!
      warn ">> FOUND 1: $1 | $2\n";

      if (&prn_item($item,$issue)) { $item=""; }

       print(" <li>$1</li>\n");
       $line=$2;
       while (<IFILE>) {
         if (/^\s/) { last; }
         chomp($_);
         $line.=" $_";
       }
       while ($line && $t_idx<$c_toc_max) {
         ++$t_idx;
         $line=~/(\d{2}): (.+?)(;|\.)(.*)/;
         &prn_item($2, $issue, $3);
         $line=$4;
       }
    }
# Contents: filter 'The Inbox'.
    if ($line=~/The inbox/) {
      if (&prn_item($item,$issue)) { $item=""; }

       print(" <li>$line</li>\n");
       $line="";
       while (<IFILE>) {
         if (/^\s/) { last; }
         chomp($_);
         $line.=" $_";
       }
       while ($line && $t_idx<$c_toc_max) {
         ++$t_idx;
         $line=~/(\d{2}): (.+?)(;|\.)(.*)/;
         &prn_item($2, $issue, $3);
         $line=$4;
       }
    }
# Contents: filter sections.
    elsif ($line=~/(Section.*)/) {
      if (&prn_item($item,$issue)) { $item=""; }

      print("  <li>$1</li>\n");
    }
# Contents: filter items.
    elsif ($line=~/([News]?.*?)(\d{2}: )(.*)/) {

      warn ">> FOUND 2: $1 | $2 | $3\n"; #| $4 | $5\n";

      if (&prn_item($item,$issue)) { $item=""; }

      if ($1) {
        if (! $brief_done) {
          #OK, News in brief...
          warn "OK, News in brief\n";
          print("  <li>$1</li>\n");
        }

        my $rem=$3;
        $rem=~/(.+?)(;|\.)(.*)/;
        warn "Found: $1 | $2 | $3\n";
        &prn_item($1, $issue, $2);
        if ($brief_done) {
          $item=$3;
        }
        $brief_done=1;
      }
      else {
        $item=$3;
      }
    }
# Contents: filter 'end'.
    elsif ($line=~/^\[(.*)/) {  # IF NOT
      if ($1=~/Contents/) {
        my $line=$idx+$t_idx;
        warn "Warning line $line: expected [Contents ends].\n";
      }
      if (&prn_item($item,$issue)) { $item=""; }

      print("</ol>\n<p class=\"EndMark\">$line</p>\n");
      print("</div>\n");
      return $t_idx;  #@contents
    }
# Contents: filter continuation lines.
    else {
      chomp($line);
      $item.=" $line";
    }
  }
}
sub prn_item {
  my $item=$_[0];
  my $issue=$_[1];
  my $sep="";
  if ($_[2]) {
    $sep=$_[2];
  }
  if (length($item)>1) {
    push(@g_contents, $item);
    my $t_idx=sprintf("%02d", $#g_contents+1 );
    print("  <li><i class=\"Ns\">$t_idx: </i><a href=\"#i$issue-$t_idx\">$item</a>$sep</li>\n");
    return 1;
  } return 0;
}
# ==============================================================================

sub format_gmtime {
  (my $sec,my $min,my $hr,my $mday,my $mon,my $yr,my $wday,my %yday,my $isdst)=gmtime(time);
  $yr+=1900; #if ($yr<1900)
  $mon++;
  return sprintf("%d-%02d-%02d %02d:%02d:%02d GMT", $yr,$mon,$mday,$hr,$min,$sec );
}

# caps: Make All Words Title-Cased ('Perl Cookbook', Christiansen et al, 1998, O'Reilly, p165).
#
sub caps {
  my @parms=@_;
  if ($parms[0]=~/</) {
    warn "Warning: not title-casing possible HTML:\n  $parms[0]\n";
    return $parms[0];
  }
  for (@parms) { s/(\w+)/\u\L$1/g }
  # 'wantarray' checks whether we were called in list context.
  return wantarray ? @parms : $parms[0];
}

# urlify: program to wrap HTML links around URL-like constructs ('Perl Cookbook', p210).
#
sub urlify {
  my $line=$_[0];
  if ($line=~m/(.*[(|,|;|\s])?(\S*?)\@(\S*?)([\)|\]|,|;|\s].*)/) {
    $line="$1<a href=\"mailto:$2\@$3\">$2\@$3</a>$4";
  }
  elsif ($line=~m/(.*)(http\:\/\/)(\S*?)([\)|,|;|\s].*)/) {
    $line="$1<a href=\"$2$3\">$2$3</a>\n$4";
  }
  return $line;
}

# entities: Replace non-ASCII with numeric entities &#00;
#           Note: TENS at present does not allow non-ASCII.

#http://stackoverflow.com/questions/487855/how-can-i-replace-all-the-html-encoded-accents-in-perl
#perl -MHTML::Entities -le 'print "If this prints, the it is installed"'
use HTML::Entities;

sub entities {
  my $line=$_[0];
  my $ln_no=$_[1];

#return encode_entities($line, '<>&"£'); #"\200-\377");
return encode_entities($line, '<>&"£‘’“”'); #NDF, 6 April 2011.

#while ($string =~ m/&[^#a]/&amp;/g) {
#  print "Found '$&'.  Next attempt at character " . pos($string)+1 . "\n";
#}
#return $string;

  my $len = length($line);
  for (my $ch=0; $ch<$len; $ch++)
  {
    my $char = substr($line, $ch, 1);
    my $ord  = ord($char);

    my $after = substr($line, ($ch+1));
    my $before = substr($line, 0, $ch);

my $ch_ = substr($after, 0, 1);

    #TODO: 1. Not allowed in HTML.
    #($char eq "\"" || $char eq "<" || $char eq ">" || $char eq "&")
    if ($char eq "&") { #&& ($ch_ neq "a" || $ch_ neq "#") {
      warn "Warning, replacing XML entity '&' (line $ln_no, $ch): $line\n";
      return $before ."&amp;". $after;
    }
    if ($ord == 163) { #$char eq "£") {
      warn "Warning, replacing pound entity (line $ln_no, $ch): $line\n";
      $line = $before ."&#163;". $after;
      $line = &entities($line, $ln_no);
    }

    if ($ord > 126) {
      #2. ISO 8859-1 Character Entities - accents, OK.
      if  ($ord >= 192 && $ord <= 255) {
        #my $after = substr($line, ($ch+1));
        #my $before = substr($line, 0, $ch);
        $line = $before ."&#$ord;". $after;
        warn "Warning, replacing non-ASCII character $ord (line $ln_no, $ch): $line\n";
        # RECURSE.
        $line = &entities($line, $ln_no);
      }
      #3. &pound; &copy; ... TENS-Error.
      else {
        #:NDF: 2005-10-27: die "Error (TENS), found non-ASCII character $ord (line $ln_no, $ch), exiting\n";
        warn "Warning 2 (TENS), found non-ASCII character $ord (line $ln_no, $ch).\n";
      }
    }
  }
  return $line;
}

# prev_next: Get URLs for previous and next bulletins.
#      Note: difficult to ensure 'next' bulletin exists.
sub prev_next {
  # this, eg: ../eab/issues/2004/jul2004.html
  my $this=$_[0];
  my $is_current=0;

  # 1-based month array.
  my @months = ("","jan","feb","mar","apr","may","jun","jul","aug","sep","oct","nov","dec");
  my %months=(
    jan => 1,
    feb => 2,
    mar => 3,
    apr => 4,
    may => 5,
    jun => 6,
    jul => 7,
    aug => 8,
    sep => 9,
    oct =>10,
    nov =>11,
    dec =>12 );


  # Find this issue's month and year.
  $this=~/(.*)(\/|\\)(.*?)(2.*?)(\..*)/; #/ URL
  my $stem= $1.$2;
  my $mon = $3;
  my $year= $4;
  my $ext = $5;
  # Access hash.
  my $midx = $months{$mon};
  warn "'prev_next' This month: $mon | index: $midx | year: $year\n";

  # Previous.
  my $prev_mon= $midx;
  my $prev_yr = $year;
  if ($midx > 1) {
    $prev_mon = $months[--$prev_mon];
  }
  else {
    $prev_mon = $months[12];
    --$prev_yr;
  }
  # Next - check for 'current' issue.
  (my $s,my $m,my $h,my $md,my $c_mon,my $c_year,my $wd,my %yd,my $i)=gmtime(time);
  $c_mon++;
  $c_year+=1900;

  my $next_mon= $midx;
  my $next_yr = $year;
  if( $year==$c_year && $midx==$c_mon ){
    $is_current = 1;
    $next_mon = $months[$next_mon];
    warn ">> Identified current issue (make next 'this').\n";
  }
  else {
    if ($midx < 12) {
      $next_mon = $months[++$next_mon];
    }
    else {
      $next_mon = $months[1];
      ++$next_yr;
    }
  }
  my $prev = "../$prev_yr/$prev_mon$prev_yr$ext";
  my $next = "../$next_yr/$next_mon$next_yr$ext";

  warn "URLs, prev: $prev | next: $next\n";
return ($prev, $next);
}
