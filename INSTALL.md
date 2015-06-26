Installation
------------

## Unix systems

Run these commands:

     make
     sudo make install

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
