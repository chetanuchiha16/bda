# =============================================================================
# LaTeX Reports Makefile
# Group 17: Chetan Kishor C G & Hongiran D
# =============================================================================

PDFLATEX := pdflatex -interaction=nonstopmode

.PHONY: all assignment1 assignment2 clean

all: assignment1 assignment2

assignment1: assignment1_report.pdf

assignment2: assignment2_report.pdf

assignment1_report.pdf: assignment1_report.tex
	$(PDFLATEX) assignment1_report.tex
	$(PDFLATEX) assignment1_report.tex

assignment2_report.pdf: assignment2_report.tex
	$(PDFLATEX) assignment2_report.tex
	$(PDFLATEX) assignment2_report.tex

clean:
	rm -f *.aux *.log *.out *.toc *.synctex.gz *.fls *.fdb_latexmk
