#! /usr/bin/perl

# Main perl script for manipulating the CCSL system
# Modification to make piglibs
# invoke with <part> -[acels] [filename]
# At least one function switch must be given
# Switches
# -a   Make a linkable archive out of a set of object files
# -c   Split up <part>mk4.f into individual modules and compile each
# -e   Extract <part> from the mistress file: parameters to be
#      substituted in filename
# -g,f   get a single module <filename> or all modules from a list ffrom partmk4.f
# (extension.got or .f)
# -l   Load a list of main programs: names in <filename>
# -m   Construct a makefile for the program and subroutines given as arguments
# -s   Split up <part>mk4.f into individual modules in directory <filename>
# eg ccsl -ace lib parlist  will create libmk4.a from mistre.ss
#    ccsl -e mai will extract the main program file maimk4.f from mistre.ss
# ccsl -asg pig piglist  will create libraries from the listed options from pigmk4,f
#
# The sources and destinations of the various files used or created are derived
# from environment variables which can be set here or outside the script.
# To customise he script it should be edited down to  the next
#*************************************************
# to select local options
#{
use strict;
use warnings;
use Cwd;
use File::Copy qw(copy move);
use File::Path qw(rmtree mkpath);
use File::Basename qw(fileparse);
use Sub::Identify ':all';
#
my (@basedirs,@perls,@sources,@fdests);
# To get the base directory for CCSL
@basedirs=qw/$ENV{CCSL_NEW} $ENV{CCSL} &cwd()/;
# To set the directory containing the ccsl perl scripts from
@perls=qw($ENV{PERL_SCRIPTS} $ENV{CCSL_PERL} $ENV{HOME}."/perl_scripts");
# The directory in which the mistre.ss file will be sought is CCSL_SSSRC if
# defined, otherwise CCSL_SRC, and finally cwd if neither is set
@sources= qw($ENV{CCSL_SSSRC} $ENV{CCSL_SRC} $ccsldir."/source" &cwd()) ;
# The directory to which the <part>mk4.f files will be written is CCSL_FDEST if
# defined, otherwise $src as above
@fdests= qw( $ENV{CCSL_FDEST}  $ENV{CCSL_SRC} $ccsldir."/source" &cwd());
#
our $cwd = &cwd();
our $ccsldir =&setPath(@basedirs);
our $src=&setPath(@sources);
our $perl=&setPath(@perls);
our $fsrc=&setPath(@fdests);
our ($fdest,$xdest,$libdest,$pigdest,$optiondir);
our ($options,$error);
unless ($fdest = $ENV{CCSL_FDEST}) {$fdest = $src}
$ENV{CCSL_FDEST} = $fdest;
if ($fdest eq".") {$fdest=$cwd}
unless ($fsrc = $ENV{CCSL_FSRC}) {
  $fsrc = $fdest;
  $ENV{CCSL_FSRC} = $fdest;
}
if ($fsrc eq".") {$fsrc=$cwd}
# Directory for executable programs
unless ($xdest = $ENV{CCSL_XDEST}) {$xdest = "$ccsldir/exe"};
# Directory for graphics utilities
unless ($pigdest = $ENV{CCSL_GDEST}) {$pigdest="$ccsldir/graf"}
# Directory for linkable libraries
unless ($libdest=$ENV{CCSL_LIBDEST}) {$libdest = "$ccsldir/lib"}
# Directory containing choices for site dependent options
unless ($optiondir = $ENV{CCSL_OPT}) {$optiondir = "$ccsldir/options"}
# CCSL_PARLIST is an optional file giving symbolic parameters (mostly dimensions,
# in common blocks) which are to be changed from the values given in the PARS
# section near the  beginning of the mistre.ss file.
unless ($ENV{CCSL_PARLIST})  {$ENV{ CCSL_PARLIST} = "$optiondir/parlist"}
# Now select other system  or site dependent options
# Those already in the master file are:
our ($rigidopt) = ("lax picky");
our (@opsysopt) = (qw/unix vms/);
our (@siteopt) = (qw/ill ral/);
#lax or picky" picky gives "strict" FORTRAN 77 no $ FORMAT processing
#unix or vms (vms not completely tested)
#ill or ral
#ill has .cry default extension for crystal data files and listing files named
# <prog>.lis
#ral has .ccl default extension for crystal data files and listing files named
# by user
#read defined options from file if present
if (-e "$optiondir/ccsl_choices") {
  if (open INFILE, "$optiondir/ccsl_choices") {
    $options = <INFILE>;
    chomp($options);
    my @temp = split(/\s+/,$options,3);
# Check them against known options
    $error = ($rigidopt !~ /$temp[0]/i);
    $error |= (!grep/^$temp[1]$/i,@opsysopt);
    $error |= (!grep /^$temp[2]$/i,@siteopt);
    if ($error) {&errorExit ("Unknown option \"$options\"\n")}
  }
# default options
} else {$options = "lax unix ill"};
#q

