import std.stdio,
       std.string,
       std.path,
       std.array,
       core.stdc.stdlib,
       dclojure.file,
       dclojure.util;

struct Opts
{
    string[] jvmOpts = [];
    string[] resolveAliases = [];
    string[] classpathAliases = [];
    string[] jvmAliases = [];
    string[] mainAliases = [];
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

struct Vars
{
    string toolsVersion;
    string toolsJar;
    string[] configPaths;
    string[] toolsArgs;
    string[] args;
    string installDir;
    string toolsCp;
    string depsData;
    string configDir;
    string userCacheDir;
    string configStr;
    string cacheDir;
    string ck;
    string libsFile;
    string cpFile;
    string jvmFile;
    string mainFile;
    string cp;
    string[] jvmCacheOpts;
    string[] mainCacheOpts;
    string javaCmd;
    bool stale = false;
}

Opts parseArgs(ref string[] args)
{
    Opts opts;

    void shift()
    {
        if (args.length > 0)
            popFront(args);
    }

    while (args.length > 0)
    {
        string arg = args[0];
        shift();
 
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
        {
            opts.depsData = args[0];
            shift();
        }
        else if (arg == "-Scp")
        {
            opts.forceCp = args[0];
            shift();
        }
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
        else if (startsWith(arg, "-S"))
            writeln("Invalid option: ", arg);
        else if (arg == "-h" || arg == "--help" || arg == "-?")
        {
            if (!opts.mainAliases.empty || !opts.allAliases.empty)
                break;
            else
                opts.help = true;
        } 
        else
        {
            args = [arg] ~ args;
            break;
        }
    }
    return opts;
}

void main(string[] args)
{
    Vars vars;
    vars.toolsVersion = "1.10.0.414";
    vars.toolsJar = "clojure-tools-" ~ vars.toolsVersion ~ ".jar";
    vars.args = args[1 .. $];

    Opts opts = parseArgs(vars.args);

    vars.javaCmd = findJava();
 
    if (opts.help) {
        printHelp();
        exit(0);
    }

    vars.installDir = getInstallDir(vars);    
    vars.toolsCp = buildPath(vars.installDir, "libexec", vars.toolsJar);
  
    if (opts.resolveTags)
    {
        if (exists("deps.edn"))
            resolveTags(vars);
        else
        {
            writeln("deps.edn does not exist");
            exit(1);
        }
    }

    vars.configDir = determineUserConfigDir();
 
    createUserConfigDir(vars);

    vars.userCacheDir = determineUserCacheDir(vars.configDir);

    if (opts.repro)
        vars.configPaths = [buildPath(vars.installDir, "deps.edn"), 
                            "deps.edn"];
    else
        vars.configPaths = [buildPath(vars.installDir, "deps.edn"), 
                            buildPath(vars.configDir, "deps.edn"), 
                            "deps.edn"];

    vars.configStr = vars.configPaths.join(",");


    // Determine whether to use user or project cache
    if (exists("deps.edn"))
        vars.cacheDir = ".cpcache";
    else
        vars.cacheDir = vars.userCacheDir;


    // Construct location of cached classpath file
    vars.ck = makeChecksum(vars, opts);
    vars.libsFile = buildPath(vars.cacheDir, vars.ck ~ ".libs");
    vars.cpFile   = buildPath(vars.cacheDir, vars.ck ~ ".cp");
    vars.jvmFile  = buildPath(vars.cacheDir, vars.ck ~ ".jvm");
    vars.mainFile = buildPath(vars.cacheDir, vars.ck ~ ".main");

    if (opts.verbose)
        printVerbose(vars);

    if (opts.force || !vars.cpFile.exists)
        vars.stale = true;
    else
    {
        // if any file is dirty, set stale
        foreach (configPath; vars.configPaths)
        {
            if (newerThan(configPath, vars.cpFile))
            {
                vars.stale = true;
                break;
            }
        }
    }

    if (vars.stale || opts.pom)
        vars.toolsArgs = makeToolsArgs(vars, opts);
     
    // If stale, run make-classpath to refresh cached classpath
    if (vars.stale && !opts.describe)
    {
        if (opts.verbose)
            writeln("Refreshing classpath");
        makeClasspath(vars);
    }

    // classpath
    if (opts.describe)
        vars.cp = "";
    else if (!opts.forceCp.empty)
        vars.cp = opts.forceCp;
    else
        vars.cp = readText(vars.cpFile);

    // at last...
    if (opts.pom)
        generateManifest(vars);
    else if (opts.printClasspath)
        writeln(vars.cp);
    else if (opts.describe)
        printDescribe(vars, opts);
    else if (opts.tree)
        printTree(vars);
    else
    {
        if (vars.jvmFile.exists)
            vars.jvmCacheOpts = [readText(vars.jvmFile)];

        if (vars.mainFile.exists)
            vars.mainCacheOpts = [readText(vars.mainFile)];

        runClojure(vars, opts);
    }
}


void main1(string[] args)
{
    import dclojure.windows;

    version (Windows) install();
}
