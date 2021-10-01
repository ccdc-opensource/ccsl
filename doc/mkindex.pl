#! /usr/bin/perl

# A procedure to make the indices for Appendices A, D to the
# CCSL manual
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
  local (%classcodes) = ("A"=>"Setting Up","B"=>"Crystallographic",
                        "C"=>"Utility");
  local (%appendices) = (qw/lib A mai D/);
  local (%classes) = ();
  local (%header) = ();
  local (%pageno) = ();
  local (%programs) = ();
  local (@list) = ();
  local (@clist) = ();
  my ($listlevel) = 0;
  my ($initlet) = ".";
  unless($TEXES_DIR = $ENV{$TEXES_DIR}) {
  	$TEXES_DIR = $ENV{CCSL_DOC};
  	if ($TEXES_DIR) {$TEXES_DIR.="/texes"}
  }
  else {$TEXES_DIR = "texes"}
  @parts = @ARGV;
  foreach  (@parts) {
    $part = lc ;
    $main = ($part eq "mai");
    open CLASSOUT, ">$TEXES_DIR/$part"."classlist.tex" or die;
    open ALFOUT, ">$TEXES_DIR/$part"."alphalist.tex" or die;
    $infile = "$TEXES_DIR/".$part."apx.idx";
# Open the index file made by LaTeX
   open INFILE, $infile or die "Can't open $infile";
   while (<INFILE>) {
   s/\|hyperpage//;
m/\{\{([A-Z]\w{1,5})\}\{([0-9]{0,2}[A-D]*)\}\{(.*?)\}\{(.*?)\}\}\{([0-9]{1,3})\}/;
	if ($1 eq "") {
		print "Module name missing in indexentry\n";
		next;
	}
	@message=();
	if ($2 eq "") {push @message,"Class marker"}
    $classes{$1} = $2;
	if ($3 eq "") {push @message,"Full name"}
     $fullname{$1} = $3;
	if ($4 eq "") {push @message,"Header"}
     $header{$1} = $4;
     $pageno{$1} = $5;
     $temp= $1;
# Check that all parameters were found
	if (scalar(@message) >0) {
		foreach $par (@message) {print "$par, "}
		print "missing in indexentry for $1\n";
		next;
	}
     if ($main) {
       if ($3 =~ /PROGRAM/i){
         $prog = $temp;
         $slist = $prog."_subr";
         @$slist = ();
         push @clist, $temp;
         $programs{$prog} = $prog
       } else {
         push @$slist, $temp;
         $programs{$temp} = $prog
       }
     }
     push @list, $temp;
     print "@list/n/n";
   }
# sort in alpha order
   @slist = sort @list;
   foreach $routine (@slist) {
     if ($initlet ne substr($routine,0,1)) {
       $initlet = substr($routine,0,1);
       if ($listlevel)  {
         print ALFOUT "\\end{alfalist}";
       }
       $listlevel = 1;
       print ALFOUT "\\begin{alfalist}{$initlet}\n";
     }
     $prog = $programs{$routine} if ($main);
     if ($main && $prog ne $routine) {
     $temp = $fullname{$routine};
     $temp =~ s/$routine.*//i;
      print ALFOUT "\\listitem[$routine]{",$temp,"used by ",$fullname{$prog},
      "}{",$pageno{$routine},"}{",$appendices{$part},"}\n";
      } else {
        print ALFOUT "\\listitem[$routine]{",$fullname{$routine},
        "}{",$pageno{$routine},"}{",$appendices{$part},"}";
        if ($temp =$header{$routine}) {print ALFOUT "\\\\\n$temp,\n" }
          else {print ALFOUT "\n"};
      }
   }
   print ALFOUT "\\end{alfalist}";
#
# sort in class order
   if ($main) {@slist = sort orderclass @clist}
   else {@slist = sort orderclass @list}
   $listlevel = 0;
   $newtype =0;
   $oldclass = 0;
   foreach $routine (@slist) {
     $classwrd = $classes{$routine};
     if ($classwrd ne $oldclass) {
     $oldclass = $classwrd;
     $classwrd =~ /([0-9]{1,2})([A-D])/;
     if (!$main) {
       $type = $2 if ($newtype = ($2 ne $type));
     }
     if ($1 ne $cat) {
        $cat = $1;
        if ($listlevel ==2) {
          print CLASSOUT "\\end{typeslist}\n";
          $listlevel--;
        }
        if ($listlevel ==1) {
          print CLASSOUT "\\end{catslist}\n";
          $listlevel--;
        }
        print CLASSOUT "\\begin{catslist}{$1}{",
        $categories[$1-1],"}\n";
        $newtype = 2;
        $listlevel = 1;
      }
      if ($newtype) {
        if ($listlevel == 2) {
          print CLASSOUT "\\end{typeslist}\n";
          $listlevel--;
        }
        if (!$main) {
          print CLASSOUT "\\begin{typeslist}{$2}{",$classcodes{$2},"}\n";
          $listlevel = 2;
        }
      }
    }
 $lcroutine= lc($routine); $ucroutine=uc($routine);
 if ($part eq "mai") {$target=$lcroutine}
 else {$target=$ucroutine}
# links for manual
    print CLASSOUT "\\ifthenelse{\\boolean{ccslman}}\n";
    print CLASSOUT "{\\listitem{\\hypertarget{$target}{",$fullname{$routine};
    print CLASSOUT  "}}{",$pageno{$routine},"}{",$appendices{$part},"}}\n";
#links for appendices
	$fullname{$routine}=~/(^.*?)$routine(.*$)/;
    print CLASSOUT "{\\listitem{",$1,"\\hyperlink{",$lcroutine,"}{",$routine,"}",$2,
    "}{",$pageno{$routine},"}{",$appendices{$part},"}}\n";
#
    if ($temp =$header{$routine}) {print CLASSOUT "\\\\\n$temp \n" }
	 else {print CLASSOUT "\n"}
    if ($main) {
      $slist = $routine."_subr";
      if (scalar (@$slist)) {
        print CLASSOUT "\\begin{subrlist}\n";
        @alist = sort @$slist;
        foreach $name (@alist) {
          print CLASSOUT "\\listitem{",$fullname{$name},"}{",
          $pageno{$name},"}{",$appendices{$part},"}";
          if ($temp =$header{$name}) {print CLASSOUT "\\\\\n$temp,\n" }
          else {print CLASSOUT "\n"};
        }
        print CLASSOUT "\\end{subrlist}\n";
      }
    }
  }
  print CLASSOUT "\\end{typeslist}\n" unless $main;
  print CLASSOUT "\\end{catslist}\n";
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
