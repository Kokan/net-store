

.PHONY: all clean

all: main.pdf

main.pdf: main.tex ref.bib Makefile
	pdflatex --halt-on-error -shell-escape main
	biber main
	pdflatex --halt-on-error -shell-escape main
	pdflatex --halt-on-error -shell-escape main

view: main.pdf
	evince main.pdf

clean:
	rm -f main.aux
	rm -f main.out
	rm -f main.bcf
	rm -f main.log
	rm -f main.pdf
	rm -f main.run.xml
	rm -f main.bbl
	rm -f main.blg
	rm -rf _minted-main/

