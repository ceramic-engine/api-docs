import ApiTypes;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;

class MarkdownGenerator {

    public function new() {}

    var target:String;

    public function generateMarkdown(apiData:ApiData, outputDir:String, target:String):Void {
        this.target = target;

        // Create output directory if it doesn't exist
        if (!FileSystem.exists(outputDir)) {
            FileSystem.createDirectory(outputDir);
        }

        // Generate markdown for each type
        for (type in apiData.types) {
            if (shouldSkipType(type)) continue;

            var markdown = generateTypeMarkdown(type, apiData, target);
            var filename = getMarkdownFilename(type);
            var filepath = Path.join([outputDir, filename]);

            // Create subdirectories if needed
            var dir = Path.directory(filepath);
            if (!FileSystem.exists(dir)) {
                createDirectoryRecursive(dir);
            }

            File.saveContent(filepath, markdown);
        }
    }

    function shouldSkipType(type:ApiType):Bool {
        // Skip private implementation classes
        if (type.isPrivate && StringTools.endsWith(type.path, "_Impl_")) {
            return true;
        }

        // Skip types with @:dox(hide) meta
        for (meta in type.meta) {
            if (meta.name == ":dox" && meta.params != null && meta.params.length > 0 && meta.params[0] == "hide") {
                return true;
            }
        }

        return false;
    }

    function getMarkdownFilename(type:ApiType):String {
        return type.path.split(".").join("/") + ".md";
    }

    function createDirectoryRecursive(path:String):Void {
        var parts = path.split("/");
        var current = "";

        for (part in parts) {
            if (part == "") continue;
            current = current == "" ? part : current + "/" + part;
            if (!FileSystem.exists(current)) {
                FileSystem.createDirectory(current);
            }
        }
    }

