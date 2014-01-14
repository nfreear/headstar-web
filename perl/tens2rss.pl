#!/usr/bin/perl -w
my $version="tens2rss.pl v1.4";
my $author="Nick Freear";
#
# Convert a Text Email Newsletter Standard document to Rich Site Summary 0.91.
#   http://www.headstar.com/ten
#   http://www.bbc.co.uk/syndication/feeds/news/rss-0.91.dtd
#
# Example TEN:  http://www.e-accessibility.com/issues/dec2002.txt
#
# Copyright 8 July 2003 Nick Freear.
# ==============================================================================

#while (( $#ARGV > -1 ) && ( $ARGV[0] =~ /^[-+].+/ ) )
{
  unless (-r $ARGV[0]) {
      die "Can't find or read file: $ARGV[0].\n";
  }
}
my $tens_file=$ARGV[0];
print(STDERR "File: $tens_file\n\n");
unless ($tens_file=~/(.*)\.txt/) {
  die "Failed to find stem: $tens_file\n";
}
my $file_stem=$1;
my $rss_file="$file_stem.rss";
my $url_stem = "http://www.e-accessibility.com";
my $url_issues= "$url_stem/issues";

if (-e $rss_file) {
  warn "File already exists: $rss_file.\n";
}
open(IFILE, "$tens_file") or die "Failed to open: $tens_file\n";
open(OFILE, ">$rss_file") or die "Failed to open: $rss_file\n";
#select(OFILE);

  my $index=0;
  my $is_ten=0;
  my $item_type="eab:none";
  my $issue_num=0;
  my $sect_num=0;
  my $item_num=0;
  
    while (<IFILE>)
    {
      $index++;
      chomp($_);
# Filter main title.
      if ($_=~/^\+\+\+(.*)/) {
        if ($is_ten=~1) {
          die "Error: found second main title: '$_'.\n";
        }
        $is_ten=1;
        
        #my $main_ttl=ucfirst(lc($1));
        my $main_ttl=&caps($1);
        my $next_ttl=<IFILE>;
        chomp($next_ttl);
        if ($next_ttl=~/-\sISSUE\s(\d+),\s(.*)\s(\d+)/) {
          $issue_num=$1;
        }
        my $mname=$2;
        my $yr=$3;
        
        &prn_rss_open;
        &prn_rss_channel("$main_ttl $next_ttl", "$url_issues/$tens_file", "$yr Headstar Limited");
      }
# Filter section title.
      elsif (/^\+\+(.*)/) {
        if ($is_ten=~0) { die "Error: no main title (+++) found.\n"; }
        my $sect_ttl=$1;
        
        print("<!--$sect_ttl-->\n");
#        ($item_type, $item_num)=&get_item_detail($sect_ttl);
  if ($sect_ttl=~/SECTION\s(.*):\sNEWS/) {
    #$sect_num=$1;
    $item_type="eab:news";
  }
  elsif ($sect_ttl=~/BRIEF/) {
    $item_type="eab:brief";
  }
  elsif ($sect_ttl=~/CONTENTS/) {
    $item_type="eab:contents";
  }
  elsif ($sect_ttl=~/INBOX/) {
    $item_type="eab:letter";
  }
  elsif ($sect_ttl=~/(\d+):.*INTERVIEW/) {
    $item_num=$1;
    $item_type="eab:interview";
  }
  elsif ($sect_ttl=~/(\d+):.*FOCUS/) {
    $item_num=$1;
    $item_type="eab:focus";
  }
  elsif ($sect_ttl=~/END\sNOTES/) {
    $item_type="eab:notes";
  }
  else {
    die "Error: unknown 'EAB' type: $_.\n";
  }
      }
# Filter item title.
      elsif (/^\+(\d+):\s(.*)/) {
        if ($is_ten=~0) { die "Error: no main title (+++) found.\n"; }
        $item_num=$1;
        
        my $item_ttl=&caps($2);
        my $first_line=$2;
        if ($first_line=~/(.*):\s(.*)/) {
          $item_ttl=&caps($1);
          $first_line=$2;
        } else {
          <IFILE>; #:BUG: Presume blank line, throw away!
          $first_line=<IFILE>;
          chomp($first_line);
          $first_line=&urlify($first_line);
        }
        $item_link="$url_issues/$file_stem.html#i$issue_num-$item_num";
        &prn_rss_item($item_ttl, $item_type, $item_link, "$first_line ...");
      }
# Filter end-note items.
      elsif (/^\+(.*)/) {
        my $note_ttl=&caps($1);
        $item_num++;

        $item_link="$url_issues/$file_stem.html#i$issue_num-$item_num";
        &prn_rss_item($note_ttl, $item_type, $item_link, "[none].");
      }
      elsif (/^\[.*\]/) {
        #print("<!--$_-->\n");
      }
      elsif (/^ISSN\s(.*)/) {
        $issn=$1;
        # International Standard [Book|Serial] Number.
        print("<id type=\"ISSN\">$issn</id>\n");
      }
    }

