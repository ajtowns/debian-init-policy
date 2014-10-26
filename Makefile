#include debian/rules

all: init-policy.txt init-policy.html/index.html init-policy.pdf

init-policy.sgml: version.ent

%.txt: %.org
	$(EMACS) --batch -Q -l ./README-css.el -l org -l org-ascii --visit $^ \
          --funcall org-export-as-ascii >/dev/null 2>&1
	test "$@" != "README.txt"  ||                            \
           perl -pli -e 's,./Process.org,Process.txt,g' $@
%.html: %.org
	$(EMACS) --batch -Q -l ./README-css.el -l org --visit $^ \
          --funcall org-export-as-html-batch >/dev/null 2>&1

%.validate: %
	nsgmls -wall -gues $<

%.html/index.html: %.sgml
	LANG=C debiandoc2html $<

%-1.html: %.sgml
	LANG=C debiandoc2html -1 -b $*-1d $< && \
        mv $*-1d.html/index.html $*-1.html && \
        rmdir $*-1d.html

%.html.tar.gz: %.html/index.html
	tar -czf $(<:/index.html=.tar.gz) $(<:/index.html=)

%.txt: %.sgml
	LANG=C debiandoc2text $<

%.txt.gz: %.txt
	gzip -cf9 $< > $@

%.ps: %.sgml
	LANG=C debiandoc2latexps $<

%.ps.gz: %.ps
	gzip -cf9 $< > $@

%.pdf: %.sgml
	LANG=C debiandoc2latexpdf $<

%.pdf.gz: %.pdf
	gzip -cf9 $< > $@

# This is a temporary hack to fold the upgrading-checklist into the Policy
# HTML directory so that it can be deployed alongside Policy on
# www.debian.org in a way that lets the cross-document links work properly.
# The correct solution is to make upgrading-checklist an appendix of Policy,
# which will probably be done as part of a general conversion to DocBook.
policy.html.tar.gz:: policy.html/upgrading-checklist.html
policy.html/upgrading-checklist.html: upgrading-checklist-1.html \
				      policy.html/index.html
	cp -p $< $@

# convenience aliases :)
html: policy.html/index.html
html-1: policy-1.html
txt text: policy.txt
ps: policy.ps
pdf: policy.pdf
policy: html txt ps pdf

leavealone :=	$(FHS_HTML) $(FHS_FILES) $(FHS_ARCHIVE) \
		libc6-migration.txt
	      
.PHONY: distclean
distclean:
	rm -rf $(filter-out $(leavealone),$(wildcard *.html))
	rm -f $(filter-out $(leavealone),$(wildcard *.txt *.txt.gz *.html.tar.gz *.pdf *.ps))
	rm -f *.lout* lout.li *.sasp* *.tex *.aux *.toc *.idx *.log *.out *.dvi *.tpt
	rm -f `find . -name "*~" -o -name "*.bak" -o -name ".#*" -o -name core`
	rm -f version.ent
	rm -f *.rej *.orig

# if a rule bombs out, delete the target
.DELETE_ON_ERROR:
# no default suffixes work here, don't waste time on them
.SUFFIXES: 
