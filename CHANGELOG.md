# Changelog

- 2019/10/23

    - replaced `os.execute` function with `mkutils.execute`. It uses the logging mechanism for the output.
    - finished transforming of filters, extensions and formats to the logging system.

- 2019/10/22

    - added `tablerows` domfilter.
    - added the `tablerows` domfilter to the `common_domfilters` extension.
    - converted most of the filters to use the logging mechanism.

- 2019/10/20

    - added `status` log level.

- 2019/10/18

    - converted most print commands to use the logging mechanism.
    - added `output` log level used for printing of the commands output.

- 2019/10/17

    - added `--loglevel` CLI parameter.
    - added logging mechanism.
    - moved `htlatex` related code to `make4ht-htlatex.lua` from `mkutils.lua`

- 2019/10/11

    - added `xindy` settings.
    - added simple regular expression to detect errors in the log file, because log parsing can be slow.

- 2019/10/09

    - added the `interaction` parameter for the `htlatex` command. The default
      value is `batchmode` to suppress the user input on errors, and to
      suppress  full log output to the terminal.
    - added the `make4ht-errorlogparser` module. It is used to parse errors in
      the `htlatex` run unless `interaction` is set to `errorstopmode`.

- 2019/10/08

    - set up Github Actions pipeline to compile the documentation to HTML and publish it at https://www.kodymirus.cz/make4ht/make4ht-doc.html.

- 2019/10/07

    - don't move the `common_domfilters` extension to the first place in the
      file matches pipeline. We may want to run `tidy` or regex filters first,
      to fix XML validation errors.

- 2019/10/04

    - added HTML documentation.

- 2019/09/27

    - don't convert Latin 1 entities to Unicode in the `entities_to_unicode` extension.

- 2019/09/20

    - fixed bugs in the temporary directory handling for the ODT output.

