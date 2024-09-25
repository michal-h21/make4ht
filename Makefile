.PHONY: build tags
lua_content = make4ht $(wildcard *.lua) 
filters = $(wildcard filters/*.lua)
domfilters = $(wildcard domfilters/*.lua)
extensions = $(wildcard extensions/*.lua)
formats = $(wildcard formats/*.lua)
tex_content = $(wildcard *.tex)
doc_root = make4ht-doc
doc_tex = $(doc_root).tex
doc_file = $(doc_root).pdf
htmldoc = $(HTML_DOC_DIR)/$(doc_root).html
doc_sources = $(doc_tex) readme.tex changelog.tex tags

TEXMFHOME = $(shell kpsewhich -var-value=TEXMFHOME)
INSTALL_DIR = $(TEXMFHOME)/scripts/lua/make4ht
MANUAL_DIR = $(TEXMFHOME)/doc/latex/make4ht
FILTERS_DIR = $(INSTALL_DIR)/filters
DOMFILTERS_DIR = $(INSTALL_DIR)/domfilters
FORMATS_DIR = $(INSTALL_DIR)/formats
EXTENSION_DIR = $(INSTALL_DIR)/extensions
BIN_DIR = /usr/local/bin
# expand the bin directory
SYSTEM_DIR = $(realpath $(BIN_DIR))
EXECUTABLE = $(SYSTEM_DIR)/make4ht
BUILD_DIR = build
BUILD_MAKE4HT = $(BUILD_DIR)/make4ht
HTML_DOC_DIR = htmldoc
VERSION:= undefined
DATE:= undefined

ifeq ($(strip $(shell git rev-parse --is-inside-work-tree 2>/dev/null)),true)
	VERSION:= $(shell git --no-pager describe --abbrev=0 --tags --always )
	DATE:= $(firstword $(shell git --no-pager show --date=short --format="%ad" --name-only))
endif

# use sudo for install to destination directory outise home
ifeq ($(findstring home,$(SYSTEM_DIR)),home)
	SUDO:=
else
	SUDO:=sudo
endif

# install the executable only if the symlink doesn't exist yet
ifeq ("$(wildcard $(EXECUTABLE))","")
	INSTALL_COMMAND:=$(SUDO) ln -s $(INSTALL_DIR)/make4ht $(EXECUTABLE)
else
	INSTALL_COMMAND:=
endif

all: doc

tags:
ifeq ($(strip $(shell git rev-parse --is-inside-work-tree 2>/dev/null)),true)
	git fetch --tags
endif 

doc: chardef $(doc_file) readme.tex 

htmldoc: chardef ${htmldoc}
 
make4ht-doc.pdf: $(doc_sources)
	latexmk -pdf -pdflatex='lualatex "\def\version{${VERSION}}\def\gitdate{${DATE}}\input{%S}"' make4ht-doc.tex

$(htmldoc): $(doc_sources)
	make4ht -ulm draft -c config.cfg -f html5+tidy+common_domfilters+latexmk_build -d ${HTML_DOC_DIR} ${doc_tex} "no^" "" "" "\"\def\version{${VERSION}}\def\gitdate{${DATE}}\""

readme.tex: README.md
	pandoc -f markdown+definition_lists -t LaTeX README.md > readme.tex

changelog.tex: CHANGELOG.md
	pandoc -f markdown+definition_lists -t LaTeX CHANGELOG.md > changelog.tex

build: chardef doc $(lua_content) $(filters) $(domfilters)
	@rm -rf build
	@mkdir -p $(BUILD_MAKE4HT)
	@mkdir -p $(BUILD_MAKE4HT)/filters
	@mkdir -p $(BUILD_MAKE4HT)/domfilters
	@mkdir -p $(BUILD_MAKE4HT)/extensions
	@mkdir -p $(BUILD_MAKE4HT)/formats
	@cp $(lua_content) $(tex_content)  make4ht-doc.pdf $(BUILD_MAKE4HT)
	@cat make4ht | sed -e "s/{{version}}/${VERSION}/" >  $(BUILD_MAKE4HT)/make4ht
	@cp $(filters) $(BUILD_MAKE4HT)/filters
	@cp $(domfilters) $(BUILD_MAKE4HT)/domfilters
	@cp $(formats)  $(BUILD_MAKE4HT)/formats
	@cp $(extensions)  $(BUILD_MAKE4HT)/extensions
	@cp README.md $(BUILD_MAKE4HT)/README
	@cd $(BUILD_DIR) && zip -r make4ht.zip make4ht

install: chardef doc $(lua_content) $(filters) $(domfilters) justinstall 
	cp  $(doc_file) $(MANUAL_DIR)

justinstall: chardef
	mkdir -p $(INSTALL_DIR)
	mkdir -p $(MANUAL_DIR)
	mkdir -p $(FILTERS_DIR)
	mkdir -p $(DOMFILTERS_DIR)
	mkdir -p $(FORMATS_DIR)
	mkdir -p $(EXTENSION_DIR)
	cp $(lua_content) $(INSTALL_DIR)
	@cat make4ht | sed -e "s/{{version}}/${VERSION}/" >  $(INSTALL_DIR)/make4ht
	cp $(filters) $(FILTERS_DIR)
	cp $(domfilters) $(DOMFILTERS_DIR)
	cp $(extensions) $(EXTENSION_DIR)
	cp $(formats)  $(FORMATS_DIR)
	chmod +x $(INSTALL_DIR)/make4ht
	echo $(wildcard $(EXECUTABLE))
	$(INSTALL_COMMAND)

chardef:
	texlua tools/make_chardata.lua > make4ht-char-def.lua

version:
	echo $(VERSION), $(DATE)

.PHONY: test
test:
	texlua test/test-mkparams.lua

