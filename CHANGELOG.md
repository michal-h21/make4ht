# Changelog

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
 
