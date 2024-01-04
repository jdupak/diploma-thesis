thesis.pdf: src/* template/* Makefile
	cd src && pandoc *.md -o ../build/thesis.pdf \
	 --from markdown+smart -s \
	 --pdf-engine=tectonic \
	 --pdf-engine-opt=--chatter=minimal \
	 --toc \
	 --bibliography=bibliography.bib \
	 --csl=../template/ieee.csl --citeproc \
	 --highlight-style=monochrome \
	 -V documentclass=report -V links-as-notes
