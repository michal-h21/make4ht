#!/bin/bash

# make4ht -um draft 
make install SUDO=""
make htmldoc
cat htmldoc/make4ht-doc.html


