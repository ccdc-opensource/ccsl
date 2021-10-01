# To make  Mk4 manual and appendices

PERLB  = $(CCSL_PERL)
PERLD  = $(CCSL_DOC)/perl
SRC = $(CCSL_SRC)
OPT = $(CCSL_OPT)
BASE= $(CCSL_DOC)
TEXDIR = $(BASE)/texes/
MAN = $(BASE)/mk4man
MANU = CCSLman
APP =  $(BASE)/appenx
PDF = $(BASE)/pdf
TEXES=  $(TEXDIR)/chap1.tex $(TEXDIR)/chap2.tex $(TEXDIR)/chap3.tex \
     	$(TEXDIR)/chap4.tex $(TEXDIR)/chap5.tex $(TEXDIR)/chap6.tex \
     	$(TEXDIR)/chap7.tex \
		$(TEXDIR)/maiclasslist.tex $(TEXDIR)/libclasslist.tex \
        $(TEXDIR)/maialphalist.tex $(TEXDIR)/libalphalist.tex
FFACTS = $(BASE)/ffacts
FFACTT = $(BASE)/ffacts/texes
FFACTH = $(BASE)/ffacts/html
#
export TARGET

 all :  $(MAN)/$(MANU).html $(APP)/appendix.html $(APP)/appene.html \
		$(PDF)/$(MANU).pdf $(PDF)/appendixA.pdf  \
        	$(PDF)/appendixC.pdf $(PDF)/appendixD.pdf $(PDF)/appendixE.pdf
allpdf :	$(PDF)/$(MANU).pdf $(PDF)/appendixA.pdf \
        	$(PDF)/appendixC.pdf $(PDF)/appendixD.pdf $(PDF)/appendixE.pdf
allhtml :  $(MAN)/$(MANU).html $(APP)/appendix.html $(APP)/appene.html
appendix :  $(APP)/appendix.html $(APP)/appene.html
ffacts : $(FFACTH)/ffacts.html
appene :  $(APP)/appene.html

# This section makes the manual
$(MAN)/$(MANU).html : $(TEXDIR)/$(MANU).html
		$(PERLD)/refile_html $(BASE) CCSLman > refile.out
$(TEXDIR)/$(MANU).html : $(TEXDIR)/$(MANU).tex $(TEXDIR)/versiondate.tex \
	 maiindex.out libindex.out
		cd $(TEXDIR); htlatex $(MANU) "ccsl,3" > manualop.log
$(TEXDIR)/$(MANU).xref : $(TEXDIR)/$(MANU).tex
		cd $(TEXDIR); htlatex $(MANU) "ccsl,3" > manualop.log
#To ensure the version is correct
$(TEXDIR)/versiondate.tex: $(CCSL_SRC)/libmk4.f $(CCSL_SRC)/maimk4.f \
$(PERLD)/orfeus
		$(PERLD)/orfeus mistre.ss both lib mai com > orfeus.out
#Section to prepare the classlists and appendices A,C,D
libindex.out	:	$(TEXDIR)/libapx.tex $(SRC)/libmk4.f
	 cd $(TEXDIR); pdflatex libapx.tex >libapxpdf.log
		$(PERLD)/mkindex lib > libindex.out
	 cd $(TEXDIR); pdflatex libapx.tex >libapxpdf.log
	 cd $(TEXDIR); pdflatex libapx.tex >libapxpdf.log
#$(TEXDIR)libapx.pdf	: $(TEXDIR)libapx.tex $(TEXDIR)libapx.aux \
#$(TEXDIR)libapx.out libindex.out
#	 cd $(TEXDIR); pdflatex libapx.tex >libapxpdf.log
$(TEXDIR)libapx.out	: $(TEXDIR)libapx.tex $(TEXDIR)libapx.aux \
libindex.out
	 cd $(TEXDIR); pdflatex libapx.tex >libapxpdf.log
maiindex.out	:	$(TEXDIR)/maiapx.tex $(SRC)/libmk4.f
	 	cd $(TEXDIR); pdflatex maiapx.tex >maiapxpdf.log
			$(PERLD)/mkindex mai > maiindex.out
	 	cd $(TEXDIR); pdflatex maiapx.tex >maiapxpdf.log
##
$(TEXDIR)/libapx.tex  :	$(SRC)libmk4.f
		$(PERLD)/orfeus mistre.ss both lib mai com >orfeus.out
		$(PERLD)/mkindex mai > maiindex.out
$(PDF)/appendixC.pdf  :  $(TEXDIR)/appenc.tex $(TEXDIR)/appenc.aux \
$(TEXDIR)/appenc.out
	 cd $(TEXDIR); pdflatex appenc > appencop.log
	 mkdir -p $(PDF) ; mv -f $(TEXDIR)/appenc.pdf $(PDF)/appendixC.pdf
