#! /usr/bin/perl

# A procedure to make Appendices A, D and possibly B and C to the
# CCSL manual

# the arguments to be given are:
# 1. Filename of header file (mistre.ss)
# 2. Kind of output wanted "tex"  gives LaTeX file (ext $TEXES_DIR)
#                          "html" gives html files
#                          "both" gives both the above
# 3. ->  parts to be included. they may be given as part names
# ie LIB PR MAI etc. Or as filenames ie libmk4.f. If one of the files
# contains main programs it should be the last in the list.
# Last startin -n Optional the name of the manual file, default is now CCSLman
# Steps in process
# 1. Process  the COMMON for the header file
# 2. First pass through file to get the names of all modules
# 3. 2nd pass through the file
#    first get the names used by each module
#    find which of these are in the declared common blocks (to use list)
#    find which are the names of modules (calls list) and (called by list)
# 4. Third pass to extract the C<x> lines for each module and make the
#    manual. Logical $TeX chooses LaTeX output, $html html pages. They can both
#    be chosen in the same run.
#
# In-line arguments are <header source> <output> <part> [other parts]
# <output> = tex, html or both
# <part> = lib, mai, pr ...etc
# [other parts] = any other part required and/or com to make appendix C
sub getfile;
sub docommon;
sub parser;
sub slist ($@);
sub modname($);
sub prilis($@);
sub docomment($);
sub inittex;
sub inithtml;
sub writeout($);
sub texpro(@);
sub texlist ($@);
sub texcomm ($@);
sub getheaders ($);
sub htmlpro(@);
sub htmllist ($@);
sub htmlcomm ($@);
sub breakline($$$$);
sub docardlinks($);
sub labelhash($);
sub getversiondate($);
#
# Local variables
# Configuration variables
  local ($suffix) = "mk4.f";
# Author Info
  local ($myname) = "P. Jane Brown";
  local ($myemail) = "brown(At)ill.fr";
  local ($myaddress) = "Institut Laue Langevin,<br>Grenoble, FRANCE";
  local ($ncomm,$pass,$fword);
  local ($initlet) = "Z";
  local ($title) = "CCSL APPENDICES";
#
# Hash tables
  local (%classtypes) = ("A","Setting Up","B","Crystallographic","C","Utility",
               "D","Main Program");
# These tables are keyed by the routine name
  local (%headers) = ();   #Heading line for each routine
  local (%classes) = ();   #class of each routine
  local (%fullnames) = (); #full calling spec of each routine
  local (%partlist) = ();  #part to which each routine belongs
  local (%proglist) = ();  #true if this program is to be included
  local (%entries) = ();
  local (%symbolicpars) = (); # Values of symbolic parameters
# Table of card links made by Tex4ht removed they will be inserted by doc3labels
#  local (%external_labels) = ();
# Table of main programs to be included
  local (%main_progs) = ();
#
# Lists
  local (@mainprogs) = ();
  local (@comnames) = ();
  local (@categories) = ("Basic Crystallography",
               "Data Collection and Reduction",
               "Manipulation of Reflection Indices",
               "Structure Factor Calculations",
               "Fourier Calculations",
               "General Least Squares Refinement",
               "Specific Least Squares Refinement",
               "Crystal Geometry","Mathematical Functions",
               "Trigonometry","Tests","Matrices and Vectors",
               "CCSL Input/Output Routines","Graphical Output",
               "Logical Operations","Miscellaneous   ",
               "Magnetic Structure Factors",
               "Multipole Form Factors","Profile Refinement");
#  local (@classcodes) = (qw/A B C D/);
# The following 3 lists must be kept in parallel, they associate the
# letter following the C in a comment line with the approproate info heading
  local (@commentcodes) = (qw/A P D I O N R S/);
  local (%htmlheaders) = ("A","Arguments","P","Prerequisite calls",
                       "D","Description","I","Input","O","Output","N","Notes",
                       "R","Running the program","S","Sample Data");
  local (%texheaders) = ("A","thearguments","P","theprecalls","D","thedescription",
                       "I","theinput","O","theoutput","N","thenotes",
                       "R","theprogrun","S","thesampledat");
#
 local (%partnumbers) =  ("lib",1,"com",3,"mai",4);
 local (%parttitles) =  ("lib","Appendix A","com","Appendix C","mai","Appendix D");
 local (%parttypes) =  ("lib","General Library Subroutines","mai",
                        "Main Programs in use at ILL", "com",
                        "Description of Common Blocks");
 local (%partheaders) = ("lib","Specifications of Subroutines",
                        "mai","Instructions for main programs in
                        \\\\use at ILL","com",
                        "Description of Common Blocks");
 local ($doingmain) = 0;
 local($inmain) = 0;
 local($main) = 0;
 local ($tab) = "  ";
#
# This is the start of the executable code
# To time the job
  local ($starttime) = (times)[0];
 print "\n****************************************************\n",
         "*        Making Appendices to the CCSL manual      *\n",
         "****************************************************\n\n";
# Environment type variables for directories
# These should be absolute
  unless ($SOURCE_DIR = $ENV{SOURCE_DIR}) {
    unless ($SOURCE_DIR= $ENV{CCSL_SRC}) {$SOURCE_DIR = "."}
  }
  unless ($LOCAL_DIR = $ENV{LOCAL_DIR}) {
    unless ($LOCAL_DIR = $ENV{CCSL_OPT}) {$LOCAL_DIR = $SOURCE_DIR}
  }
  unless ($HEADER_DIR = $ENV{HEADER_DIR}) {
    $HEADER_DIR = $SOURCE_DIR;
  }
  unless ($MANUAL_DIR = $ENV{MANUAL_DIR}) {
    if ($MANUAL_DIR= $ENV{CCSL_DOC}) {$MANUAL_DIR .="/mk4man"}
    else {$MANUAL_DIR = "mk4man"}
  }
  unless ($APPENX_DIR = $ENV{APPENX_DIR}) {
    if ($APPENX_DIR  = $ENV{CCSL_DOC}) {$APPENX_DIR.="/appenx"}
    else {$APPENX_DIR = appenx}
  }
  unless ($TEXES_DIR = $ENV{CCSL_TEX}) {
    if ($TEXES_DIR  = $ENV{CCSL_DOC}) {$TEXES_DIR.="/texes"}
    else {$TEXES_DIR = "texes"}
  }
  unless(-d $APPENX_DIR) {mkdir($APPENX_DIR, 493) or die
  "error creating appendix directory $APPENX_DIR"}
#
#These should be relative to the html directory
  unless ($APPEN_MAN_DIR = $ENV{APP_MAN_DIR}) {
    $APPEN_MAN_DIR = "../mk4man";
    }
  unless ($APPEN_ICON_DIR = $ENV{ICON_DIR}) {
  $APPEN_ICON_DIR = "../icons";
  }
  print  "** Source directory is              $SOURCE_DIR\n",
         "** Header directory is              $HEADER_DIR\n",
         "** Appendix directory is            $APPENX_DIR\n",
         "** Directory for TeX files is       $TEXES_DIR\n",
         "** Directory with local options is  $LOCAL_DIR\n\n",
         "** Path from Appendix to manual directory is  $APPEN_MAN_DIR\n",
         "** Path from Appendix to Icon directory is    $APPEN_ICON_DIR\n",
#
#Interpret inline arguments
$manual="CCSLman"; # default
 @args = @ARGV;
# Check the name of the manual
 shift @args;
 $hdrfile = $HEADER_DIR."/".$ARGV[0];
