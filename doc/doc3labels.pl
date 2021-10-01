#! /usr/bin/perl
# A procedure to insert card references in Appendices A and D to the
# CCSL manual
local @filelist=();
# Table of card links to be made made from .xref file
  local (%external_labels) = ();

# Environment type variables for directories
# These should be absolute
  unless ($MANUAL_DIR = $ENV{MANUAL_DIR}) {
    if ($MANUAL_DIR= $ENV{CCSL_DOC}) {$MANUAL_DIR .="/mk4man"}
    else {$MANUAL_DIR = "mk4man"}
  }
  unless ($APPENX_DIR = $ENV{APPENX_DIR}) {
    if ($APPENX_DIR  = $ENV{CCSL_DOC}) {$APPENX_DIR.="/appenx"}
    else {$APPENX_DIR = "appenx"}
  }
  unless ($TEXES_DIR = $ENV{TEXES_DIR}) {
    if ($TEXES_DIR= $ENV{CCSL_DOC}) {$TEXES_DIR .="/texes"}
    else {$MANUAL_DIR = "./texes"}
}
#
#These should be relative to htlm directory
  unless ($APPEN_MAN_DIR = $ENV{APP_MAN_DIR}) {
    $APPEN_MAN_DIR = "../mk4man";
    }
  unless ($TEXES_MAN_DIR = $ENV{TEXES_MAN_DIR}) {
    $TEXES_MAN_DIR = "../texes";
    }
# Make the external labels for referring to card specs
        %external_labels=labelhash($TEXES_DIR."/CCSLman");
# This creates the hash %external_labels in which the keys have the form carddef.card:x
# where x is the required initial letter and the value gives the URL and label
# Now work over all html files in both apendices A and D
 	opendir APPDIR, $APPENX_DIR or die "cannot open $APPENX_DIR";
 	@filelist=readdir(APPDIR);
#	@filelist=("bonds.htm");
 	foreach $file (@filelist) {
 	  $file="$APPENX_DIR/$file";
 	  $sfile=$file;
 	  next if ($file !~ s/\.htm$//);
 	  open INFILE, "$sfile" or die "can't open $sfile for read";
 	  $file = "$file.html";
 	  open OFILE, ">$file" or die "can't open $file for output";
 	  print ("Reading from $sfile and writing to $file\n");
 	  while ($_=<INFILE>) {
 	  @matches=();
 	  while (s|(<a href = \"mk4man\">.*</a>)|@@@|) {
 	  	push @matches, $1;
 	  }
 	  $line=$_;
 	  foreach $match (@matches) {
 	 	$match =~ m|>(.*</a>)|;
 	 	$ref=$1;
 	   	$ref=~/[ \"]*([A-Z])/;
        $letter = $1;
        $href="$APPEN_MAN_DIR/".$external_labels{"carddef.card:".uc $letter};
        $match= "<a href = \"$href\">$ref";
        $line=~s|@@@|$match|;
      }
    print $line
    print OFILE $line;
}
close OFILE;
unlink $sfile;
  }


sub labelhash() {
#Make the c3labels hash
my ($ifile,$line,%labels,$key,$url,$pos,$ppos,$i,$x);
	%labels=();
	$ifile=shift(@_).".xref";
	open IFILE, $ifile or die "Labelhash: Can't open crossref file $ifile";
	while (<IFILE>) {
		$line=$_;
		if (s/\\:CrossWord\{\)N //) {
			$i=index($_,"{");
			$x=substr($_,0,$i+1,"");
			$i=index($_,"}");
			if ($i<0) {die "Labelhash: error in line $line"};
			$url=substr($_,0,$i,"");
			/(\d{1,5})/;
			$pos=$1;
		}
		if (s/^\\:CrossWord\{\)Qcarddef.card://) {
			$i=index($_,"}");
			if ($i<0) {die "Labelhash: error in line $line"};
			$key="carddef.card:".substr($_,0,$i,"");
			/(\d{1,5})\}\{(\d{1,5})/;
			$ppos=$2;
			if ($pos==$ppos) {$labels{$key}=$url}
		}
	}
	@list=keys(%labels) ;
	@slist=sort(@list);
		foreach $key (@slist) {
			printf "%20s ..... %s\n",$key,$labels{$key};
	}
	return  %labels;
}