# Select FORTRAN options
our ($ftncommand,$ftncompiler,$cswitches,$flibs)=&readopts("$optiondir/f77_choices");
# Fortran command to compile library modules as object modules
 $ftncommand = "gfortran -c" unless $ftncommand;
# Libraries switches etc for main progs
 $ftncompiler = "gfortran"unless $ftncompiler;
# Any extra Compiler switches go here
 $cswitches = "" unless $cswitches;
# Extra fortran libraries which may be required for date/time etc
 $flibs = "" unless $flibs;
# This will produce Postscript graphics output with no visual display
#*************************************************
# End of part which can be modified#
#
our ($switch,$part,@filenames) = @ARGV;
our $verbose= $switch =~ s/v//;
if ($verbose) {
	print "Directories set as:
        		Working directory  $cwd
                CCSL directory     $ccsldir
                Source directory   $src
                Perl directory     $perl
                F sources from     $fsrc
                F destination is   $fdest\n";
    }
our %switchnums=qw/e 0  s 1  c 2  a 3  l 4  f 5  g 6  m 7/;
our %parts = (qw/NEW 4 LIB 1 MAI 2 PJB 2 JBF 2 PIG 3 PR 1 PF 1 PMA 2/);
our %usedparts = (qw/LIB 1 MAI 2 PIG 3 /);
our %statflag= ();
our $flagfile="$ccsldir/ccsl_flags";
# file names of dependencies
our @deps=("$src/xxxmk4.f","$src/temp/xxx","$src/temp/xxx","$libdest/libmk4.a","$src/exe");
#+-+-+-+-+-+-+-+-+-+-+-+-+ INITIAL STATUS FLAGS +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
unless (-e "$src/mistre.ss") {&errorExit ("CCSL Master file $src/mistre.ss not found")}
    my $srcage= (-M "$src/mistre.ss");
	foreach my $part (keys %usedparts) {
		$part=lc $part;
		$statflag{$part}=0;
    	my $prevage= $srcage;
    	for (my $i=0;$i<4;$i++) {
    		my $j=$i;
    		if ($i==3 && $part eq "mai") {$j=4}
    		my $depfile= $deps[$j];
   			$depfile=~ s!xxx!$part!;
    		next unless (-e $depfile) ;
     		if ($verbose) {print "Testing $part bit $i $depfile $prevage ".(-M $depfile),"\n"}
   			last if ( "$prevage" < (-M $depfile)) ;
   			$statflag{$part} |=1<<$i;
   			$prevage= (-M $depfile);
     	 }
	}

if ($verbose) {print "Initial statflags\n";
while((my $key, my $value) = each(%statflag)) {
    printf  "$key %4d\n", $value;
	}
}
our $errfile=$cwd."/fortran_errors";
our $complog=$cwd."/compile_log";
our $badf="$cwd/badf";
our @functions= qw/extract split compile archive load/;
#*************************************************
# Executable part of script
our ($partno);
our @grafopts=();
our @plist=();
#+-+-+-+-+-+-+-+-+-+-+-+-+CHECK ARGUMENTS+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
{@grafopts=&readopts("$optiondir/graphics_choices");
   		if(!@grafopts) {$grafopts[0]="pigps"}}