    function generateTypeMarkdown(type:ApiType, apiData:ApiData, target:String):String {
        var md = new StringBuf();

        // Add front matter
        md.add('---\n');
        md.add('layout: api-docs\n');
        md.add('category: api-docs\n');
        md.add('subCategory: doc\n');
        md.add('menu: ${getMenuGroup(type)}\n');
        md.add('title: ${getTypeTitle(type)}\n');
        md.add('target: ${formatTargetName(target)}\n');
        md.add('permalink: api-docs/${target}/${getMarkdownPermalink(type)}/\n');
        md.add('---\n\n');

        // Title
        md.add('# ${getTypeTitle(type)}\n\n');

        // Add GitHub link for ceramic types and submodules
        if (type.file != null && type.file.indexOf("/ceramic/") != -1) {
            // Extract the path after "/ceramic/"
            var ceramicIndex = type.file.indexOf("/ceramic/");
            if (ceramicIndex != -1) {
                var relativePath = type.file.substring(ceramicIndex + 9); // Skip "/ceramic/"

                // Check if it's a submodule path
                if (StringTools.startsWith(relativePath, "git/")) {
                    // Extract submodule name
                    var slashIndex = relativePath.indexOf("/", 4);
                    if (slashIndex != -1) {
                        var submoduleName = relativePath.substring(4, slashIndex);
                        var submodulePath = relativePath.substring(slashIndex + 1);

                        // Map submodule to GitHub URL
                        var repoUrl = switch (submoduleName) {
                            case "linc_timestamp": "https://github.com/ceramic-engine/linc_timestamp";
                            case "linc_stb": "https://github.com/ceramic-engine/linc_stb";
                            case "linc_ogg": "https://github.com/ceramic-engine/linc_ogg";
                            case "linc_opengl": "https://github.com/ceramic-engine/linc_opengl";
                            case "spine-hx": "https://github.com/jeremyfa/spine-hx";
                            case "polyline": "https://github.com/jeremyfa/polyline";
                            case "generate": "https://github.com/jeremyfa/generate";
                            case "format-tiled": "https://github.com/ceramic-engine/format-tiled";
                            case "arcade": "https://github.com/jeremyfa/arcade";
                            case "akifox-asynchttp": "https://github.com/ceramic-engine/akifox-asynchttp";
                            case "nape": "https://github.com/ceramic-engine/nape";
                            case "differ": "https://github.com/ceramic-engine/differ";
                            case "hsluv": "https://github.com/ceramic-engine/hsluv";
                            case "tracker": "https://github.com/jeremyfa/tracker";
                            case "linc_dialogs": "https://github.com/ceramic-engine/linc_dialogs";
                            case "clay": "https://github.com/ceramic-engine/clay";
                            case "imgui-hx": "https://github.com/jeremyfa/imgui-hx";
                            case "gif": "https://github.com/ceramic-engine/gif";
                            case "hxWebSockets": "https://github.com/ceramic-engine/hxWebSockets";
                            case "linc_rtmidi": "https://github.com/ceramic-engine/linc_rtmidi";
                            case "linc_soloud": "https://github.com/jeremyfa/linc_soloud";
                            case "hxnodejs-ws": "https://github.com/ceramic-engine/hxnodejs-ws";
                            case "bin-packing": "https://github.com/ceramic-engine/bin-packing";
                            case "hscript": "https://github.com/ceramic-engine/hscript";
                            case "ase": "https://github.com/ceramic-engine/ase";
                            case "bind": "https://github.com/jeremyfa/bind";
                            case "hxnodejs": "https://github.com/ceramic-engine/hxnodejs";
                            case "format": "https://github.com/ceramic-engine/format";
                            case "fuzzaldrin": "https://github.com/jeremyfa/fuzzaldrin";
                            case "hxcpp": "https://github.com/ceramic-engine/hxcpp";
                            case "linc_process": "https://github.com/jeremyfa/linc_process";
                            case "msdf-atlas-gen-binary": "https://github.com/jeremyfa/msdf-atlas-gen-binary";
                            case "loreline": "https://github.com/jeremyfa/loreline";
                            case "yaml": "https://github.com/jeremyfa/yaml";
                            case "SDL": "https://github.com/libsdl-org/SDL";
                            case "build-sdl3": "https://github.com/jeremyfa/build-sdl3";
                            case _: null;
                        }

                        if (repoUrl != null) {
                            md.add('<div class="view-source"><a href="${repoUrl}/blob/master/${submodulePath}">View source</a></div>\n\n');
                        }
                    }
                } else if (relativePath.indexOf("git/haxe-binary") == -1 &&
                    (StringTools.startsWith(relativePath, "runtime/") ||
                     StringTools.startsWith(relativePath, "plugins/") ||
                     StringTools.startsWith(relativePath, "tools/"))) {
                    // Regular ceramic source file
                    md.add('<div class="view-source"><a href="https://github.com/ceramic-engine/ceramic/blob/master/${relativePath}">View source</a></div>\n\n');
                }
            }
        }

        // Build complete hierarchy line
        var hasDerivedTypes = apiData.inheritanceMap != null && apiData.inheritanceMap.exists(type.path);
        var derivedTypes = hasDerivedTypes ? apiData.inheritanceMap.get(type.path) : null;
        var hasInheritance = type.superClass != null && !type.isInterface;

        if (hasInheritance || (hasDerivedTypes && derivedTypes.length > 0)) {
            // Show full hierarchy line in HTML
            md.add('<div class="type-hierarchy">');

            // Format inheritance chain if any
            if (hasInheritance) {
                var chain = buildInheritanceChain(type, apiData);
                for (i in 0...chain.length - 1) {
                    var typePath:TypePath = { path: chain[i], params: [] };
                    md.add(formatTypePathWithContextHtml(typePath, type.path));
                    md.add(' → ');
                }
            }

            // Current type in bold
            md.add('<strong>${type.path}</strong> (${getTypeKindString(type)})');

            // Add derived types
            if (hasDerivedTypes && derivedTypes.length > 0) {
                md.add(' → ');

                // Sort subtypes for consistent output
                derivedTypes.sort(Reflect.compare);

                var formattedSubtypes = [];
                for (subtype in derivedTypes) {
                    var subtypePath:TypePath = { path: subtype, params: [] };
                    formattedSubtypes.push(formatTypePathWithContextHtml(subtypePath, type.path));
                }

                md.add(formattedSubtypes.join(', '));
            }

            md.add('</div>\n\n');
        } else {
            // No hierarchy - just show type
            md.add('<div class="type-hierarchy"><strong>${type.path}</strong> (${getTypeKindString(type)})</div>\n\n');
        }

        // Interfaces implemented (show separately if there are any)
        if (type.interfaces != null && type.interfaces.length > 0) {
            md.add('<div class="type-implements"><strong>Implements:</strong> ');
            var formattedInterfaces = [];
            for (iface in type.interfaces) {
                formattedInterfaces.push(formatTypePathWithContextHtml(iface, type.path));
            }
            md.add(formattedInterfaces.join(', '));
            md.add('</div>\n\n');
        }

        // Description - moved after hierarchy
        if (type.doc != null && type.doc != "") {
            md.add(formatDocumentation(type.doc, type.path, apiData) + '\n\n');
        }

        // Abstract conversions
        if (type.kind.match(TAbstract)) {
            if ((type.from != null && type.from.length > 0) || (type.to != null && type.to.length > 0)) {
                md.add('## Type Conversions\n\n');

                if (type.from != null && type.from.length > 0) {
                    md.add('**From:**\n');
                    for (fromType in type.from) {
                        md.add('- `${formatTypePath(fromType)}`\n');
                    }
                    md.add('\n');
                }

                if (type.to != null && type.to.length > 0) {
                    md.add('**To:**\n');
                    for (toType in type.to) {
                        md.add('- `${formatTypePath(toType)}`\n');
                    }
                    md.add('\n');
                }
            }
        }

        // Enum constructors
        if (type.kind.match(TEnum) && type.constructors != null && type.constructors.length > 0) {
            md.add('## Constructors\n\n');

            for (ctor in type.constructors) {
                md.add('### ${ctor.name}\n\n');

                if (ctor.args != null && ctor.args.length > 0) {
                    md.add('```haxe\n');
                    md.add('${ctor.name}(');
                    md.add(formatFunctionArgs(ctor.args, false));
                    md.add(')\n```\n\n');

                    // Check if any constructor args have descriptions
                    var hasDescriptions = false;
                    for (arg in ctor.args) {
                        if (ctor.doc != null && extractParamDoc(ctor.doc, arg.name) != null) {
                            hasDescriptions = true;
                            break;
                        }
                    }

                    // Document parameters in a table
                    md.add('**Parameters:**\n\n');
                    md.add('| Name | Type');
                    if (hasDescriptions) md.add(' | Description');
                    md.add(' |\n');

                    md.add('|------|------');
                    if (hasDescriptions) md.add('|-------------');
                    md.add('|\n');

                    for (arg in ctor.args) {
                        md.add('| `${arg.name}` ');
                        md.add('| ${formatTypePath(arg.type)} ');

                        if (hasDescriptions) {
                            md.add('| ');
                            // Extract parameter description from doc if available
                            if (ctor.doc != null) {
                                var paramDoc = extractParamDoc(ctor.doc, arg.name);
                                if (paramDoc != null) {
                                    md.add(paramDoc);
                                }
                            }
                            md.add(' ');
                        }

                        md.add('|\n');
                    }
                    md.add('\n');
                } else {
                    md.add('```haxe\n${ctor.name}\n```\n\n');
                }

                if (ctor.doc != null && ctor.doc != "") {
                    md.add(formatDocumentation(ctor.doc, type.path, apiData) + '\n\n');
                }
            }
        }

        // Fields and methods
        if (type.fields != null && type.fields.length > 0) {
            var publicStaticFields = type.fields.filter(f -> f.isStatic && f.isPublic);
            var publicInstanceFields = type.fields.filter(f -> !f.isStatic && f.isPublic);
            var privateFields = type.fields.filter(f -> !f.isPublic);

            // Public static fields
            if (publicStaticFields.length > 0) {
                md.add('## Static Members\n\n');
                generatePublicFieldsMarkdown(md, publicStaticFields, type, apiData);
            }

            // Public instance fields
            if (publicInstanceFields.length > 0) {
                md.add('## Instance Members\n\n');
                generatePublicFieldsMarkdown(md, publicInstanceFields, type, apiData);
            }

            // Private fields (both static and instance)
            if (privateFields.length > 0) {
                md.add('## Private Members\n\n');
                generatePrivateFieldsMarkdown(md, privateFields, type, apiData);
            }
        }

        // Metadata
        if (type.meta != null && type.meta.length > 0) {
            var relevantMeta = type.meta.filter(m -> !isInternalMeta(m.name));
            if (relevantMeta.length > 0) {
                md.add('## Metadata\n\n');
                md.add('| Name | Parameters |\n');
                md.add('|------|------------|\n');
                for (meta in relevantMeta) {
                    md.add('| `${meta.name}` | ');
                    if (meta.params != null && meta.params.length > 0) {
                        md.add(meta.params.join(", "));
                    } else {
                        md.add('-');
                    }
                    md.add(' |\n');
                }
                md.add('\n');
            }
        }

        return md.toString();
    }

    function buildInheritanceChain(type:ApiType, apiData:ApiData):Array<String> {
        var chain = [];
        var currentType = type;

        while (currentType != null && currentType.superClass != null) {
            var superPath = currentType.superClass.path;
            chain.push(superPath);

            // Find the super type in apiData
            currentType = null;
            for (t in apiData.types) {
                if (t.path == superPath) {
                    currentType = t;
                    break;
                }
            }
        }

        // Reverse to have base class first
        chain.reverse();
        chain.push(type.path);

        return chain;
    }

