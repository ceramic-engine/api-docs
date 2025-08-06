import ApiTypes;
import haxe.Json;
import sys.io.File;

typedef TocEntry = {
    var path:String;
    var name:String;
    var kind:String;
    var module:String;
    var isPrivate:Bool;
    var md:String;
    var ?description:String;
}

typedef TocGroup = {
    var name:String;
    var entries:Array<TocEntry>;
}

class TocGenerator {

    public function new() {}

    public function generateToc(apiData:ApiData, outputFile:String):Void {
        var groups = new Map<String, Array<TocEntry>>();

        // Process all types
        for (type in apiData.types) {
            if (shouldSkipType(type)) continue;

            var group = determineGroup(type);
            if (!groups.exists(group)) {
                groups.set(group, []);
            }

            var entry:TocEntry = {
                path: type.path,
                name: getTypeName(type),
                kind: getTypeKindString(type),
                module: type.module != null ? type.module : type.path,
                isPrivate: type.isPrivate,
                md: getMarkdownFilePath(type),
                description: extractShortDescription(type.doc)
            };

            groups.get(group).push(entry);
        }

        // Convert to array format for JSON
        var tocGroups:Array<TocGroup> = [];

        // Define the order of groups
        var groupOrder = [
            // Main Ceramic group
            "Ceramic",

            // Plugin groups (from /plugins/*)
            "Arcade",
            "Tilemap",
            "Ldtk",
            "Spine",
            "Script",
            "Sprite",
            "Ui",
            "Dialogs",
            "Gif",

            // Git submodule groups (from /git/*)
            "Tracker",
            "Elements",
            "Backend",
            "Clay",
            "Unity",
            "Ase",
            "Format",
            "Tiled",
            "Nape",
            "OpenGL",
            "Soloud",
            "Stb",
            "Timestamp",
            "BinPacking",
            "Hsluv",
            "Hscript",
            "Fuzzaldrin",
            "Polyline",

            // Other groups
            "Spec",
            "Other",

            // Haxe language types
            "Haxe"
        ];

        // Add groups in the defined order
        for (groupName in groupOrder) {
            if (groups.exists(groupName)) {
                var entries = groups.get(groupName);
                // Sort entries alphabetically by path within each group, with private types at the end
                entries.sort((a, b) -> {
                    var aIsPrivate = isPrivateType(a.path);
                    var bIsPrivate = isPrivateType(b.path);

                    // If one is private and the other isn't, private goes last
                    if (aIsPrivate && !bIsPrivate) return 1;
                    if (!aIsPrivate && bIsPrivate) return -1;

                    // Otherwise, sort alphabetically by path
                    return Reflect.compare(a.path.toLowerCase(), b.path.toLowerCase());
                });
                tocGroups.push({
                    name: groupName,
                    entries: entries
                });
            }
        }

        // Add any remaining groups not in the order
        for (groupName => entries in groups) {
            if (groupOrder.indexOf(groupName) == -1) {
                // Sort entries alphabetically by path within each group, with private types at the end
                entries.sort((a, b) -> {
                    var aIsPrivate = isPrivateType(a.path);
                    var bIsPrivate = isPrivateType(b.path);

                    // If one is private and the other isn't, private goes last
                    if (aIsPrivate && !bIsPrivate) return 1;
                    if (!aIsPrivate && bIsPrivate) return -1;

                    // Otherwise, sort alphabetically by path
                    return Reflect.compare(a.path.toLowerCase(), b.path.toLowerCase());
                });
                tocGroups.push({
                    name: groupName,
                    entries: entries
                });
            }
        }

        // Write to JSON file
        var json = Json.stringify(tocGroups, null, "  ");
        File.saveContent(outputFile, json);
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

    function determineGroup(type:ApiType):String {
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
        // Check if file path indicates it's from Haxe standard library
        if (type.file != null &&
            (type.file.indexOf("/haxe/std/") != -1 ||
             type.file.indexOf("\\haxe\\std\\") != -1 ||
             type.file.indexOf("/haxe-binary/") != -1)) {
            return true;
        }

        // Common built-in types
        var builtinTypes = [
            "Any", "Array", "Bool", "Class", "Date", "Dynamic", "EReg",
            "Enum", "EnumValue", "Float", "Int", "Iterable", "Iterator",
            "Map", "Math", "Null", "Reflect", "Std", "String", "StringBuf",
            "StringTools", "Sys", "Type", "UInt", "Void", "Xml"
        ];

        return builtinTypes.indexOf(type.path) != -1;
    }

    function getPluginName(type:ApiType):Null<String> {
        // Check if any field has @:plugin metadata
        if (type.fields != null) {
            for (field in type.fields) {
                for (meta in field.meta) {
                    if (meta.name == ":plugin" && meta.params != null && meta.params.length > 0) {
                        // Remove quotes from plugin name
                        var pluginName = meta.params[0];
                        if (StringTools.startsWith(pluginName, '"') && StringTools.endsWith(pluginName, '"')) {
                            pluginName = pluginName.substring(1, pluginName.length - 1);
                        }
                        return pluginName;
                    }
                }
            }
        }
        return null;
    }

    function getTypeName(type:ApiType):String {
        var parts = type.path.split(".");
        return parts[parts.length - 1];
    }

    function getTypeKindString(type:ApiType):String {
        return switch (type.kind) {
            case TClass: type.isInterface ? "interface" : "class";
            case TInterface: "interface";
            case TEnum: "enum";
            case TTypedef: "typedef";
            case TAbstract: "abstract";
        }
    }

    function extractShortDescription(doc:Null<String>):Null<String> {
        if (doc == null || doc == "") return null;

        // Take first meaningful line or sentence
        var lines = doc.split("\n");
        var firstLine = "";
        var inLicenseHeader = false;

        for (line in lines) {
            line = StringTools.trim(line);

            // Skip empty lines
            if (line == "") continue;

            // Skip lines that are just asterisks and whitespace
            var cleanedLine = StringTools.replace(line, "*", "");
            if (StringTools.trim(cleanedLine).length == 0) continue;

            // Check if we're in a license header (lines of asterisks or license text)
            if (StringTools.startsWith(line, "* Spine Runtimes Software License") ||
                StringTools.startsWith(line, "Spine Runtimes Software License") ||
                StringTools.startsWith(line, "* Copyright") ||
                StringTools.startsWith(line, "Copyright") ||
                StringTools.startsWith(line, "* Version ") ||
                StringTools.startsWith(line, "Version ") ||
                line.indexOf("Software License") >= 0 ||
                line.indexOf("LICENSE") >= 0) {
                inLicenseHeader = true;
                continue;
            }

            // Skip lines that are part of the license
            if (inLicenseHeader) {
                if (line.indexOf("POSSIBILITY OF SUCH DAMAGE") >= 0 ||
                    line.indexOf("ADVISED OF THE POSSIBILITY") >= 0) {
                    inLicenseHeader = false;
                }
                continue;
            }

            // We found a meaningful line
            firstLine = line;
            break;
        }

        if (firstLine == "") return null;

        // Remove JavaDoc-style comment prefix
        if (StringTools.startsWith(firstLine, "* ")) {
            firstLine = firstLine.substring(2);
        }

        // Remove leading asterisk if present
        if (StringTools.startsWith(firstLine, "*")) {
            firstLine = StringTools.ltrim(firstLine.substring(1));
        }

        // Limit length
        if (firstLine.length > 100) {
            var periodIndex = firstLine.indexOf(".");
            if (periodIndex > 0 && periodIndex < 100) {
                firstLine = firstLine.substring(0, periodIndex + 1);
            } else {
                firstLine = firstLine.substring(0, 97) + "...";
            }
        }

        return firstLine;
    }

    function getMarkdownFilePath(type:ApiType):String {
        // Handle package paths
        var parts = type.path.split(".");
        if (parts.length > 1) {
            var fileName = parts.pop() + ".md";
            var dirs = parts.join("/");
            return dirs + "/" + fileName;
        }
        return type.path + ".md";
    }

    public function generateIndexFromToc(tocFile:String, outputFile:String, target:String):Void {
        // Read the TOC JSON
        var tocContent = sys.io.File.getContent(tocFile);
        var tocGroups:Array<TocGroup> = Json.parse(tocContent);

        // Generate the index markdown
        var md = new StringBuf();

        // Add front matter
        md.add('---\n');
        md.add('layout: api-docs\n');
        md.add('category: api-docs\n');
        md.add('subCategory: index\n');
        md.add('menu: Index\n');
        md.add('title: API Reference\n');
        md.add('target: ${formatTargetName(target)}\n');
        md.add('permalink: api-docs/${target}/\n');
        md.add('---\n\n');

        // Add title
        md.add('# API Reference\n\n');

        // Add table of contents
        for (group in tocGroups) {
            md.add('- [${group.name}](#${generateAnchorId(group.name)})\n');
        }
        md.add('\n');

        // Add groups
        for (group in tocGroups) {
            md.add('## ${group.name}\n\n');

            // Create a table for this group
            md.add('| Type | Kind | Description |\n');
            md.add('|------|------|-------------|\n');

            for (entry in group.entries) {
                // Create link with permalink format
                var permalink = '/api-docs/${target}/${entry.path.split(".").join("/")}/';
                var displayName = entry.name;

                md.add('| [${displayName}](${permalink}) ');
                md.add('| ${entry.kind} ');
                md.add('| ');
                if (entry.description != null) {
                    md.add(entry.description);
                }
                md.add(' |\n');
            }
            md.add('\n');
        }

        // Write the index file
        sys.io.File.saveContent(outputFile, md.toString());
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

    function isPrivateType(path:String):Bool {
        // Check if any part of the path starts with underscore
        var parts = path.split(".");
        for (part in parts) {
            if (StringTools.startsWith(part, "_")) {
                return true;
            }
        }
        return false;
    }

    function generateAnchorId(text:String):String {
        // Convert to lowercase and replace spaces with hyphens
        return text.toLowerCase().split(" ").join("-");
    }

    public function generateRootIndex(targets:Array<String>, outputFile:String):Void {
        var md = new StringBuf();

        // Add front matter
        md.add('---\n');
        md.add('layout: api-docs\n');
        md.add('category: api-docs\n');
        md.add('subCategory: root-index\n');
        md.add('menu: API Documentation\n');
        md.add('title: Ceramic API Documentation\n');
        md.add('permalink: api-docs/\n');
        md.add('---\n\n');

        // Add title
        md.add('# Ceramic API Documentation\n\n');

        // Add description
        md.add('Choose a target platform below to explore the available APIs.\n\n');

        // Add description
        md.add('<p class="extra-info">Most of the APIs are available on all targets. Choosing a target allows you to see what\'s available in addition to the cross-platform APIs.</p>\n\n');

        // Add targets table
        md.add('## Available Targets\n\n');
        md.add('| Target | Description |\n');
        md.add('|--------|-------------|\n');

        for (target in targets) {
            var displayName = formatTargetName(target);
            var description = getTargetDescription(target);
            md.add('| [${displayName}](/api-docs/${target}/) | ${description} |\n');
        }

        // Write the file
        sys.io.File.saveContent(outputFile, md.toString());
    }

    function getTargetDescription(target:String):String {
        return switch (target) {
            case "clay-native": "Native desktop and mobile builds using the Clay backend";
            case "clay-web": "Web builds using the Clay backend with WebGL rendering";
            case "headless": "Server-side and headless builds without rendering";
            case "unity": "Unity integration for using Ceramic within Unity projects";
            case _: "Documentation for " + target + " target";
        }
    }
}