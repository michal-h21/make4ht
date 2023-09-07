# Changelog

- 2023/09/07

  - fix spacing for the `dcases*` environment in the `mathml_fixes` DOM filter.

- 2023/08/24

  - support non-numerical values in index entry destinations (for example roman numerals).

- 2023/08/22

  - updated list of DOM filters used by the `common_domfilters` extension, and documented that it is used automatically in the HTML output.

- 2023/08/12

  - remove unnecessary `<a>` elements with `id` attributes and set the `id` on the parent.

- 2023/07/06

  - add prefix to section IDs if the section name is empty.

- 2023/06/20

  - added the `copy_images` extension.

- 2023/06/14

  - fixed bug in the `mathmlfixes` DOM filter -- non-empty last rows were
    removed if they contained only one element.

- 2023/05/26

  - load `tex4ht.sty` before input file processing starts.

- 2023/04/19

  - handle additional characters in the `idcolons` DOM filter.

- 2023/04/06

  - fixed handling of ID attributes in the `idcolons` DOM filter.

- 2023/03/07

  - remove empty rows in `longtable`.

- 2023/02/24

  - version `0.3k` released.

- 2023/01/09

  - fixed detection of image file names in `mkutils.parse_lg()`

- 2022/11/25

  - reverted change of index page numbers, it was buggy
  - test if the `.idx` file exists.

- 2022/11/24

  - `make4ht-indexing`: fixed handling of numbers in index entries text.

- 2022/11/01

  - remove empty last rows in MathML tables.

- 2022/10/21

  - added the `inlinecss` DOM filter and extension with the same name.

- 2022/09/29

  - the `join_characters` DOM filter now shouldn't produce extra `<span>` elements after white space.

- 2022/09/16

  - use the `no^` option to compile the `make4ht` HTML docs, to prevent clash with the Doc package.

- 2022/07/22

  - `mathmlfixes` DOM filter: 
    - don't change `<mo>` to `<mtext>` if the element contain the `stretchy` attribute.
    - add `<mtext>` to `<mstyle>` if it contains only plain text

- 2022/07/08

  - configure elements used in `join_characters` DOM filter.
  - added support for the `mml:` prefix in `mathml_fixes` DOM filter.

- 2022/06/28

  - handle `\maketitle` in JATS.

- 2022/06/24
  
  - handle internal and external links in the JATS output.
  - better detection of empty paragraphs.

- 2022/06/16

  - use DOM filters to fix JATS output.

- 2022/04/22

  - use more explicit options for `latexmk`.

- 2022/04/19

  - remove all `htlatex` calls from the build sequence when the `latexmk_build` extension is used.
  - fixed other issues that caused spurious executions of `latexmk`.

- 2022/04/01

  - don't copy files to the output dir if it wasn't requested
  - fixed copying of the ODT file to the output dir.

- 2022/03/29

  - check if tidy return non-empty string in the `tidy` extension.

- 2022/03/24

  - don't use totally random names in the `preprocess_input` extension, in order to support images correctly.

- 2022/03/22

  - version `0.3l` released.
  - fixed issues with filenames on Windows.

- 2022/03/01

  - use `rmarkdown` package to process `.rmd` files in the `preprocess_input`
    extension (thanks to James Clawson).

- 2022/02/18

  - version `0.3k` released.

- 2022/02/07

  - fixed support for some fonts in the ODT format.
  - added `odtfonts` DOM filter.

- 2022/01/30

  - fix `mathvariant` attribue of `<mi>` elements if they are children of `<mstyle>`.

- 2021/12/17

  - quote jobname in order to support filenames like `(xxx).tex`.

- 2021/12/13

  - fixed setting of properties in the `staticsite` filter.

- 2021/12/06

  - in the end, use `<mtext>` even for one `<mo>` in the `fix_operators` function. LO 
    had issues with `<mi>`. 

- 2021/12/03

  - don't add additional `<mrow>` elements in the `mathmlfixes` DOM filter. It caused 
    various issues.

