import  std.stdio, 
        std.string, 
        std.path, 
        std.process,
        std.algorithm,
        core.sys.posix.sys.stat,
        dclojure.file;

struct Opts
{
    string[] jvmOpts = [];
    string[] resolveAliases = [];
    string[] classpathAliases = [];
    string[] jvmAliases = [];
    string[] mainAliases = ["1", "2", "3"];
    string[] allAliases = [];
    string depsData = "";
    string forceCp = "";
    bool printClasspath = false;
    bool verbose = false;
    bool describe = false;
    bool force = false;
    bool repro = false;
    bool tree = false;
    bool pom = false;
    bool resolveTags = false;
    bool help = false;
}

Opts opts;

void main(string[] args)
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

    opts = parseArgs(args.remove(0));
    writeln("opts = ", opts);
 }

Opts parseArgs(string[] args)
{
    Opts opts;

    for (int i=0; i < args.length; i++)
    {
        string arg = args[i];

        if (startsWith(arg, "-J"))
            opts.jvmOpts ~= arg[2 .. $];
        else if (startsWith(arg, "-R"))
            opts.resolveAliases ~= arg[2 .. $];
        else if (startsWith(arg, "-C"))
            opts.classpathAliases ~= arg[2 .. $];
        else if (startsWith(arg, "-O"))
            opts.jvmAliases ~= arg[2 .. $];
        else if (startsWith(arg, "-M"))
            opts.mainAliases ~= arg[2 .. $];
        else if (startsWith(arg, "-A"))
            opts.allAliases ~= arg[2 .. $];
        else if (arg == "-Sdeps")
            opts.depsData = args[++i];
        else if (arg == "-Scp")
            opts.forceCp = args[++i];
        else if (arg == "-Spath")
            opts.printClasspath = true;
        else if (arg == "-Sverbose")
            opts.verbose= true;
        else if (arg == "-Sdescribe")
            opts.describe = true;
        else if (arg == "-Sforce")
            opts.force = true;
        else if (arg == "-Srepro")
            opts.repro = true;
        else if (arg == "-Stree")
            opts.tree = true;
        else if (arg == "-Spom")
            opts.pom = true;
        else if (arg == "-Sresolve-tags")
            opts.resolveTags = true;
        else if (arg == "-h" || arg == "--help" || arg == "-?")
        {
            if (opts.mainAliases.length > 0 || opts.allAliases.length > 0)
                break;
            else
                opts.help = true;
        } 
        else
            writeln("Invalid option: ", arg);
    }
    return opts;
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
