#! /usr/bin/perl
#Script to run tests on CCSL programs
use Scalar::Util qw(looks_like_number);
$newlist = $ARGV[0];
$ncyc=0;
# Read environment variables
unless ($testdata=$ENV{T}) {
	unless ($testdata=$ENV{CCSL_TESTD}) {
		print  "Give path to testdata: ";
		$testdata=<STDIN>;
		chomp ($testdata);
		if ($testdata =~ s!^\$(\w{1,})/!!) {
			$testdata=$ENV{$1}."/$testdata";
		}
	}
	$ENV{T}=$testdata;
}
    $wdir=$ENV{PWD};
if ($newlist) {$listfile=$newlist}
else {$listfile=$testdata."/test_list"}
open LIST,$listfile  or die "Can't open $listfile";
while (<LIST>) {
	last if ($numprog && $ncyc>=$numprog);
	($lprog,$cry,$resp,@out)=split;
	next unless ($cry);
#Directory or simple program name
	$p=rindex($lprog,"/");
	if ($p>=0) {$prog=substr($lprog,$p+1)}
	else {$prog=$lprog}
	next if ($next && $next ne $prog) ;
	$next=0;
	$statusp+=$status;
	$lprog =~ s/_([pgl]{1,2})//;
	if ($prog ne $oprog) {
#	if ($statusp) {push @badlist,"$oprog using $cry"}
		printf "*" x 12 ."\n** %6s **\n",$prog;
		$statusp=0;
	}
	$oprog=$prog;
	$tdir=$testdata."/$lprog";
	$ENV{TT} = $tdir;
	if ($resp) {
		$cmd="$prog < $tdir/$resp >> test.log";
		print "Command: $cmd\n";
	} else {
		open RESP, ">r" or die "Can't open r to write";
		print RESP $tdir,"/",$cry,"\n";
		close RESP;
		$cmd="$prog < r >> test.log";
	}
	$prog =~ s/_([pgl]{1,2})//;
# Remove possible existing listing or output files
	if (-e "$prog.lis") {unlink "$prog.lis"}
	foreach $out (@out) {if (-e $out) {unlink $out}}
	if (system $cmd) {
		print "Error while testing command $cmd\n";
		 push @badlist,"$prog using $cry";
		next;
	}
# Check for differences in output
	$lisfile= $tdir."/".$prog."_".$cry.".lis";
	$cmd = "diff -ba $prog.lis $lisfile	 > difs";
	$status=(system $cmd)/256;
	if ($status==2) {
		print "Error doing diff command: $cmd\n";
		$status=1;
		goto END;
	}
	if ($status==1) {$dif="difs";$status=checkdifs($dif,$prog,$cry)}
	if ($status) {
		print
		"$status Significant differences in listing file from $prog with $cry\n";
		rename "$prog.lis",$prog."_".$cry.".lis";
	}  else {unlink "$prog.lis"}
# Check other data output
	foreach $out (@out) {
		if ($out =~ /\.ps$/ || $out =~ /\.eps$/) {
#Don't bother with .ps or .eps files
 				unlink "$out";
 				next;
 #			}
 		} else { $theout=$out}
 		if ($out !~ /$cry/) {
 		    $i=index($out,".");
 		    if ($i<0) {
 				$out.="_".$cry;
 			} else {
 				$out= substr($out,0,$i)."_".$cry.substr($out,$i);
 			}
 		}
		$outfile= $tdir."/".$out;
		$cmd = "diff -bB $theout $outfile	 > difs";
		$statusd=(system $cmd)/256;
		if ($statusd==2) {
			print "Error doing diff command: $cmd\n";
		} else {
			$dif="difs";
			$statusd=checkdifs($dif,$out,$cry);
			if ($statusd) {
				print "$statusd Significant differences in output file $out from $prog",
				 " with $cry\n";
				 if ($out ne $theout) {rename $theout, $out}
			} else {unlink $theout}
		}
# remove ps and eps	files created
		$status+=$statusd;
	}
END:
	opendir WDIR , "$wdir"	or die "Can't open $tdir";
	@files=grep {/^$prog.*ps$/} readdir(WDIR);
	foreach $f (@files) {
		print "$f\n";
		unlink "$f";
	}
	closedir WDIR;
	if ($status==0)	{print "Test of $prog with $cry was successful\n"}
	else { push @badlist,"$prog using $cry";}

	$ncyc++;
}
print "\n","+-" x 25 ,"\n";
$first=1;
if (scalar(@badlist)) {
	foreach $prog (@badlist) {
		if ($first) {
			print "Possible problems with:  $prog\n" ;
			$first=0;
		} else {
			print " " x 25, "$prog\n";
		}
	}
} else { print "No problems were found\n"}
print "+-" x 25 ,"\n";


