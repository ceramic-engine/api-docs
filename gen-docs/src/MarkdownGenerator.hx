import ApiTypes;
import sys.io.File;
import sys.FileSystem;
import haxe.io.Path;

class MarkdownGenerator {
    
    public function new() {}
    
    public function generateMarkdown(apiData:ApiData, outputDir:String):Void {
        // Create output directory if it doesn't exist
        if (!FileSystem.exists(outputDir)) {
            FileSystem.createDirectory(outputDir);
        }
        
        // Generate markdown for each type
        for (type in apiData.types) {
            if (shouldSkipType(type)) continue;
            
            var markdown = generateTypeMarkdown(type, apiData);
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
    
    function generateTypeMarkdown(type:ApiType, apiData:ApiData):String {
        var md = new StringBuf();
        
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
            // Show full hierarchy line
            
            // Format inheritance chain if any
            if (hasInheritance) {
                var chain = buildInheritanceChain(type, apiData);
                for (i in 0...chain.length - 1) {
                    var typePath:TypePath = { path: chain[i], params: [] };
                    md.add(formatTypePathWithContext(typePath, type.path));
                    md.add(' → ');
                }
            }
            
            // Current type in bold
            md.add('**${type.path}** (${getTypeKindString(type)})');
            
            // Add derived types
            if (hasDerivedTypes && derivedTypes.length > 0) {
                md.add(' → ');
                
                // Sort subtypes for consistent output
                derivedTypes.sort(Reflect.compare);
                
                var formattedSubtypes = [];
                for (subtype in derivedTypes) {
                    var subtypePath:TypePath = { path: subtype, params: [] };
                    formattedSubtypes.push(formatTypePathWithContext(subtypePath, type.path));
                }
                
                md.add(formattedSubtypes.join(', '));
            }
            
            md.add('\n\n');
        } else {
            // No hierarchy - just show type
            md.add('**${type.path}** (${getTypeKindString(type)})\n\n');
        }
        
        // Interfaces implemented (show separately if there are any)
        if (type.interfaces != null && type.interfaces.length > 0) {
            md.add('**Implements:** ');
            var formattedInterfaces = [];
            for (iface in type.interfaces) {
                formattedInterfaces.push(formatTypePathWithContext(iface, type.path));
            }
            md.add(formattedInterfaces.join(', '));
            md.add('\n\n');
        }
        
        // Description - moved after hierarchy
        if (type.doc != null && type.doc != "") {
            md.add('## Description\n\n');
            md.add(formatDocumentation(type.doc) + '\n\n');
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
                    
                    // Document parameters in a table
                    md.add('**Parameters:**\n\n');
                    md.add('| Name | Type | Description |\n');
                    md.add('|------|------|-------------|\n');
                    for (arg in ctor.args) {
                        md.add('| `${arg.name}` ');
                        md.add('| ${formatTypePath(arg.type)} ');
                        md.add('| ');
                        
                        // Extract parameter description from doc if available
                        if (ctor.doc != null) {
                            var paramDoc = extractParamDoc(ctor.doc, arg.name);
                            if (paramDoc != null) {
                                md.add(paramDoc);
                            }
                        }
                        
                        md.add(' |\n');
                    }
                    md.add('\n');
                } else {
                    md.add('```haxe\n${ctor.name}\n```\n\n');
                }
                
                if (ctor.doc != null && ctor.doc != "") {
                    md.add(formatDocumentation(ctor.doc) + '\n\n');
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
                generatePublicFieldsMarkdown(md, publicStaticFields, type);
            }
            
            // Public instance fields
            if (publicInstanceFields.length > 0) {
                md.add('## Instance Members\n\n');
                generatePublicFieldsMarkdown(md, publicInstanceFields, type);
            }
            
            // Private fields (both static and instance)
            if (privateFields.length > 0) {
                md.add('## Private Members\n\n');
                generatePrivateFieldsMarkdown(md, privateFields, type);
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
    
    function generatePublicFieldsMarkdown(md:StringBuf, fields:Array<Field>, type:ApiType):Void {
        // Separate plugin fields from regular fields
        var regularFields = [];
        var pluginFields = new Map<String, Array<Field>>();
        
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
        for (prop in regularProperties) {
            generateFieldMarkdown(md, prop, type, false);
        }
        
        // Methods
        for (method in regularMethods) {
            generateFieldMarkdown(md, method, type, false);
        }
        
        // Generate plugin fields grouped by plugin
        var pluginNames = [for (name in pluginFields.keys()) name];
        pluginNames.sort(Reflect.compare);
        
        for (pluginName in pluginNames) {
            var pluginFieldList = pluginFields.get(pluginName);
            
            // Sort plugin fields by properties first, then methods
            var pluginProperties = pluginFieldList.filter(f -> f.type != null && f.type.kind.match(FVar));
            var pluginMethods = pluginFieldList.filter(f -> f.type != null && f.type.kind.match(FMethod));
            
            // Properties
            for (prop in pluginProperties) {
                generateFieldMarkdown(md, prop, type, false, pluginName);
            }
            
            // Methods
            for (method in pluginMethods) {
                generateFieldMarkdown(md, method, type, false, pluginName);
            }
        }
    }
    
    function generatePrivateFieldsMarkdown(md:StringBuf, fields:Array<Field>, type:ApiType):Void {
        // Separate plugin fields from regular fields
        var regularFields = [];
        var pluginFields = new Map<String, Array<Field>>();
        
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
        for (prop in regularProperties) {
            generateFieldMarkdown(md, prop, type, true);
        }
        
        // Methods
        for (method in regularMethods) {
            generateFieldMarkdown(md, method, type, true);
        }
        
        // Generate plugin fields grouped by plugin
        var pluginNames = [for (name in pluginFields.keys()) name];
        pluginNames.sort(Reflect.compare);
        
        for (pluginName in pluginNames) {
            var pluginFieldList = pluginFields.get(pluginName);
            
            // Sort plugin fields by properties first, then methods
            var pluginProperties = pluginFieldList.filter(f -> f.type != null && f.type.kind.match(FVar));
            var pluginMethods = pluginFieldList.filter(f -> f.type != null && f.type.kind.match(FMethod));
            
            // Properties
            for (prop in pluginProperties) {
                generateFieldMarkdown(md, prop, type, true, pluginName);
            }
            
            // Methods
            for (method in pluginMethods) {
                generateFieldMarkdown(md, method, type, true, pluginName);
            }
        }
    }
    
    function generateFieldMarkdown(md:StringBuf, field:Field, type:ApiType, isPrivate:Bool, ?pluginName:String = null):Void {
        // Add plugin indicator if provided
        if (pluginName != null) {
            md.add('<div class="plugin-name">$pluginName</div>\n');
        }
        
        // Generate header with HTML code signature (no ### prefix)
        if (field.type.kind.match(FVar) && field.type != null && field.type.type != null) {
            md.add('<div class="signature" id="${field.name}"><code>${field.name}: ${formatTypePathForHtml(field.type.type, type.path)}</code><a class="header-anchor" href="#${field.name}"><span aria-hidden="true" class="header-anchor__symbol">#</span></a></div>\n\n');
        } else if (field.type.kind.match(FMethod)) {
            // Format method header with full signature in HTML
            var methodSig = formatMethodSignatureHtml(field, type.path);
            md.add('<div class="signature" id="${field.name}"><code>${methodSig}</code><a class="header-anchor" href="#${field.name}"><span aria-hidden="true" class="header-anchor__symbol">#</span></a></div>\n\n');
        } else {
            md.add('<div class="signature" id="${field.name}"><code>${field.name}</code><a class="header-anchor" href="#${field.name}"><span aria-hidden="true" class="header-anchor__symbol">#</span></a></div>\n\n');
        }
        
        if (field.type.kind.match(FVar)) {
            // Variable/Property - skip signature code block since type is in header
            if (field.doc != null && field.doc != "") {
                md.add(formatDocumentation(field.doc) + '\n\n');
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
                    md.add(formatDocumentation(processedDoc));
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
                md.add('\n| Name | Type | Default | Description |\n');
                md.add('|------|------|---------|-------------|\n');
                
                for (arg in field.type.args) {
                    md.add('| `${arg.name}` ');
                    md.add('| ${formatTypePathWithContext(arg.type, type.path)} ');
                    if (arg.opt && arg.value != null) {
                        md.add('| `${arg.value}` ');
                    } else if (arg.opt) {
                        md.add('| *(optional)* ');
                    } else {
                        md.add('| ');
                    }
                    md.add('| ');
                    
                    // Extract parameter description from doc if available
                    if (field.doc != null) {
                        var paramDoc = extractParamDoc(field.doc, arg.name);
                        if (paramDoc != null) {
                            md.add(paramDoc);
                        }
                    }
                    
                    md.add(' |\n');
                }
                
                md.add('\n');
            }
            
            // Returns table (separate from parameters)
            var hasReturn = field.type != null && field.type.ret != null && !isVoidType(field.type.ret);
            
            if (hasReturn) {
                md.add('| Returns | Description |\n');
                md.add('|---------|-------------|\n');
                md.add('| ${formatTypePathWithContext(field.type.ret, type.path)} | ');
                
                // Extract return description from doc if available
                if (field.doc != null) {
                    var returnDoc = extractReturnDoc(field.doc);
                    if (returnDoc != null) {
                        md.add(returnDoc);
                    }
                }
                
                md.add(' |\n\n');
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
            // Create relative link to the type
            var targetParts = path.split(".");
            var targetFileName = targetParts.join("/") + ".md";
            
            // Calculate relative path from current file to target
            var relativePath = targetFileName;
            if (currentTypePath != null) {
                var currentParts = currentTypePath.split(".");
                var currentDir = currentParts.slice(0, currentParts.length - 1);
                var targetDir = targetParts.slice(0, targetParts.length - 1);
                
                // For basic types with no package (Int, Float, etc.), they're at the root
                if (targetParts.length == 1) {
                    // Basic type at root - need to go up from current package
                    if (currentDir.length > 0) {
                        var ups = [];
                        for (i in 0...currentDir.length) ups.push("..");
                        relativePath = ups.join("/") + "/" + targetFileName;
                    } else {
                        // Already at root
                        relativePath = targetFileName;
                    }
                } else {
                    // Find common prefix for packaged types
                    var common = 0;
                    while (common < currentDir.length && common < targetDir.length && currentDir[common] == targetDir[common]) {
                        common++;
                    }
                    
                    // Build relative path
                    var upSteps = currentDir.length - common;
                    var downPath = targetParts.slice(common);
                    
                    if (upSteps > 0) {
                        var ups = [];
                        for (i in 0...upSteps) ups.push("..");
                        relativePath = ups.concat(downPath).join("/") + ".md";
                    } else if (downPath.length > 0) {
                        relativePath = downPath.join("/") + ".md";
                    } else {
                        // Same directory
                        relativePath = targetParts[targetParts.length - 1] + ".md";
                    }
                }
            }
            
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
            
            result = '[$displayName]($relativePath)';
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
        
        // Remove @param tags and their descriptions
        doc = ~/@param\s+\w+\s+[^\n@]+/g.replace(doc, "");
        
        // Remove formatted parameter docs (- **paramName**: description)
        doc = ~/^(\s*)-\s*\*\*\w+\*\*:\s*[^\n]+$/gm.replace(doc, "");
        
        // Remove @return tags and their descriptions
        doc = ~/@return\s+[^\n@]+/g.replace(doc, "");
        
        // Remove formatted returns docs (**Returns:** description)
        doc = ~/\*\*Returns:\*\*\s*[^\n]+/g.replace(doc, "");
        
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
    
    function formatDocumentation(doc:String):String {
        // Clean up documentation
        doc = StringTools.trim(doc);
        
        // Convert tabs to spaces
        doc = StringTools.replace(doc, "\t", "    ");
        
        // Remove JavaDoc-style comment prefixes
        var lines = doc.split("\n");
        var cleanedLines = [];
        var isJavaDoc = false;
        
        // Check if this looks like JavaDoc format
        for (line in lines) {
            var trimmed = StringTools.ltrim(line);
            if (trimmed.charAt(0) == "*" && trimmed.charAt(1) == " ") {
                isJavaDoc = true;
                break;
            }
        }
        
        if (isJavaDoc) {
            for (line in lines) {
                // Remove leading whitespace and * prefix
                var cleaned = ~/^\s*\*\s?/.replace(line, "");
                cleanedLines.push(cleaned);
            }
            doc = cleanedLines.join("\n");
        }
        
        // Clean up @param, @return, @see tags for better markdown formatting
        doc = ~/@param\s+(\w+)\s+(.+)/g.map(doc, function(r) {
            return '- **${r.matched(1)}**: ${r.matched(2)}';
        });
        
        doc = ~/@return\s+(.+)/g.replace(doc, "**Returns:** $1");
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
            for (see in seeMatches) {
                doc += "**See:** " + see + "\n";
            }
        }
        doc = ~/@throws\s+(.+)/g.replace(doc, "**Throws:** $1");
        doc = ~/@since\s+(.+)/g.replace(doc, "**Since:** $1");
        doc = ~/@deprecated\s+(.+)/g.replace(doc, "**Deprecated:** $1");
        
        // Escape > and < when they appear after - in lists to prevent markdown interpretation
        doc = ~/^(\s*-\s*)([<>])/gm.replace(doc, "$1\\$2");
        
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
            // Create HTML link to the type
            var targetParts = path.split(".");
            var targetFileName = targetParts.join("/") + ".md";
            
            // Calculate relative path from current file to target
            var relativePath = targetFileName;
            if (currentTypePath != null) {
                var currentParts = currentTypePath.split(".");
                var currentDir = currentParts.slice(0, currentParts.length - 1);
                var targetDir = targetParts.slice(0, targetParts.length - 1);
                
                // For basic types with no package (Int, Float, etc.), they're at the root
                if (targetParts.length == 1) {
                    // Basic type at root - need to go up from current package
                    if (currentDir.length > 0) {
                        var ups = [];
                        for (i in 0...currentDir.length) ups.push("..");
                        relativePath = ups.join("/") + "/" + targetFileName;
                    } else {
                        // Already at root
                        relativePath = targetFileName;
                    }
                } else {
                    // Find common prefix for packaged types
                    var common = 0;
                    while (common < currentDir.length && common < targetDir.length && currentDir[common] == targetDir[common]) {
                        common++;
                    }
                    
                    // Build relative path
                    var upSteps = currentDir.length - common;
                    var downPath = targetParts.slice(common);
                    
                    if (upSteps > 0) {
                        var ups = [];
                        for (i in 0...upSteps) ups.push("..");
                        relativePath = ups.concat(downPath).join("/") + ".md";
                    } else if (downPath.length > 0) {
                        relativePath = downPath.join("/") + ".md";
                    } else {
                        // Same directory
                        relativePath = targetParts[targetParts.length - 1] + ".md";
                    }
                }
            }
            
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
            
            result = '<a href="$relativePath">$displayName</a>';
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
}