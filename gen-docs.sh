#!/bin/bash
set -e

cd ${0%/*}

rm -rf ./docs
rm -rf ./docs-xml

ceramic clay setup web
ceramic clay hxml web > docs.hxml
$(ceramic haxe) docs.hxml --xml ../../../docs/clay-web.xml -D doc-gen -D documentation -D dox_events --no-output -D no-compilation

if [ "$(uname)" == "Darwin" ]; then
ceramic clay setup mac
ceramic clay hxml mac > docs.hxml
$(ceramic haxe) docs.hxml --xml ../../../docs/clay-native.xml -D doc-gen -D documentation -D dox_events --no-output -D no-compilation
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
ceramic clay setup linux
ceramic clay hxml linux > docs.hxml
$(ceramic haxe) docs.hxml --xml ../../../docs/clay-native.xml -D doc-gen -D documentation -D dox_events --no-output -D no-compilation
fi

ceramic headless setup node
ceramic headless hxml node > docs.hxml
$(ceramic haxe) docs.hxml --xml ../../../docs/headless.xml -D doc-gen -D documentation -D no_backend_docs -D dox_events --no-output -D no-compilation

ceramic unity setup unity
ceramic unity hxml unity > docs.hxml
$(ceramic haxe) docs.hxml --xml ../../../docs/unity.xml -D doc-gen -D documentation -D no_backend_docs -D dox_events --no-output -D no-compilation

mkdir docs-xml
cp -f docs/*.xml docs-xml

# Build gen-docs tool
cd gen-docs
haxe build.hxml
cd ..

# Generate markdown documentation from XML files
rm -rf ./docs-md
mkdir -p docs-md

# Generate markdown for each XML file
for xml_file in docs-xml/*.xml; do
    base_name=$(basename "$xml_file" .xml)
    echo "Generating markdown for $base_name..."
    node gen-docs/bin/gen-docs.js markdown "$xml_file" "docs-md/$base_name"
    
    # Generate table of contents
    echo "Generating table of contents for $base_name..."
    node gen-docs/bin/gen-docs.js toc "$xml_file" "docs-md/$base_name/toc.json"
done

# Old dox command (commented out since we're using our own generator now)
# $(ceramic haxelib) run dox -i ./docs --output-path docs --keep-field-order --exclude 'zpp_nape|microsoft|unityengine|fuzzaldrin|gif|timestamp|stb|sys|spec|sdl|polyline|poly2tri|opengl|openal|ogg|js|hsluv|hscript|glew|format|earcut|cs|cpp|com|assets|ceramic.scriptable|ceramic.macros' --title 'Ceramic API'

# node transform-docs.js
