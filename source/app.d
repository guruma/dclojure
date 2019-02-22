import  std.stdio, 
        std.string, 
        std.path, 
        std.process,
        std.algorithm,
        core.sys.posix.sys.stat,
        dclojure.file;


void main()
{
    auto home = environment.get("HOME");
    writeln("HOME = ", home); 

    auto javaHome = environment.get("JAVA_HOME");
    writeln("JAVA_HOME = ", javaHome);

    auto pwd = environment.get("PWD");
    writeln("PWD = ", pwd);

    string paths = environment.get("PATH");

    foreach (path; paths.split(pathSeparator).map!(path => asAbsolutePath(path)))
    {
        writeln(path);
    }

    if("dclojure".exists) writeln("exist");
 
    runJava("/usr/bin/java -version");
    writeln("configDir = ", configDir());
 }

void runJava(string cmd)
{
    auto ls = executeShell(cmd);
    writeln(ls.output);
}

string configDir()
{
    string dir = environment.get("CLJ_CONFIG");
    if (dir != "")
        return dir;

    dir = environment.get("XDG_CONFIG_HOME");
    if (dir != "")
        return buildPath(dir, "clojure");
    
    version (Posix) dir = environment.get("HOME");
    version (Windows) dir = environment.get("HOMEDRIVE") ~ environment.get("HOMEPATH");
    if (dir != "")
        return buildPath(dir, ".clojure");
    else
        return dir;
}