&prn_rss_close;
close(IFILE);
close(OFILE);

# ==============================================================================
sub prn_rss_open {
  print("<?xml version='1.0' encoding='iso-8859-1'?>\n");
  print("<!DOCTYPE rss SYSTEM \"http://www.bbc.co.uk/syndication/feeds/news/rss-0.91.dtd\">\n");
	print("<rss version=\"0.91\">\n<channel>\n");
}
sub prn_rss_close {
  print("</channel>\n</rss>\n");
}
sub prn_rss_channel {
  my $title=$_[0];
  my $link=$_[1];
  my $rights=$_[2];
  print("  <title>$title</title>\n");
  print("  <date>",&format_time,"</date>\n");
  print("  <link>$link</link>\n");
  print("  <copyright>Copyright $rights.</copyright>\n");
  print("  <language>en-GB</language>\n");
  print("  <creator>$author ($version).</creator>\n\n");
}
sub prn_rss_item {
  my $title=$_[0];
  my $type=$_[1];
  my $link=$_[2];
  my $desc=$_[3];
  print("<item>\n  <title>$title</title>\n");
  print("  <type>$type</type>\n");
  print("  <link>$link</link>\n");
  print("  <description>$desc</description>\n");
  print("</item>\n\n");
}

sub get_item_detail {
  my $sec_ttl=$_[0];
  my $item_type="eab:none";
  my $item_num=0;
##
  return ($item_type, $item_num);
}
sub format_time {
  (my $sec,my $min,my $hour,my $mday,my $mon,my $year,my $wday,my %yday,my $isdst)=localtime(time);
  $year+=1900;
  $mon++;
  if ($mon<10) { $mon="0$mon"; }
#  $wday+=0; $yday+=0; $isdst+=0;
  
  return "$year-$mon-$mday $hour:$min:$sec";
}
sub ten_or_die {
  if ($_[0]=~0) { die "Error: no main title (+++) found.\n"; }
}

#
# caps: Make All Words Title-Cased ('Perl Cookbook', Christiansen et al, 1998, O'Reilly, p165).
#
sub caps {
  my @parms=@_;
  for (@parms) { s/(\w+)/\u\L$1/g }  # tr/A-Z/a-z/
  # wantarray check whether we were caled in list context.
  return wantarray ? @parms : $parms[0];
}

#
# urlify: program to wrap HTML links around URL-like constructs
#   (other 'urlify', 'Perl Cookbook', p210).
#
sub urlify {
  my $line=$_[0];
  if ($line=~m/(.*[(|,|;|\s])(\S*?)\@(\S*?)([\)|,|;|\s].*)/) {
    $line="$1<link>mailto:$2\@$3</link>$4";
  }
  elsif ($line=~m/(.*)(http\:\/\/\S*?)([\)|,|;|\s].*)/) {
    $line="$1<link>$2</link>$3";
  }
  return $line;
}
#   @words=split(/\s/, $parms[0]);