    function generatePublicFieldsMarkdown(md:StringBuf, fields:Array<Field>, type:ApiType, apiData:ApiData):Void {
        // Separate plugin fields from regular fields
        var regularFields = [];
        var pluginFields = new Map<String, Array<Field>>();

        // Check if the type itself is in a plugin folder
        var typePluginName:Null<String> = null;
        if (type.file != null && type.file.indexOf("/plugins/") != -1) {
            var pluginIndex = type.file.indexOf("/plugins/");
            var afterPlugins = type.file.substring(pluginIndex + 9); // Skip "/plugins/"
            var slashIndex = afterPlugins.indexOf("/");
            if (slashIndex > 0) {
                typePluginName = afterPlugins.substring(0, slashIndex);
                // Keep plugin name in lowercase
            }
        }

        // Check for specific git submodules that should show plugin names
        if (typePluginName == null && type.file != null && type.file.indexOf("/git/") != -1) {
            var gitIndex = type.file.indexOf("/git/");
            var afterGit = type.file.substring(gitIndex + 5); // Skip "/git/"
            var slashIndex = afterGit.indexOf("/");
            if (slashIndex > 0) {
                var gitName = afterGit.substring(0, slashIndex);
                // Map specific git submodules to plugin names
                typePluginName = switch (gitName) {
                    case "arcade": "arcade";
                    case "spine-hx": "spine";
                    case "gif": "gif";
                    case "nape": "nape";
                    case _: null;
                }
            }
        }

        for (field in fields) {
            if (shouldSkipField(field)) continue;

            // Check for @:plugin metadata
            var pluginName:Null<String> = null;
            for (meta in field.meta) {
                if (meta.name == ":plugin" && meta.params != null && meta.params.length > 0) {
                    var param = meta.params[0];
                    if (param != null) {
                        pluginName = StringTools.replace(param, '"', '');
                        pluginName = StringTools.replace(pluginName, "'", '');
                    }
                    break;
                }
            }

            // If no @:plugin metadata but type is in a plugin folder, use that plugin name
            if (pluginName == null && typePluginName != null) {
                pluginName = typePluginName;
            }

            if (pluginName != null) {
                // Add to plugin fields
                if (!pluginFields.exists(pluginName)) {
                    pluginFields.set(pluginName, []);
                }
                pluginFields.get(pluginName).push(field);
            } else {
                // Add to regular fields
                regularFields.push(field);
            }
        }

        // Generate regular fields first
        var regularProperties = regularFields.filter(f -> f.type != null && f.type.kind.match(FVar));
        var regularMethods = regularFields.filter(f -> f.type != null && f.type.kind.match(FMethod));

        // Properties
        for (i in 0...regularProperties.length) {
            generateFieldMarkdown(md, regularProperties[i], type, false, null, apiData);
            if (i < regularProperties.length - 1 || regularMethods.length > 0) {
                md.add('<hr class="field-separator" />\n\n');
            }
        }

        // Methods
        for (i in 0...regularMethods.length) {
            generateFieldMarkdown(md, regularMethods[i], type, false, null, apiData);
            if (i < regularMethods.length - 1) {
                md.add('<hr class="field-separator" />\n\n');
            }
        }

        // Add separator between regular fields and plugin fields if needed
        if ((regularProperties.length > 0 || regularMethods.length > 0) && pluginFields.keys().hasNext()) {
            md.add('<hr class="field-separator" />\n\n');
        }

        // Generate plugin fields grouped by plugin
        var pluginNames = [for (name in pluginFields.keys()) name];
        pluginNames.sort(Reflect.compare);

        for (i in 0...pluginNames.length) {
            var pluginName = pluginNames[i];
            var pluginFieldList = pluginFields.get(pluginName);

            // Sort plugin fields by properties first, then methods
            var pluginProperties = pluginFieldList.filter(f -> f.type != null && f.type.kind.match(FVar));
            var pluginMethods = pluginFieldList.filter(f -> f.type != null && f.type.kind.match(FMethod));

            // Properties
            for (i in 0...pluginProperties.length) {
                generateFieldMarkdown(md, pluginProperties[i], type, false, pluginName, apiData);
                if (i < pluginProperties.length - 1 || pluginMethods.length > 0) {
                    md.add('<hr class="field-separator" />\n\n');
                }
            }

            // Methods
            for (i in 0...pluginMethods.length) {
                generateFieldMarkdown(md, pluginMethods[i], type, false, pluginName, apiData);
                if (i < pluginMethods.length - 1) {
                    md.add('<hr class="field-separator" />\n\n');
                }
            }

            // Add separator between different plugin groups
            if (i < pluginNames.length - 1) {
                md.add('<hr class="field-separator" />\n\n');
            }
        }
    }

    function generatePrivateFieldsMarkdown(md:StringBuf, fields:Array<Field>, type:ApiType, apiData:ApiData):Void {
        // Separate plugin fields from regular fields
        var regularFields = [];
        var pluginFields = new Map<String, Array<Field>>();

        // Check if the type itself is in a plugin folder
        var typePluginName:Null<String> = null;
        if (type.file != null && type.file.indexOf("/plugins/") != -1) {
            var pluginIndex = type.file.indexOf("/plugins/");
            var afterPlugins = type.file.substring(pluginIndex + 9); // Skip "/plugins/"
            var slashIndex = afterPlugins.indexOf("/");
            if (slashIndex > 0) {
                typePluginName = afterPlugins.substring(0, slashIndex);
                // Keep plugin name in lowercase
            }
        }

        // Check for specific git submodules that should show plugin names
        if (typePluginName == null && type.file != null && type.file.indexOf("/git/") != -1) {
            var gitIndex = type.file.indexOf("/git/");
            var afterGit = type.file.substring(gitIndex + 5); // Skip "/git/"
            var slashIndex = afterGit.indexOf("/");
            if (slashIndex > 0) {
                var gitName = afterGit.substring(0, slashIndex);
                // Map specific git submodules to plugin names
                typePluginName = switch (gitName) {
                    case "arcade": "arcade";
                    case "spine-hx": "spine";
                    case "gif": "gif";
                    case "nape": "nape";
                    case _: null;
                }
            }
        }

        for (field in fields) {
            if (shouldSkipField(field)) continue;

            // Check for @:plugin metadata
            var pluginName:Null<String> = null;
            for (meta in field.meta) {
                if (meta.name == ":plugin" && meta.params != null && meta.params.length > 0) {
                    var param = meta.params[0];
                    if (param != null) {
                        pluginName = StringTools.replace(param, '"', '');
                        pluginName = StringTools.replace(pluginName, "'", '');
                    }
                    break;
                }
            }

            // If no @:plugin metadata but type is in a plugin folder, use that plugin name
            if (pluginName == null && typePluginName != null) {
                pluginName = typePluginName;
            }

            if (pluginName != null) {
                // Add to plugin fields
                if (!pluginFields.exists(pluginName)) {
                    pluginFields.set(pluginName, []);
                }
                pluginFields.get(pluginName).push(field);
            } else {
                // Add to regular fields
                regularFields.push(field);
            }
        }

        // Generate regular fields first
        var regularProperties = regularFields.filter(f -> f.type != null && f.type.kind.match(FVar));
        var regularMethods = regularFields.filter(f -> f.type != null && f.type.kind.match(FMethod));

        // Properties
        for (i in 0...regularProperties.length) {
            generateFieldMarkdown(md, regularProperties[i], type, true, null, apiData);
            if (i < regularProperties.length - 1 || regularMethods.length > 0) {
                md.add('<hr class="field-separator" />\n\n');
            }
        }

        // Methods
        for (i in 0...regularMethods.length) {
            generateFieldMarkdown(md, regularMethods[i], type, true, null, apiData);
            if (i < regularMethods.length - 1) {
                md.add('<hr class="field-separator" />\n\n');
            }
        }

        // Add separator between regular fields and plugin fields if needed
        if ((regularProperties.length > 0 || regularMethods.length > 0) && pluginFields.keys().hasNext()) {
            md.add('<hr class="field-separator" />\n\n');
        }

        // Generate plugin fields grouped by plugin
        var pluginNames = [for (name in pluginFields.keys()) name];
        pluginNames.sort(Reflect.compare);

        for (i in 0...pluginNames.length) {
            var pluginName = pluginNames[i];
            var pluginFieldList = pluginFields.get(pluginName);

            // Sort plugin fields by properties first, then methods
            var pluginProperties = pluginFieldList.filter(f -> f.type != null && f.type.kind.match(FVar));
            var pluginMethods = pluginFieldList.filter(f -> f.type != null && f.type.kind.match(FMethod));

            // Properties
            for (i in 0...pluginProperties.length) {
                generateFieldMarkdown(md, pluginProperties[i], type, true, pluginName, apiData);
                if (i < pluginProperties.length - 1 || pluginMethods.length > 0) {
                    md.add('<hr class="field-separator" />\n\n');
                }
            }

            // Methods
            for (i in 0...pluginMethods.length) {
                generateFieldMarkdown(md, pluginMethods[i], type, true, pluginName, apiData);
                if (i < pluginMethods.length - 1) {
                    md.add('<hr class="field-separator" />\n\n');
                }
            }

            // Add separator between different plugin groups
            if (i < pluginNames.length - 1) {
                md.add('<hr class="field-separator" />\n\n');
            }
        }
    }

