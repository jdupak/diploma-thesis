PDF_ENGINE=tectonic


thesis.pdf: src/* template/* Makefile
	cd src && pandoc *.md -o ../build/thesis.pdf \
	 --from markdown+smart -s \
	 --pdf-engine=$(PDF_ENGINE) \
	 --number-sections \
	 --filter pandoc-crossref \
	 --bibliography=bibliography.bib \
	 --csl=../template/ieee.csl --citeproc \
	 --highlight-style=monochrome \
	 -V documentclass=report -V links-as-notes