- 2021/12/01

  - transform `<mn>x</mn><mo>.</mo><mn>x</mn>` to `<mn>x.x</mn>` in MathML.
  - transform `<mo>` elements that are single childs to `<mi>` in MathML, and
    list of consecutive `<mo>` elements to `<mtext>`. This should fix rendering
    issues of superscripts in LibreOffice.
  - added filter names in extensions to prevent multiple execution of filters.

- 2021/11/29
 
  - make current logging level available outside of the Logging module.
  - print Xtpipes and Tidy output if these command fail in the Xtpipes module.

- 2021/11/18

  - don't put `<mrow>` as children of `<mrow>` in the `mathmlfixes` DOM filter.

- 2021/11/04

  - more intelligent handling of text and inline elements outside of paragraphs
    in the `fixinlines` DOM filter.

- 2021/10/11

  - version `0.3j` released.

- 2021/10/09

  - fixed wrong DOM object name in the ODT format.
  - add addtional `<mrow>` elements when necessary.

- 2021/09/30

  - version `0.3i` released.

- 2021/09/21

    - run DOM parse in sandbox in the ODT format picture size function.

- 2021/09/20

    - remove LaTeX commands from TOC entries in `sectionid` DOM filter.

- 2021/09/09

    - corrected SVG dimension setting in the ODT output. Dimensions are set also for PNG and JPG pictures.

- 2021/09/05

    - corrected detection of closing brace in CSS style in `mjcli` filter.

- 2021/08/13

    - use LaTeX new hook mechanism to load `tex4ht.sty` before document class.
      It fixes some issues with packages required in classes.

- 2021/08/12

    - correctly set dimensions for `SVG` images in the `ODT` format.

- 2021/07/29

    - sort YAML header in the `staticsite` filter.

- 2021/07/25

    - version `0.3h` released.

- 2021/07/25

    - use current directory as default output dir in `staticsite` extension.

- 2021/07/23

    - fixed detection of single paragraphs inside `<li>` in the `itemparagraphs` DOM filter.

- 2021/07/18
 
    - remove elements produced by `\maketitle` in the `staticsite` extension.

- 2021/07/05

    - sort colors alphabetically in the `joincolors` DOM filter to enable reproducible builds.

- 2021/06/26

    - rewrote the `collapsetoc` DOM filter.

- 2021/06/20

    - test for the `svg` picture mode in the `tex4ht` command. Use the `-g.svg`
      option if it is detected. This is necessary for correct support of
      pictorial characters.

- 2021/06/16

    - better handling of duplicate ID attributes in `sectionid` DOM filter.
    - support `notoc` option in `sectionid`.

- 2021/06/13

    - added `itemparagraphs` DOM filter. It removes unnecessary paragraphs from `<li>` elements.

- 2021/05/06

    - remove `<hr>` elements in `.hline` rows in `tablerows` DOM filter.

- 2021/05/01

    - added function `mkutils.isModuleAvailable`. It checks if Lua library is available.
    - check for `char-def` library in `sectionid` DOM filter.

