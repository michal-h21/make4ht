# Changelog

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
 