unless ($switch =~ /^-([escalgfm])$/) {
&errorExit("No function switch given need \"-\" then"." one of a, c, e, g, l, m, s")}
our $swi=$switchnums{$1};
$part = lc($part);
unless (defined($usedparts{uc $part})) {&errorExit("Part $part not currently allowed by this ccsl")}
until ($partno = $parts{uc $part}) {
   my $opt;
   print "Unkown part ".$part." should be one of: \n";
   while (($opt) = each %parts) {print" ",$opt}
   print "\n Part? ";
  $part = uc <STDIN>;
  chomp $part;
 }
#+-+-+-+-+-+-+-+-+-+-+-+-+CHECK SWITCHES+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
# Check switches
if    ($partno == 1) {$error =  $switch =~ m/[lm]/}
elsif ($partno == 2) {$error =  $switch =~ m/[a]/}
elsif ($partno == 3) {$error =  $switch =~ m/[lm]/}
elsif ($partno == 4) {$error =  $switch =~ m/[lacgm]/}
else  {$error = 1}
if ($error) {&errorExit ( "Illegal combination of switch and part\n")}
#
#+-+-+-+-+-+-+-+-+-+-+-+-+FIND WHAT NEEDS TO BE DONE +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
our (@partslist,@targetlist,@modelist,$makeTarget);
our $fileexten="f";
our $ignoreflags=0;
#for l,f,g,and m switches
if ($swi >3) {
	if ($swi==4) {  #l
		@partslist =qw/lib pig mai/;
		@targetlist=(8,8,8);
		@modelist=(0,0,1);
		if (!@filenames) {
# Read ist of programs to load from options
			if (-e $optiondir."list_of_progs") {
				open (my $inh,  $optiondir."list_of_progs") or
				&errorExit("Can't read filenames from  ".$optiondir."list_of_progs");
	 			@filenames=grep{chomp;/./}readline($inh);
			} else {&errorExit ("List of programs to compile not found\n")}
		}
	} else {
		if (!@filenames) {&errorExit ("A filename or a list of names ".
		"must be given as the third argument for f, g, or m switches")}
		if ($swi==7) {  #m
			$makeTarget=shift(@filenames);
			@partslist=("mai");
			@targetlist=(15);
			@modelist=(3)
		}
		if ( scalar @filenames>1 && -e $filenames[0]) {
			open (my $inh, $filenames[0]) or &errorExit ("Can't read filenames from $filenames[0]");
			@filenames=();
			@filenames=grep{chomp} readline($inh);
		}
		@filenames=sort(@filenames);

		if ($swi<7) {
			@partslist=($part);
			@targetlist=(2);
			@modelist=(2);
			if ($swi==6) {$fileexten='got'}
		}
	}
} elsif  ($swi==3) {  #a
		@partslist=qw /pig lib/;
		@targetlist=(8,8);
		@modelist=(0,0);

} else {
	my $it=0;
	for (my $i=0;$i<=$swi;$i++) {
		$it+=1<<$i;
	}
	@partslist=($part);
	@modelist=(0);
	@targetlist=($it);
}

# Clear up leftovers
 	if (-e $badf) {&rmtree($badf); print "Deleting old bad directory\n"}
 	if (-e $errfile) {unlink($errfile)}
 	if (-e $complog) {unlink $complog}
