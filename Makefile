PDF_ENGINE=tectonic
CITATION_FLAGS=--bibliography=bibliography.bib --csl=../template/iso690-numeric-en.csl --citeproc
STYLE_FLAGS=--highlight-style=monochrome --number-sections
DOC_FLAGS=-V documentclass=report -V links-as-notes --top-level-division=chapter
FILTERS=--filter pandoc-crossref
METADATA=--metadata-file=../template/settings.yml

OPTIONS= --from markdown+smart -s --pdf-engine=$(PDF_ENGINE) $(METADATA) $(STYLE_FLAGS) $(DOC_FLAGS) $(FILTERS) $(CITATION_FLAGS)

DEPS=$(wildcard src/*.md) template/* Makefile

thesis.pdf: $(DEPS)
	cd src && pandoc *.md -o ../build/thesis.pdf $(OPTIONS)

thesis.tex: $(DEPS)
	cd src && pandoc *.md -o ../build/thesis.tex $(OPTIONS)

thesis.docx: $(DEPS)
	cd src && pandoc *.md -o ../build/thesis.docx $(OPTIONS)