- 2019/09/13

    - added `preprocess_input` extension. It enables compilation of formats
      supported by [Knitr](https://yihui.name/knitr/) (`.Rnw`, `.Rtex`, `.Rmd`, `.Rrst`) 
      and also Markdown and reStructuredText formats.

- 2019/09/12

    - added support for the ODT files in `common_domfilters` extension.
    - renamed `charclases` option for the `joincharacters` DOM filter to `charclasses`.
    - don't execute the `fixentities` filter before Xtpipes, it makes no sense.

- 2019/09/11

    - added support for Biber in the build files.

- 2019/08/28

    - added support for input from `stdin`.

- 2019/08/27

    - fixed `-jobname` detection regex.
    - added function `handle_jobname`.
    - added the `--jobname` command line option.

- 2019/08/26

    - quote file names and paths in `xtpipes` and `tidy` invocation.

- 2019/08/25

    - the issue tracker link in the help message is now configurable.
    - fixed bug in the XeTeX handling: the `.xdv` argument for `tex4ht` wasn't
      used if command line arguments for `tex4ht` were present.

- 2019/07/03

    - new DOM filter: `odtpartable`. It fixes tables nested in paragraphs in the ODT format.

- 2019/06/13

    - new DOM extension: `collapsetoc`.

- 2019/05/29

    - new module: `make4ht-indexing` for working  with index files.

- 2019/05/24

    - version 0.2g released
    - fixed failing `dvisvgm_hashes` extension on Windows.

- 2019/05/02

    - fixed infinite loop bug in the `dvisvgm_hashes` extension.

- 2019/04/09

    - `make4ht-joincolors` fix: remove the hash character from the color name.
      This caused issues with colors specified in the hexadecimal format.

- 2019/04/02

    - `dvisvgm_hashes` fix:  update also the lgfile.images table with generated filenames, in order to support tex4ebook

- 2019/04/01
  
    - fixed bug in `dvisvgm_hashes` extension: didn't check for table index existence in string concenation

- 2019/03/21

    - version 0.2f released 

- 2019/03/15

    - check for the image dimensions existence in the `odtimagesize` domfilter.

- 2019/03/13

    - don't use `odtimagesize` domfilter in the `ODT` format, the issue it fixes had been resolved in `tex4ht`.

- 2019/03/08

    - use `%USERPROFILE` for home dir search on Windows.

- 2019/01/28

    - added `joincolors` domfilter and `join_colors` extension. It can join CSS rules created for the LaTeX colors and update the HTML file.

- 2019/01/22

    - version 0.2e released
    - updated the `odttemplate` filter. It will use styles from the generated ODT file that haven't been present in the template file.

- 2019/01/10

    - version 0.2d released

- 2019/01/05

    - added `docbook` and `tei` output formats.

- 2018/12/19

    - new library: `make4ht-xtpipes.lua`. It contains code for xtpipes handling.
    - moved Xtpipes handling code from `formats/odt.lua`.

- 2018/12/18

    - new filter: `odttemplate`. It can be used for replacing style in a generated `ODT` file by a style from another existing `ODT` file.
    - new extension: `odttemplate`. Companioning extension for filter with the same name.
    - fixed bug in `make4ht-filters.lua`: the parameters table haven't been passed to filters.

- 2018/12/17

    - fixed extension handling. The disabling from the command line didn't take
      precedence over extensions enabled in the config file. Extensions also
      could be executed multiple times.

- 2018/11/08

    - removed replacing newlines by blank strings in the `joincharacters` domfilter. The issue it fixed doesn't seem to exist anymore, and it ate spaces sometimes.

- 2018/11/01

    - added `t4htlinks` domfilter
    - fixed the `xtpipes` and `filters` execution order in the `ODT` format

- 2018/10/26

    - fixed ODT generation for files that contains special characters for Lua string patterns
    - replace non-breaking spaces with entities. It caused issues in LO 

- 2018/10/18

    - fixed the executable installation

- 2018/09/16

    - added the `scale` option for `dvisvgm_hashes` extension

- 2018/09/14

    - require the `-dvi` option with `latexmk_build` extension

- 2018/09/12

    - added `xindy` command for the build file

- 2018/09/03

    - expanded the `--help` option

- 2018/08/27

    - added `odtimagesize` domfilter
    - load `odtimagesize` by default in the ODT format

- 2018/08/23

    - released version 0.2c

- 2018/08/21

    - added processor core detection on Windows
    - make processor number configurable
    - updated the documentation.

- 2018/08/20

    - added `dvisvgm_hashes` extension

- 2018/07/03

    - create the `mimetype` file to achieve the ODT file validity

- 2018/07/02

    - disabled conversion of XML entities for &, < and > characters back to Unicode, because it breaks XML validity

- 2018/06/27

    - fixed root dir detection

- 2018/06/26

    - added code for detection of TeX distribution root for Miktex and TL

- 2018/06/25

    - moved call to `xtpipes` from `t4ht` to the `ODT` format drives. This should fix issues with path expansion in `tex4ht.env` in TeX distributions.

- 2018/06/22

    - added `mkutils.find_zip` function. It detects `zip` or `miktex-zip` executables

- 2018/06/19

    - added new filter: `entities-to-unicode`. It converts XML entites for Unicode characters back to Unicode.
    - execute `entities-to-unicode` filter on text and math files in the ODT output.

- 2018/06/12

    - added support for direct `ODT` file packing

- 2018/06/11

    - new function available for formats, `format.modify_build`
    - function `mkutils.delete_dir` for directory removal
    - function `mkutils.mv` for file moving
    - started on packing of the `ODT` files directly by the format, instead of `t4ht`

- 2018/06/08

    - added support for filenames containing spaces
    - added support for filenames containing non-ascii characters
    - don't require sudo for the installation, let the user to install symbolic links to `$PATH`

- 2018/05/03

    - released version `0.2b`
    - bug fix: use only `load` function in `Make:run`, in order to support a local environment.

- 2018/05/03

    - released version `0.2a`
    - renamed `latexmk` extension to `latexmk_build`, due to clash in TL

- 2018/04/18

    - `staticsite` extension:
      - make YAML header configurable
      - set the `time` and `updated` headers
    - don't override existing tables in `filter_settings`

- 2018/04/17

    - done first version of `staticsite` extension

- 2018/04/16

    - check for Git repo in the Makefile, don't run Git commands outside of repo

- 2018/04/15

    - added `staticsite` filter
    - working on `staticsite` extension

- 2018/04/13

    - use `ipairs` instead of `pairs` to traverse lists of images and image match functions
    - load extensions in the correct order

- 2018/04/09

    - released version `0.2`
    - disabled default loading of `common_domfilters` extension
    

- 2018/04/06

    - added `Make:enable_extension` and `Make:disable_extension` functions
    - documented the configuration file

- 2018/03/09

    - load the configuration file before extensions

- 2018/03/02

    - Aeneas execution works
    - Aeneas documentation
    - added support for `.make4ht` configuration file

- 2018/02/28

    - Aeneas configuration file creation works

- 2018/02/22

    - fixed bug in `fixinlines` DOM filter

- 2018/02/21

    - added Aeneas domfilter
    - fixed bugs in `joincharacters` DOM filter

- 2018/02/20

    - fixed bug in `joincharacters` DOM filter
    - make `woff` default font format for `mathjaxnode`
    - added documentation for `mathjaxnode` settings

- 2018/02/19

    - fixed bug in filter loading
    - added `mathjaxnode` extension

- 2018/02/15

    - use HTML5 as a default format
    - use `common_domfilters` implicitly for the XHTML and HTML5 formats

- 2018/02/12

    - added `common_domfilters` extension
    - documented DOM filters

- 2018/02/12

    - handle XML parsing errors in the DOM handler
    - enable extension loading in Formatters

- 2018/02/11

    - fixed Tidy extension output to support LuaXML
    - fixed white space issues with `joincharacters` DOM filter
 
- 2018/02/09

    - fixed issues with the Mathjax filter
    - documented basic info about thd DOM filters
    - DOM filter optimalizations

- 2018/02/08

    - make Tidy extension configurable
    - documented filter settings

- 2018/02/07

    - added filter for Mathjax-node

- 2018/02/06

    - created DOM filter function
    - added DOM filter for spurious inlinine elements

- 2018/02/03

    - added settings handling functions
    - settings made available for extensions and filters

- 2017/12/08

    - fixed the `mk4` build file loading when it is placed in the current working dir and another one with same filename somewhere in the TEXMF tree.

- 2017/11/10

    - Added new filter: `svg-height`. It tries to fix height of some of the images produced by `dvisvgm`

- 2017/10/06

    - Added support for output format selection. Supported formats are `xhtml`, `html5` and `odt`
    - Added support for extensions

- 2017/09/10

    - Added support for Latexmk
    - Added support of `math` library and `tonumber` function in the build files

- 2017/09/04

    - fixed bug caused by the previous change -- the --help and --version didn't work

- 2017/08/22

    - fixed the command line option parsing for `tex4ht`, `t4ht` and `latex` commands
    - various grammar and factual fixes in the documentation

- 2017/04/26

    - Released version `v0.1c`

- 2017/03/16

    - check for `TeX capacity exceeded` error in the \LaTeX\ run.

- 2016/12/19

    - use full input name in `tex_file` variable. This should enable use of files without `.tex` extension.

- 2016/10/22

    - new command available in the build file: `Make:add_file(filename)`. This enables filters and commands to register files to the output.
    - use ipairs instead of pairs for traversing files and executing filters. This should ensure correct order of executions.

- 2016/10/18

    - new filter: replace colons in `id` and `href` attributes with underscores

- 2016/01/11

    - fixed bug in loading documents with full path specified

- 2015/12/06 version 0.1b

    - modifed lapp library to recognize `--version` and 
    - added `--help` and `--version` command line options

- 2015/11/30

    - use `kpse` library for build file locating

- 2015/11/17

    - better `-jobname` handling

- 2015/09/23 version 0.1a

    - various documentation updates
   - `mozhtf` profile for unicode output is used, this should prevent ligatures in the output files

- 2015/06/29 version 0.1

    - major README file update


- 2015/06/26

    - added Makefile
    - moved INSTALL instructions from README to INSTALL
 