- 2021/04/08

    - removed `build_changed`. New script, [siterebuild](https://github.com/michal-h21/siterebuild), should be used instead.
    - new DOM filter, `sectionid`. It uses sanitized titles instead of automatically generated numbers as section IDs.
    - added `sectionid` to `common_domfilters`.
    - use `context` in the Docker file, because it contains the `char-def.lua` file.

- 2021/03/20

    - use `kpse` library when files are copied to the output directory.
    - added `clean` mode. It removes all generated, temporary and auxilary files.

- 2021/03/19 

    - version `0.3g` released.

- 2021/02/08

    - remove `<?xtpipes ?>` processing instructions from the generated ODT file.

- 2021/02/01

    - better error messages when extension cannot be loaded.
    - added `mjcli` extension.
    - `mjcli` filter supports \LaTeX\ syntax.
    - updated documentation.

- 2021/01/31

    - added new MathJax Node filter, `mjcli`.

- 2020/12/19

    - build web documentation only when documentation sources change.

- 2020/11/22

    - set exit status for the `make4ht` command.

- 2020/11/22

    - new extension, `build_changed`. 

- 2020/11/01

    - fix deprecated `<mfenced>` element in MathML 
    - convert `<mo fence>` elements to `<mfenced>` in `ODT` format.

- 2020/10/28

    - fixed handling of nested `<span>` elements in `joincharacters` DOM filter.

- 2020/10/25

    - fixed command name for `Make:httex`, it was `Make:htttex`.

- 2020/10/17

    - generate YAML header for all generated files with the `staticsite` extension.

- 2020/09/17

    - require `mathml` option when `mathjaxnode` extension is used.

- 2020/09/07

    - version `0.3f` released.

- 2020/08/26

    - `fixinlines` DOM filter: added `<a>` element into list of inline elements.

- 2020/08/24

    - initialize attributes in new element in `mathmlfixes` DOM extension.

- 2020/07/18

    - changed CSS for the HTML documentation.

- 2020/07/17

    - fixed bug in index parsing.

- 2020/07/10

    - use the `joincharacters` DOM filter for TEI output.

- 2020/07/08

    - don't fail when filename cannot be detected in `make4ht-errorlogparser.lua`.

- 2020/05/27

    - test if copied file exists in `mkutils.cp`.
    
- 2020/05/19

    - fixed image filename replace in `dvisvgm_hashes` extension.

- 2020/05/16

    - fixed HTML filename matching in extensions.

- 2020/05/08

    - use global environment in the build files.

- 2020/03/03

    - added `jats` format.

- 2020/02/28

    - version `0.3e released`.

- 2020/02/24

    - `t4htlinks` DOM filter: cleanup file names from internal links.
    - `make4ht-indexing`: added support for splitindex.

- 2020/02/19

    - use `UTF-8` output by default. `8-bit` output is broken and non fixable.

- 2020/02/07

    - use `lualatex-dev` instead of `harflatex`

- 2020/02/06

    - added support for `harflatex` and `harftex` in the `detect_engine` extension.

- 2020/01/22

    - version `0.3d` released.
    - added `Make:httex` command for Plain TeX support.
    - added `detect_engine` extension. It supports detection of the used engine
      and format from TeX Shop or TeXWorks magic comments. These comments can
      look like: `%!TEX TS-program = xelatex`.

- 2020/01/22

    - fixed support for multiple indices in `make4ht-indexing.lua`.

- 2019/12/29

    - use the `mathvariant="italic"` attribute for joined `<mi>` elements.
    - fixed comparison of element attributes in `joincharacters` DOM filter.

- 2019/12/28

    - print warning if the input file doesn't exist.

- 2019/12/17

    - added `booktabs` DOM filter.
    - load the `booktabs` in `common_domfilters` by default. 

- 2019/12/14

    - fixed bug in the `tablerows` DOM filter -- it could remove table rows if
      they contained only one column with elements that contained no text
      content.

- 2019/11/28

    - version `0.3c` released.
    - updated `mathmlfixes` DOM filter. It handles `<mstyle>` element inside token elements now.
    - use `mathmlfixes` and `joincharacters` DOM filters for math XML files in the ODT output.

- 2019/11/25

    - added `pythontex` command.
    - added `mathmlfixes` DOM filter.
    - use the `mathmlfixes` DOM filter in `common_domfilters` extension.

- 2019/11/22

    - `make4ht-joincharacters` dom filter: added support for the  `<mi>`
      element. Test all attributes for match when joining characters.
    - `html5` format: use the `common_domfilters` by default.

- 2019/11/03

    - version `0.3b`
    - use `make4ht-ext-` prefix for extensions to prevent filename clashes with corresponding filters.

- 2019/11/01

    - version `0.3a` released.
    - added `make4ht-` prefix to all extensions and formats
    - removed the unused `mathjaxnode.lua` file.

- 2019/11/01

    - version `0.3` released.
    - added `Make:makeindex`, `Make:xindex` and `Make:bibtex` commands.

- 2019/10/25

    - modified the `Make:xindy` command to use the indexing mechanism.

- 2019/10/24

    - added functions for preparing and cleaning of the index files in `make4ht-indexing.lua`.

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
 