#
 $outputtype= lc(shift @args);
 $html= ($outputtype eq "html") || ($outputtype eq "both"); # for TeX output
 $TeX = ($outputtype eq "tex")  || ($outputtype eq "both"); # for html output
 $doapc = 0;
 @parts = ();
 foreach $arg (@args) {
 if ($arg=~s/^-n//) {$manual=$arg}
 else {$arg = lc ($arg);
	if ($arg eq "com") {$doapc = 1}
  	 else {push @parts, $arg}
  	}
 }
# @parts should now be just a list of required parts
#
# Check that the required files exist
  local ($numerrs) = 0;
  foreach $part (@parts) {
    unless (-r $SOURCE_DIR."/".$part.$suffix) {
      print $SOURCE_DIR."/".$part.$suffix," is not readable\n";
      ++$numerrs;
    }
    if (lc $part eq "mai") {
      $infile = $LOCAL_DIR."/list_of_progs";
      unless (-r $infile) {
        print "$infile is not readable\n";
        ++$numerrs;
      }
      open (INFILE, $infile) or die "Can't open input file $infile";
      while ( <INFILE>) {
# April 2003: remove any graphic switches from the module name
        @tmp=split;
        $temp = uc $tmp[0];
      $proglist{$temp} = $temp}
    }
  }
#  	$xreffile="$TEXES_DIR/CCSLman.xref";
#   $cardrefs = (-r "$xreffile");
#   $htm="html";
#   unless ($cardrefs) {
#    print "$xreffile is not readable\n",
#    "Must run doc3labels after making mk4man to get card references right\n";
    $htm="htm";
#  }
  unless (-r $HEADER_DIR."/".$ARGV[0]) {
    print $HEADER_DIR."/".$ARGV[0]," is not readable\n";
    ++$numerrs;
  }
  !$numerrs or die "$numerrs missing files\n";

# Name input and output files
  $htmlhead = $APPENX_DIR."/"."appendix.$htm" if ($html);
  $hdrfile = $HEADER_DIR."/".$ARGV[0];
 print "** Header file with common is  $hdrfile\n\n";
 print "\n\n";
# 1. Process  the COMMON for the header file
# This creates the list @comnames containing the names of all the COMMON blocks
# and for each <name> in comnames a list @$<name> containing all the
# variables in that COMMON block
 $ncomm = docommon ($hdrfile);
 $fword = "([a-zA-Z]\w{0,5}\b)";
 $stars = " *** ";
PASS: for ($pass =1;$pass<4;++$pass) {
        print "\n*****  Executing pass $pass *****\n";
PART:   foreach $part (@parts) {
          $part = lc($part);
          $main = ($part eq "mai");
          $infile = $SOURCE_DIR."/".$part.$suffix;
          open(INFILE, $infile) or die "can't open source".$infile;
          print "** File being analysed is      $infile\n";
          do {
            $firstline = <INFILE>;
          } until ($firstline =~ /^CCSL/);
          getversiondate($firstline);
# initialise for getline;
          $thisline = 0;
          $nextline = 0;
          if ($pass == 1) {
            &firstpass;
             next PART;
           }
          if ($pass == 2) {
            &secondpass;
            next PART;
          }
         if ($pass == 3) {
           if ($html) {
             $htmlfile = $APPENX_DIR."/".$part."apx.$htm";
             $htmlalph = $APPENX_DIR."/".$part."alfa.html";
             print "HTML file will be made and written to    $htmlfile\n";
             &inithtml($part);
           }
           if ($TeX) {
             $texfile = $TEXES_DIR."/".$part."apx.tex";
             print "TeX version will be made and written to  $texfile\n";
             &inittex($part);
           }
           &thirdpass;
           if ($part eq "lib" && $doapc) {
             if ($html) {
               $htmlfile = "$APPENX_DIR/appenc.html";
               &inithtml("com")
             }
             if ($TeX) {
               $texfile = "$TEXES_DIR/appenc.tex";
               &inittex("com")
             }
             &doappenc($hdrfile)
           }
           next PART;
         }
      }
      if ($pass == 1) {
      if ($cardrefs) {
# Make the external labels for referring to card specs (do later)
#        %external_labels=labelhash($xreffile);
# This creates the hash %external_labels in which the keys have the form card:x
# where x is the required initial letter and the value gives the URL and labe
        }
      } elsif ($pass == 2 && $html) {
# Write the start of the appendix file
      open(HTMLTOP, ">".$htmlhead) or die "can't open ".$htmlhead.
      " for output";
      print "Appendix file $htmlhead opened\n";
      &dopreamble(HTMLTOP,"CCSL Appendices");
      &htmltop;
      } elsif ($pass == 3 && $html) {
# Write the end of the appendix file
       &forappene(HTMLTOP);
       &dopostamble(0,0)
     }
  }
  print "END \n";
  $endtime = (times)[0];
  $time = $endtime - $starttime;
  print "That took ",$time," CPU seconds\n";

sub docommon {
 local (
   @steps,@vwords,@labels,@lines,$nc,$first,$part);
   @vwords = qw/DIMENSION CHARACTER LOGICAL REAL INTEGER COMPLEX DOUBLE
   PRECISION SKIP EQUIVALENCE/;
   @steps = qw/COMM DONE DUM/;
   @labels =qw/SKIP SCOM ECOM/;
   @lines=();
   $nc = 0;
   $first = 1;

 open(INFILE, $_[0]) or die "can't open header file ".$_[0];
  foreach $step (@steps) {
    $label = shift @labels;
    print "step ",$step," ",$label,"\n";
     while ($line = <INFILE>) {
      if ($line =~ /^$step/)  {last;}
      goto $label;
SKIP: next;
# Read all the COMMON blocks into $lines
SCOM: if ($line =~ s/^ {6,}COMMON//) {
        if (!$first) {push @lines, $part}
        chomp($line);
        $part = $line;
        $first = 0;
      }
      elsif ($line =~ s/^ {5}\S//) {
        chomp($line);
        $part .= ($line);
      }
      elsif (!$first) {
        push @lines, $part;
        $first = 1;
      }
      next;
# Find names of variables  in common blocks
ECOM:  $nwords=0;
       foreach $line (@lines) {
# obliterate symbolic parameters
         $line =~ s/%\w+?%/\#/g;
# Find the name of the COMMON block  between / /
           if ($line =~ s%/([a-zA-Z]\w{0,5}\b) */%\#%) {
           $comname = $1;
# intilaise lists to contain the modules using these
           $list = $comname."_module";
           @$list = ();
           push @comnames, $comname;
# clear list to receive names of variables in this COMMON
           @$comname = ();
           $nc++;
# try to pick out fortran words
          while ($line =~ s/([a-zA-Z]\w{0,5}\b)/\#/) {
          push @$comname, $1;
        }
      }
    }
    last;
  }
}
  return $nc;
}


sub firstpass() {
# First pass through a file to get the names of all modules
# These are saved in the list @modules
# we also get the classification and header lines
  my(@temp) = ();
  my($rlist,$stlist,$srname) = ();
  if (!$main) {
# Record ENTRY's
    $elist =  $part."_entrylist";
    @$elist = ();
  }
  while (1) {
    ($line,$clevel) = &getline;
    last if !$line;
    next if !$clevel;
    $routine = $line;
    ($name,$inmain) = modname($line);
    next unless ($name);
     if ($clevel < 0) {
      push  @$elist, $name;
      $fullnames{$name} = $routine;
      $partlist{$name} = $srname;
      next;
    }
# check for alphabetic order
    if (!$main) {
      $test = $srname cmp $name ;
    print "**ERROR $name found after $srname is out of order\n" if ($test >
    0)}
# save the routine name
    $srname = $name;
    &getheaders($name);
    $partlist{$name} = $part;
    if ($inmain) {
      $partlist{$name} = $name;
      if (scalar @tlist) {@$sublist = sort @tlist}
      $sublist = lc $name."_ownsubs";
# initialise it with the main name
      @tlist = ($name);
# Record ENTRY's
      $elist = lc $doingmain."_entrylist";
      @$elist = ();
     }
     if ($main && !$inmain) {
       push @tlist, $name;
       $partlist{$name} = $doingmain;
# Need a called by list for own subroutines
       $list = $doingmain."_".$name."caldby";
       @$list = ();
     } else {
       if (!main) {
         $list = "_".$name."caldby";
       }
       push @temp, $name;
       @$list = ();
     }
#    print "$doingmain  $name  ",$classes{$name},"\n";
   }
   if ($main) {@$sublist = sort(@tlist)}  # sort the last list
   $rlist = $part."_modules";
   @$rlist = sort(@temp);
   $stlist = $part."_sorted";
   @$stlist = sort orderclass @$rlist;
}

sub secondpass() {
#For  each <module>
# First get the names of the COMMON blocks and FORTRAN "words" used by
# each module and  put them in the temporary lists @cused and @fwords
  local(@temp) = ();
  local(@ntrylist) = ();
  $first = 1;
  while (1) {
    ($line,$clevel) = &getline;
    last unless $line;
    next if ($first && !$clevel);
    if ($clevel>0) {
      ($module,$inmain) = modname($line);
      next unless ($module);
      $first = 0;
# Record subroutine entries in @$elist
# These are not used at the moment
      @ntrylist = ();
      %fwords = &parser;
      if (scalar @ntrylist) {
        $entries{$module} = $module;
        $elist = $doingmain."_".uc ($module)."_entries";
        foreach $entry (@ntrylist) {$entries{$entry} =$module}
        @$elist=@ntrylist;
      }
      print "                     \rModule: $module      ";
      $list = $doingmain."_".$module."_calls";
      @$list = ();
# If doing LIB
# Find which other module names <name> are present in @fwords
# and put them into the list @$<module>_calls
# and also add <module> to the  list @$<name>_caldby
       foreach $name (@lib_modules,@lib_entrylist) {
        if ($module ne $name) {
          if ($fwords{$name}) {
            $nname = $entries{$name};
            push @$list, $name unless ($nname);
            unless ($nname eq $module) {
              $wlist = "_".$name."_caldby";
              push @$wlist, $module;
            }
          }
        }
      }
# if doing main programs they shouldn't be called by anything
# but must check the list of own subroutines for calls
      if ($main) {
        if ($inmain) {
          $mlist = lc $module."_ownsubs";
          $enlist = lc $module."_entrylist";
        }
#        print "$module\n";
        foreach $name  (@$mlist,@$enlist) {
          if ($module ne $entries{$name}) {
            if ($fwords{$name}) {
              push @$list, $name;
              $wlist = $doingmain."_".$name."_caldby";
              push @$wlist, $module;
            }
          }
        }
        @$list = &removecopies(@$list);
      }
# copy @cwords to  @$<module>_comm  and for each member <cname>
# Search @fwords for names which occur in the COMMON block <cname>
# These go into the lists @$<module>_<cname>
      $clist = $module."_comm";
      $listc = $module."_comm";
      @$clist = ();
      foreach $word (@cused) {
      $listc = $word."_module";
        push @$clist, $word;
        push @$listc, $module;
        $list = $module."_".$word;
        @$list = ();
        foreach $name (@$word) {
          if ($fwords{$name}) {push @$list, $name}
        }
        if (scalar @$list == scalar @$word) {@$list = ("all members")}
      }
      @cused = ();
    }
  }
}


sub thirdpass() {
# Third pass through: extract comment lines for manual
# Write manual pages using these and the previously prepared lists
  my ($first,$prevname);
  $first = 1;
  $prevname = "";
  while (1) {
    ($line,$clevel) = &getline;
    last unless $line;
    next if ($first && !$clevel);
    next if ($clevel<0) ;
    if ($clevel) {
      ($name,$inmain) = modname($line);
      next unless $name;
      $first = 0;
      $clist = $name."_comm";
 # initialise the arrays
      $updt = "";
      foreach $swi (@commentcodes) {
        $commentlist = "comment_".$swi;
        @$commentlist = ();
      }
    next;
    }
    if ($line =~ /^C/) {
      if ($line =~ /^C /) {
        $i = index $line, $stars;
        if ($i >= 0 ) {
          if (index $line, $stars, $i + 5 >= 0) {
            $updt = substr $line, $i + 1;
          }
        }
      } elsif ($line =~ m/^C([A-Z])/) {
        if ($htmlheaders{$1}) {&docomment($line)}
      }
      next;
    }
# Make the manual page for this subroutine
# Classification
    $first = 1;
    $routine = $fullnames{$name};
    $classwrd = $classes{$name};
    $classwrd =~ /([0-9]{1,2})([A-D])/;
    $classnum  = $1;
    $category = $categories[$classnum-1];
    $classtype = $classtypes{$2};
    $hedline = ($headers{$name});
# subdivide by initial letter for ease of cross-reference from manual
    if ($html) {
      if ($main) {
         if ($inmain) {
# close the old subfile for this program
           $fname = "$APPENX_DIR/".lc $name.".$htm";
           if ($prevname) {
           &dopostamble(HTMLOUT,lc $name.".$htm");
           $oldname = lc substr($prevname,index($prevname,"/")+1).".$htm";
           }
# open an html subfile for this program
           open(HTMLOUT, ">".$fname) or die "can't create ".$fname;
           $prevname = "Program $name";
           &dopreamble(HTMLOUT,$prevname,$oldname);
         }
       } else {
         if ($initlet ne lc(substr($name,0,1))) {
           $initlet = lc(substr($name,0,1));
# close the old subfile for this letter
           $oldname= substr($fname,index($fname,"/")+1);
           $fname = "$APPENX_DIR/$part"."sec_".$initlet.".$htm";
           if ($prevname) {&dopostamble(HTMLOUT,$fname)}
           $prevname = "Library Section".uc $initlet;
# open an html subfile for this initial letter
           open(HTMLOUT, ">".$fname) or die "can't create ".$fname;
           &dopreamble(HTMLOUT,$prevname,$oldname);
         }
       }
     }
     writeout($name);
  }
# Close the last file of the part
  &dopostamble(HTMLOUT,$fname) if ($html);
  print TEXOUT "\\begin{MakeAlphaList}{",$parttypes{$part},"}\n";
  print TEXOUT "\\input{",$part,"alphalist}\n
  \\end{MakeAlphaList}\n
  \\end {document}\n" if ($TeX);
}


sub prilis ($@)  {
  local ($word,$n);
  print (shift,"\n");
  $n=0;
  foreach $word (@_) {
    if (++$n > 8) {print "\n"; $n = 0}
    print $word," ";
  }
  if ($n) {print "\n"}
  return 1;
}

sub modname ($) {
# called after C LEVEL line to extract module name
# expects to have the uncommented module line in $_;
 local ($_) =@_;
 my ($sname,$type);
 $type = 0;
 $sname = "";
 if ($_ =~ s/^ .*(SUBROUTINE|FUNCTION|BLOCK *DATA|PROGRAM|ENTRY)//i) {
   $type = ($1 eq PROGRAM);
   m/([a-zA-Z]\w{0,5})( *$| *\()/;
   $sname= uc $1;
# Ensure it is in the program list
   if ($type) {
     $sname = $proglist{$sname};
     $doingmain = ($sname);
   }
 } else {
   print "stray C LEVEL line: ",$_[0]
 }
 return ($sname,$type);
}

sub parser {
  %verbs = (qw/SUBROUTINE ROUT FUNCTION ROUT BLOCKDATA ROUT PROGRAM ROUT
            ENTRY NTRY
            COMMON COMM
            END CONT
            DIMENSION SKIP CHARACTER SKIP LOGICAL SKIP
            REAL SKIP INTEGER SKIP DOUBLE SKIP PRECISION SKIP
            COMPLEX SKIP EQUIVALENCE SKIP
            CONTINUE SKIP RETURN SKIP STOP SKIP FORMAT SKIP
            CALL CONT IF CONT ELSE CONT ENDIF CONT DO CONT GOTO CONT
            READ CONT WRITE CONT DATA CONT THEN CONT
            \.GT\. LOGO \.GE\. LOGO \.LT\. LOGO \.LE\. LOGO \.EQ\.
            LOGO \.NE\. LOGO \.NOT\. CONT \.TRUE\. CONT
            \.FALSE\. CONT/);
   my (%fwords,$nwords,$statement,$rout);
   $nwords = 1;
   %fwords = ();
# main reading loop
LINE:  while (1) {
         ($statement,$clevel) = &getline;
         last unless $statement;
         last if ($clevel >0);
         if ($clevel <0) {
#         print $statement;
       }
# skip comment lines
         if ($statement =~ /^C/) {next LINE}
#analyse the statement
         $statement = substr $statement,6;
# remove all spaces
         $statement =~ s/ //g;
# remove literals
         $statement =~ s/\'.*?\'/\#/g;
         $num = keys(%verbs);
# Treat the END statement specially
         last LINE if ($statement =~/^END$/);
WORD:  while (($word,$type) = each %verbs) {
         if ($type eq LOGO) {
           $match = ($statement =~ s/$word/#/)
         } else {
           $match = ($statement =~ s/^$word/#/);
           unless ($match) {
             $match = ($statement =~ s/(\W)$word/$1#/)
           }
         }
         if ($match) {
           next LINE if ($type eq "SKIP");
           last LINE if ($type eq "DONE");
           if ($type eq "CONT" || $type eq "CONT") {
             $num = keys(%verbs);
             next WORD;
           }
             if ($type eq "COMM") {
             if ($statement =~ m|/(\w*)/|) {push @cused, $1}
             next LINE;
           }
           if ($type eq "ROUT") {
             if ($statement =~ /(\w{1,6})/) {$rout = $1}
             next LINE;
           }
           if ($type eq "NTRY") {
             if ($statement =~ /(\w{1,6})/) {push @ntrylist, $1}
             next WORD;
           }f
         }
       }
       while ($statement =~ s/([a-zA-Z]\w+?\b)/\#/) {
         $fwords{$1} = $nwords++ unless ($fwords{$1});
#           print "FORTRAN word $1\n";
       }
       next LINE;
     }
     return %fwords
 }

sub getheaders ($) {
my ($done,$inhed,$swi);
  $done = 0;
  $inhed = 0;
  # get the full routine spec
  chomp $routine;   $routine =~ s/^ * *$//;
  $fullnames{$_[0]} = $routine;
#  print "Setting fullname ",$_[0],"\n",$routine,"\n";
  while (1) {
    ($line,$clevel) = &getline;
#    return if ($clevel);
    last unless $line;
# read until first non-comment line
    if ($done == 3)  {return}
    if ($line !~ /^C/)  {$done |=3; $swi = "";}
    else {$swi = substr $line,1,1}
#    print "Line read: $line";
     if ($swi eq "H") {
      if (!($done & 2)) {
        chomp($line);
        if (!$inhed ) {$hedline = substr ($line ,3); $inhed = 1;}
        else {$line =~ s/^CH */ /; $hedline .= $line}
      }
    } elsif ($inhed) {$done |= 2; $headers{$_[0]} = $hedline}
    if ($swi eq "C") {
    	$save=$line;
    	chomp $save;
      $line =~ s/(\d{1,2}[A-Da-d]) *$//;
      $classes{$_[0]} = uc $1;
      $done |= 1;
#       print "From getheaders: r=$routine h=$hedline 1=$classes{$_[0]} swi=$swi\n";
   }
  }
}

sub docomment ($) {
my ($swi,$clist);
  $swi = substr $_[0],1,1;
  if ($swi eq " ") {return 0}
# Skip blank comment lines
  unless (/^C[A-Z] *$/) {
    $clist = "comment_".$swi;
    push @$clist, substr($line ,3);
  }
  return 1;
}

sub doappenc {
# A subroutine to make Appendix  C to the CCSL manual
# It must be called after the second pass of orfeus with
# the name of the header file as argument, snd $htmlfile
# and $texfile already set
 local (@steps,@lines,@dlines,@sympars);
 local ($word,$value);
 local($thiscomname,$n,$nlines,$htmlout);
   @steps = qw/PARS STOP DUM COMM DONE DUM/;
   @labels =qw/SKIP SPARS EPARS SKIP SCOM ECOM/;
   @lines=();
   $htmlout = "";
   $thiscomname = "";
   local (%symbolicpars) = ();
   local (%symboldescr) = ();
# If TeX set to read the sympar file when it is finally made
   if ($TeX) {
   print TEXOUT "\\appendix\n\\setcounter{chapter}{3}\n",
   "\\markright{Labelled Common}\n",
   "\\input sympars\n",
   "\\newpage\n",
   "\\section{Description of Common Blocks}\n"}
#
# Read list of symbolic parameters
  unless ($parlist = $ENV{CCSL_PARLIST}) {
    if ($ccsl = $ENV{CCSL}) {$parlist = "$ccsl/options/parlist"}
    unless (-e $parlist) {$parlist = "$source/parlist"}
  }
  open(PARFILE, $parlist) or
   print "$parlist failed to open; no symbolic parameters changed";

# Read names and value of parameters to change $word and $value
  %symbolicpars =() ;
  while ($line = <PARFILE>) {
    chomp $line;
    $word=substr($line,0,4);
    $value=substr($line,5,5);
    # kill trailing spaces
    $value =~ s/ *$//;
    $symbolicpars{$word} = $value;
   }
#
 open(INFILE, $_[0]) or die "can't open header file ".$_[0];
# Main loop starts here
   foreach $label (@labels) {
     $step=shift(@steps);
     print $label," ",$step,"\n";
     while ($line = <INFILE>) {
       if ($line =~ /^$step/)  {last;}
       goto $label;
# Print out header
HEAD:  print OUTFILE $line;
       next;
# Skip lines of mistress
SKIP:  next;
# Read names and values of symbolic parameters into hash %cwords
# Substitute new values where necessary
SPARS: chomp $line;
       $word=substr($line,6,4);
       $value =substr($line,11,5);
       $symboldescr{$word} = substr($line,17);
# Initialise the lists of which common cites which par
       $list = $word."_cited";
       @$list = ();
        # Initialise the spused lists
       $list = $word."_spused";
       @$list = ();
       # kill trailing spaces
       $value=~ s/ *$//;
       $newvalue = $symbolicpars{$word};
       unless ($newvalue) {
         $symbolicpars{$word} = $value;
#        print "Parameter ",$word," value ",$value,"\n";
       }
       else {
       print OUTFILE "C   Parameter ",$word," altered from ",$value,
           " to ",$newvalue,"\n";
           print"Parameter ",$word," altered from ",$value," to ",$newvalue,"\n";
       }
       next;
EPARS: last;
# Identify symbolic parameters in $lines
SCOM: ($line =~ m/^ *(-{0,1}\d{1,2})/) or die "error in COMMON line\n$line";
      $nlines = $1;
      if ($nlines > 0) {
        if ($thiscomname) {
          docommout($thiscomname);
         $thiscomname = 0;
          @sympars = ();
        }
        @lines = ();
        @rlines = ();
        @dlines = ();
        for ($n =0; $n < $nlines; $n++) {
          $_ =  <INFILE>;
          push @rlines,$_;
        }
        $line = shift(@rlines);
		if ($line =~ m|^ {6,}COMMON */([A-Za-z]\w{0,5})/|) {
	          $thiscomname = $1;
        } else {
        	print "error getting name of common from:\n $line";
        	$i=index($line,"/");
        	$j=rindex($line,"/");
        	$thiscomname=substr($line,$i+1,$j-$i-1);
        	print $thiscomname."\n";
        	}
        while (1) {
         if ($newline = shift(@rlines)) {
           if ($newline =~ s/^ {5}[\w\&] *//) {
             chomp($line);
             $line = join("",$line,$newline);
             next;
           }
         }
#         print "$line at end of loop\n";
         while (2) {
           last unless ($line =~ s/%(.{2,4})%/#/);
           $par = $1;
           $value = $symbolicpars{$par};
           if ($line =~ m/\W([A-Za-z]\w{0,5})[\(\*][\d,]*#/) {
             $list = $par."_spused";
             push @sympars, $par;
             push @$list, $1;
             $citelist = "$1_cited";
             push @$citelist, $thiscomname;
           } else {print "variable name not found in $line\n"}
           if ($value) {$line =~ s/#/$value/g }
           else {print "Parameter ",$1," not found\n"}
         }
# and break them up again
         while (length($line) > 72) {
           $i = rindex($line,",",72) + 1;
           push (@lines, substr($line,0,$i)."\n");
           $line = "     \&".substr($line,$i);
         }
         push @lines,$line;
         last unless $newline;
         $line = $newline;
       }
     } else {
       for ($n =0; $n > $nlines; $n--) {
          $_ = <INFILE>;
          s/^\s*//;
          push @dlines,$_;
        }
      }
      next;
ECOM: if ($thiscomname) {
        docommout($thiscomname)
      }
      last;
     }
  }
  if ($html)  {
# Finally if html make the actual appenc.html
 if ($html) {
   print HTMLOUT "</dl>\n";
   &dopostamble(HTMLOUT);
 }
    open(HTMLOUT, ">".$htmlfile) or die "can't open ",$htmlfile,
    " for output";
    &dopreamble(HTMLOUT,"Appendix C: Description of Common Blocks");
    print HTMLOUT "<dl><dt><h2>List of symbolic parameters </h2>\n";
  }
# If TeX end the main file and write the sympars file
  if ($TeX) {
    print TEXOUT "\\end{document}\n";
    close TEXOUT;
    open TEXOUT, ">$TEXES_DIR/sympars.tex"
    or die "can't open sympars.tex for output";
    print TEXOUT "\\begin{thesympars}\n";
  }
# Make an alphabetic list of symbolic parameters
   while (($word,$value) = each %symbolicpars) {push @parlist, $word}
   @sparlist = sort(@parlist);
   foreach $word (@sparlist) {
     if  ($html) {print HTMLOUT "<dd><dl><dt><bold><big><a name = \"PAR$word\">",
       "$word</a></big></bold><spacer type=horizontal size=30>",$symboldescr{$word},"\n<dd>set to ",
       $symbolicpars{$word},"\n"}
     if ($TeX) {print TEXOUT "\\begin{sympar}{$word}{",$symbolicpars{$word},"}{",
       $symboldescr{$word},"}\n"}
     $list = $word."_cited";
     if (scalar(@$list)) {
     if ($html) {print HTMLOUT "<dd> assigned in "}
     if ($TeX) {$n=2; print TEXOUT "\\citedlist "}
       foreach $name (@$list) {
         $letter = lc substr($name,0,1);
         if ($html)  {print HTMLOUT " <a href=\"comsec_$letter.html#COM$name\">",
           "$name </a>\n"}
         if ($TeX) {
           print TEXOUT " $name";
           if ($n++ > 8) {print TEXOUT "\n"; $n=0}
         }
       }
    }
    if ($TeX) {print TEXOUT "\\end{sympar}\n"}
    if ($html) { print HTMLOUT "</dl>"}
  }
 if ($html) {
   print HTMLOUT "</dl>";
   &dopostamble(HTMLOUT,"comsec_a.html");
 }
 if ($TeX) {print TEXOUT "\\end{thesympars}\n"}
}

sub docommout {
  local ($name) = ($_[0]);
  if ($html) {
    $init=lc substr($name,0,1);
    $newname =  "$APPENX_DIR/comsec_$init.html";
    unless ($htmlout =~ m/_$init/) {
      if ($htmlout) {
        print HTMLOUT "</dl>\n";
        $oldname = substr($htmlout,index($htmlout,"/")+1);
        &dopostamble(HTMLOUT,"$newname")
        }
      $htmlout = $newname;
      open HTMLOUT, ">$htmlout" or die "can't open $htmlout";
      &dopreamble(HTMLOUT, "CCSL COMMON blocks ".uc $init,$oldname);
      print HTMLOUT "<dl>\n";
    }
    print HTMLOUT "<dt><h2>Common Block <a name = \"COM$name\">",
    uc $name,"</a></h2>\n<dd><dl><dt><h3>Specification</h3><dd><code>\n";
  }
  if ($TeX) {print TEXOUT "\\thecomblock{$name}\n"}
  foreach $line (@lines) {
    if ($html)  {print HTMLOUT "$line<br>"}
    if ($TeX) {print TEXOUT "$line"}
  }
  if ($html)  {print HTMLOUT "</code>\n"}
  if ($TeX) {print TEXOUT "\\end{verbatim}\n"}
  if (scalar(@dlines)) {
    if ($html)  {print HTMLOUT "<dt><h3>Description</h3><dd>\n"}
    if ($TeX) {print TEXOUT "\\begin{thecomdesc}\n"}
    $first=1;
    foreach $line (@dlines) {
     if ($html)  {print HTMLOUT &docardlinks($line)}
     if ($TeX)  {print TEXOUT &dotexchars($line)}
     unless ($first || $line !~ /^[A-Z]/) {
       if ($html)  { print  HTMLOUT "\n"}
       if ($TeX)  {print TEXOUT"\n"}
     } else {
       if ($html) {print  HTMLOUT "<br>\n"}
       if ($TeX)  {print TEXOUT"\\\\\n"}
     }
   }
#   if ($html) {print HTMLOUT "\n"}
   if ($TeX)  {print TEXOUT"\\end{thecomdesc}\n"}
 }
 $mlist = $name."_module";
 if (scalar(@$mlist)) {
   if ($html) {print HTMLOUT "<dt><h3>Declared by</h3><dd>\n"}
   if ($TeX)  {print TEXOUT"\\begin{thecomdecl}\n"}
   foreach $line (@$mlist) {
     $clist =$line."_".$name;
     if ($html) {
       if ($partlist{$line} eq $line) {$href = "$line.html"}
       else {$href = $partlist{$line}."sec_".lc(substr($line,0,1)).".html#$line"}
       print HTMLOUT "<a href=\"$href\">$line</a> to use\n";
     }
     if ($TeX)  {print TEXOUT "\\commitem{$line} to use"}
     foreach $word (@$clist) {
       if ($html) {
         print HTMLOUT " $word ";
       }
       if ($TeX)  {print TEXOUT " ",$word}
     }
     if ($html) {print HTMLOUT "<br>\n"}
     if ($TeX)  {print TEXOUT "\n"}
   }
#   if ($html) {print HTMLOUT "\n"}
   if ($TeX)  {print TEXOUT  "\\end{thecomdecl}\n"}
  }
  if (scalar(@sympars)) {
    @sympars = removecopies(@sympars);
    if ($html) {print HTMLOUT "<dt><h3>Symbolic parameters used</h3><dd>\n"}
    if ($TeX)  {print TEXOUT"\\begin{thecomsymb}\n"}
    foreach $line (@sympars) {
      if ($html) {print HTMLOUT
       "<a href = \"appenc.html#PAR$line\">$line</a>",
       " set to ",$symbolicpars{$line}," dimensioning "}
      if ($TeX)  {print TEXOUT
        "\\commitem {$line (",$symbolicpars{$line},")} dimensioning "}
      $list = $line."_spused";
      foreach $word (@$list) {
        if ($html) {print HTMLOUT " $word"}
        if ($TeX)  {print TEXOUT " $word"}
       }
# clear the list
       @$list = ();
       if ($html) {print HTMLOUT "<br>\n"}
       if ($TeX)  {print TEXOUT "\n"}
     }
#     if ($html) {print HTMLOUT "\n"}
     if ($TeX)  {print TEXOUT  "\\end{thecomsymb}\n"}
   }
   if ($html) {print HTMLOUT "</dl>\n"}

 }

sub getline {
# This is the routine called to read each line of the input files.
# If it encounters a C LEVEL line it positions to the next non-commented
# SUBROUTINE FUNCTION or PROGRAM line and returns $clevel true. $clevel is also set to
# be true if ($doingmain) and the line contains  SUBROUTINE or FUNCTION.
# It also concatenates FORTRAN continuation lines.
# Before the first call with a new input file handle INFILE $thisline and $nextline
# must be initialised:
#     $thisline = 0;
#     $nextline = 0;

  my ($clevel) = 0;
  if ($nextline) {
    $thisline = $nextline;
    $nextline = <INFILE>;
  }
  elsif ($thisline) {return @returnlist} # end of file
  else {
    $thisline = <INFILE>;
    $nextline = <INFILE>;
  }
  if ($thisline =~ /^ .*( SUBROUTINE| FUNCTION| BLOCK *DATA| ENTRY)/) {
    if ($1 eq " ENTRY") {
      $clevel = -1;
    } elsif ($doingmain) {
      $clevel = 2;
    }
  }
  if ($thisline =~ /^C LEVEL *(\d{1,2})/) {
    $clevel = 1;
    $main = ($1 > 20);
    while ($nextline !~ /SUBROUTINE|FUNCTION|BLOCK *DATA|PROGRAM/) {
      $nextline = <INFILE>;
      return @returnlist unless ($nextline);
    }
    $thisline = $nextline;
    $nextline = <INFILE>;
  }
  if ($thisline !~ /^C/i) {
# Deal with shriek comment
    if ($thisline =~ /!.*$/) {
# Get rid of literals
      $thisline =~ s/\'.*?\'/\#/g;
# and try again
      if ($thisline =~ s/(!.*$)//) {
#         print "Shriek comment '",$1,"'\n"
      }
    }
    while ($nextline =~ s/(^     [^ ] *)//) {
      chomp $thisline;
      $thisline.=$nextline;
#     print "Line with continuation '",$1,"'\n",$thisline;
      $nextline = <INFILE>;
    }
  }
  return ($thisline,$clevel);
}


sub writeout ($) {
  my (@texlist,@templist);
  my (@listtitles) = ("Entries: ","Calls:","Called by:");
  my (@listlists) = ("_entries","_calls","_caldby");
  my ($listfound) =0;
  if ($TeX) {
  	print TEXOUT "\\hypertarget{",lc($_[0]),"}{}\n";
    print TEXOUT "\\startmodule{",$_[0],"}{",
      breakline($routine,66,",","\\\\"),"}\n{",&dotexchars($hedline),"}
      {$classwrd}\n";
  }
  if ($html) {
    print HTMLOUT "<h2> <a name = \"",uc$_[0],"\">\n",breakline($routine,
    50,",","<br>"),"</a> </h2>\n";
    print HTMLOUT "<h4> ",breakline(docardlinks($hedline),66," ","<br>"),"</h4> <dl>\n";
  }
  foreach $swi (@commentcodes) {
    $clist = "comment_$swi";
    if (scalar @$clist > 0) {
      if ($TeX) {
        @texlist = @$clist;
        print TEXOUT "\\",$texheaders{$swi},"\n";
        print TEXOUT texpro(@texlist);
      }
      if ($html) {
        print HTMLOUT "<dt><h3>",$htmlheaders{$swi},": </h3><dd>\n";
        @templist =  htmlpro(@$clist);
        print HTMLOUT @templist;
      }
    }
  }
  foreach $listtitle (@listtitles) {
    $thislist =shift(@listlists);
    $list = $doingmain."_".$_[0].$thislist;
    if (scalar @$list > 0) {
      $listfound++;
      if ($TeX) {
        print TEXOUT "\\begin{callslist}\n" if ($listfound==1);
        texlist($thislist,@$list)
      }
      if ($html) {htmllist($listtitle,@$list)}
    } else {
      if ($main && !inmain && !shift(@listlists)) {
        print "Routine $name of program $doingmain is not called";
      }
    }
  }
  print TEXOUT "\\end{callslist}\n" if ($listfound && TeX);
  $list = $_[0]."_comm";
  if (scalar @$list > 0) {
    if ($TeX) {texcom($_[0],@$list)}
    if ($html) {htmlcom($_[0],@$list)}
  }
  if ($TeX) {
     if ($updt) {print TEXOUT "\\finmodule{$updt\\\\ }"}
     else {print TEXOUT "\\finmodule{}"}
     if ($classwrd) {print TEXOUT "{$category}\n{$classtype,}";
     } else {
       print TEXOUT "{}{}";
     }
     print TEXOUT "\n";
  }
  if ($html) {
    print HTMLOUT "</dl> <h4> ",$updt,"</h4> \n";
    if ($classwrd) {print HTMLOUT "<dt><h3>Classification:</h3><dd>    ",
    $category," . . . . . . . ",$classtype,"</dl> <hr> <br>\n";}
    else {print HTMLOUT "</dl> <hr> <br>\n"}
  }
}

sub htmlpro (@) {
  my ($line,$spaces,@lines,$init,$new,$n,$indent,$inline);
  my (%htmlchars) = (qw/< &lt; > &gt; &[^lg] &amp$1;/);
  @lines = ();
  $inline = 0;
  $indent = 0;
  $n = 0;
  foreach $line (@_) {
# Process HTML special characters
  while (($char,$rchar) = each %htmlchars) {
    $line =~ s/$char/$rchar/g;
  }
#remove and count initial spaces
#  print $line;
    $line =~ s/^( *)//;
    $new = length $1;
    if ($new-1 > $n) {
      $n = $new;
      push @lines, "<br><dl><dt><dd>";
      $inline = 0;
      ++$indent;
    }
    elsif ($new+1 < $n)  {
      push @lines, "</dl>";
       --$indent;
      $n = $new;
    }
# Start new line if line starts with a capital letter
    if ($inline) {
    if ($line =~ m/^([A-Z])/) {push @lines, "<br>\n"}
     }
     $inline = 1;
# Put in links for card references
    push @lines, &docardlinks($line);
   }
  if ($indent <0) {print "\nNegative indent in $name\n"}
  while ($indent>0) {push @lines,"</dl>"; --$indent}
  return @lines;
}

sub texpro (@) {
  my ($line,$spaces,@lines,$init,$new,$n,$openbrace,$inline);
  $init = ("\\setlength {\\remainwidth}{\\textwidth}\n");
  @lines = ();
  $inline = 0;
  $openbrace = 0;
  foreach $line (@_) {
# Process TeX special characters
    $line = dotexchars($line);
    if ($line =~ s/^( *)//) {
      $new = length $1;
      if ($new != $n) {
         $n = $new;
         if ($n > 0) {
           $spaces = ($new/2)."em";
           if ($openbrace) {push @lines,#{
            "}\n"}
           if ($inline) {push @lines, "\\\\ "}
           $inline = 0;
           push @lines, $init;
           push @lines, "\\addtolength{\\remainwidth}{-".$spaces."}\n";
           push @lines, "\\makebox[".$spaces
                    ."]{ }\\parbox[t]{\\remainwidth}{\n";#}
           $openbrace = 1;
         }
       } else {
# Start new line if line starts with a capital letter
       if ($inline) {
         if ($line !~ s/^([A-Z])/\\\\ $1/) {$line =~ s/^/ /}
         }
       }
     }
     push @lines, $line;
     $inline = 1;
   }
   if ($openbrace) {push @lines,#{
    "} \n"}
   if ($inline) {push @lines, "\\ssp\n"}
   else {push @lines, "\\ssk\n"}
   return @lines;
 }

sub htmllist ($@) {
  local ($word,@list) = @_;
  my ($n,$init,$entry);
  print HTMLOUT "$tab<dt><h3>",$word,"</h3>\n";
  $entry = (substr ($word,0,1) eq "E");
  $n=0;
  print HTMLOUT "$tab$tab<dd>" unless ($entry);
  foreach $word (@list) {
    if ($entry) {
      print HTMLOUT "$tab$tab<dd>$word ";
      $clist = $doingmain."_".$word."_caldby";
      if (scalar @$clist) {
        print HTMLOUT " called by: ";
        foreach $cname (@$clist)  {
          &printhtmlref(HTMLOUT,$cname);
        }
        print HTMLOUT "<br>\n$tab$tab";
        $n=0;
      } else  {print HTMLOUT "\n"}
    } else {
      printhtmlref(HTMLOUT,$word);
    }
    if (++$n > 8) {print HTMLOUT "\n$tab$tab"; $n=0}
  }
  if ($n) {print HTMLOUT "\n"}
 }

sub texlist ($@){
  my ($word,@list) = @_;
  my ($n,$entry);
  $entry = (substr ($word,1,1) eq "e");
  $word = "\\".substr($word,1,4)."item ";
  print TEXOUT $word;
  $n=0;
  foreach $word (@list) {
    if ($entry) {
      print TEXOUT $word;
        $clist = $doingmain."_".$word."_caldby";
        if (scalar @$clist) {
          print TEXOUT "called by: ";
          foreach $cname (@$clist)  {
            print TEXOUT " $cname";
          }
        }
        print TEXOUT "\\\\\n";
        $n=0;
      } else {
        print TEXOUT $word," ";
      if (++$n > 8) {print TEXOUT "\n"; $n=0}
    }
  }
}


sub htmlcom ($@) {
  $name = shift;
  $n = 0;
  print HTMLOUT "<dt><h3>Common blocks used:</h3><dl><dd>\n";
  foreach $block (@_) {
    $clist = $name."_".$block;
    if (scalar @$clist > 0) {
      print HTMLOUT "<dt> /<a href=\"comsec_",lc(substr($block,0,1)),
      ".html#COM$block\">$block</a>/ to use";
      foreach $word (@$clist) {
        print HTMLOUT " $word";
      }
    }
  }
  print HTMLOUT "</dl>\n";
}

sub texcom ($@) {
  my ($name,$cclist,$block,$word,$cfound,$n);
  $cfound = 0;
  $name = shift;
  foreach $block (@_) {
    $cclist = $name."_".$block;
#    print "List ",$cclist," contains ",scalar @$clist," items\n";
    if (scalar @$cclist > 0) {
      print TEXOUT "\\thecommon\n" if (++$cfound==1);
      print TEXOUT "\\commitem{$block}";
      $n = 0;
      foreach $word (@$cclist) {
        print TEXOUT $word," ";
        if (++$n > 8) {print TEXOUT "\n"; $n=0}
      }
      print TEXOUT "\n" if ($n);
    }
  }
  print TEXOUT "\\end{commlist}\n" if ($cfound);
}

sub inittex  {
local ($part) = $_[0];
  open(TEXOUT, ">".$texfile) or die "can't open ".$texfile.
  " for output";
# Write preamble
  print TEXOUT "\\documentclass[onecolumn,twoside,11pt,a4paper]{report}\n";
  print TEXOUT "\\usepackage{makeidx,color}\n";
  print TEXOUT "\\usepackage{ifthen,CCSLapa}\n";
  print TEXOUT "\\makeatletter\n ","\\\@ifpackageloaded{tex4ht}\n",
  	"{\\let\\iftexforht\\\@firstoftwo}\n","{\\let\\iftexforht\\\@secondoftwo}\n",
	"\\makeatother\n";
  print TEXOUT "\\usepackage{hyperref}\n";
  print TEXOUT "\\pagestyle{appheadings}\n";
  print TEXOUT "\\makeindex\n\\begin{document}\n",
  "\\appendix{}\n\\setcounter{chapter}{",$partnumbers{$part},"}\n";
  print TEXOUT "\\markboth{",$parttypes{$part},"}{}\n";
# Title page etc
  print TEXOUT "\\MakeTitlePage{",$parttitles{$part},
  "}{",$partheaders{$part},"}\n";
  unless ($part eq "com") {
    print TEXOUT "\\begin{MakeClassList}{",$parttypes{$part},"}\n";
    print TEXOUT "\\input{",$part,"classlist}\n";
    print TEXOUT "\\end{MakeClassList}\n\\pagenumbering{arabic}\n";
# Make two empty files
    open DUMMY, ">".$TEXES_DIR."/".$part."classlist.tex" or die;
    print DUMMY "
\\typeout{***********************************************************}\n
\\typeout{*** You Must run makeindices.pl  to make contents lists ***}\n
\\typeout{***********************************************************}\n";
  open DUMMY, ">".$TEXES_DIR."/".$part."alphalist.tex" or die;
  print DUMMY "
\\typeout{***********************************************************}\n
\\typeout{*** You Must run makeindices.pl  to make contents lists ***}\n
\\typeout{***********************************************************}\n";
    $oldnum = -1;
    $oldtype = "";
  }
}
sub htmltop  {
  $heading = "Cambridge Crystallographic Subroutine Library ";
    $ind = 0;
 # Title etc
    print HTMLTOP "<Head>\n<Title>",$heading,$title,
    "</Title>\n</Head>\n <Body>";
    print HTMLTOP
   "<center><h1>Cambridge Crystallographic Subroutine Library </h1><br>\n",
   "<h3>$firstline</h3><br>\n<h1>Appendices
    (<a href=\"#appa\"> A</a>
    <a href=\"#appc\"> C</a>
    <a href=\"#appd\"> D</a>
    <a href=\"#appe\"> E</a>)
    </h1></center>\n";
}
sub inithtml  {
  local ($part) = $_[0];
  local (%types) =  ("lib","subroutines","mai","programs and their special subroutines");
  local (%hrefname) =  ("lib","appa","mai","appd","com","appc");
  my ($comm) = ($part eq "com");
  my $letter = "z";
  if ($comm) {
      print HTMLTOP  "<dl><dt><h1>";
      print HTMLTOP $parttitles{$part},"</h1>\n</h1>\n<a name = \"",
      $hrefname{$part},"\"></a>\n";
      print HTMLTOP "<dd><h2><a href=\"appenc.html\"> List of Symbolic Parameters</a></h2> \n";
      print HTMLTOP  "<dd><dl><dt><h2> Description of Common Blocks <dd>\n";
    foreach $block (@comnames) {
      unless ($block =~ /^$letter/i) {
        $letter = lc(substr($block,0,1));
        print HTMLTOP "<a href=\"comsec_",$letter, ".html\">",uc $letter,"</a>\n";
      }
    }
    print HTMLTOP "</h2></dl></dl>\n";
  } else {
     open HTMLOUT, ">$htmlfile" or die "Can't open $htmlfile for output";
    &dopreamble(HTMLOUT,$parttitles{$part}." Classified List");
    my ($list,$elist,$subname,$entry);
      print HTMLTOP  "<dl><dt><h1>",$parttitles{$part},"</h1>",
      "<a name =\"",$hrefname{$part},"\"></a>\n";
      print HTMLTOP
     "<dd><dl><dt><h2> Alphabetic List of ",$types{$part},
     "<dd>\n";
#
# do alphabetical list
    open(HTMLALF, ">".$htmlalph) or die "can't open ".$htmlalph;
    &dopreamble(HTMLALF,$parttitles{$part}." Alphabetic List");
    unless ($main) {
      @alist = alphalist(HTMLALF,@lib_modules,@lib_entrylist);
    } else {
      @alist = alphalist(HTMLALF,@mai_modules);
    }
    &dopostamble(HTMLALF);
    foreach $letter (@alist) {
      print HTMLTOP "<a href=\"",$part,"alfa.html#alflist",$letter,
      "\">$letter</a>\n";
    }
    print HTMLOUT "</h2></dl>";
#
# Then list by categories
    print HTMLTOP
   "<dt> List of ",$types{$part}," divided according to topic",
   "</h2><dd><ol>\n";
  foreach $category (@categories) {
    print HTMLTOP "<li><a href= \"",$part,"apx.html\#",
    substr($category,0,12),"\"> ",
    $category, "</a>\n";
  }
  print HTMLTOP "</ol></dl></dl>\n";
  print HTMLOUT "<dl><dd><h2> ",$parttypes{$part}," </h2><dt><dl>\n";
  $oldnum = -1;
  $oldtype = "";
  $slist = $part."_sorted";
  foreach $name (@$slist) {
    &thisone($name);
    if ($main) {
      $list = lc $name."_ownsubs";
      if (scalar @$list>1) {
        print HTMLOUT "<dd><em>Attached Subroutines</em><dl>\n";
        foreach $subname (@$list) {
          unless ($partlist{$subname} eq $subname) {
            $routine = $fullnames{$subname};
            if (!$routine) {print "can't find ",$name," in fullnames\n"}
            $hedline = $headers{$subname};
            print HTMLOUT "<dt> <a href = \"",lc $name,
          ".html#",uc $subname,"\">\n";
            print HTMLOUT breakline($routine, 66,",","<br>\n"),"</a> <dd> \n";
            print HTMLOUT "   ",breakline(docardlinks($hedline),72," ","<br>\n"),"\n";
            if ($entries{$subname}) {
              $elist = $name."_".$subname."_entrylist";
              foreach $entry (@$elist) {
#                print HTMLOUT "<p>",breakline($fullnames{$entry}, 66,",","<br>\n"),
                print HTMLOUT breakline($fullnames{$entry}, 66,",","<br>\n"),
                "<br>\n";
              }
            }
          }
        }
        print HTMLOUT "</dl>";
      }
    }
  }
#  while ($ind >= 0) {print HTMLOUT "</dl>"; $ind--}
  &dopostamble(HTMLOUT);
  }
}
sub forappene {
  local($htmltop) = @_;
        print $htmltop  "<dl><dt><h1><a name = appe> Appendix E</a></h1>\n";
      print $htmltop
     "<dd><h2><a href=\"appene.html\"> Manipulating the Master File</a>\n",
     "</h2></dl>\n";
}
sub thisone($) {
  my ($name,$elist);
  $name = $_[0];
  $routine = $fullnames{$name};
  if (!$routine) {print "can't find ",$name," in fullnames\n"}
  $classwrd = $classes{$name};
  $classwrd =~ /([0-9]{1,2})([A-D])/;
  $classnum  = $1;
  $category = $categories[$classnum-1];
  $classtype = $classtypes{$2};
  $hedline = $headers{$name};
  if ($oldnum != $classnum)  {
    while ($ind) {print HTMLOUT "</dl>"; $ind--}
    print HTMLOUT "<dt><h2> <a name = \"",substr($category,0,12),
    "\"> \n";
    ++$ind;
    print HTMLOUT $classnum,". ",$category," </a></h2><dd><dl>";
    $oldtype = "";
    $oldnum = $classnum;
  }
  if (!$main && $oldtype ne $classtype) {
    while ($ind> 1) {print HTMLOUT "</dl>"; $ind--}
    print HTMLOUT "<dt><h2> ",$2,". ",$classtype," </h2><dd><dl>\n";
    $oldtype = $classtype;
    ++$ind;
  }
  if ($main) {
    print HTMLOUT "<dt> <a href = \"",lc $name,".html#",uc $name, "\">\n";
  } else {
    print HTMLOUT "<dt> <a href = \"",$part,"sec_",
    lc(substr($name,0,1)),".html#",uc $name, "\">\n";
  }
  print HTMLOUT breakline($routine, 66,",","<br>\n"),"</a> <dd> \n";
  print HTMLOUT "   ",breakline(docardlinks($hedline),72," ","<br>\n"),"\n";
  unless ($main) {
    if ($entries{$name}) {
      $elist = "_".$name."_entries";
      foreach $entry (@$elist) {
#        print HTMLOUT "<p>",breakline($fullnames{$entry}, 66,",","<br>\n"),
#        "<br>\n";
        print HTMLOUT breakline($fullnames{$entry}, 66,",","<br>\n"),
        "<br>\n";
      }
    }
  }
#  print HTMLOUT breakline($routine, 66,",","<br>\n"),"</a> <dd> \n";
#  print HTMLOUT "   ",breakline($hedline,72," ","<br>\n"),"\n";
}

sub orderclass  {
  $na = $classes{$a};
  $nb = $classes{$b};
  $c = length $na <=> length $nb;
  if (!$c) {
    $c = $na cmp $nb;
    if (!$c) {$c = $a cmp $b}
  }
  return $c;
}

 sub breakline($$$$) {
  my ($dum);
  $dum = $_[0];
  if (length($_[0]) > $_[1]) {$dum =~ s/^(.{0,$_[1]}$_[2])/$1$_[3]/}
  return $dum;
}


sub docardlinks ($) {
  my ($ref,$letter,$match);
  $_ = @_[0];
 @matches=();
  while (s/ (\"{0,1}[A-Z]\"{0,1} [A-Z]{0,4} {0,1}card[s ])/@@@/) {
  	push @matches,$1;
  }
  my $line=$_;
	foreach $match (@matches) {
#  		if ($cardrefs) {
#    		unless ($match=~/(^[A-Z])/) {$match=~/^.([A-Z])/}
#    		$letter=$1;
#    		 print "Card link is $letter\n";
#     		$ref="$APPEN_MAN_DIR/".$external_labels{"carddef.card:".$letter};
# 		 } else {
# Identify for modification when reread by doc3labels
   			 $ref = "mk4man";
#  		}
  		$href="<a href = \"$ref\"> $match</a>\n";
  		$line=~s/@@@/$href/;
#  		print $line;
  	}
  return $line;
}

 sub removecopies {
 my (@tmplist);
 my (@newlist) = ();
 my ($item);
 my ($lastitem,) = "";
 @tmplist = sort @_;
 foreach $item (@tmplist) {
   if ($item ne $lastitem) {push @newlist, $item}
   $lastitem = $item;
 }
 return @newlist;
}

sub printhtmlref {
  local ($htmlout,$word,$rout) = @_;
  my ($temp,$temp1,$tword);
  $rout = $word if (!$rout);
  unless ($tword = $entries{$word}) {$tword = $word}
  $temp = $partlist{$tword}; # could be part or main
  $temp1 = $partlist{$temp}; # 0 or main
  unless ($temp1) {
    $temp = lc ($temp."sec_".lc(substr($tword,0,1)));
    print $htmlout "<a href = \"$temp.html#",uc $tword,"\"> $rout </a> \n";
  }  else {
#    if ($main) {
#      print$htmlout "<a href = \","lc $temp,".html\"#",uc $tword,
#      "\"> $word </a> \n";
#    } else {
      print $htmlout "<a href = \"",lc $temp1,".html#",uc $tword,
      "\"> $rout </a> \n";
#    }
  }
}
sub alphalist {
  local ($htmlout) = shift;
  local (@letters,$cutname) = ();
  my (@alist,$name);
  my ($initlet) = 0;
  @alist = sort @_;
  print $htmlout "<dl><dd><dl>\n";
  foreach $name (@alist) {
    unless ($initlet eq substr($name,0,1)) {
      $initlet = substr($name,0,1);
      push @letters, $initlet;
      print $htmlout "$tab<dt><h2><a name = \"alflist$initlet\"> ",
      "$initlet </a></h2>\n";
    }
    print $htmlout "$tab<dt>";
    &printhtmlref($htmlout,$name,$routine{$name});
    print $htmlout "\n";
     if (($ename = $entries{$name}) && ($name ne $ename)) {
      print $htmlout "$tab$tab<dd>Entry to $ename\n";
    } else {
      print $htmlout "$tab$tab<dd>",$headers{$name},"<br>\n";
    }
  }
  print $htmlout "</dl></dl>\n";
  return @letters;
}

sub dopreamble {
local ($outfile,$title,$prev) = @_;

  print $outfile "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 3.2 Final//EN\">\n";
  print $outfile "<HEAD>\n<TITLE>$title</TITLE>\n";
#
  if (($title  =~ /dix D/)) {
   print $outfile "<style>\n dl{margin-bottom:10pt}\n";
	print $outfile "dl dd {margin-top:3pt;margin-bottom:3pt}\n";
	print $outfile "dl dl {margin-left:30pt;margin-top:3pt}\n";
	print $outfile "em {font-weight:bold;font-style:normal}\n</style>\n";
	}
  print $outfile "<link rel=\"stylesheet\" type=\"text/css\" ",
	"href=\"../html/ccsldoc.css\">\n";
  print $outfile "</HEAD>\n<BODY>\n";
# Top Navigation bar
  print $outfile "<table cellspacing=\"5\"><tr>\n",
  "<td class=\"clinks\"><a href=\"appendix.html\">Contents</a></td>\n"
  unless ($title eq "CCSL Appendices");
  if ($prev) {
    print $outfile "<td class=\"clinks\"><a href=\"$prev\">",
  "Prev</a></td>\n";
  }
  print $outfile "<td class=\"clinks\"><a href=\"../mk4man/$manual.html\">",
  "Manual</a></td>\n";
  print $outfile "</tr></table><hr>\n";
}

sub dopostamble {
  local ($outfile,$next) = @_;
  print $outfile "<p><hr>\n";
  print $outfile "<table cellspacing=\"5\"><tr>\n";
  unless ($outfile eq $next) {
    print $outfile "<td class=\"clinks\"><a href=\".appendix.html\">",
  "Contents</a></td>\n";
  } else {
    if ($next) {
    print $outfile "<td class=\"clinks\"><a href=\"$next\">",
  "Next</a></td>\n";
  }
}
  print $outfile "<td class=\"clinks\"><a href=\"../mk4man/$manual.html\">",
  "Manual</a></td>\n";
#
  print $outfile "</tr></table>\n<ADDRESS>\n",
  "$myname <br>$myaddress\n",
	"<script type=\"text/javascript\" src=\"../html/mailing.js\">  </script>\n",
 "</ADDRESS></BODY>\n</HTML>\n";
 }

sub dotexchars {
 local ($_) = @_;
  my (%texchars) = ('#'=>'\\#','\$'=>'\\$','%'=>'\\%','\&'=>'\\&');
# Process TeX special characters
  while (($char,$rchar) = each %texchars) {
    s/$char/$rchar/g;
  }
# try to cope with maths mode
  s/\\{2,2}\$/\$/g;
  return $_;
}
sub labelhash($) {
#Make the c3labels hash
my ($ifile,$line,%labels,$key,$url,$pos,$ppos,$i,$x);
	%labels=();
	$ifile=shift(@_);
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
#	@list=keys(%labels) ;
#	@slist=sort(@list);
#		foreach $key (@slist) {
#			printf "%20s ..... %s\n",$key,$labels{$key};
#	}
	return  %labels;
}
#
sub getversiondate($) {
	$_=shift;
	my @coms= qw/vday vmonth vyear/;
	my (@wordS,@comps,$date);
	@words=split;
	$date=$words[5];
	@comps=split("-",$date);
	$tfile=$TEXES_DIR."/versiondate.tex";
	open TFILE,">$tfile" or die "can't open $tfile";
	print TFILE "\\newcommand{\\version}[1]{$comps[1] $comps[2]}\n";
	foreach $c (@coms) {
		$p=shift(@comps);
		print TFILE "\\newcommand{\\$c}[1]{$p}\n";
	}
	close TFILE;
}