#+-+-+-+-+-+-+-+-+-+-+-+-+FUNCTION REFERENCES FOR PROCEDURES+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
our @funcrefs=(\&extractit,\&splitit, \&compileit, \&archiveit, \&loadit);
#+-+-+-+-+-+-+-+-+-+-+-+-+ DO IT +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+--+-+-+-+-+-+-+-+-+-+-+-+-+-+-
#print "actions for $switch, $part, ".@filenames."\n";
my $np=scalar(@partslist);
if ($np != scalar(@targetlist)) {&errorExit ( "Program error unequal dimensions")}
my $it=1;
for (my $i = 0;$i<4;$i++) {
	for (my $ip = 0;$ip<$np;$ip++) {
		my $part=lc $partslist[$ip];
		my $mode=$modelist[$ip];
		my $OK =($targetlist[$ip] & $statflag{$part});
		$OK |= ($it > $targetlist[$ip] && $it & $statflag{$part});
		$OK |=($statflag{$part}&$it);
		my $j=$i;
		if ($mode==1 && $j==3){ $j=4}
if ($verbose) {
		print "Target ".$targetlist[$ip]." for $part mode $mode; testbit $it, statflag ".$statflag{$part};
		if ($OK) {print ": No action\n"} else { print ": do ".&sub_name($funcrefs[$j])."\n"}
	}
		unless($OK) {
if ($verbose) {
			printf 'It=%2d Function  %s \n',$it, &sub_name($funcrefs[$j]);
}
			if ($funcrefs[$j]->($part,$it,$mode)) {
				my $pp=$statflag{$part};
#				if ($mode !=2) {
					$statflag{$part}=$pp|$it ;
					if ($verbose) {print "Statflag{$part} set to ". $statflag{$part}."\n"}
#					}
			} else {&errorExit ("Error making target $part $it")}
		}
	}
	$it=$it<<1;
}
#exit(0);
# Clear up and finish;
	if (&dirIsEmpty($ccsldir."/temp")) {
		rmdir($ccsldir."/temp")}
# Record the status flags
	open my $flags, ">$flagfile" or &errorExit ("Can't write to $flagfile\n");
	print "Writing statflags\n";
	while((my $key, my $value) = each(%statflag)) {
		if (defined($statflag{$key})) {
# f and o files have been deleted
			if ($value&8) {$value&= ~6}
  			printf $flags "$key %4d\n", $value;
    		printf "$key %4d\n", $value;
    	}
	}
close $flags;
exit(0);
#}
#+-+-+-+-+-+-+-+-+-+-+-+-+-+ERROR EXIT-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
sub errorExit() {
	print "***ERROR*** ".$_[0]."\n";
	exit(256);
}
#
#
#*******************************************************************
#             THE SPECIAL FUNCTION SUBROUTINE DEFINITIONS
#+-+-+-+-+-+-+-+-+-+-+-+-+-+EXTRACT-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
sub extractit() {
#*******************************************************************
	my ($part,$target)=@_;
 	 my $command = "$perl/extract $part $options";
 	 print "Command: ".$command."\n";
 	 my $status= system ($command);
 	 if ($status!=0) { &errorExit( "Error extracting $part fortran file")}
 	 return 1;
}
#+-+-+-+-+-+-+-+-+-+-+-+-+-+-SPLIT-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
sub splitit() {
#*******************************************************************
	my $libname;
	my ($part,$target,$mode)=@_;
	if ($mode<2) {
		$libname=$ccsldir."/temp/".$part;
		# Empty the destination directory
		&rmtree($libname); &mkpath($libname,0,0775 );
	} else { $libname=$cwd}
	my $infile="$fsrc".lc $part."mk4.f";
	unless (-e $infile) { &errorExit("$infile does not exist".
 		 " must extract it with \"e\" switch\n")}
	&splitFile($part,$infile,$libname,$mode,@filenames);
	return 1;
}
#+-+-+-+-+-+-+-+-+-+-+-+-+-+-COMPILE+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
sub compileit() {
#*******************************************************************
	my ($part,$target,$mode)=@_;
	my $libname=$ccsldir."/temp/".$part;
	my ($ncomp,$nfail);
	($ncomp,$nfail)=&docompile($libname,$ftncommand);
	if ($nfail>0) {
		unless (-e $badf) {&mkpath($badf,0,0775) or &errorExit( "Can't create directory $badf\n")}
		opendir (my $dh,$libname) or  &errorExit("Can't open directory $libname");
		my @list=grep{/\.f$/} readdir($dh);
		foreach  my $f (@list) {move $f,$badf}
	}
	printf "$libname %3d complations were successful, %3d failed\n",$ncomp,$nfail;
  	chdir $cwd;
  	return ($nfail==0);
}
#+-+-+-+-+-+-+-+-+-+-+-+-+MAKE LIBRARY ARCHIVE+-+-+-+-+-+-+-+-+-+-+-
sub archiveit() {
#*******************************************************************
# Section to create a library archive <part>mk4.a
# Should not be called until both lib and pig have compiled successfully
#	my ($part,$target)=@_;
   	my @list=qw/lib pig/;
   	my( $status,$opart,$cmd);
   	unless (-e $libdest) {&mkpath($libdest,0,0775) }
	my $libr=lc "$libdest/libmk4.a";
	foreach $part (@list) {
#		next if( $statflag{$part}==7);
		my $libname=$ccsldir."/temp/".$part;
		(chdir $libname) or  &errorExit("Can't change directory to $libname\n");
# modules in piglib replace those in mk4lib with the same names
    	if ($part eq 'lib' ) {$cmd="ar -cr $libr *.o"} else {$cmd="ar -rs $libr *.o"}
    	my $status=system($cmd);
    	if ($status)  { &errorExit( "Attempt to archive $part returns $status")}
   		$statflag{$part}|=8;
   }
# ensure the status of both pig and lib are updated
 	foreach $part (@list) {
		my $libname=$ccsldir."/temp/".$part;
		(chdir $libname) or  &errorExit("Can't change directory to $libname\n");
 		opendir (my $dh,$libname) or  &errorExit("Can't open directory $libname");
		my @flist =(grep{/\.o$/;} readdir($dh));
		my $n=unlink(@flist);
  	}
  	return 1;
 }