sub checkdifs() {
	my ($indif,$code,$ndifs,$line,@pars,@new,@old);
	my ($dif,$prog,$cry)=@_;
#
	open DIFFS, "$dif" or die "Can't open file $dif";
	open my $outh,">temp" or die "Can't open $ofile";
	$indif=0;
	$ndifs=0;
	while (<DIFFS>) {
		if (/^\d{1,}/) {
		# line begins with digit (line number)
			$code=$_;
			if ($indif) {
				if ($line=docheck($outh,@pars,@new,@old))	{$ndifs++}
				@new=();
				@old=();
			}
# $code gives the difference code  (eg 525,526c525,526)
			@pars=parse($code);
			$indif=1;
		} elsif ($indif) {
			if (s/^<//) {push @new,$_}
			if (s/^>//) {push @old,$_}
		}
	}
	close DIFFS;
	unlink $dif;
	if ($ndifs) {
		if ($prog !~ /$cry/) {
			rename "temp",$prog."_".$cry.".sigDifs";
		} else {
			rename "temp",$prog.".sigDifs";
		}
	}
	close $outh;
	if ($ndifs ==0) {unlink "temp"; print "No Differences\n"}
	return $ndifs;
}

sub parse() {
# splits up the diffs code line
	my @a=();
	my ($b,$c);
	$_=shift;
	s/([acd])/|/; $b=$1;
	s/^(\d{1,})// ; $a[0]=$1;$a[1]=1;
	if (s/^,//) {s/^(\d{1,})// ; $a[1]+=$1-$a[0]}
	s/^\|(\d{1,})// ; $c=$1;$a[2]=1;
	if (s/^,//) {s/^(\d{1,})// ; $a[2]+=$1-$c}
	return ($b,@a);
}
sub docheck() {
	my @skips = ("Job run","does not exist","opened","saved",
	"Read from","Cambridge Crystallography","Observations read from");
	my ($acode,$lno,$nnew,$nold,@nlines,@olines,$old,$eline,$i);
	my ($outh,$acode,$lno,$nnew,$nold)=splice(@_,0,5);
	if ($acode eq "a") {@nlines=splice(@_,0,$nold)}
	else {@nlines=splice(@_,0,$nnew)}
	if ($acode eq "c") {@olines=splice(@_,0,$nold)}
	$eline=-1;
LINE:for ($i=0;$i<$nnew;$i++) {
		next unless ($nlines[$i]=~/\w/);
		foreach $skip (@skips) {next LINE if ($nlines[$i]=~/$skip/)}
		if ($acode eq "c") {
			$old=shift(@olines);
			next LINE if (compsig($nlines[$i],$old)==0);
		}
		$eline=$i;
		last;
	}
	if ($eline<0) {return 0}
	$lno+=$eline;
	if ($acode eq "d"){
		print  $outh "Extra lines in New at line $lno\n";
		print  $outh "New ",$nlines[$eline];
	} elsif ($acode eq "a") {
		print  $outh "Missing lines in New at line $lno\n";
		print  $outh "Old ",$nlines[$eline];
	}else {
		print  $outh "Files differ at line: $lno\n";
		print  $outh "New ",$nlines[$eline];
		print  $outh "Old ",$old;
	}
}



sub compsig() {
	my ($old,$new,$valn,$valo,$dif,$sum);
	my (@old,@new,$acc,$np);
	($new,$old)=@_;
	if (isdate($old)) {return 0}
	$_=$old; @old=split	;
	$_=$new; @new=split	;
	if (scalar(@old)!=scalar(@new)) {return 1}
	foreach $valo (@old) {
		$valn=shift(@new);
		next if ($valo eq $valn);
		if (&looks_like_number($valo)&& &looks_like_number($valn)) {
			$sum=abs($valo+$valn);
			next if ($sum < 10e-5);
			$dif=abs($valo-$valn);
			next if ($dif < 10e-5);
			next if ($dif/$sum<10e-4);
			if (length($dif) >4) {
# Check fir unit difference in last char (rounding?)
			  	$dif =~ s/[0\.]*//;
			  	next if ($dif eq 1);
			}
		}
#		print "Mismatch at $valo $valn\n";
		return 1;
	}
	return 0;
}

sub isdate() {
	my @weekdays = (qw/Mon Tue Wed Thu Fri Sat Sun/);
	my @months = (qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/);
	$_=shift;
	foreach $day (@weekdays) {
		if (/$day/)  {
			foreach $month (@months) {
				if (/$month/) {return 1}
			}
			last;
		}
	}
	return 0;
}


#