    function generateFieldMarkdown(md:StringBuf, field:Field, type:ApiType, isPrivate:Bool, ?pluginName:String = null, ?apiData:ApiData = null):Void {
        // Determine field type class and if it has description
        var fieldTypeClass = field.type.kind.match(FVar) ? "field-var" : "field-method";
        var hasDescription = field.doc != null && StringTools.trim(field.doc) != "";
        var descriptionClass = hasDescription ? "has-description" : "no-description";

        // Generate header with HTML code signature
        var pluginClass = pluginName != null ? " has-plugin" : "";
        md.add('<div class="signature ${fieldTypeClass} ${descriptionClass}${pluginClass}" id="${field.name}">');

        // Add plugin indicator inside signature if provided
        if (pluginName != null) {
            md.add('<div class="plugin-name">$pluginName</div>');
        }

        // Generate the signature with span wrapping
        if (field.type.kind.match(FVar) && field.type != null && field.type.type != null) {
            md.add('<code>');
            md.add('<span class="field-name">${field.name}</span>');
            md.add('<span class="operator">:</span> ');
            md.add(formatTypePathForHtmlWithSpans(field.type.type, type.path));
            md.add('</code>');
        } else if (field.type.kind.match(FMethod)) {
            // Format method header with full signature in HTML
            md.add('<code>');
            md.add(formatMethodSignatureHtmlWithSpans(field, type.path));
            md.add('</code>');
        } else {
            md.add('<code><span class="field-name">${field.name}</span></code>');
        }

        md.add('<a class="header-anchor" href="#${field.name}"><span aria-hidden="true" class="header-anchor__symbol">#</span></a>');
        md.add('</div>\n\n');

        if (field.type.kind.match(FVar)) {
            // Variable/Property - skip signature code block since type is in header
            if (field.doc != null && field.doc != "") {
                md.add(formatDocumentation(field.doc, type.path, apiData) + '\n\n');
            }
        } else if (field.type.kind.match(FMethod)) {
            // Skip method signature code block - it's now in the header

            // Don't show Returns section here - it will be shown after the description

            // Method documentation
            if (field.doc != null && field.doc != "") {
                // Strip parameter and return docs when they'll be shown in table
                var processedDoc = field.doc;
                var hasParams = field.type != null && field.type.args != null && field.type.args.length > 0;
                var hasReturn = field.type != null && field.type.ret != null && !isVoidType(field.type.ret);

                if (hasParams || hasReturn) {
                    processedDoc = stripParameterDocs(field.doc);
                }
                if (processedDoc != null && processedDoc != "") {
                    md.add(formatDocumentation(processedDoc, type.path, apiData));
                    // Only add double newline if there are no params or returns
                    if (!hasParams && !hasReturn) {
                        md.add('\n\n');
                    } else {
                        md.add('\n');
                    }
                }
            }

            // Parameters table (after documentation)
            var hasParams = field.type != null && field.type.args != null && field.type.args.length > 0;

            if (hasParams) {
                // Check if any parameters have defaults or descriptions
                var hasDefaults = false;
                var hasDescriptions = false;

                for (arg in field.type.args) {
                    if (arg.opt && (arg.value != null || arg.opt)) {
                        hasDefaults = true;
                    }
                    if (field.doc != null && extractParamDoc(field.doc, arg.name) != null) {
                        hasDescriptions = true;
                    }
                }

                // Build table header based on what columns are needed
                md.add('\n| Name | Type');
                if (hasDefaults) md.add(' | Default');
                if (hasDescriptions) md.add(' | Description');
                md.add(' |\n');

                md.add('|------|------');
                if (hasDefaults) md.add('|---------');
                if (hasDescriptions) md.add('|-------------');
                md.add('|\n');

                for (arg in field.type.args) {
                    md.add('| `${arg.name}` ');
                    md.add('| ${formatTypePathWithContext(arg.type, type.path)} ');

                    if (hasDefaults) {
                        if (arg.opt && arg.value != null) {
                            md.add('| `${arg.value}` ');
                        } else if (arg.opt) {
                            md.add('| *(optional)* ');
                        } else {
                            md.add('| ');
                        }
                    }

                    if (hasDescriptions) {
                        md.add('| ');
                        // Extract parameter description from doc if available
                        if (field.doc != null) {
                            var paramDoc = extractParamDoc(field.doc, arg.name);
                            if (paramDoc != null) {
                                md.add(paramDoc);
                            }
                        }
                        md.add(' ');
                    }

                    md.add('|\n');
                }

                md.add('\n');
            }

            // Returns table (separate from parameters)
            var hasReturn = field.type != null && field.type.ret != null && !isVoidType(field.type.ret);

            if (hasReturn) {
                // Check if there's a return description
                var returnDoc = field.doc != null ? extractReturnDoc(field.doc) : null;
                var hasReturnDescription = returnDoc != null && returnDoc != "";

                if (hasReturnDescription) {
                    md.add('| Returns | Description |\n');
                    md.add('|---------|-------------|\n');
                    md.add('| ${formatTypePathWithContext(field.type.ret, type.path)} | ${returnDoc} |\n\n');
                } else {
                    md.add('| Returns |\n');
                    md.add('|---------|\n');
                    md.add('| ${formatTypePathWithContext(field.type.ret, type.path)} |\n\n');
                }
            }
        }
    }

