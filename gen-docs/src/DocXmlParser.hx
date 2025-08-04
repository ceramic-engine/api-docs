import ApiTypes;

class DocXmlParser {
    
    public function new() {}
    
    function getTextContent(element:Xml):Null<String> {
        if (element == null) return null;
        
        var text = "";
        for (child in element) {
            if (child.nodeType == Xml.PCData || child.nodeType == Xml.CData) {
                text += child.nodeValue;
            }
        }
        
        return text.length > 0 ? text : null;
    }
    
    public function parse(xmlContent:String):ApiData {
        var xml = Xml.parse(xmlContent);
        var root = xml.firstElement();
        
        if (root == null || root.nodeName != "haxe") {
            throw "Invalid XML format: expected root element 'haxe'";
        }
        
        var types:Array<ApiType> = [];
        
        for (element in root.elements()) {
            var type = parseType(element);
            if (type != null) {
                types.push(type);
            }
        }
        
        // Build inheritance map
        var inheritanceMap = new Map<String, Array<String>>();
        for (type in types) {
            // Handle superclass relationships
            if (type.superClass != null && type.superClass.path != null) {
                if (!inheritanceMap.exists(type.superClass.path)) {
                    inheritanceMap.set(type.superClass.path, []);
                }
                inheritanceMap.get(type.superClass.path).push(type.path);
            }
            
            // Handle interface implementations
            if (type.interfaces != null) {
                for (iface in type.interfaces) {
                    if (iface.path != null) {
                        if (!inheritanceMap.exists(iface.path)) {
                            inheritanceMap.set(iface.path, []);
                        }
                        inheritanceMap.get(iface.path).push(type.path);
                    }
                }
            }
        }
        
        // Debug: count inheritance relationships
        var inheritanceCount = 0;
        for (key in inheritanceMap.keys()) {
            inheritanceCount += inheritanceMap.get(key).length;
        }
        trace('Built inheritance map with ${inheritanceCount} relationships');
        
        return { types: types, inheritanceMap: inheritanceMap };
    }
    
    function parseType(element:Xml):Null<ApiType> {
        var kind:TypeKind = switch (element.nodeName) {
            case "class": TClass;
            case "interface": TClass; // Will be marked with isInterface
            case "enum": TEnum;
            case "typedef": TTypedef;
            case "abstract": TAbstract;
            default: return null;
        }
        
        var type:ApiType = {
            kind: kind,
            path: element.get("path"),
            module: element.get("module"),
            file: element.get("file"),
            params: element.get("params") != null ? element.get("params") : "",
            doc: null,
            meta: [],
            isPrivate: element.get("private") == "1",
            isExtern: element.get("extern") == "1",
            isFinal: element.get("final") == "1",
            isInterface: element.get("interface") == "1"
        };
        
        // Parse child elements
        for (child in element.elements()) {
            switch (child.nodeName) {
                case "haxe_doc":
                    type.doc = getTextContent(child);
                    
                case "meta":
                    type.meta = parseMeta(child);
                    
                case "impl":
                    // For abstracts
                    var implClass = child.firstElement();
                    if (implClass != null) {
                        type.impl = implClass.get("path");
                    }
                    
                case "from":
                    // For abstracts
                    if (type.from == null) type.from = [];
                    var fromType = parseTypeReference(child);
                    if (fromType != null) {
                        type.from.push(fromType);
                    }
                    
                case "to":
                    // For abstracts
                    if (type.to == null) type.to = [];
                    var toType = parseTypeReference(child);
                    if (toType != null) {
                        type.to.push(toType);
                    }
                    
                case "this":
                    // For abstracts - underlying type
                    type.underlying = parseTypeReference(child);
                    
                case "extends":
                    // For classes - extends has a path attribute
                    var path = child.get("path");
                    if (path != null) {
                        type.superClass = {
                            path: path,
                            params: []
                        };
                    }
                    
                case "implements":
                    // For classes - implements has a path attribute
                    if (type.interfaces == null) type.interfaces = [];
                    var path = child.get("path");
                    if (path != null) {
                        type.interfaces.push({
                            path: path,
                            params: []
                        });
                    }
                    
                default:
                    // Check if it's a field
                    if (kind == TClass || kind == TAbstract) {
                        var field = parseField(child, type);
                        if (field != null) {
                            if (type.fields == null) type.fields = [];
                            type.fields.push(field);
                        }
                    } else if (kind == TEnum) {
                        // Enum constructor
                        var ctor = parseEnumConstructor(child);
                        if (ctor != null) {
                            if (type.constructors == null) type.constructors = [];
                            type.constructors.push(ctor);
                        }
                    } else if (kind == TTypedef) {
                        // Typedef underlying type
                        type.underlying = parseTypeReference(child);
                    }
            }
        }
        
        return type;
    }
    
