import std.stdio;
import std.process,
       std.file;


version (Windows):

void main(string[] args)
{
	install();
}

void install()
{
    string toolsVersion = import("version");
	
    string fromDir = "resources\\tools\\";
    string toDir = environment.get("LocalAppData") ~ "\\lib\\clojure\\";
 
    string[] toolsFiles = ["deps.edn",
                           "example-deps.edn",
                           "libexec\\clojure-tools-1.10.0.414.jar"];

    if (!toDir.isDir)
    {
        mkdirRecurse(toDir ~ "libexec");
        foreach (file; toolsFiles)
        {
           copy (fromDir ~ file, toDir ~ file); 
        }
	}
}