#+-+-+-+-+-+-+-+-+-+-+-LOAD PROGRAMS +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
sub loadit() {
#+-+-+-+-+-+-+-+-+-+-+-+-+-+-COMPILE+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
# libmk4 should by now be up to date and the program files should have been split
# into temp/mai
	my ($part,$target,$mode)=@_;
		my $libname=$ccsldir."/temp/mai";
		my ($prog,$loadcmd);
		my $nfail=0;
 		unless (-e $xdest) {&mkpath($xdest,0,0775)};
 		chdir $libname or  &errorExit( "Can't change directory to $libname\n");
 	 	foreach $prog (@filenames) {
   			$loadcmd = "$ftncompiler $cswitches $prog.o";
   			$loadcmd .= " $libdest/libmk4.a ";
   			$loadcmd .= "$flibs -o $prog 2>>$errfile";
   	 		if ((my $status=system $loadcmd) !=0) {
    			print "Error loading $prog\n Command: $loadcmd,\n";
    			$nfail++;
    			unless (-e $badf) {
    				&mkpath($badf,0,0775) or  &errorExit( "Can't create directory $badf\n");
    			}
      			rename "$prog.f", "$badf/$prog.f";
   			} else {rename $prog, "$xdest/$prog";
   				unlink("$prog.o")}
			}
			chdir($cwd);
			&rmtree($libname);
			return ($nfail==0);
	}

