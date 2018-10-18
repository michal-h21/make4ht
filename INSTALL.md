Installation
------------

If you use TeX Live 2015 or up-to date Miktex distributions, `make4ht` should be installed already on your system. 
You need to install it only if you use older distribution or try new features which aren't accessible in the version
included in the distributions.

## Prerequisites  

You need a teX distribution such as TeX Live or Miktex. It must include `tex4ht` system and `texlua` script. All modern
distributions include it. You also need [Pandoc](http://pandoc.org/) in order to make the documentation and 
`latexmk`, which should be included in your TeX distro.

## Unix systems

Run these commands:

     make
     make install

`make4ht` is installed to `/usr/local/bin` directory by default. The
directory can be changed by passing it's location to the `BIN_DIR` variable:

    make install BIN_DIR=~/.local/bin/

## Windows

See a [guide by Volker Gottwald](https://d800fotos.wordpress.com/2015/01/19/create-e-books-from-latex-tex-files-ebook-aus-latex-tex-dateien-erstellen/) on how
to install `make4ht` and `tex4ebook`. 

Create a batch file for `make4ht` somewhere in the `path`:

    texlua "C:\full\path\to\make4ht" %*

you can find directories in the path with 

    path

command, or you can create new directory and [add it to the path](http://stackoverflow.com/questions/9546324/adding-directory-to-path-environment-variable-in-windows).

Note for `Miktex` users: you may need to create `texmf` directory first. See 
[this answer on TeX.sx](http://tex.stackexchange.com/questions/69483/create-a-local-texmf-tree-in-miktex).


## Troubleshooting

### Missing support for LuaLaTeX in `latexmk`

If you get the following error message:

    latexmk -lualatex make4ht-doc.tex
    Latexmk: -lualatex bad option
    Latexmk: Bad options specified
    Use
      latexmk -help
    to get usage information
    make: *** [make4ht-doc.pdf] Error 10

then you have old version of `latexmk`. Try to replace line:

    latexmk -lualatex make4ht-doc.tex
    
in the `Makefile` with

    lualatex make4ht-doc.tex
    lualatex make4ht-doc.tex
    
`latexmk` takes care of correct number of compilations needed to produce the correct document.

### Need to update TeX database

If you get following error message:

    /usr/local/bin/make4ht:5: module 'make4ht-lib' not found:
    no field package.preload['make4ht-lib']
    [kpse lua searcher] file not found: 'make4ht-lib'
    [kpse C searcher] file not found: 'make4ht-lib'

then try to run command 

    texhash
    
this will update the TeX file database and newly installed files should be usable.
