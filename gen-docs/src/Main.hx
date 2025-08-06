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
                
            case "index":
                if (args.length < 4) {
                    Sys.println("Error: Missing toc file, output file, or target");
                    printUsage();
                    Sys.exit(1);
                }
                generateIndex(args[1], args[2], args[3]);
                
            case "root-index":
                if (args.length < 2) {
                    Sys.println("Error: Missing output directory");
                    printUsage();
                    Sys.exit(1);
                }
                generateRootIndex(args[1]);
                
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
        Sys.println("  node gen-docs.js index <toc-file> <output-file> <target>");
        Sys.println("  node gen-docs.js root-index <output-dir>");
        Sys.println("");
        Sys.println("Examples:");
        Sys.println("  node gen-docs.js json ../docs-xml/clay-native.xml");
        Sys.println("  node gen-docs.js markdown ../docs-xml/clay-native.xml ../docs-md/clay-native");
        Sys.println("  node gen-docs.js toc ../docs-xml/clay-native.xml ../docs-md/clay-native/toc.json");
        Sys.println("  node gen-docs.js index ../docs-md/clay-native/toc.json ../docs-md/clay-native/index.md clay-native");
        Sys.println("  node gen-docs.js root-index ../docs-md");
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
            
            // Extract target from output directory (e.g., "docs-md/clay-native" -> "clay-native")
            var target = Path.withoutDirectory(outputDir);
            
            // Generate markdown files
            var generator = new MarkdownGenerator();
            generator.generateMarkdown(apiData, outputDir, target);
            
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
    
    static function generateIndex(tocFile:String, outputFile:String, target:String):Void {
        if (!FileSystem.exists(tocFile)) {
            Sys.println('Error: File not found: $tocFile');
            Sys.exit(1);
        }
        
        try {
            // Generate index from TOC
            var generator = new TocGenerator();
            generator.generateIndexFromToc(tocFile, outputFile, target);
            
            Sys.println('Generated index in $outputFile');
            
        } catch (e:Dynamic) {
            Sys.println('Error: $e');
            #if debug
            Sys.println(haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
            #end
            Sys.exit(1);
        }
    }
    
    static function generateRootIndex(outputDir:String):Void {
        if (!FileSystem.exists(outputDir)) {
            Sys.println('Error: Directory not found: $outputDir');
            Sys.exit(1);
        }
        
        try {
            // Find all subdirectories in the output directory
            var targets = [];
            for (item in FileSystem.readDirectory(outputDir)) {
                var path = Path.join([outputDir, item]);
                if (FileSystem.isDirectory(path) && FileSystem.exists(Path.join([path, "index.md"]))) {
                    targets.push(item);
                }
            }
            
            // Sort targets for consistent output
            targets.sort(Reflect.compare);
            
            // Generate root index
            var generator = new TocGenerator();
            generator.generateRootIndex(targets, Path.join([outputDir, "index.md"]));
            
            Sys.println('Generated root index in $outputDir/index.md');
            
        } catch (e:Dynamic) {
            Sys.println('Error: $e');
            #if debug
            Sys.println(haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
            #end
            Sys.exit(1);
        }
    }
}