$(TEXDIR)/appenc.aux  :  $(TEXDIR)/appenc.tex
	 cd $(TEXDIR); pdflatex appenc > appencop.log
$(TEXDIR)/appenc.out  :  $(TEXDIR)/appenc.tex
	 cd $(TEXDIR); pdflatex appenc > appencop.log
$(APP)/appendix.htm :  $(SRC)/libmk4.f $(SRC)/maimk4.f
	$(PERLD)/orfeus mistre.ss htlm lib mai com> orfeus.out
$(APP)/appendix.html : $(APP)/appendix.htm $(TEXDIR)/$(MANU).xref
	$(PERLD)/doc3labels >doc3labels.out
##
#Section to finalize pdf files
$(PDF)/$(MANU).pdf  : $(TEXDIR)/$(MANU).pdf $(TEXDIR/$(MANU).aux \
 maiindex.out libindex.out
	 mkdir -p $(PDF) ; mv -f $(TEXDIR)/$(MANU).pdf $(PDF)
$(TEXDIR)/$(MANU).pdf : $(TEXDIR)/$(MANU).tex  $(TEXES) $(TEXDIR)/$(MANU).aux \
$(TEXES) $(TEXDIR)/$(MANU).out maiindex.out libindex.out
		cd $(TEXDIR); pdflatex  $(MANU) > ccslmanop.log
$(TEXDIR)/$(MANU).aux  :  $(TEXDIR)/$(MANU).tex
	 cd $(TEXDIR); pdflatex $(MANU) > ccslmanop.log
$(TEXDIR)/$(MANU).out  :  $(TEXDIR)/$(MANU).tex
	 cd $(TEXDIR); pdflatex $(MANU) > ccslmanop.log
$(PDF)/appendixA.pdf  : $(TEXDIR)libapx.pdf
	 	mkdir -p $(PDF) ; mv -f $(TEXDIR)/libapx.pdf $(PDF)/appendixA.pdf
$(PDF)/appendixD.pdf   :  $(TEXDIR)maiapx.pdf
		 mkdir -p $(PDF) ; mv -f $(TEXDIR)/maiapx.pdf $(PDF)/appendixD.pdf
##
# To update the fortran library from the mistress file
$(SRC)/libmk4.f : $(SRC)/mistre.ss
	$(PERLB)/ccsl -e lib
##
# To update the main program data from the mistress file
$(SRC)/maimk4.f : $(SRC)/mistre.ss
	$(PERLB)/ccsl -e mai
##
#This section makes appendix E
$(APP)/appene.html : $(TEXDIR)/appene.tex
		cd $(TEXDIR); htlatex appene "ccsl,3" > appeneop.log
		$(PERLD)/refile_html $(BASE) appene > refile_appe.out
$(PDF)/appendixE.pdf  : $(TEXDIR)/appene.pdf
	 mkdir -p $(PDF) ; mv -f $(TEXDIR)/appene.pdf $(PDF)/appendixE.pdf
$(TEXDIR)/appene.pdf   : $(TEXDIR)/appene.tex $(TEXDIR)/appene.aux \
$(TEXDIR)/appene.out
	 cd $(TEXDIR);  pdflatex appene > appeneop.log
$(TEXDIR)/appene.aux  : $(TEXDIR)/appene.tex
	 cd $(TEXDIR); pdflatex appene appeneop.log
$(TEXDIR)/appene.out : $(TEXDIR)/appene.tex
	 cd $(TEXDIR); pdflatex appene appeneop.log


# This section prepares the form factor data
$(FFACTH)/ffacts.html : $(FFACTT)/ffacts.tex $(FFACTT)/fftable.tex
		cd $(FFACTT); htlatex ffacts "$(TEXDIR)/ccsl,3"
		$(PERLD)/refile_html $(FFACTS) ffacts > refile_ffacts.out

# targets tidy and clean remove all intermediate files, leaving html png and pdf
TEMPS = $(TEXDIR)/*.aux  $(TEXDIR)/*.log $(TEXDIR)/*.toc  $(TEXDIR)/*.out \
	$(TEXDIR)/*.idx $(BASE)/*.log $(BASE)/*.out

.PHONY:  tidy
tidy:
	rm -f $(TEMPS)

.PHONY: clean
clean:
	rm -f  $(TEMPS)  $(TEXDIR)/lib*.tex  $(TEXDIR)/mai*.tex $(TEXDIR)/sympars.tex \

 #Clear removes all generated documentation files
 .PHONY: clear
 clear:
	rm -f $(TEMPS)  $(TEXDIR)/mai*.tex $(TEXDIR)/lib*.tex \
	 $(TEXDIR)/appenc.tex  $(TEXDIR)/sympars.tex $(TEXDIR)/versiondate.tex \
	rm -rf $(MAN)/*
	rm -rf $(APP)/*
	rm -rf $(PDF)/*

