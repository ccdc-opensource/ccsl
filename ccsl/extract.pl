#! /usr/bin/perl

# To extract a "part" of the mistress file as a fortran file.
# Source directory $SSSRC, destination directory $FDEST
# Options are one of LAX/PICKY, UNIX/VMS, ILL/RAL

sub dateandtime;

 @steps=("UPDT","PARS","STOP","DUM","COMM","DONE","DUM","##LIB","##ENDLIB") ;
 @labels=("HEAD","SKIP","SPARS","EPARS","SKIP","SCOM","ECOM","SKIP","SPRT","EPRT");
 %parts = (qw/NEW 1 LIB 5 MAI 6 PJB 7 JBF 8 PIG 4 PR 2 PF 3 PMA 4/);
 @choices=("LAX","UNIX","ILL");
 %optsf77 = (qw/LAX 1 PICKY 2/);
 %optssys = (qw/UNIX 1 VMS 2/);
 %optssite = (qw/ILL 1  RAL 2/);
#
  $infile= "mistre.ss";
  $outfile = "LIBMK4";
  $source = $ENV{CCSL_SSSRC};
  unless ($source) {
    $source = $ENV{CCSL_SRC};
    unless ($source) {$source = "."}
  }
  $dest = $ENV{CCSL_FDEST};
  unless ($dest) {
    $dest = $ENV{CCSL_SRC};
    unless ($dest) {$dest = "."}
  }
  unless ($parlist = $ENV{CCSL_PARLIST}) {
    if ($ccsl = $ENV{CCSL}) {$parlist = "$ccsl/options/parlist"}
    unless (-e $parlist) {$parlist = "$source/parlist"}
  }
# Read options given as arguments
  ($part,$optf77,$optsys,$optsite) =@ARGV;
# chack the options
  $err = 0;
  if ($part) {
    $part = uc $part;
    if (!$parts{$part}) {
      print "Unkown part ".$part." should be one of: \n";
      while (($opt) = each %parts) {print" ",$opt}
      print "\n";
      $err+=1;
    }
   } else {$part = "LIB"}
   if ($optf77) {
     $optf77 = uc $optf77;
     if (!$optsf77{$optf77}) {
       print "Unkown option code ".$optf77." should be one of ";
       while (($opt) = each %optsf77) {print " ",$opt}
       print"\n";
       $err+=2;
     }
   } else {$optf77 = "LAX"}
   if ($optsys) {
     $optsys = uc $optsys;
     if (!$optssys{$optsys}) {
       print "Unkown system ".$optsys." should be one of ";
       while (($opt) = each %optssys) {print " ",$opt}
       print "\n";
       $err+=4;
     }
   } else {$optsys = "UNIX"}
   if ($optsite) {
     $optsite = uc $optsite;
     if (!$optssite{$optsite}) {
       print "Unkown site ".$optsite." should be one of ";
       while (($opt) = each %optssite) {print" ",$opt}
       print "\n";
       $err+=8
     }
   } else {$optsite = "ILL"}
   if ($err) {die}
# Report options
   print "Extracting ".$part." with options $optf77 $optsys $optsite";
   $steps[7] =~ s/LIB/$part/;
   $steps[8] =~ s/LIB/$part/;
   $outfile =~ s/LIB/$part/;
   @choices = ($optf77, $optsys, $optsite);
 # Fiddle file names
  $infile =~ s|^|$source/|;
 if ($optsys eq "VMS") {
   $outfile = uc ($outfile.".for");
 } else {
   $outfile =  lc ($outfile.".f");
 }
 $outfile =~ s|^|$dest/|;
 print "\n from: ",$infile,"\n   to: ",$outfile,"\n #OK ? (y/n)";
# Check is OK by user
# if (<STDIN> =~ m/^n/i) {exit(1)}
# Open files
 open(INFILE, $infile) or die "can't open ".$infile;
 open(OUTFILE, ">".$outfile) or die "can't open ".$outfile." for write";
 print OUTFILE "C Extracted from:\nC $infile \nC with options: ",
 "$optf77 $optsys $optsite\nC on ",&dateandtime,"\nC\n";
 open(PARFILE, $parlist) or
   print "$parlist failed to open; no symbolic parameters changed";
#
# Read names and value of parameters to change @sword and $svalue
  %cwords =() ;
  while ($line = <PARFILE>) {
    chomp $line;
    $word=substr($line,0,4);
    $value=substr($line,5,5);
    # kill trailing spaces
    $value =~ s/ *$//;
    $cwords{$word} = $value;
   }
