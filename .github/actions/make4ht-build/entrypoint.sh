#!/bin/bash

# make4ht -um draft 
make justinstall SUDO=""
make htmldoc
cat htmldoc/make4ht-doc.html


