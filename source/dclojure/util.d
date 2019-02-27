module dclojure.util;

import std.stdio, 
       std.string, 
       std.path, 
       std.algorithm,
       core.stdc.stdlib,
       dclojure.file,
       std.array;

import std.process : env = environment, executeShell;

/// helpMessage
string helpMessage = q"END
Usage: dclojure [dep-opt*] [init-opt*] [main-opt] [arg*]
       dclj     [dep-opt*] [init-opt*] [main-opt] [arg*]

dclojure is a runner for Clojure written in the D language.
dclj is a wrapper for interactive repl use. 
These programs ultimately construct and invoke a command-line of the form:

java [java-opt*] -cp classpath clojure.main [init-opt*] [main-opt] [arg*]

The dep-opts are used to build the java-opts and classpath:
 -Jopt          Pass opt through in java_opts, ex: -J-Xmx512m
 -Oalias...     Concatenated jvm option aliases, ex: -O:mem
 -Ralias...     Concatenated resolve-deps aliases, ex: -R:bench:1.9
 -Calias...     Concatenated make-classpath aliases, ex: -C:dev
 -Malias...     Concatenated main option aliases, ex: -M:test
 -Aalias...     Concatenated aliases of any kind, ex: -A:dev:mem
 -Sdeps EDN     Deps data to use as the last deps file to be merged
 -Spath         Compute classpath and echo to stdout only
 -Scp CP        Do NOT compute or cache classpath, use this one instead
 -Srepro        Ignore the ~/.clojure/deps.edn config file
 -Sforce        Force recomputation of the classpath (don't use the cache)
 -Spom          Generate (or update existing) pom.xml with deps and paths
 -Stree         Print dependency tree
 -Sresolve-tags Resolve git coordinate tags to shas and update deps.edn
 -Sverbose      Print important path info to console
 -Sdescribe     Print environment and command parsing info as data

init-opt:
 -i, --init path     Load a file or resource
 -e, --eval string   Eval exprs in string; print non-nil values

main-opt:
 -m, --main ns-name  Call the -main function from namespace w/args
 -r, --repl          Run a repl
 path                Run a script from a file or resource
 -                   Run a script from standard input
 -h, -?, --help      Print this help message and exit

For more info, see:
 https://clojure.org/guides/deps_and_cli
 https://clojure.org/reference/repl_and_main
END";


/// Opts
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
    string[] resolveAliases;
    string[] classpathAliases;
    string[] allAliases;
    string[] jvmAliases;
    string[] mainAliases;
    string[] configPaths;
    string[] toolsArgs;
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
    string jvmCacheOpts;
    string mainCacheOpts;

    string javaCmd;

    bool stale = false;
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


string findCmdPath(string cmd)
{
    string envPath = env.get("PATH");
    
    string cmdPath;
    foreach (path; envPath.split(pathSeparator))
    {
        cmdPath = buildPath(absolutePath(path), cmd);
        if (cmdPath.isExec)
            break;
        else
            cmdPath = null; 
    }

    if (cmdPath)
      return cmdPath;
    else
      return null; 
}

string findJava()
{
    version (Posix) string javaCmd = "java";
    version (Windows) string javaCmd = "java.exe";
    
    string javaPath = findCmdPath(javaCmd);

    if (!javaPath.empty)
        return javaPath;

    string javaHome = env.get("JAVA_HOME");

    if (javaHome.empty)
        return null;

    javaPath = buildPath(javaHome, "bin", javaCmd);

    if (javaPath.isExec) 
        return javaPath;

    return null;
}

void runJava(string cmd)
{
    auto ls = executeShell(cmd);
}


/// config dir
string determineConfigDir()
{
    string dir = env.get("CLJ_CONFIG");
    if (! dir.empty)
        return dir;

    dir = env.get("XDG_CONFIG_HOME");
    if (! dir.empty)
        return buildPath(dir, "clojure");
    
    version (Posix) dir = env.get("HOME");
    version (Windows) dir = env.get("HOMEDRIVE") ~ env.get("HOMEPATH");

    if (! dir.empty)
        return buildPath(dir, ".clojure");
    else
        return dir;
}

string determineCacheDir(string configDir)
{
    string dir = env.get("CLJ_CAHCE");
    if (!dir.empty)
        return dir;

    dir = env.get("XDG_CACHE_HOME");
    if (!dir.empty)
        return buildPath(dir, "clojure");
    else
        return buildPath(configDir, ".cpcache");
}

void resolveTags(in ref Vars vars)
{
    if(exists("deps.edn"))
    {
        string cmd = join([vars.javaCmd, 
                           "-Xmx256m -classpath", 
                           vars.toolsCp, 
                           "clojure.main -m clojure.tools.deps.alpha.script.resolve-tags --deps-file=deps.edn"],
                           " ");

        runJava(cmd);
    }
    else
    {
        writeln("deps.edn does not exist");
        exit(1);
    }
}

string makeClasspath()
{
    return "";
}

string makeConfigStr(string[] config_paths)
{
    return "";
}

string makeChecksum(in ref Vars vars, in ref Opts opts)
{
    string val = join([opts.resolveAliases.join(),
                       opts.classpathAliases.join(),
                       opts.allAliases.join(),
                       opts.jvmAliases.join(),
                       opts.mainAliases.join(),
                       opts.depsData],
                       "|");

    foreach (string configPath; vars.configPaths)
    {
        if (exists(configPath))
            val ~= "|" ~ configPath;
        else
            val ~= "|NIL";
    }

    import std.digest.crc;
    import std.conv;

    ubyte[4] hash = val.crc32Of();
    uint u = hash[3] <<  0 |
             hash[2] <<  8 |
             hash[1] << 16 |
             hash[0] << 24;

    return u.text();
}

void printVerbose(in ref Vars vars) 
{
    writeln("version      = ", vars.toolsVersion);
    writeln("install_dir  = ", vars.installDir);
    writeln("config_dir   = ", vars.configDir);
    writeln("config_paths = ", join(vars.configPaths, " "));
    writeln("cache_dir    = ", vars.cacheDir);
    writeln("cp_file      = ", vars.cpFile);
    writeln();
}

void printDescribe(in ref Vars vars, in ref Opts opts)
{
    string[] pathVector;

    foreach(path; vars.configPaths)
    {
        if (isFile(path))
            pathVector ~= path;
    }

    writefln(`{:version "%s"`, vars.toolsVersion);
    writefln(` :config-files [%(%s %)]`, pathVector);
    writefln(` :install-dir "%s"`, vars.installDir);
    writefln(` :config-dir "%s"`, vars.configDir);
    writefln(` :cache-dir "%s"`, vars.cacheDir);
    writeln( ` :force `, opts.force);
    writeln( ` :repro `, opts.repro);
    writefln(` :resolve-aliases "%s"`, join(opts.resolveAliases, " "));
    writefln(` :classpath-aliases "%s"`, join(opts.classpathAliases, " "));
    writefln(` :jvm-aliases "%s"`, join(opts.jvmAliases, " "));
    writefln(` :main-aliases "%s"`, join(opts.mainAliases, " "));
    writefln(` :all-aliases "%s"}`, join(opts.allAliases, " "));
}

string[] makeToolsArgs(in ref Vars vars, in ref Opts opts)
{
    string[] toolsArgs;

    if(! vars.depsData.empty())
        toolsArgs ~= ["--config-data", vars.depsData];

    if(! opts.resolveAliases.empty())
        toolsArgs ~= ["-R" ~ opts.resolveAliases.join()];
    if(! opts.classpathAliases.empty())
        toolsArgs ~= ["-C" ~ opts.classpathAliases.join()];
    if(! opts.jvmAliases.empty())
        toolsArgs ~= ["-J" ~ opts.jvmAliases.join()];
    if(! opts.mainAliases.empty())
        toolsArgs ~= ["-M" ~ opts.mainAliases.join()];
    if(! opts.allAliases.empty())
        toolsArgs ~= ["-A" ~ opts.allAliases.join()];
    if(! opts.forceCp.empty())
        toolsArgs ~= ["--skip-cp"];

    return toolsArgs;
}

void makeClasspath(in ref Vars vars, in ref Opts opts)
{
}

void generateManifest(in ref Vars vars, in ref Opts opts)
{
}

void printTree(in ref Vars vars, in ref Opts opts)
{
}

void runClojure(in ref Vars vars, in ref Opts opts)
{
}

void createUserConfigDir(in ref Vars vars)
{
    import std.file: mkdirRecurse, copy;

    if (! vars.configDir.isDir)
        mkdirRecurse(vars.configDir);

    if (! buildPath(vars.configDir, "deps.edn").exists)
       copy(buildPath(vars.installDir, "example-deps.edn"), 
            buildPath(vars.configDir, "deps.edn"));
}

