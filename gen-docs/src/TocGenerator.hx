import ApiTypes;
import sys.io.File;
import haxe.Json;

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
            "Ceramic",
            "Tracker", 
            "Elements",
            "Arcade",
            "Tilemap", 
            "Spine",
            "Script",
            "Ase",
            "Format",
            "Backend",
            "Clay",
            "Unity",
            "Other",
            "Haxe"
        ];
        
        // Add groups in the defined order
        for (groupName in groupOrder) {
            if (groups.exists(groupName)) {
                var entries = groups.get(groupName);
                // Sort entries alphabetically within each group
                entries.sort((a, b) -> Reflect.compare(a.name.toLowerCase(), b.name.toLowerCase()));
                tocGroups.push({
                    name: groupName,
                    entries: entries
                });
            }
        }
        
        // Add any remaining groups not in the order
        for (groupName => entries in groups) {
            if (groupOrder.indexOf(groupName) == -1) {
                entries.sort((a, b) -> Reflect.compare(a.name.toLowerCase(), b.name.toLowerCase()));
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
        
        // Check for plugin types by examining fields with @:plugin metadata
        var pluginName = getPluginName(type);
        if (pluginName != null) {
            return switch (pluginName.toLowerCase()) {
                case "arcade": "Arcade";
                case "tilemap": "Tilemap";
                case "spine": "Spine";
                case "script": "Script";
                case _: pluginName.charAt(0).toUpperCase() + pluginName.substring(1);
            }
        }
        
        // Group by package prefix
        if (StringTools.startsWith(path, "ceramic.")) {
            return "Ceramic";
        } else if (StringTools.startsWith(path, "tracker.")) {
            return "Tracker";
        } else if (StringTools.startsWith(path, "elements.")) {
            return "Elements";
        } else if (StringTools.startsWith(path, "backend.")) {
            return "Backend";
        } else if (StringTools.startsWith(path, "clay.")) {
            return "Clay";
        } else if (StringTools.startsWith(path, "unity.")) {
            return "Unity";
        } else if (StringTools.startsWith(path, "ase.")) {
            return "Ase";
        } else if (StringTools.startsWith(path, "format.")) {
            return "Format";
        }
        
        // Default group
        return "Other";
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
        
        // Take first line or sentence
        var lines = doc.split("\n");
        var firstLine = "";
        
        for (line in lines) {
            line = StringTools.trim(line);
            if (line != "") {
                firstLine = line;
                break;
            }
        }
        
        if (firstLine == "") return null;
        
        // Remove JavaDoc-style comment prefix
        if (StringTools.startsWith(firstLine, "* ")) {
            firstLine = firstLine.substring(2);
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
}