    function shouldSkipField(field:Field):Bool {
        // Skip fields with @:dox(hide) or @:noCompletion
        for (meta in field.meta) {
            if (meta.name == ":dox" && meta.params != null && meta.params.length > 0 && meta.params[0] == "hide") {
                return true;
            }
            if (meta.name == ":noCompletion") {
                return true;
            }
        }

        // Skip internal fields starting with underscore
        if (StringTools.startsWith(field.name, "_")) {
            return true;
        }

        // Skip getter/setter methods
        if (StringTools.startsWith(field.name, "get_") || StringTools.startsWith(field.name, "set_")) {
            return true;
        }

        return false;
    }

    function formatFunctionArgs(args:Array<FunctionArg>, createLink:Bool = true):String {
        return formatFunctionArgsWithContext(args, null, createLink);
    }

    function formatFunctionArgsWithContext(args:Array<FunctionArg>, currentTypePath:String, createLink:Bool = true):String {
        var parts = [];

        for (arg in args) {
            var part = "";
            if (arg.opt) part += "?";
            part += arg.name;
            part += ": " + formatTypePathWithContext(arg.type, currentTypePath, createLink);
            if (arg.value != null) {
                part += " = " + arg.value;
            }
            parts.push(part);
        }

        return parts.join(", ");
    }

    function formatTypePathWithContext(tp:TypePath, currentTypePath:String, createLink:Bool = true):String {
        if (tp == null) return "Unknown";

        var path = tp.path;
        var result = "";

        // Check if this is a generic type parameter (e.g., someMethod.T or Class<method.T>)
        var isGenericParam = false;
        if (path.indexOf(".") != -1) {
            var parts = path.split(".");
            var lastPart = parts[parts.length - 1];
            // If the last part is a single uppercase letter, it's likely a generic parameter
            if (lastPart.length == 1 && lastPart == lastPart.toUpperCase()) {
                isGenericParam = true;
            }
        }

        // Types that we shouldn't link (truly special types)
        var noLinkTypes = ["Unknown", "Function", "Anonymous", "AnonStruct"];
        var shouldNotLink = noLinkTypes.indexOf(path) != -1 || isGenericParam;

        if (createLink && !shouldNotLink) {
            // Use permalink format
            var permalink = '/api-docs/${target}/${path.split(".").join("/")}/';

            // Determine display name (omit package if same)
            var displayName = path;
            if (currentTypePath != null) {
                var currentParts = currentTypePath.split(".");
                var targetParts = path.split(".");

                // Check if same package (all parts except last match)
                if (currentParts.length > 1 && targetParts.length > 1 &&
                    currentParts.slice(0, -1).join(".") == targetParts.slice(0, -1).join(".")) {
                    // Same package, just show type name
                    displayName = targetParts[targetParts.length - 1];
                }
            }

            result = '[$displayName]($permalink)';
        } else {
            result = path;
        }

        if (tp.params != null && tp.params.length > 0) {
            result += "<";
            result += tp.params.map(p -> formatTypePathWithContext(p, currentTypePath, createLink)).join(", ");
            result += ">";
        }

        return result;
    }

    function formatTypePath(tp:TypePath, createLink:Bool = true):String {
        return formatTypePathWithContext(tp, null, createLink);
    }

    function stripParameterDocs(doc:String):String {
        if (doc == null) return null;

        // First, handle multi-line @param tags with continuation lines
        // This regex matches @param tags and all their continuation lines (indented lines following the tag)
        var paramRegex = ~/@param\s+\w+\s+[^\n]+(?:\n\s*(?:\*\s*)?\s+[^\n@]+)*/g;
        doc = paramRegex.replace(doc, "");

        // Handle multi-line @return/returns tags
        var returnRegex = ~/@returns?\s+[^\n]+(?:\n\s*(?:\*\s*)?\s+[^\n@]+)*/g;
        doc = returnRegex.replace(doc, "");

        // Handle multi-line @throws tags
        var throwsRegex = ~/@throws\s+[^\n]+(?:\n\s*(?:\*\s*)?\s+[^\n@]+)*/g;
        doc = throwsRegex.replace(doc, "");

        // Remove formatted parameter docs (- **paramName**: description)
        // This might also span multiple lines
        doc = ~/^(\s*)-\s*\*\*\w+\*\*:\s*[^\n]+(?:\n\s+[^\n-]+)*/gm.replace(doc, "");

        // Remove formatted returns docs (**Returns:** description)
        doc = ~/\*\*Returns:\*\*\s*[^\n]+/g.replace(doc, "");

        // Clean up any leftover indented lines that were part of removed content
        // This handles cases where continuation lines might be orphaned
        var lines = doc.split("\n");
        var cleanedLines = [];
        var previousLineRemoved = false;

        for (i in 0...lines.length) {
            var line = lines[i];
            var trimmed = StringTools.trim(line);

            // Check if this looks like a continuation line (heavily indented with content)
            var leadingSpaces = line.length - StringTools.ltrim(line).length;
            var looksLikeContinuation = leadingSpaces >= 10 && trimmed.length > 0 &&
                                        !StringTools.startsWith(trimmed, "*") &&
                                        !StringTools.startsWith(trimmed, "@");

            // Skip lines that look like orphaned continuation lines
            if (previousLineRemoved && looksLikeContinuation) {
                continue;
            }

            // Keep the line
            cleanedLines.push(line);
            previousLineRemoved = false;
        }

        doc = cleanedLines.join("\n");

        // Clean up extra blank lines that might result
        doc = ~/\n\s*\n\s*\n+/g.replace(doc, "\n\n");
        doc = StringTools.trim(doc);

        return doc;
    }

    function extractReturnDoc(doc:String):Null<String> {
        if (doc == null) return null;

        // Look for @return documentation
        var regex = new EReg('@return\\s+(.+?)(?=@|$)', 's');
        if (regex.match(doc)) {
            var desc = regex.matched(1);
            // Clean up the description
            desc = StringTools.trim(desc);
            desc = ~/\s*\n\s*\*\s*/g.replace(desc, " ");
            desc = ~/\s+/g.replace(desc, " ");
            return desc;
        }

        // Also check for formatted return docs (after conversion)
        var formattedRegex = new EReg('\\*\\*Returns:\\*\\*\\s*(.+?)(?=\\n|$)', '');
        if (formattedRegex.match(doc)) {
            return StringTools.trim(formattedRegex.matched(1));
        }

        return null;
    }

    function extractParamDoc(doc:String, paramName:String):Null<String> {
        if (doc == null) return null;

        // Look for @param documentation
        var regex = new EReg('@param\\s+' + paramName + '\\s+(.+?)(?=@|$)', 's');
        if (regex.match(doc)) {
            var desc = regex.matched(1);
            // Clean up the description
            desc = StringTools.trim(desc);
            desc = ~/\s*\n\s*\*\s*/g.replace(desc, " ");
            desc = ~/\s+/g.replace(desc, " ");
            return desc;
        }

        // Also check for formatted parameter docs (after conversion)
        var formattedRegex = new EReg('- \\*\\*' + paramName + '\\*\\*: (.+?)(?=\\n|$)', '');
        if (formattedRegex.match(doc)) {
            return StringTools.trim(formattedRegex.matched(1));
        }

        return null;
    }

