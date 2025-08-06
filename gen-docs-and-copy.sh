#!/bin/bash
./gen-docs.sh && rm -rf ../ceramic-engine.github.io/content/api-docs && cp -r docs-md ../ceramic-engine.github.io/content/api-docs