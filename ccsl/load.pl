#! /usr/bin/perl
#******************************************************************
#*our ($ftncommand,$ftmcompiler,$cswitches,$flibs)=&readopts("$optiondir/f77_choices");
#******************************************************************
# Select FORTRAN options
our ($prog,@plist)=@ARGV;
# Directory containing choices for site dependent options
unless (our $optiondir = $ENV{CCSL_OPT}) {$optiondir = "$ccsldir/options"}
our ($ftncommand,$ftncompiler,$cswitches,$flibs)=&readopts("$optiondir/f77_choices");
our $ccsldir=$ENV{CCSL};
if ($plist) {
	our ($pfiles,$lfiles)=inpig(@plist);
	print "In libpig.a\n";
	foreach $_ (@$pfiles) {print"$_ \n"};
	print "Not in libpig.a\n";
	foreach $_ (@$lfiles) {print"$_ \n"};
}
 	my $subs=""; my $flag = 0;
 	my $pscript=$ENV{CCSL_PERL}."/ccsl";
  	open  my $mfh,">Makefile" or die "Can't open new Makefile ";
	print $mfh "FFLAGS =$cswitches\n";
 	print $mfh "FC= $ftncompiler\nCCSLPL=$pscript\n";
 	print $mfh "SRC=",$ENV{CCSL_SRC}."\n";
 	print $mfh "LIBA=".$ENV{CCSL_LIB}."libmk4.a\n";
 	if ($plist) {
		if (scalar(@{$lfiles})) {
			print $mfh "PREQ = ";
	 		foreach my $r (@{$lfiles}) {print $mfh $r.".f "}; print $mfh "\n";
			print $mfh "ftno=\$(PREQ:.f=.o)\n#\n";
			$subs.="\$(ftno)"; $flag|=1;
 		}
			if (scalar(@{$pfiles})) {
			print $mfh "PREQP= ";
	 		foreach my $r (@{$pfiles}) {print $mfh $r.".f "}; print $mfh "\n";
			print $mfh "ftnpo= \$(PREQP:.f=.o)\n#\n";
			$subs.=" \$(ftnpo)";$flag|=2
 		}
 	}
	print $mfh "$prog : $prog.o  \$(LIBA) $subs \n";
 	print $mfh "\t \$(FC) -o $prog ".$prog.".o $subs  \$(LIBA)\n#\n";
# makefile rules
	print $mfh "$prog.f : \$(SRC)/maimk4.f ;\t\$(CCSLPL) -f mai $prog\n#\n";
	if ($flag & 1) {print $mfh "\$(ftno) : \$(PREQ)\n#\n";
 		print $mfh "\$(PREQ): \$(SRC)/maimk4.f\n";
 		print $mfh "\t\$(CCSLPL) -f lib \$*\n#\n";
 	}
	if ($flag & 2) {print $mfh "\$(ftnpo) : \$(PREQP)\n#\n";
 		print $mfh "\$(PREQP):\$(SRC)/pigmk4.f\n";
 		print $mfh "\t\$(CCSLPL) -f pig \$*\n#\n";
 	}
 	print $mfh "\$(LIBA)  :  \$(SRC)/pigmk4.f \$(SRC)libmk4.f\n\t\$(CCSLP)  -a lib\n#\n";
   	close $mfh;

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
#******************************************************************
sub inpig($@) {
# Find which routines in the list are in pigmk4.f
	my @alphorder=sort{uc($a) cmp uc(b)} @_;
	my $infile=$ccsldir."/source/pigmk4.f";
	my @pigl=();my @libl=();
	open  my $inhandle, $infile or die "can't open ".$infile;
	$rname=shift(@alphorder);
	while (<$inhandle>) {
    	next unless (/^C LEVEL/);
    	my $rout=lc (routname($_));
	COMP:   my $comp=($rout cmp lc($rname));
    	next if ($comp< 0);
    	if ($comp ==0) {push @pigl,$rname}
    	if ($comp >0) {push @libl,$rname}
    	$rname=shift(@alphorder);
    	if ($rname) {goto COMP}
    	last;
	}
	push @libl,@alphaorder;
	return (\@pigl,\@libl);
}

#*******************************************************************
sub routname($) {
	$_=shift;
	unless (/\w* *(\w{1,6}) *\(/ || /\w* *(\w{1,6}) *$/)   #)
	{ die "Error reading module name from:\n$_"}
	return $1
}
#*******************************************************************
