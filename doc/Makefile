all:	manual-ru.pdf

clean:
	rm -f *.aux *.log *.out *.toc mp-manual-ru.tex

mp-manual-ru.tex: manual-ru.md
	multimarkdown manual-ru.md -t latex -o mp-manual-ru.tex

manual-ru.pdf: manual-ru.tex mp-manual-ru.tex
	xelatex manual-ru.tex
	xelatex manual-ru.tex
	xelatex manual-ru.tex
