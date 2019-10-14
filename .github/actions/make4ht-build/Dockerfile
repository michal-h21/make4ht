FROM debian:unstable-slim

LABEL "maintainer"="Michal Hoftich <michal.h21@gmail.com>"
LABEL "repository"="https://github.com/michal-h21/make4ht"
LABEL "homepage"="https://github.com/michal-h21/make4ht"

LABEL "com.github.actions.name"="LaTeX to XML"
LABEL "com.github.actions.description"="Convert LaTeX documents to XML with make4ht."
LABEL "com.github.actions.icon"="code"
LABEL "com.github.actions.color"="blue"

ENV DEBIAN_FRONTEND noninteractive

# Install all TeX and LaTeX dependencies
RUN apt-get update && \
    apt-get install --yes --no-install-recommends \
    make luatex texlive-base texlive-luatex texlive-latex-extra \
    tidy \
    # texlive-fonts-recommended \
    fonts-noto \
    texlive-plain-generic texlive-generic-recommended \
    pandoc latexmk texlive lmodern fonts-lmodern tex-gyre fonts-texgyre \
    texlive-lang-english && \
    apt-get autoclean && apt-get --purge --yes autoremove && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
