#!/bin/sh

BASEDIR=$(dirname "$0")
cp "$BASEDIR/../README.md" "$BASEDIR/index.md"
perl -pi -e s,./doc/,,g index.md
cd "$BASEDIR/../" && mkdocs gh-deploy
