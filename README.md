% [![Build Status](https://travis-ci.org/michal-h21/make4ht.svg?branch=master)](https://travis-ci.org/michal-h21/make4ht)

# Introduction

`make4ht` is a build system for \TeX4ht, \TeX\ to XML converter. It provides a command line tool
that drives the conversion process. It also provides a library that can be used to create
customized conversion tools. An example of such a tool is
[tex4ebook](https://github.com/michal-h21/tex4ebook), a tool for conversion from \TeX\ to
ePub and other e-book formats.


The basic conversion from \LaTeX\ to `HTML` using `make4ht` can be executed using the following command:

    $ make4ht filename.tex

It will produce a file named `filename.html` if the compilation goes without fatal errors.


# Command line options {#clioptions}
\label{sec:clioptions}

    make4ht - build system for TeX4ht
    Usage:
    make4ht [options] filename ["tex4ht.sty op." "tex4ht op." 
         "t4ht op" "latex op"]
    -a,--loglevel (default status) Set log level.
                possible values: debug, info, status, warning, error, fatal
    -b,--backend (default tex4ht) Backend used for xml generation.
         possible values: tex4ht or lua4ht
    -c,--config (default xhtml) Custom config file
    -d,--output-dir (default "")  Output directory
    -e,--build-file (default nil)  If build filename is different 
         than `filename`.mk4
    -f,--format  (default nil)  Output file format
    -j,--jobname (default nil)  Set the jobname
    -l,--lua  Use lualatex for document compilation
    -m,--mode (default default) Switch which can be used in the makefile
    -n,--no-tex4ht  Disable DVI file processing with tex4ht command
    -s,--shell-escape Enables running external programs from LaTeX
    -u,--utf8  For output documents in utf8 encoding
    -x,--xetex Use xelatex for document compilation
    -v,--version  Print version number
    <filename> (string) Input filename


It is still possible to invoke `make4ht` in the same way as is invoked `htlatex`:

    $ make4ht filename "customcfg, charset=utf-8" "-cunihtf -utf8" "-dfoo"

Note that this will not use `make4ht` routines for the output directory handling. 
See section \ref{sec:output-dir} for more information about this issue.
To use these routines, change the previous listing to:

    $ make4ht -d foo filename "customcfg, charset=utf-8" "-cunihtf -utf8"

This call has the same effect as the following:

    $ make4ht -u -c customcfg -d foo filename


Output directory doesn't have to exist, it will be created automatically. 
Specified path can be relative to the current directory, or absolute:

    $ make4ht -d use/current/dir/ filename
    $ make4ht -d ../gotoparrentdir filename
    $ make4ht -d ~/gotohomedir filename
    $ make4ht -d c:\documents\windowspathsareworkingtoo filename

The short options that don't take parameters can be collapsed:


    $ make4ht -ulc customcfg -d foo filename


To pass output from the other commands to `make4ht` use the `-` character as a
filename. It is best to use this feature together with the `--jobname` or `-j`
option.

    $ cat hello.tex | make4ht -j world -

By default, `make4ht` tries to be quiet, so it hides most of the command line
messages and the output from the executed commands. It will display only status
messages, warnings and errors. The logging level can be selected using the
`--loglevel` or `-a` options. If the compilation fails, it may be useful to display more 
information using the `info` or `debug` levels. 


    $ make4ht -a debug faulty.tex



# Why `make4ht`? -- `htlatex` issues


\TeX4ht\ system supports several output formats, most notably `XHTML`, `HTML 5`
and `ODT`, but it also supports `TEI` or `Docbook`.

The conversion can be invoked using several scripts, which are distributed with \TeX4ht.
They differ in parameters passed to the underlying commands.

These scripts invoke \LaTeX\ or Plain \TeX\ with special instructions to load
the `tex4ht.sty` package. The \TeX\ run produces a special `DVI` file 
that contains the code for the desired output format. The produced `DVI` file
is then processed using the `tex4ht` command, which in conjunction with the
`t4ht` command produces the desired output files.

## Passing command line arguments

The basic conversion script provided by \TeX4ht\ system is named `htlatex`. It  compiles \LaTeX\  
files to `HTML` with this command sequence:

    $ latex $latex_options 'code for loading tex4ht.sty \input{filename}'
    $ latex $latex_options 'code for loading tex4ht.sty \input{filename}'
    $ latex $latex_options 'code for loading tex4ht.sty \input{filename}'
    $ tex4ht $tex4ht_options filename
    $ t4ht $t4ht_options filename

The options for various parts of the system can be passed on the command line:

    $ htlatex filename "tex4ht.sty options" "tex4ht_options" "t4ht_options" "latex_options"

For basic `HTML` conversion it is possible to use the most basic invocation:

    $ htlatex filename.tex

It can be much more involved for the `HTML 5` output in `UTF-8` encoding:

    $ htlatex filename.tex "xhtml,html5,charset=utf-8" " -cmozhtf -utf8"

`make4ht` can simplify it:

    $ make4ht -u filename.tex

The `-u` option requires the `UTF-8` encoding. `HTML 5` is used as the default
output format by `make4ht`.

More information about the command line arguments can be found in section
\ref{sec:clioptions}.


## Compilation sequence

`htlatex` has a fixed compilation order and a hard-coded number of \LaTeX\ invocations. 

It is not possible to execute additional commands during the compilation.
When we want to run a program that interacts with \LaTeX, such as `Makeindex`
or `Bibtex`, we have two options. The first option is to create a new script based on
`htlatex` and add the wanted commands to the modified script. The second option
is to execute `htlatex`, then the additional and then `htlatex` again. The
second option means that \LaTeX\ will be invoked six times, as each call to
`htlatex` executes three calls to \LaTeX. This can lead to significantly long
compilation times. 

`make4ht` provides a solution for this issue using a build file, or extensions.
These can be used for interaction with external tools.

`make4ht`  also provides compilation modes, which enables to select commands that
should be executed using a command line option.

There is a built-in `draft` mode, which invokes \LaTeX\ only once, instead of
the default three invocations.  It is useful for the compilations of the
document before its final stage, when it is not important that  all
cross-references work. It can save quite a lot of the compilation time:

    $ make4ht -um draft filename.tex

More information about the build files can be found in section \ref{sec:buildfiles}.

## Handling of the generated files
\label{sec:output-dir}

There are also issues with the behavior of the `t4ht` application. It reads the 
`.lg` file generated by the `tex4ht` command. This file contains
information about the generated files, `CSS` instructions, calls to the external
applications, instructions for image conversions, etc. 


`t4ht` can be instructed to copy the generated files to an output directory, but
it doesn't preserve the directory structure. When the images are placed in a  
subdirectory, they will be copied to the output directory, losing the directory structure.
Links will be pointing to a non-existing subdirectory. The following command
should copy all output files to the correct destinations.

    $ make4ht -d outputdir filename.tex

## Image conversion and post-processing of the generated files

\TeX4ht\ can convert parts of the document to images. This is useful 
for diagrams or complicated math, for example.

By default, the image conversion is configured in a
[`.env` file](http://www.tug.org/applications/tex4ht/mn35.html#index35-73001).
It has a bit of strange syntax,  with 
[operating system dependent](http://www.tug.org/applications/tex4ht/mn-unix.html#index27-69005) rules.
`make4ht` provides simpler means for the image conversion in the build files.
It is possible to change the image conversion parameters without a need to modify the `.env` file.
The process is described in section \ref{sec:imageconversion}.

It is also possible to post-process the generated output files. The post-processing can be done
either using external programs such as `XSLT` processors and `HTML Tidy` or
using `Lua` functions. More information can be found in section \ref{sec:postprocessing}.



# Output file formats and extensions

The default output format used by `make4ht` is `html5`. A different
format can be requested using the `--format` option. Supported formats are:

 - `xhtml`
 - `html5`
 - `odt`
 - `tei`
 - `docbook`

The `--format` option can be also used for extension loading.

## Extensions

Extensions can be used to modify the build process without the need to use a build file. They
may post-process the output files or request additional commands for the compilation.

The extensions can be enabled or disabled by appending `+EXTENSION` or `-EXTENSION` after
the output format name:

     $ make4ht -uf html5+tidy filename.tex

Available extensions:


common\_filters

:    clean the output HTML files using filters.

common\_domfilters

:    clean the HTML file using DOM filters. It is more powerful than
`common_filters`. Used DOM filters are `fixinlines`, `idcolons`,
`joincharacters`, and `tablerows`.

detect\_engine

:    detect engine and format necessary for the document compilation from the
     magic comments supported by \LaTeX\ editors such as TeXShop or TeXWorks. 
     Add something like the following line at the beginning of the main \TeX\ file:

     `%!TEX TS-program = xelatex`

     It supports also Plain \TeX, use for example `tex` or `luatex` as the program name.

dvisvgm\_hashes

:    efficient generation of SVG pictures using Dvisvgm. It can utilize
multiple processor cores and generates only changed images.

join\_colors

:    load the `joincolors` domfilter for all HTML files.

latexmk\_build

:    use [Latexmk](https://ctan.org/pkg/latexmk?lang=en) for the \LaTeX\ compilation.

mathjaxnode

:    use [mathjax-node-page](https://github.com/pkra/mathjax-node-page/) to
     convert from MathML code to HTML + CSS or SVG. See [the available
     settings](#mathjaxsettings).

odttemplate

:    it automatically loads the `odttemplate` filter (page \pageref{sec:odttemplate}).

preprocess\_input 

:     compilation of the formats
      supported by [Knitr](https://yihui.name/knitr/) (`.Rnw`, `.Rtex`, `.Rmd`, `.Rrst`) 
      and also Markdown and reStructuredText formats. It requires
[R](https://www.r-project.org/) + [Knitr](https://yihui.name/knitr/)
installation, it requires also [Pandoc](https://pandoc.org/) for formats based on Markdown or
reStructuredText.

staticsite

:    build the document in a form suitable for static site generators like [Jekyll](https://jekyllrb.com/).

tidy

:    clean the `HTML` files using the `tidy` command.

# Build files
\label{sec:buildfiles}

`make4ht` supports build files. These are `Lua` scripts that can adjust
the build process. They can request external applications like `BibTeX` or `Makeindex`,
pass options to the commands, modify the image conversion process, or post-process the
generated files.

`make4ht` tries to load default build file named as `filename + .mk4 extension`.
It is possible to select a different build file with `-e` or `--build-file` command line
option.

Sample build file:

    Make:htlatex()
    Make:match("html$", "tidy -m -xml -utf8 -q -i ${filename}")

`Make:htlatex()` is preconfigured command for calling \LaTeX\ with the `tex4ht.sty` package
loaded. In this example, it will be executed  only once. After the 
compilation, the `tidy` command is executed on the output `HTML` files.

Note that it is not necessary to call `tex4ht` and `t4ht` commands explicitly in the
build file, they are called automatically. 

## User commands

It is possible to add more commands like `Make:htlatex` using the `Make:add` command:

    Make:add("name", "command", {settings table}, repetition)

This defines the `name` command, which can be then executed using `Make:name()`
command in the build file. 

The `name` and `command` parameters are required, the rest of the parameters are optional.

The defined command receives a table with settings as a parameter at the call time. 
The default settings are provided by `make4ht`. Additional settings can be
declared in the `Make:add` commands, user can also override the default settings
when the command is executed in the build file:

    Make:name({hello="world"})

More information about settings, including the default settings provided by
`make4ht`,  can be found in section \ref{sec:settings} on page
\pageref{sec:settings}.


### The `command` function
\label{sec:commandfunction}

The `command` parameter can be either a string template or function:

    Make:add("text", "echo hello, input file: ${input}")

The template can get a variable value from the parameters table using a
`${var_name}` placeholder. Templates are executed using the operating system, so
they should invoke existing OS commands. 





### The `settings table` table


The `settings table` parameter is optional. If it is present, it should be
a table with new settings available in the command. It can also override the default
`make4ht` settings for the defined command.

    Make:add("sample_function", function(params) 
      for k, v in pairs(params) do 
        print(k..": "..v) 
      end, {custom="Hello world"}
    )


### Repetition

The `repetition` parameter  specifies the maximum number of executions of the
particular command.  This is used for instance for `tex4ht` and `t4ht`
commands, as they should be executed only once in the compilation. They would
be executed multiple times when they are included in the build file, as they
are called by `make4ht` by default. Because these commands allow only one
`repetition`, the second execution is blocked.

### Expected exit code

You can set the expected exit code from a command with a `correct_exit` key in the
settings table. The compilation will be terminated when the command returns a
different exit code. 

    Make:add("biber", "biber ${input}", {correct_exit=0})

Commands that execute lua functions can return the numerical values using the `return` statement.


This mechanism isn't used for \TeX, because it doesn't differentiate between fatal and non-fatal errors. 
It returns the same exit code in all cases. Because of this, log parsing is used for a fatal error detection instead.
Error code value `1` is returned in the case of a fatal error, `0` is used
otherwise. The `Make.testlogfile` function can be used in the build file to
detect compilation errors in the TeX log file.


## Provided commands

`Make:htlatex`

:    One call to the TeX engine with special configuration for loading of the `tex4ht.sty` package.

`Make:httex`

:    Variant of `Make:htlatex` suitable for Plain \TeX.

`Make:latexmk`

:    Use `Latexmk` for the document compilation. `tex4ht.sty` will be loaded automatically.

`Make:tex4ht`

:    Process the `DVI` file and create output files.

`Make:t4ht`

:    Create the CSS file and generate images.

`Make:biber`

:    Process bibliography using the `biber` command.

`Make:pythontex`

:    Process the input file using `pythontex`.

`Make:bibtex`

:    Process bibliography using the `bibtex` command.

`Make:xindy`

:    Generate index using Xindy index processor.

`Make:makeindex`

:    Generate index using the Makeindex command.

`Make:xindex`

:    Generate index using the Xindex command.


## File matches
\label{sec:postprocessing}

Another type of action that can be specified in the build file is
`Make:match`.  It can be used to post-process  the generated files:

    Make:match("html$", "tidy -m -xml -utf8 -q -i ${filename}")

The above example will clean all output `HTML` files using the `tidy` command.

The `Make:match` action tests output filenames using a `Lua` pattern matching function.  
It executes a command or a function, specified in the second argument, on files
whose filenames match the pattern. 

The commands to be executed can be specified as strings. They can contain
`${var_name}` placeholders, which are replaced with corresponding variables
from the `settings` table. The templating system was described in 
subsection \ref{sec:commandfunction}. There is an additional variable
available in this table, called `filename`. It contains the name of the current
output file.


If a function is used instead, it will get two parameters.  The first one is the
current filename, the second one is the `settings` table. 

    Make:match("html$", function(filename, settings)
      print("Post-processing file: ".. filename)
      print("Available settings")
      for k,v in pairs(settings)
        print(k,v)
      end
      return true
   end)

Multiple post-processing actions can be executed on each filename. The Lua
action functions can return an exit code. If the exit code is false, the execution
of the post-processing chain for the current file will be terminated.

### Filters
\label{sec:filters}

To make it easier to post-process the generated files using the `match`
actions, `make4ht` provides a filtering mechanism thanks to the
`make4ht-filter` module. 

The `make4ht-filter` module returns a function that can be used for the filter
chain building. Multiple filters can be chained into a pipeline. Each filter
can modify the string that is passed to it from the previous filters. The
changes are then saved to the processed file. 

Several built-in filters are available, it is also possible to create new ones.

Example that use only the built-in filters:

    local filter = require "make4ht-filter"
    local process = filter{"cleanspan", "fixligatures", "hruletohr"}
    Make:htlatex()
    Make:match("html$",process)

Function `filter` accepts also function arguments, in this case this function
takes file contents as a parameter and modified contents are returned.

Example with custom filter:

    local filter  = require "make4ht-filter"
    local changea = function(s) return s:gsub("a","z") end
    local process = filter{"cleanspan", "fixligatures", changea}
    Make:htlatex()
    Make:match("html$",process)

In this example, spurious span elements are joined, ligatures are decomposed,
and then all letters "a" are replaced with "z" letters.

Built-in filters are the following:

cleanspan

:    clean spurious span elements when accented characters are used

cleanspan-nat

:    alternative clean span filter, provided by Nat Kuhn

fixligatures

:    decompose ligatures to base characters

hruletohr

:   `\hrule` commands are translated to series of underscore characters
    by \TeX4ht, this filter translates these underscores to `<hr>` elements

entites

:    convert prohibited named entities to numeric entities (only
     `&nbsp;` currently).

fix-links

:    replace colons in local links and `id` attributes with underscores. Some
     cross-reference commands may produce colons in internal links, which results in
     a validation error.

mathjaxnode

:    use [mathjax-node-page](https://github.com/pkra/mathjax-node-page/) to
     convert from MathML code to HTML + CSS or SVG. See [the available
     settings](#mathjaxsettings).

odttemplate

:    use styles from another `ODT` file serving as a template in the current
     document. It works for the `styles.xml` file in the `ODT` file. During
     the compilation, this file is named as `\jobname.4oy`.
     \label{sec:odttemplate}

staticsite

:    create HTML files in a format suitable for static site generators such as [Jekyll](https://jekyllrb.com/)

svg-height

:    some  SVG images produced by `dvisvgm` seem to have wrong dimensions. This filter
     tries to set the correct image size.


### DOM filters

DOM filters are variants of filters that use the
[`LuaXML`](https://ctan.org/pkg/luaxml) library to modify
directly the XML object. This enables more powerful
operations than the regex-based filters from the previous section. 

Example:

    local domfilter = require "make4ht-domfilter"
    local process = domfilter {"joincharacters"}
    Make:match("html$", process)


Available DOM filters:

aeneas

:  [Aeneas](https://www.readbeyond.it/aeneas/) is a tool for automagical synchronization of text and audio.
   This filter modifies the HTML code to support synchronization.

booktabs

:  fix lines produced by the `\cmidrule` command provided by the Booktabs package.

collapsetoc

:  collapse table of contents to contain only top-level sectioning level and sections on the current page.

fixinlines

:  put all inline elements which are direct children of the `<body>` elements to a paragraph.

idcolons

:  replace the colon (`:`) character in internal links and `id` attributes. They cause validation issues.

joincharacters

:  join consecutive `<span>` or `<mn>` elements. This DOM filter supersedes the `cleanspan` filter.

joincolors

:  many `<span>` elements with unique `id` attributes are created when \LaTeX\ colors are being used in the document.
   A CSS rule is added for each of these elements, which may result in
   substantial growth of the CSS file. This filter replaces these rules with a
   common one for elements with the same color value.

odtimagesize

:  set correct dimensions for images in the ODT format. It is loaded by default for the ODT output.

odtpartable

:  resolve tables nested inside paragraphs, which is invalid in the ODT format.

tablerows

:  remove spurious rows from HTML tables.

mathmlfixes

:  fix common issues for MathML.

t4htlinks

:  fix hyperlinks in the ODT format.



## Image conversion
\label{sec:imageconversion}

It is possible to convert parts of the \LaTeX\ input as pictures. It can be used
for preserving the appearance of  math or diagrams, for example. 

These pictures are stored in a special `DVI` file, which can be processed by
a `DVI` to image commands, such as `dvipng` or `dvisvgm`. 

This conversion is normally configured in the `tex4ht.env` file. This file
is system dependent and it has quite an unintuitive syntax.
The configuration is processed by the `t4ht` application and the conversion
command is called for all pictures.

It is possible to disable `t4ht` image processing and configure image
conversion in the build file using the `image` action:

    Make:image("png$",
    "dvipng -bg Transparent -T tight -o ${output}  -pp ${page} ${source}")


`Make:image` takes two parameters, a `Lua` pattern to match the image name, and
the action.

Action can be either a string template with the conversion command
or a function that takes a table with parameters as an argument.

There are three parameters:

  - `output` - output image filename
  - `source` - `DVI` file with the pictures
  - `page`   - page number of the converted image

## The `mode` variable

The `mode` variable available in the build process contains 
contents of the `--mode` command line option.  It can be used to run some commands
conditionally. For example:

     if mode == "draft" then
       Make:htlatex{} 
     else
       Make:htlatex{}
       Make:htlatex{}
       Make:htlatex{}
     end

In this example (which is the default configuration used by `make4ht`),
\LaTeX\ is called only once when `make4ht` is called with the `draft` mode:
    
    make4ht -m draft filename

## The `settings` table
\label{sec:settings}

It is possible to access the parameters outside commands, file matches
and image conversion functions. For example, to convert the document to
the `OpenDocument Format (ODT)`, the following settings can be used. They are
based on the `oolatex` command:

    settings.tex4ht_sty_par = settings.tex4ht_sty_par ..",ooffice"
    settings.tex4ht_par = settings.tex4ht_par .. " ooffice/! -cmozhtf"
    settings.t4ht_par = settings.t4ht_par .. " -cooxtpipes -coo "

(Note that it is possible to use the `--format odt` option
which is superior to the previous code. This example is intended just as an
illustration)

There are some functions to simplify access to the settings:

`set_settings{parameters}`

:   overwrite settings with values from a passed table

`settings_add{parameters}`

:   add values to the current settings 

`filter_settings "filter name" {parameters}`

:   set settings for a filter

`get_filter_settings(name)`

:   get settings for a filter


For example, it is possible to simplify the sample from the previous code listings:

    settings_add {
      tex4ht_sty_par =",ooffice",
      tex4ht_par = " ooffice/! -cmozhtf",
      t4ht_par = " -cooxtpipes -coo "
    }

Settings for filters and extensions can be set using `filter_settings`:

    
    filter_settings "test" {
      hello = "world"
    }

These settings can be retrieved in the extensions and filters using the `get_filter_settings` function:

    function test(input)
       local options = get_filter_settings("test")
       print(options.hello)
       return input
    end
       
### Default settings

The default parameters are the following:

`htlatex`

:     used \TeX\ engine

`input`

:    content of `\jobname`, see also the `tex_file` parameter.

`interaction`

:    interaction mode for the \TeX\ engine. The default value is `batchmode` to
     suppress user input on compilation errors. It also suppresses most of the \TeX\ 
     compilation log output. Use the `errorstopmode` for the default behavior.

`tex_file`

:    input \TeX\ filename

`latex_par`

:    command line parameters to the \TeX\ engine

`packages`

:    additional \LaTeX\ code  inserted before `\documentclass`.
     Useful for passing options to packages used in the document or to load additional packages.

`tex4ht_sty_par`

:    options for `tex4ht.sty`

`tex4ht_par`

:     command line options for the `tex4ht` command

`t4ht_par`

:    command line options for the `t4ht` command

`outdir`

:    the output directory

`correct_exit`

:    expected `exit code` from the command. The compilation will be terminated
     if the exit code of the executed command has a different value.


# Configuration file {#configfile}

It is possible to globally modify the build settings using the configuration
file. It is a special version of a build file where the global settings can be set.

Common tasks for the configuration file can be a declaration of the new commands,
loading of the default filters or specification of a default build sequence. 

One additional functionality not available in the build files are commands for
enabling and disabling of extensions.


## Location 

The configuration file can be saved either in the
`$HOME/.config/make4ht/config.lua` file, or in the `.make4ht` file placed in
the current directory or it's parent directories (up to the `$HOME` directory). 

## Additional commands

There are two additional commands:

`Make:enable_extension(name)`

:  require extension

`Make:disable_extension(name)`

:  disable extension

## Example

The following example of the configuration file adds support for the `biber` command, requires
`common_domfilters` extension and requires MathML
output for math.

    Make:add("biber", "biber ${input}")
    Make:enable_extension "common_domfilters"
    settings_add {
      tex4ht_sty_par =",mathml"
    }

<!--
# Development

## Custom filters

## New extensions

## How to add a new output format

-->

# List of available settings for filters and extensions.

These settings may be set using `filter_settings` function in a build file or in the `make4ht` configuration file.



## Indexing commands

The indexing commands (like `xindy` or `makeindex`) use some common settings.

idxfile

:    name of the `.idx` file. Default value is `\jobname.idx`.

indfile

:    name of the `.ind` file. Default value is the same as `idxfile` with the file extension changed to `.ind`.

Each indexing command can have some additional settings.

### The `xindy` command

encoding

:    text encoding of the `.idx` file. Default value is `utf8`.

language

:    index language. Default language is English.

modules

:    table with names of additional `Xindy` modules to be used.

### The `makeindex` command

options


:    additional command line options for the Makeindex command.

### The `xindex` command

options


:    additional command line options for the Xindex command.

language

:    document language

## The `tidy` extension

options

:  command line options for the `tidy` command. Default value is `-m -utf8 -w 512 -q`.

## The `collapsetoc` dom filter

`toc_query` 

:  CSS selector for selecting the table of contents container. 

`title_query`

:  CSS selector for selecting all elements that contain the section ID attribute.

`toc_levels` 

:  table containing a hierarchy of classes used in TOC

Default values:

    filter_settings "collapsetoc" {
      toc_query = ".tableofcontents",
      title_query = ".partHead a, .chapterHead a, .sectionHead a, .subsectionHead a",
      toc_levels = {"partToc", "chapterToc", "sectionToc", "subsectionToc", "subsubsectionToc"}
    }

## The `fixinlines` dom filter 

inline\_elements

:  table of inline elements that shouldn't be direct descendants of the `body` element. The element names should be table keys, the values should be true.

Example

    filter_settings "fixinlines" {inline_elements = {a = true, b = true}}

## The `joincharacters` dom filter

charclasses 

:  table of elements that should be concatenated when two or more of such elements with the same value of the `class` attribute are placed one after another.

Example

    filter_settings "joincharacters" { charclasses = { span=true, mn = true}}

## The `mathjaxnode` filter {#mathjaxsettings}

options

:  command line options for the `mjpage` command. Default value is `--output CommonHTML`

Example

    filter_settings "mathjaxnode" {
      options="--output SVG --font Neo-Euler"
    }

cssfilename  

:  the `mjpage` command puts some CSS code into the HTML pages. `mathjaxnode` extracts this information and saves it to a standalone CSS file. Default CSS filename is `mathjax-chtml.css`

fontdir

:  directory with MathJax font files. This option enables the use of local fonts, which
   is useful in the conversion to ePub, for example. The font directory should be
   sub-directory of the current directory. Only TeX font is supported at the moment.

Example


    filter_settings "mathjaxnode" {
      fontdir="fonts/TeX/woff/" 
    }


## The `staticsite` filter and extension

site\_root 

:  directory where generated files should be copied.

map

:  a hash table where keys contain patterns that match filenames and values contain
destination directory for the matched files. The destination directories are
relative to the `site_root` (it is possible to use `..` to switch to a parent
directory).

file\_pattern 

:  a pattern used for filename generation. It is possible to use string templates
and format strings for `os.date` function. The default pattern `%Y-%m-%d-${input}`
creates names in the form of `YYYY-MM-DD-file_name`.

header

:  table with variables to be set in the YAML header in HTML files. If the
table value is a function, it is executed with current parameters and HTML page
DOM object as arguments.

Example:


    local outdir = os.getenv "blog_root" 
    
    filter_settings "staticsite" {
      site_root = outdir, 
      map = {
        [".css$"] = "../css/"
      },
      header = {
         layout="post",
         date = function(parameters, dom)
           return os.date("!%Y-%m-%d %T", parameters.time)
         end
      }
    }

## The `dvisvgm_hashes` extension

options

:  command line options for Dvisvgm. The default value is `-n --exact -c 1.15,1.15`.

cpu_cnt

:  the number of processor cores used for the conversion. The extension tries to detect the available cores automatically by default.

parallel_size

:  the number of pages used in each Dvisvgm call. The extension detects changed
pages in the DVI file and constructs multiple calls to Dvisvgm with only changed
pages.

scale

:  SVG scaling.

## The `odttemplate` filter and extension

template

:  filename of the template `ODT` file 


`odttemplate` can also get the template filename from the `odttemplate` option from `tex4ht_sty_par` parameter. It can be set using the following command line call:

     make4ht -f odt+odttemplate filename.tex "odttemplate=template.odt"

## The `aeneas` filter

skip\_elements

:  List of CSS selectors that match elements that shouldn't be processed. Default value: `{ "math", "svg"}`.

id\_prefix 

:  prefix used in the ID attribute forming.

sentence\_match 

:  Lua pattern used to match a sentence. Default value: `"([^%.^%?^!]*)([%.%?!]?)"`.

## The  `make4ht-aeneas-config` package

Companion for the `aeneas` DOM filter is the `make4ht-aeneas-config` plugin. It
can be used to write the Aeneas configuration file or execute Aeneas on the
generated HTML files.

Available functions:

write\_job(parameters)

:  write Aenas job configuration to `config.xml` file. See the [Aeneas
   documentation](https://www.readbeyond.it/aeneas/docs/clitutorial.html#processing-jobs)
   for more information about jobs.

execute(parameters)

:  execute Aeneas.

process\_files(parameters)

:  process the audio and generated subtitle files.


By default, a `SMIL` file is created. It is assumed that there is an audio file
in the `mp3` format, named as the \TeX\ file. It is possible to use different formats
and filenames using mapping.

The configuration options can be passed directly to the functions or set using
`filter_settings "aeneas-config" {parameters}` function.


### Available parameters


lang 

:  document language. It is interfered from the HTML file, so it is not necessary to set it. 

map 

:  mapping between HTML, audio and subtitle files. More info below. 

text\_type 

:  type of input. The `aeneas` DOM filter produces an `unparsed` text type.

id\_sort 

:  sorting of id attributes. The default value is `numeric`.

id\_regex 

:  regular expression to parse the id attributes.

sub\_format 

:  generated subtitle format. The default value is `smil`.


### Additional parameters for the job configuration file

- description 
- prefix 
- config\_name 
- keep\_config 



It is possible to generate multiple HTML files from the \LaTeX\ source. For
example, `tex4ebook` generates a separate file for each chapter or section. It is
possible to set options for each HTML file, in particular names of the
corresponding audio files. This mapping is done using the `map` parameter. 

Example:

    filter_settings "aeneas-config" {
      map = {
        ["sampleli1.html"] = {audio_file="sample.mp3"}, 
        ["sample.html"] = false
      }
    }

Table keys are the configured filenames. It is necessary to insert them as
`["filename.html"]`, because of Lua syntax rules.

This example maps audio file `sample.mp3` to a section subpage. The main HTML
file, which may contain title and table of contents doesn't have a
corresponding audio file.

Filenames of the subfiles correspond to the chapter numbers, so they are not
stable when a new chapter is added. It is possible to request filenames
derived from the chapter titles using the `sec-filename` option for `tex4ht.sty`.

### Available `map` options


audio\_file 

:  the corresponding audio file 

sub\_file 

:  name of the generated subtitle file

The following options are the same as their counterparts from the main parameters table and generally, don't need to be set:

- prefix 
- file\_desc 
- file\_id 
- text\_type 
- id\_sort
- id\_prefix 
- sub\_format 


### Full example


    local domfilter = require "make4ht-domfilter"
    local aeneas_config = require "make4ht-aeneas-config"
    
    filter_settings "aeneas-config" {
      map = {
        ["krecekli1.xhtml"] = {audio_file="krecek.mp3"}, 
        ["krecek.xhtml"] = false
      }
    }
    
    local process = domfilter {"aeneas"}
    Make:match("html$", process)

    if mode == "draft" then
      aeneas_config.process_files {}
    else
      aeneas_config.execute {}
    end




# Troubleshooting 

## Incorrect handling of command line arguments for `tex4ht`, `t4ht` or `latex`

Sometimes, you may get a similar error:

    make4ht:unrecognized parameter: i

It may be caused by a following `make4ht` invocation:

    $ make4ht hello.tex "customcfg,charset=utf-8" "-cunihtf -utf8" -d foo

The command line option parser is confused by mixing options for `make4ht` and
\TeX4ht\ in this case. It tries to interpret the `-cunihtf -utf8`, which are
options for the `tex4ht` command, as `make4ht` options. To fix that, try to
move the `-d foo` directly after the `make4ht` command:

    $ make4ht -d foo hello.tex "customcfg,charset=utf-8" "-cunihtf -utf8"

Another option is to add a space before the `tex4ht` options:

    $ make4ht hello.tex "customcfg,charset=utf-8" " -cunihtf -utf8" -d foo

The former way is preferable, though.

## Filenames containing spaces

`tex4ht` command cannot handle filenames containing spaces. to fix this issue, `make4ht` 
replaces spaces in the input filenames with underscores. The generated
XML filenames use underscores instead of spaces as well.

## Filenames containing non-ASCII characters

The `odt` output doesn't support accented filenames, it is best to stick to ASCII characters in filenames.

# License

Permission is granted to copy, distribute and/or modify this software
under the terms of the LaTeX Project Public License, version 1.3.
