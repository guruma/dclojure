module dclojure.windows;

import std.stdio, 
       std.string, 
       std.process,
       std.path,
       std.algorithm,
       std.array, 
       dclojure.file;

version (Windows):

void install()
{
    import std.file: mkdirRecurse, copy;

    string fromDir = "resources\\tools\\";
    string toDir = environment.get("LocalAppData") ~ "\\lib\\clojure\\");

    string toolsFiles = ["deps.edn", "example-deps.edn", "libexec\\deps.edn"];

    if (!installDir.isDir)
    {
        mkdirRecurse(buildPath(installgDir ~ "libexec"));
        foreach (file; toolsFiles)
        {
           copy (fromDir ~ file, toDir ~ file); 
        }
    }
}