    function formatDocumentation(doc:String, ?currentTypePath:String = null, ?apiData:ApiData = null):String {
        // Clean up documentation
        doc = StringTools.trim(doc);

        // Convert tabs to spaces
        doc = StringTools.replace(doc, "\t", "    ");

        // Remove JavaDoc-style comment prefixes and normalize indentation
        var lines = doc.split("\n");
        var cleanedLines = [];
        var minIndent = 999999; // Track minimum indentation after removing JavaDoc markers

        // First pass: remove JavaDoc markers and find minimum indentation
        for (line in lines) {
            // Remove leading whitespace and optional * prefix
            var cleaned = ~/^\s*\*?\s?/.replace(line, "");
            cleanedLines.push(cleaned);

            // Track minimum indentation of non-empty lines
            if (StringTools.trim(cleaned).length > 0) {
                var leadingSpaces = cleaned.length - StringTools.ltrim(cleaned).length;
                if (leadingSpaces < minIndent) {
                    minIndent = leadingSpaces;
                }
            }
        }

        // Second pass: remove the common indentation from all lines
        if (minIndent > 0 && minIndent < 999999) {
            for (i in 0...cleanedLines.length) {
                var line = cleanedLines[i];
                if (StringTools.trim(line).length > 0) {
                    // Remove the common indentation
                    if (line.length >= minIndent) {
                        cleanedLines[i] = line.substring(minIndent);
                    }
                } else {
                    // Keep empty lines as empty
                    cleanedLines[i] = "";
                }
            }
        }

        doc = cleanedLines.join("\n");

        // Process and remove all @param, @return, @throws, @returns tags
        // These are handled in parameter tables, so we need to remove them entirely

        // First pass: Identify and remove @param/@return/@throws blocks completely
        var lines = doc.split("\n");
        var processedLines = [];
        var inParamBlock = false;

        for (i in 0...lines.length) {
            var line = lines[i];
            var trimmed = StringTools.trim(line);

            // Check if this line starts a @param, @return, @returns, or @throws
            if (~/^\s*@(param|returns?|throws)\s+/.match(line)) {
                inParamBlock = true;
                continue;
            }

            // If we're in a param block
            if (inParamBlock) {
                // Check if this line starts a new @ tag (ends the param block)
                if (~/^\s*@\w+/.match(line)) {
                    inParamBlock = false;
                    // Process this line normally (it's a new tag)
                }
                // Check if this is an empty line (ends the param block)
                else if (trimmed == "") {
                    inParamBlock = false;
                    processedLines.push(line);
                    continue;
                }
                // Check if this line is indented (continuation of param block)
                else if (line.length > 0 && line.charAt(0) == " ") {
                    // This is a continuation line - skip it
                    continue;
                }
                // This line starts at column 0, so it's a new paragraph
                else {
                    inParamBlock = false;
                    // Process this line normally
                }
            }

            // Keep the line if we're not in a param block
            if (!inParamBlock) {
                processedLines.push(line);
            }
        }

        doc = processedLines.join("\n");

        // Process @see tags - each on its own line
        var seeMatches = [];
        var seeRegex = ~/@see\s+([^\n@]+)/g;
        var pos = 0;
        while (seeRegex.matchSub(doc, pos)) {
            seeMatches.push(StringTools.trim(seeRegex.matched(1)));
            pos = seeRegex.matchedPos().pos + seeRegex.matchedPos().len;
        }

        // Remove all @see tags first
        doc = ~/@see\s+[^\n@]+/g.replace(doc, "");

        // Add them back formatted at the end
        if (seeMatches.length > 0) {
            doc = StringTools.trim(doc);
            if (doc != "") doc += "\n\n";
            
            // Format all see references
            var formattedSees = [];
            for (see in seeMatches) {
                formattedSees.push(formatSeeReference(see, currentTypePath, apiData));
            }
            
            // Join with commas
            doc += '<div class="see"><strong>See:</strong> ' + formattedSees.join(', ') + '</div>\n';
        }
        doc = ~/@throws\s+(.+)/g.replace(doc, "**Throws:** $1");
        doc = ~/@since\s+(.+)/g.replace(doc, "**Since:** $1");
        doc = ~/@deprecated\s+(.+)/g.replace(doc, "**Deprecated:** $1");

        // Escape > and < when they appear after - in lists to prevent markdown interpretation
        doc = ~/^(\s*-\s*)([<>])/gm.replace(doc, "$1\\$2");

        // Clean up lines that are just asterisks and empty space (from JavaDoc)
        lines = doc.split("\n");
        var cleanedLines = [];
        for (line in lines) {
            // Skip lines that are just asterisks and whitespace
            var cleanedLine = StringTools.replace(line, "*", "");
            if (StringTools.trim(cleanedLine).length > 0 || line == "") {
                cleanedLines.push(line);
            }
        }
        doc = cleanedLines.join("\n");

        // Remove unnecessary indentation from non-code/non-list paragraphs
        lines = doc.split("\n");
        var processedLines = [];
        var inCodeBlock = false;
        var previousLineWasEmpty = false;

        for (i in 0...lines.length) {
            var line = lines[i];
            var trimmedLine = StringTools.ltrim(line);

            // Check for code block markers
            if (StringTools.startsWith(trimmedLine, "```")) {
                inCodeBlock = !inCodeBlock;
                processedLines.push(line);
                previousLineWasEmpty = false;
                continue;
            }

            if (inCodeBlock) {
                processedLines.push(line);
                previousLineWasEmpty = false;
                continue;
            }

            // Check if this is a list item
            var leadingSpaces = line.length - trimmedLine.length;
            var isList = ~/^[\*\-\+]\s/.match(trimmedLine) || ~/^\d+\.\s/.match(trimmedLine);

            // For potential code blocks, require 4+ spaces, preceding blank line, and code-like content
            var isIndentedCode = false;
            if (leadingSpaces >= 4 && trimmedLine.length > 0 && previousLineWasEmpty) {
                // Check if content looks like code
                var codePatterns = [
                    ~/^(var|function|if|for|while|return|class|interface|enum|import|package)\s/,
                    ~/[{}();]/,
                    ~/^\w+\s*[:=]/,
                    ~/^\w+\.\w+/,
                    ~/^\/\//  // Comments
                ];

                for (pattern in codePatterns) {
                    if (pattern.match(trimmedLine)) {
                        isIndentedCode = true;
                        break;
                    }
                }
            }

            if (isList) {
                processedLines.push(line);
                previousLineWasEmpty = false;
            } else if (isIndentedCode) {
                // This is likely code, keep the indentation
                processedLines.push(line);
                previousLineWasEmpty = false;
            } else if (trimmedLine.length == 0) {
                processedLines.push("");
                previousLineWasEmpty = true;
            } else {
                // Regular paragraph text - remove ALL indentation
                processedLines.push(trimmedLine);
                previousLineWasEmpty = false;
            }
        }

        doc = processedLines.join("\n");

        // Ensure proper line breaks
        doc = ~/\n\s*\n\s*\n/g.replace(doc, "\n\n");

        // Trim trailing whitespace from each line
        lines = doc.split("\n");
        for (i in 0...lines.length) {
            lines[i] = StringTools.rtrim(lines[i]);
        }
        doc = lines.join("\n");

        return doc;
    }

