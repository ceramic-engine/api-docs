#!/bin/bash
set -e

cd ${0%/*}

rm -rf ./docs

ceramic clay setup web
ceramic clay hxml web > docs.hxml
$(ceramic haxe) docs.hxml --xml ../../../docs/clay-web.xml -D doc-gen -D documentation -D dox_events --no-output -D no-compilation

ceramic clay setup web --variant use_tilemap
ceramic clay hxml web --variant use_tilemap > docs.hxml
$(ceramic haxe) docs.hxml --xml ../../../docs/tilemap-plugin.xml -D doc-gen -D documentation -D dox_events --no-output -D no-compilation

ceramic clay setup web --variant use_ase
ceramic clay hxml web --variant use_ase > docs.hxml
$(ceramic haxe) docs.hxml --xml ../../../docs/ase-plugin.xml -D doc-gen -D documentation -D dox_events --no-output -D no-compilation

ceramic clay setup web --variant use_ldtk
ceramic clay hxml web --variant use_ldtk > docs.hxml
$(ceramic haxe) docs.hxml --xml ../../../docs/ldtk-plugin.xml -D doc-gen -D documentation -D dox_events --no-output -D no-compilation

ceramic clay setup web --variant use_ui
ceramic clay hxml web --variant use_ui > docs.hxml
$(ceramic haxe) docs.hxml --xml ../../../docs/ui-plugin.xml -D doc-gen -D documentation -D dox_events --no-output -D no-compilation

ceramic clay setup web --variant use_sprite
ceramic clay hxml web --variant use_sprite > docs.hxml
$(ceramic haxe) docs.hxml --xml ../../../docs/sprite-plugin.xml -D doc-gen -D documentation -D dox_events --no-output -D no-compilation

ceramic clay setup web --variant use_spine
ceramic clay hxml web --variant use_spine > docs.hxml
$(ceramic haxe) docs.hxml --xml ../../../docs/spine-plugin.xml -D doc-gen -D documentation -D dox_events --no-output -D no-compilation

ceramic clay setup web --variant use_arcade
ceramic clay hxml web --variant use_arcade > docs.hxml
$(ceramic haxe) docs.hxml --xml ../../../docs/arcade-plugin.xml -D doc-gen -D documentation -D dox_events --no-output -D no-compilation

ceramic clay setup web --variant use_nape
ceramic clay hxml web --variant use_nape > docs.hxml
$(ceramic haxe) docs.hxml --xml ../../../docs/nape-plugin.xml -D doc-gen -D documentation -D dox_events --no-output -D no-compilation

ceramic clay setup web --variant use_imgui
ceramic clay hxml web --variant use_imgui > docs.hxml
$(ceramic haxe) docs.hxml --xml ../../../docs/imgui-plugin.xml -D doc-gen -D documentation -D dox_events --no-output -D no-compilation

ceramic clay setup web --variant use_dialogs
ceramic clay hxml web --variant use_dialogs > docs.hxml
$(ceramic haxe) docs.hxml --xml ../../../docs/dialogs-plugin.xml -D doc-gen -D documentation -D dox_events --no-output -D no-compilation

ceramic clay setup web --variant use_gif
ceramic clay hxml web --variant use_gif > docs.hxml
$(ceramic haxe) docs.hxml --xml ../../../docs/gif-plugin.xml -D doc-gen -D documentation -D dox_events --no-output -D no-compilation

ceramic clay setup web --variant use_elements
ceramic clay hxml web --variant use_elements > docs.hxml
$(ceramic haxe) docs.hxml --xml ../../../docs/elements-plugin.xml -D doc-gen -D documentation -D dox_events --no-output -D no-compilation

ceramic clay setup web --variant use_script
ceramic clay hxml web --variant use_script > docs.hxml
$(ceramic haxe) docs.hxml --xml ../../../docs/script-plugin.xml -D doc-gen -D documentation -D dox_events --no-output -D no-compilation

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
$(ceramic haxe) docs.hxml --xml ../../../docs/headless.xml -D doc-gen -D documentation -D dox_events --no-output -D no-compilation

ceramic unity setup unity
ceramic unity hxml unity > docs.hxml
$(ceramic haxe) docs.hxml --xml ../../../docs/unity.xml -D doc-gen -D documentation -D dox_events --no-output -D no-compilation

$(ceramic haxelib) run dox -i ./docs --output-path docs --keep-field-order --exclude 'zpp_nape|microsoft|unityengine|fuzzaldrin|gif|timestamp|stb|sys|spec|sdl|polyline|poly2tri|opengl|openal|ogg|js|hsluv|hscript|glew|format|earcut|cs|cpp|com|assets|ceramic.scriptable|ceramic.macros' --title 'Ceramic API'

node transform-docs.js
