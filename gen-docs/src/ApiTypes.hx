typedef ApiData = {
    var types:Array<ApiType>;
    var inheritanceMap:Map<String, Array<String>>; // Maps a type to all types that extend/implement it
}

typedef ApiType = {
    var kind:TypeKind;
    var path:String;
    var module:Null<String>;
    var file:String;
    var params:String;
    var doc:Null<String>;
    var meta:Array<MetaData>;
    var isPrivate:Bool;
    var isExtern:Bool;
    var isFinal:Bool;
    var isInterface:Bool;
    var ?impl:Null<String>; // For abstracts
    var ?superClass:Null<TypePath>; // For classes
    var ?interfaces:Array<TypePath>; // For classes
    var ?from:Array<TypePath>; // For abstracts
    var ?to:Array<TypePath>; // For abstracts
    var ?underlying:Null<TypePath>; // For abstracts and typedefs
    var ?constructors:Array<EnumConstructor>; // For enums
    var ?fields:Array<Field>; // For classes, abstracts, interfaces
}

enum TypeKind {
    TClass;
    TInterface;
    TEnum;
    TTypedef;
    TAbstract;
}

typedef TypePath = {
    var path:String;
    var params:Array<TypePath>;
}

typedef MetaData = {
    var name:String;
    var params:Null<Array<String>>;
}

typedef EnumConstructor = {
    var name:String;
    var args:Null<Array<FunctionArg>>;
    var doc:Null<String>;
    var meta:Array<MetaData>;
}

typedef Field = {
    var name:String;
    var type:FieldType;
    var isPublic:Bool;
    var isStatic:Bool;
    var line:Null<Int>;
    var getter:Null<String>;
    var setter:Null<String>;
    var expr:Null<String>;
    var doc:Null<String>;
    var meta:Array<MetaData>;
    var overloads:Null<Array<Field>>;
}

typedef FieldType = {
    var kind:FieldTypeKind;
    var args:Null<Array<FunctionArg>>; // For functions
    var ret:Null<TypePath>; // For functions
    var type:Null<TypePath>; // For variables
}

enum FieldTypeKind {
    FVar;
    FMethod;
}

typedef FunctionArg = {
    var name:String;
    var type:TypePath;
    var opt:Bool;
    var value:Null<String>;
}