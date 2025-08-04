import sys.io.File;
import sys.FileSystem;
import haxe.io.Path;

class Main {
    static function main() {
        var args = Sys.args();
        
        if (args.length < 1) {
            printUsage();
            Sys.exit(1);
        }
        
        var command = args[0];
        
        switch (command) {
            case "json":
                if (args.length < 2) {
                    Sys.println("Error: Missing XML file path");
                    printUsage();
                    Sys.exit(1);
                }
                generateJson(args[1]);
                
            case "markdown":
                if (args.length < 3) {
                    Sys.println("Error: Missing XML file path or output directory");
                    printUsage();
                    Sys.exit(1);
                }
                generateMarkdown(args[1], args[2]);
                
            case "toc":
                if (args.length < 3) {
                    Sys.println("Error: Missing XML file path or output file");
                    printUsage();
                    Sys.exit(1);
                }
                generateToc(args[1], args[2]);
                
            default:
                // Legacy mode: if first argument is a file, generate JSON
                if (FileSystem.exists(command) && !FileSystem.isDirectory(command)) {
                    generateJson(command);
                } else {
                    Sys.println('Error: Unknown command "$command"');
                    printUsage();
                    Sys.exit(1);
                }
        }
    }
    
    static function printUsage():Void {
        Sys.println("Usage:");
        Sys.println("  node gen-docs.js json <xml-file>");
        Sys.println("  node gen-docs.js markdown <xml-file> <output-dir>");
        Sys.println("  node gen-docs.js toc <xml-file> <output-file>");
        Sys.println("");
        Sys.println("Examples:");
        Sys.println("  node gen-docs.js json ../docs-xml/clay-native.xml");
        Sys.println("  node gen-docs.js markdown ../docs-xml/clay-native.xml ../docs-md/clay-native");
        Sys.println("  node gen-docs.js toc ../docs-xml/clay-native.xml ../docs-md/clay-native/toc.json");
    }
    
    static function generateJson(xmlPath:String):Void {
        if (!FileSystem.exists(xmlPath)) {
            Sys.println('Error: File not found: $xmlPath');
            Sys.exit(1);
        }
        
        try {
            var xmlContent = File.getContent(xmlPath);
            var parser = new DocXmlParser();
            var apiData = parser.parse(xmlContent);
            
            // Output as JSON
            var json = haxe.Json.stringify(apiData, null, "  ");
            Sys.println(json);
            
        } catch (e:Dynamic) {
            Sys.println('Error parsing XML: $e');
            #if debug
            Sys.println(haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
            #end
            Sys.exit(1);
        }
    }
    
    static function generateMarkdown(xmlPath:String, outputDir:String):Void {
        if (!FileSystem.exists(xmlPath)) {
            Sys.println('Error: File not found: $xmlPath');
            Sys.exit(1);
        }
        
        try {
            var xmlContent = File.getContent(xmlPath);
            var parser = new DocXmlParser();
            var apiData = parser.parse(xmlContent);
            
            Sys.println('Parsed ${apiData.types.length} types from $xmlPath');
            
            // Generate markdown files
            var generator = new MarkdownGenerator();
            generator.generateMarkdown(apiData, outputDir);
            
            Sys.println('Generated markdown documentation in $outputDir');
            
        } catch (e:Dynamic) {
            Sys.println('Error: $e');
            #if debug
            Sys.println(haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
            #end
            Sys.exit(1);
        }
    }
    
    static function generateToc(xmlPath:String, outputFile:String):Void {
        if (!FileSystem.exists(xmlPath)) {
            Sys.println('Error: File not found: $xmlPath');
            Sys.exit(1);
        }
        
        try {
            var xmlContent = File.getContent(xmlPath);
            var parser = new DocXmlParser();
            var apiData = parser.parse(xmlContent);
            
            Sys.println('Parsed ${apiData.types.length} types from $xmlPath');
            
            // Generate table of contents
            var generator = new TocGenerator();
            generator.generateToc(apiData, outputFile);
            
            Sys.println('Generated table of contents in $outputFile');
            
        } catch (e:Dynamic) {
            Sys.println('Error: $e');
            #if debug
            Sys.println(haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
            #end
            Sys.exit(1);
        }
    }
}