#*******************************************************************
#                UTILITY SUBROUTINES FOLLOW
#*******************************************************************
sub setPath() {
# get a defined  path from options
my ($sorc,$opt);
my @list=@_;
foreach $opt (@list)  {
	$sorc=eval($opt);
	if ($sorc) {last}
	}
	return ($sorc);
}
#*******************************************************************
sub splitFile() {
#called with $part to split,
#            $infile
#            $libname destination for split modules
#			 $ mode = or -
#            $name for output file = required routine for mode get
	my ($part,$infile,$libname,$mode,@names)=@_;
	my ($glib,$rout,$skip,$pname,$write,$outhandle);
	my @buffer=(); $write=0;
#print ("SplitFile called  mode=$mode libname=$libname source:$infile files: ",@names,"\n");
	open  my $inhandle, $infile or  &errorExit( "can't open ".$infile);
	$skip=($part eq 'pig');
	if ($mode>0) {$pname=shift(@names)}
	# main reading loop looks for "C LEVEL"
LOOP: while (my $line = <$inhandle>) {
    		if ($line =~ /^C LEVEL/)  {
    			if ($write) {
    		    	doModule($outhandle,@buffer);
    				if ($mode==2) {
    					print "Module $libname/$rout.".$fileexten." extracted from $infile \n"}
    				close $outhandle; $write=0;
     				if ($mode>0) {
    					unless ($pname=shift @names) {
    						last LOOP;
    					}
    				}
   				}
			# check whether start of required plot library
				if ($line =~ /49/) {
			   		if ($line =~ /(pig\w{2})lib$/i && lc $1 eq $grafopts[0]) {
						$skip=0;
					} else { $skip=1}
						next;
				} else {
			 		unless ($skip) {
			 	  		$rout=lc routname($line);
			 	   		if ( $mode==0 || $rout eq $pname) {
#			 	   		print "starting write: $rout\n";
			 	   			$write=1;
			 	    		@buffer=$line;
			 				open $outhandle, ">$libname/$rout.".$fileexten or
			 				 &errorExit( "can't open $rout for write");
    						}
    					}
    				}
      			} elsif ($write) {push @buffer,$line}
      	}
    close $inhandle;
# Module not found
    if ($mode==2 && $pname) { &errorExit( "Module $pname not found in $part\n")}
# for trailing module
	if ($write) {
		doModule ($outhandle,@buffer);
		close $outhandle;
	}
    return;
}
#*******************************************************************
sub doModule() {
	my ($outhandle,@buffer)=@_;
	my $line;
	do {$line = pop(@buffer)}
	until($line =~ /^ *end *$/i);
	print $outhandle (@buffer,$line);
}
#*******************************************************************
sub docompile() {
	my ($dir,$ftncmd)=@_;
	my ($status,$file,$ncomp,$nfail,$fdir);
	$ncomp=0;$nfail=0;
	opendir ($fdir,$dir) or  &errorExit(  "Can't open directory $dir" );
	chdir($dir);
	while (defined($file=readdir($fdir))) {
		next if ($file =~ /^\./);
		next unless($file =~ /\.f$/);
  		system("echo  \"Command: $ftncmd $file\" >> $complog");
  		$status = system("$ftncommand $file >>  $complog 2>>$errfile" );
  		if (!$status) {
    		system ("echo  \"$file compiled\" >> $complog");
   		    unlink $file;
    		$ncomp++;
  		} else {
  			system("echo \"$file failed to compile,status = $status\" >>  $complog");
  			$nfail++;
  		}
  	}
  	return ($ncomp,$nfail);
}
#*******************************************************************
sub makepiglib() {
	my ($name,$inhandle)=@_;
#		close($outhandle);
#		$name.=&routname();
        $_=<$inhandle>;
        chomp;
		rmtree($name);
		mkpath($name,0,755);
		return $name;
}
#*******************************************************************
sub routname($) {
	$_=shift;
	unless (/\w* *(\w{1,6}) *\(/ || /\w* *(\w{1,6}) *$/)   #)
	{  &errorExit( "Error reading module name from:\n$_")}
	return $1
}
#*******************************************************************
sub readopts() {
	my @opts = ();
	my $bit="";
	my $fname = $_[0];
	if (-e $fname) {
		if (open INFILE, "$fname") {
	    	while (<INFILE>) {
  		  		chomp;
	      		s/#.*$//;     # remove comment
	      		s/^\s*\s*$//; #remove leading and trailing spaces
	      		$bit.=$_;
#	      		if (substr($_,-1,1) ne "\\") {
				if ($bit !~ s/\\$// && length($bit) >0) {
					$bit =~ s/ *$//;
	      			push @opts,$bit;
	      			$bit="";
	      		}
      		}
      	}
    }
	return @opts;
}

#*******************************************************************
sub dirIsEmpty {
	my $checkdir=shift;
    return 1  unless -d $checkdir;
    opendir my $dh, $checkdir or die $!;
    my @count= grep { ! /^\.{1,2}/ } readdir $dh; # strips out . and ..
    my $found=scalar(@count);
    my ($dir,$in);
    foreach $dir (@count) {
    	if(-d "$checkdir/$dir") {
    		opendir  $dh,"$checkdir/$dir" or  &errorExit( "Can't open directory $checkdir/$dir $!");
   			$in= grep { ! /^\.{1,2}/ } readdir $dh;
    		if ($in==0) {$found-=rmdir "$checkdir/$dir"} ;
      		} else {
     		print "$checkdir/$dir is not a directory\n"}

     	}
    return ($found==0);
}
#******************************************************************