    function parseField(element:Xml, parentType:ApiType):Null<Field> {
        // Determine default visibility based on parent type
        var defaultPublic = parentType.isInterface || parentType.isExtern;
        var isPublicAttr = element.get("public");
        var isPublic = if (isPublicAttr != null) {
            isPublicAttr == "1";
        } else {
            defaultPublic;
        }
        
        var field:Field = {
            name: element.nodeName,
            type: null,
            isPublic: isPublic,
            isStatic: element.get("static") == "1",
            line: element.get("line") != null ? Std.parseInt(element.get("line")) : null,
            getter: element.get("get"),
            setter: element.get("set"),
            expr: element.get("expr"),
            doc: null,
            meta: [],
            overloads: null
        };
        
        // Parse field type
        for (child in element.elements()) {
            switch (child.nodeName) {
                case "f":
                    // Function type
                    field.type = {
                        kind: FMethod,
                        args: parseFunctionArgs(child),
                        ret: null,
                        type: null
                    };
                    
                    // Get return type (last child that's not an argument)
                    var lastType:Xml = null;
                    for (typeChild in child.elements()) {
                        if (typeChild.nodeName != "m") {
                            lastType = typeChild;
                        }
                    }
                    if (lastType != null) {
                        field.type.ret = parseTypeReference(lastType);
                    }
                    
                case "c", "x", "t", "e", "d":
                    // Variable type
                    field.type = {
                        kind: FVar,
                        args: null,
                        ret: null,
                        type: parseTypeReference(child)
                    };
                    
                case "haxe_doc":
                    field.doc = getTextContent(child);
                    
                case "meta":
                    field.meta = parseMeta(child);
            }
        }
        
        return field;
    }
    
    function parseEnumConstructor(element:Xml):Null<EnumConstructor> {
        var ctor:EnumConstructor = {
            name: element.nodeName,
            args: null,
            doc: null,
            meta: []
        };
        
        // Check if it has arguments
        if (element.get("a") != null) {
            ctor.args = [];
            var argNames = element.get("a").split(":");
            var i = 0;
            
            for (child in element.elements()) {
                if (child.nodeName != "haxe_doc" && child.nodeName != "meta") {
                    var arg:FunctionArg = {
                        name: i < argNames.length ? argNames[i] : "arg" + i,
                        type: parseTypeReference(child),
                        opt: false,
                        value: null
                    };
                    ctor.args.push(arg);
                    i++;
                }
            }
        }
        
        // Parse documentation and meta
        for (child in element.elements()) {
            switch (child.nodeName) {
                case "haxe_doc":
                    ctor.doc = getTextContent(child);
                case "meta":
                    ctor.meta = parseMeta(child);
            }
        }
        
        return ctor;
    }
    
    function parseFunctionArgs(funcElement:Xml):Array<FunctionArg> {
        var args:Array<FunctionArg> = [];
        var argAttr = funcElement.get("a");
        
        if (argAttr == null || argAttr == "") {
            return args;
        }
        
        // Get default values if present
        var defaultValues = funcElement.get("v");
        var defaults = defaultValues != null ? defaultValues.split(":") : [];
        
        // Parse argument names
        var argParts = argAttr.split(":");
        var argIndex = 0;
        
        for (child in funcElement.elements()) {
            if (child.nodeName == "m") continue; // Skip meta
            
            if (argIndex < argParts.length) {
                var argDef = argParts[argIndex];
                var isOpt = argDef.charAt(0) == "?";
                var name = argDef;
                var value:String = null;
                
                if (isOpt) {
                    name = name.substr(1);
                }
                
                // Check for default value
                if (argIndex < defaults.length && defaults[argIndex] != "") {
                    value = defaults[argIndex];
                }
                
                var arg:FunctionArg = {
                    name: name,
                    type: parseTypeReference(child),
                    opt: isOpt,
                    value: value
                };
                
                args.push(arg);
            }
            
            argIndex++;
        }
        
        return args;
    }
    
    function parseTypeReference(element:Xml):Null<TypePath> {
        if (element == null) return null;
        
        switch (element.nodeName) {
            case "c":
                // Class path reference
                var path = element.get("path");
                if (path == null) return null;
                
                var typePath:TypePath = {
                    path: path,
                    params: []
                };
                
                // Parse type parameters
                for (child in element.elements()) {
                    var param = parseTypeReference(child);
                    if (param != null) {
                        typePath.params.push(param);
                    }
                }
                
                return typePath;
                
            case "x":
                // Path reference (like Null<T>)
                var path = element.get("path");
                if (path == null) return null;
                
                var typePath:TypePath = {
                    path: path,
                    params: []
                };
                
                // Parse type parameters
                for (child in element.elements()) {
                    var param = parseTypeReference(child);
                    if (param != null) {
                        typePath.params.push(param);
                    }
                }
                
                return typePath;
                
            case "t":
                // Type parameter reference
                var path = element.get("path");
                if (path == null) {
                    // Sometimes it's just a type parameter like T
                    if (element.firstChild() != null) {
                        path = element.firstChild().nodeValue;
                    }
                }
                
                return {
                    path: path != null ? path : "Unknown",
                    params: []
                };
                
            case "d":
                // Dynamic
                return {
                    path: "Dynamic",
                    params: []
                };
                
            case "e":
                // Anonymous structure
                return {
                    path: "Anonymous",
                    params: []
                };
                
            case "f":
                // Function type
                return {
                    path: "Function",
                    params: []
                };
                
            case "a":
                // Anonymous type with fields
                return {
                    path: "AnonStruct",
                    params: []
                };
                
            default:
                // For typedef references and other direct children
                if (element.firstElement() != null) {
                    return parseTypeReference(element.firstElement());
                }
                return null;
        }
    }
    
    function parseMeta(metaElement:Xml):Array<MetaData> {
        var meta:Array<MetaData> = [];
        
        for (m in metaElement.elements()) {
            if (m.nodeName == "m") {
                var metaItem:MetaData = {
                    name: m.get("n"),
                    params: []
                };
                
                // Parse meta parameters if they exist
                for (child in m.elements()) {
                    if (child.nodeName == "e") {
                        if (metaItem.params == null) metaItem.params = [];
                        var paramValue = child.firstChild() != null ? child.firstChild().nodeValue : "";
                        metaItem.params.push(paramValue);
                    }
                }
                
                meta.push(metaItem);
            }
        }
        
        return meta;
    }
}