    function getTypeTitle(type:ApiType):String {
        var parts = type.path.split(".");
        return parts[parts.length - 1];
    }

    function getPackagePath(fullPath:String):String {
        var parts = fullPath.split(".");
        if (parts.length > 1) {
            parts.pop();
            return parts.join(".");
        }
        return "";
    }

    function getShortFilePath(fullPath:String):String {
        // Try to shorten the file path by removing common prefixes
        var patterns = [
            ~/.*\/ceramic\//,
            ~/.*\/haxe\/std\//,
            ~/.*\/src\//
        ];

        for (pattern in patterns) {
            if (pattern.match(fullPath)) {
                return pattern.matchedRight();
            }
        }

        return fullPath;
    }

    function getTypeKindString(type:ApiType):String {
        var kind = switch (type.kind) {
            case TClass: type.isInterface ? "Interface" : "Class";
            case TInterface: "Interface";
            case TEnum: "Enum";
            case TTypedef: "Typedef";
            case TAbstract: "Abstract";
        };

        var modifiers = [];
        if (type.isExtern) modifiers.push("extern");
        if (type.isFinal) modifiers.push("final");
        if (type.isPrivate) modifiers.push("private");

        if (modifiers.length > 0) {
            return modifiers.join(" ") + " " + kind.toLowerCase();
        }

        return kind;
    }

    function isVoidType(tp:TypePath):Bool {
        return tp != null && tp.path == "Void";
    }

    function isInternalMeta(name:String):Bool {
        var internal = [
            ":keep", ":coreApi", ":coreType", ":native",
            ":directlyUsed", ":used", ":buildXml", ":valueUsed",
            ":runtimeValue", ":noCompletion", ":dox"
        ];
        return internal.indexOf(name) != -1;
    }

    function formatMethodSignature(field:Field, currentPackage:String):String {
        if (!field.type.kind.match(FMethod) || field.type.args == null) {
            return '${field.name}()';
        }

        var args = formatMethodArgs(field.type.args, currentPackage);
        var ret = field.type.ret != null ? formatTypePathWithContext(field.type.ret, currentPackage, true) : "Void";
        return '${field.name}($args): $ret';
    }

    function formatMethodArgs(args:Array<FunctionArg>, currentPackage:String):String {
        return args.map(arg -> {
            var s = arg.opt ? '?' : '';
            s += arg.name + ': ';
            s += formatTypePathWithContext(arg.type, currentPackage, true);
            if (arg.value != null && StringTools.trim(arg.value) != '') {
                s += ' = ' + arg.value;
            }
            return s;
        }).join(', ');
    }

    function formatMethodSignatureHtml(field:Field, currentPackage:String):String {
        if (!field.type.kind.match(FMethod) || field.type.args == null) {
            return '${field.name}()';
        }

        var args = formatMethodArgsHtml(field.type.args, currentPackage);
        var ret = field.type.ret != null ? formatTypePathForHtml(field.type.ret, currentPackage) : "Void";
        return '${field.name}($args): $ret';
    }

    function formatMethodArgsHtml(args:Array<FunctionArg>, currentPackage:String):String {
        return args.map(arg -> {
            var s = arg.opt ? '?' : '';
            s += arg.name + ': ';
            s += formatTypePathForHtml(arg.type, currentPackage);
            if (arg.value != null && StringTools.trim(arg.value) != '') {
                s += ' = ' + arg.value;
            }
            return s;
        }).join(', ');
    }

    function formatTypePathForHtml(tp:TypePath, currentTypePath:String):String {
        if (tp == null) return "Unknown";

        var path = tp.path;
        var result = "";

        // Check if this is a generic type parameter
        var isGenericParam = false;
        if (path.indexOf(".") != -1) {
            var parts = path.split(".");
            var lastPart = parts[parts.length - 1];
            if (lastPart.length == 1 && lastPart == lastPart.toUpperCase()) {
                isGenericParam = true;
            }
        }

        // Types that we shouldn't link (truly special types)
        var noLinkTypes = ["Unknown", "Function", "Anonymous", "AnonStruct"];
        var shouldNotLink = noLinkTypes.indexOf(path) != -1 || isGenericParam;

        if (!shouldNotLink) {
            // Use permalink format
            var permalink = '/api-docs/${target}/${path.split(".").join("/")}/';

            // Determine display name (omit package if same)
            var displayName = path;
            if (currentTypePath != null) {
                var currentParts = currentTypePath.split(".");
                var targetParts = path.split(".");

                // Check if same package
                if (currentParts.length > 1 && targetParts.length > 1 &&
                    currentParts.slice(0, -1).join(".") == targetParts.slice(0, -1).join(".")) {
                    // Same package, just show type name
                    displayName = targetParts[targetParts.length - 1];
                }
            }

            result = '<a href="$permalink">$displayName</a>';
        } else {
            result = path;
        }

        if (tp.params != null && tp.params.length > 0) {
            result += "&lt;";
            result += tp.params.map(p -> formatTypePathForHtml(p, currentTypePath)).join(", ");
            result += "&gt;";
        }

        return result;
    }

    function getMenuGroup(type:ApiType):String {
        var path = type.path;

        // Check if it's a built-in Haxe type
        if (isBuiltinHaxeType(type)) {
            return "Haxe";
        }

        // Check if it's from a git submodule
        if (type.file != null && type.file.indexOf("/git/") != -1) {
            // Extract submodule name from file path
            var gitIndex = type.file.indexOf("/git/");
            var afterGit = type.file.substring(gitIndex + 5); // Skip "/git/"
            var slashIndex = afterGit.indexOf("/");
            if (slashIndex > 0) {
                var gitName = afterGit.substring(0, slashIndex);
                // Skip haxe-binary as it's for built-in Haxe types
                if (gitName == "haxe-binary") {
                    return "Haxe";
                }
                // Format the name nicely
                return formatGroupName(gitName);
            }
        }

        // Check if it's a plugin type by examining the file path
        if (type.file != null && type.file.indexOf("/plugins/") != -1) {
            // Extract plugin name from file path
            var pluginIndex = type.file.indexOf("/plugins/");
            var afterPlugins = type.file.substring(pluginIndex + 9); // Skip "/plugins/"
            var slashIndex = afterPlugins.indexOf("/");
            if (slashIndex > 0) {
                var pluginName = afterPlugins.substring(0, slashIndex);
                // Capitalize first letter
                return pluginName.charAt(0).toUpperCase() + pluginName.substring(1);
            }
        }

        // Group by package prefix for remaining types
        if (StringTools.startsWith(path, "ceramic.")) {
            return "Ceramic";
        } else if (StringTools.startsWith(path, "backend.")) {
            return "Backend";
        } else if (StringTools.startsWith(path, "spec.")) {
            return "Spec";
        }

        // Default group
        return "Other";
    }

    function formatGroupName(name:String):String {
        // Handle special cases
        return switch (name) {
            case "linc_opengl": "OpenGL";
            case "linc_soloud": "Soloud";
            case "linc_stb": "Stb";
            case "linc_timestamp": "Timestamp";
            case "linc_dialogs": "Dialogs";
            case "spine-hx": "Spine";
            case "format-tiled": "Tiled";
            case "bin-packing": "BinPacking";
            case _:
                // Default: capitalize first letter
                name.charAt(0).toUpperCase() + name.substring(1);
        }
    }