# Initialise
     $begin=1;
     $nlines=0;
# Main program loop starts here
   foreach $label (@labels) {
     $step=shift(@steps);
     print $label," ",$step,"\n";
     while ($line = <INFILE>) {
       if ($line =~ /^$step/)  {last;}
       goto $label;
# Print out header
HEAD:  print OUTFILE $line;
	if ($begin) {
#Pick update level from $line
		$_=substr($line,index($line,"Update"));
		@temp=split;
		$cwords{"UPDT"} = $temp[1];
		$begin=0;
	}
    next;
# Skip lines of mistress
SKIP:  next;
# Read names and values of symbolic parameters into hash %cwords
# Substitute new values where necessary
SPARS: chomp $line;
       $word=substr($line,6,4);
       $value =substr($line,11,5);
       # kill trailing spaces
       $value=~ s/ *$//;
       $newvalue = $cwords{$word};
       unless ($newvalue) {
         $cwords{$word} = $value;
#        print "Parameter ",$word," value ",$value,"\n";
       }
       else {
       print OUTFILE "C   Parameter ",$word," altered from ",$value,
           " to ",$newvalue,"\n";
           print"Parameter ",$word," altered from ",$value," to ",$newvalue,"\n";
       }
       next;
EPARS: last;
# Read all the COMMON blocks into $lines
SCOM:  $lines[++$nlines] =$line;
       next;
# Substitute symbolic parameters in $lines
ECOM:  foreach $line (@lines) {
       while ($line =~ /%(.{2,4})%/) {
           $value = $cwords{$1}; #print "Parameter ",$1," value",$value;
           $test=quotemeta("%".$1."%");
         if ($value) {$line =~ s/$test/$value/g }
           else {print "Parameter ",$1," not found\n" ;
            $line =~ s/%$1%/1/g }
           # print "Newline: ",$line;
        }
       }
       last;
# Read The required part
SPRT:   if ($line =~ m:^/:) {
       # Insert COMMON from @lines
         chomp($line);
         $line =~ s/ *$//;
         $nlines=0;
         foreach $cline (@lines) {
           if ($cline =~ m:COMMON *$line:) {
             $num = $lines[$nlines-1];
             chomp($num);
             $num =~ s/ *$//;
             for ($i=0;$i<$num;$i++) {
               print OUTFILE $lines[$nlines+$i];
             }
             last;
           }
           $nlines++;
         }
       # Replace symbolic parameters in lines beginning %
       } elsif ($line =~ s/^%//) {
           print OUTFILE "C%",$line; #"
           while ($line =~ /%([\w*+]{2,4})%/) {
             $value = $cwords{$1};
             $test=quotemeta("%".$1."%");
             if ($value) {$line =~ s/$test/$value/g }
             else {
               print "Parameter ",$1," not found\n" ;
               $line =~ s/$test/1/g;
             }
           }
           print OUTFILE $line;
       # Adjust code for system dependent choices
       } elsif ($line =~ m/^CS/) {
           if ($line  =~ m/^CS /) {
             foreach $choice (@choices) {
               $useline = ($line  =~ s/^CS $choice/CS $choice\n/);
               if ($useline) {
                 print OUTFILE $line;
                 last;
               }
             }
           } else {
             foreach $choice (@choices) {
              $useline = !($line  =~ m/^CS-$choice/);
              if (!$useline) {last}
             }
             if ($useline) {
               $line =~ s/ /\n /;
               print OUTFILE $line;
             }
           }
           # Or just print unmodified line
           if (!$useline) {print OUTFILE $line}
         } else {
           print OUTFILE $line;
         }
     next;
EPRT: print "All done";
      close OUTFILE;
      exit(0);
   }
   if (!$line) {
     print "Premature end of file in $label\n";
     exit(1)}
 }
 print "All done\n";
 exit(0);

sub dateandtime {
  my ($sec,$min,$hour,$mday,$month,$year,$wday,$idst,@months);
  @months = (qw/January February March April May June July August
  September October November December/);
  ($sec,$min,$hour,$mday,$month,$year,$wday,$idst) = localtime(time);
  $year +=1900;
  if (length $min < 2) {$min =~ s/^/0/}
  return "$mday-".$months[$month]."-$year ($hour:$min)";
}
