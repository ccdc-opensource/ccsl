#! /usr/bin/perl
# rearrange files over directories after htlatex
%dests=();
$base=$ARGV[0];
$target=$ARGV[1];
$texes="$base/texes";
$dests{tex}=x;
$dests{sty}=x;
$dests{cfg}=x;
$dests{xref}=x;
$dests{idx}=x;
$dests{aux}=x;
$dests{pdf}=x;
	$htdest = "$base/mk4man";
# read the xref file to prepare chapter links
	$xfile="$texes/$target.xref";
	@chaplinks=prepare_links($xfile);
	printf "%20s %20s\n"x scalar(@chaplinks/2),@chaplinks;
#	exit(0);
# html files to mk4man
if ($target eq CCSLman) {
# xref file to appenx
#	$nfile="manual.xref";
#	rename ($xfile, "$base/appenx/$nfile");
}
	elsif ($target eq appene){$htdest = "$base/appenx";
}
	elsif ($target eq ffacts){
		$htdest = "$base/html";
		$texes="$base/texes";
}
$dests{html}=$htdest;
$dests{css}=$htdest;
# png files to mk4man
$dests{png}=$htdest;
# check that htdest exists and make it if not
unless (-e "$htdest" && -d  "$htdest") {
	unless (mkdir("$htdest",0755)) {
	die "Error $! creating directory  $htdest"}
}
unless (-e "$base/appenx" && -d  "$base/appenx") {
	unless (mkdir("$base/appenx",0755)) {
	die "Error $! creating directory  $base/appenx"}
}
opendir TEXES, $texes or die "Can't open tex directory $texes";
@filelist= readdir( TEXES);
foreach $file (@filelist) {
	$done=0;
	$i=rindex($file,".");
	next if ($i<=0);
	$ext=substr($file,$i+1);
	print $ext,"  ",$dests{$ext},"   ",$file,"\n";
	if (!defined($dests{$ext})) {
		$i=unlink ("$texes/$file");
		print "$texes/$file deleted  $i\n";
	} elsif ($dests{$ext}eq "x") {
		print "$base/$file left alone \n";
		next
	} else {
		if ($ext eq "html") {$done=checklinks($file,@chaplinks)}
		if (!$done) {
			$nfile=$file;
			$i=rename ("$texes/$file",  $dests{$ext}."/$nfile");
			print "$file refiled in ",$dests{$ext},"\n"
		}
	}
}

sub prepare_links() {
	my (@first,@second,@links,$i,$num,$xfile);
	$xfile=shift;
	open XREF, "$xfile" or die "can't open xref file $xfile";
	$swi=0;
	while (<XREF>) {
		if (s/^\\:CrossWord\{\)B//) {
			s/($target\w{0,5}.html)\(//;
			push @first, $1;
			s/($target\w{0,5}.html)//;
			push @second,$1
		}
	}
	close XREF;
	$num=scalar(@first);
	for ($i=0;$i<$num-1;$i++) {
		if ($new=$first[$i] eq $second[$i+1]) {
			push @links, ($first[$i-1], $first[$i+1]);
		}
	}
	return @links;
}
sub checklinks() {
	my ($file,@links,@lines,@rlines,$line,$num,$i,$j,$hfile,$nfile);
	my @button=qw/Next Prev/;
	my @phrase = ("</tr></table>","<table cellspacing=\"5\"><tr>");
	$file=shift;
	$hfile="$texes/$file";
	@links=@_;
# add NEXT and PREV links
	$num=scalar(@links);
	for ($i=0;$i<$num;$i+=2) {
		for ($j=0;$j<2;$j++) {
#		print "Comparing $file with ",$links[$i+$j],"\n";
			if ($file eq $links[$i+$j]) {
				$addtext ="<td class=\"clinks\"><a \n".
				"href=\"".$links[$i+1-$j]."\" >$button[$j]</a></td>";
				$nfile="$htdest/$file";
				open HTML, $hfile  or die "Can't open html file $file";
				print "$hfile opened to add to navigation bar\n";
# read the whole file into @lines
				@lines=reverse <HTML>;
				close HTML;
# Search for the navigation bars
				$top=0;
				SEARCH:	foreach $line (@lines) {
					if ($line =~ m|$phrase[$j]|) {
						if ($j==0) {$line =~s|$phrase[$j]|$addtext $phrase[$j]|;
						} else { $line =~s|$phrase[$j]|$phrase[$j] $addtext |}
						last;
					}
				}
				unless($top) {
					@lines=reverse(@lines);
					$top=1;
					goto SEARCH;
				}
				open NEW, ">$nfile"  or die "Can't open new html file $nfile";
				print NEW @lines;
				close NEW;
				unlink $hfile;
				print "$nfile closed after adding to $pos[$j] navigation bar\n";
				return 1;
			}
		}
	}
	return 0;
}