    function isBuiltinHaxeType(type:ApiType):Bool {
        if (type.file != null &&
            (type.file.indexOf("/haxe/std/") != -1 ||
             type.file.indexOf("\\haxe\\std\\") != -1 ||
             type.file.indexOf("/haxe-binary/") != -1)) {
            return true;
        }

        var builtinTypes = [
            "Any", "Array", "Bool", "Class", "Date", "Dynamic", "EReg",
            "Enum", "EnumValue", "Float", "Int", "Iterable", "Iterator",
            "Map", "Math", "Null", "Reflect", "Std", "String", "StringBuf",
            "StringTools", "Sys", "Type", "UInt", "Void", "Xml"
        ];

        return builtinTypes.indexOf(type.path) != -1;
    }

    function formatTargetName(target:String):String {
        return switch (target) {
            case "clay-native": "Clay (Native)";
            case "clay-web": "Clay (Web)";
            case "headless": "Headless";
            case "unity": "Unity";
            case _: target;
        }
    }

    function getMarkdownPermalink(type:ApiType):String {
        // Convert type path to URL-friendly format
        return type.path.split(".").join("/");
    }

    function formatTypePathWithContextHtml(tp:TypePath, currentTypePath:Null<String>):String {
        var path = tp.path;
        var result = "";

        // Check if this should have a link
        var isGenericParam = false;
        if (path.indexOf(".") != -1) {
            var parts = path.split(".");
            var lastPart = parts[parts.length - 1];
            if (lastPart.length == 1 && lastPart == lastPart.toUpperCase()) {
                isGenericParam = true;
            }
        }

        var noLinkTypes = ["Unknown", "Function", "Anonymous", "AnonStruct"];
        var shouldNotLink = noLinkTypes.indexOf(path) != -1 || isGenericParam;

        if (!shouldNotLink) {
            // Use permalink format
            var permalink = buildRelativePath(path, currentTypePath);

            // Determine display name
            var displayName = getDisplayName(path, currentTypePath);

            result = '<a href="$permalink">$displayName</a>';
        } else {
            result = path;
        }

        if (tp.params != null && tp.params.length > 0) {
            result += "&lt;";
            result += tp.params.map(p -> formatTypePathWithContextHtml(p, currentTypePath)).join(", ");
            result += "&gt;";
        }

        return result;
    }

    function formatTypePathForHtmlWithSpans(tp:TypePath, currentTypePath:Null<String>):String {
        var path = tp.path;
        var result = "";

        // Check if this should have a link
        var isGenericParam = false;
        if (path.indexOf(".") != -1) {
            var parts = path.split(".");
            var lastPart = parts[parts.length - 1];
            if (lastPart.length == 1 && lastPart == lastPart.toUpperCase()) {
                isGenericParam = true;
            }
        }

        var noLinkTypes = ["Unknown", "Function", "Anonymous", "AnonStruct"];
        var shouldNotLink = noLinkTypes.indexOf(path) != -1 || isGenericParam;

        if (!shouldNotLink) {
            var relativePath = buildRelativePath(path, currentTypePath);
            var displayName = getDisplayName(path, currentTypePath);
            result = '<a href="$relativePath" class="type-link">$displayName</a>';
        } else {
            result = '<span class="type-name">$path</span>';
        }

        if (tp.params != null && tp.params.length > 0) {
            result += '<span class="operator">&lt;</span>';
            var paramStrs = [];
            for (p in tp.params) {
                paramStrs.push(formatTypePathForHtmlWithSpans(p, currentTypePath));
            }
            result += paramStrs.join('<span class="operator">,</span> ');
            result += '<span class="operator">&gt;</span>';
        }

        return result;
    }

    function formatMethodSignatureHtmlWithSpans(field:Field, currentTypePath:String):String {
        var result = '<span class="field-name">${field.name}</span>';
        result += '<span class="parenthesis">(</span>';

        if (field.type != null && field.type.args != null && field.type.args.length > 0) {
            var argStrs = [];
            for (arg in field.type.args) {
                var argStr = "";
                if (arg.opt) {
                    argStr += '<span class="operator">?</span>';
                }
                argStr += '<span class="arg-name">${arg.name}</span>';
                argStr += '<span class="operator">:</span> ';
                argStr += formatTypePathForHtmlWithSpans(arg.type, currentTypePath);
                if (arg.value != null) {
                    argStr += ' <span class="operator">=</span> <span class="default-value">${arg.value}</span>';
                }
                argStrs.push(argStr);
            }
            result += argStrs.join('<span class="operator">,</span> ');
        }

        result += '<span class="parenthesis">)</span>';

        if (field.type != null && field.type.ret != null) {
            result += '<span class="operator">:</span> ';
            result += formatTypePathForHtmlWithSpans(field.type.ret, currentTypePath);
        }

        return result;
    }

    function buildRelativePath(targetPath:String, currentTypePath:Null<String>):String {
        if (targetPath == currentTypePath) return "#";

        // Use permalink format: /api-docs/{target}/{type-path}/
        return '/api-docs/${target}/${targetPath.split(".").join("/")}/';
    }

    function getDisplayName(path:String, currentTypePath:Null<String>):String {
        if (currentTypePath == null) return path;

        var currentParts = currentTypePath.split(".");
        var targetParts = path.split(".");

        if (currentParts.length > 1 && targetParts.length > 1 &&
            currentParts.slice(0, -1).join(".") == targetParts.slice(0, -1).join(".")) {
            return targetParts[targetParts.length - 1];
        }

        return path;
    }

    function formatSeeReference(see:String, currentTypePath:String, apiData:ApiData):String {
        if (currentTypePath == null || apiData == null) {
            return see;
        }

        // Check if this looks like a type reference (starts with uppercase or contains dots)
        var firstChar = see.charAt(0);
        var looksLikeType = (firstChar == firstChar.toUpperCase() && firstChar.toLowerCase() != firstChar) || see.indexOf(".") != -1;

        if (!looksLikeType) {
            return see;
        }

        // Try to resolve the type
        var typePath = see;
        var typeExists = false;

        // If no package, try current package first
        if (see.indexOf(".") == -1 && currentTypePath != null) {
            var currentParts = currentTypePath.split(".");
            if (currentParts.length > 1) {
                var currentPackage = currentParts.slice(0, -1).join(".");
                var possiblePath = currentPackage + "." + see;

                // Check if this type exists
                for (type in apiData.types) {
                    if (type.path == possiblePath) {
                        typePath = possiblePath;
                        typeExists = true;
                        break;
                    }
                }
            }
        }

        // If not found in current package, check as top-level type
        if (!typeExists) {
            for (type in apiData.types) {
                if (type.path == see) {
                    typePath = see;
                    typeExists = true;
                    break;
                }
            }
        }

        if (typeExists) {
            // Create a TypePath object for formatting
            var tp:TypePath = { path: typePath, params: [] };
            return formatTypePathForHtml(tp, currentTypePath);
        }

        return see;
    }
}