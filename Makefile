lua_content = make4ht $(wildcard *.lua)
doc_file = make4ht-doc.pdf
TEXMFHOME = $(shell kpsewhich -var-value=TEXMFHOME)
INSTALL_DIR = $(TEXMFHOME)/scripts/lua/make4ht
MANUAL_DIR = $(TEXMFHOME)/doc/latex/make4ht

all: doc

doc: $(doc_file) readme.tex

make4ht-doc.pdf: make4ht-doc.tex readme.tex changelog.tex
	latexmk -lualatex make4ht-doc.tex

readme.tex: README.md
	pandoc -f markdown+definition_lists -t LaTeX README.md > readme.tex

changelog.tex: CHANGELOG.md
	pandoc -f markdown+definition_lists -t LaTeX CHANGELOG.md > changelog.tex

build: doc $(lua_content)
	@rm -rf build
	@mkdir build
	@zip build/make4ht.zip $(lua_content)  README.md make4ht-doc.pdf

install: doc $(lua_content)
	mkdir -p $(INSTALL_DIR)
	mkdir -p $(MANUAL_DIR)
	cp $(lua_content) $(INSTALL_DIR)
	cp $(doc_file) $(MANUAL_DIR)

