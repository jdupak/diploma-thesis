thesis.pdf: thesis.md src/*.md bibliography.bib iso690-numeric-en.csl Makefile template/front.tex
	pandoc thesis.md src/* -o thesis.pdf \
	 --from markdown+smart \
	 --pdf-engine=tectonic \
	 --toc \
	 --bibliography=bibliography.bib \
	 --csl=ieee.csl --citeproc \
	 --highlight-style=monochrome \
	 --abbreviations=abbr.md \
	 --data-dir=. \
	 -V documentclass=report -V links-as-notes
