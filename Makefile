thesis.pdf: src/* template/* Makefile
	pandoc src/*.md -o build/thesis.pdf \
	 --from markdown+smart \
	 --pdf-engine=tectonic \
	 --toc \
	 --bibliography=src/bibliography.bib \
	 --csl=template/ieee.csl --citeproc \
	 --highlight-style=monochrome \
	 --abbreviations=abbr.md \
	 --data-dir=src \
	 -V documentclass=report -V links-as-notes
