module dclojure.util;

import std.stdio, 
       std.string, 
       std.process,
       std.path,
       std.algorithm,
       std.array, 
       dclojure.file;

import app: Opts, Vars;

string findExecutable(string cmd)
{
    string envPath = environment.get("PATH");
    
    string cmdPath;
    foreach (path; envPath.split(pathSeparator))
    {
        cmdPath = buildPath(absolutePath(path), cmd);
        if (cmdPath.isExec)
            return cmdPath;
    }

    return null; 
}

string findJava()
{
    version (Posix) string javaCmd = "java";
    version (Windows) string javaCmd = "java.exe";
    
    string javaPath = findExecutable(javaCmd);

    if (!javaPath.empty)
        return javaPath;

    string javaHome = environment.get("JAVA_HOME");

    if (javaHome.empty)
        return null;

    javaPath = buildPath(javaHome, "bin", javaCmd);

    if (javaPath.isExec) 
        return javaPath;

    return null;
}

void runJava(string cmd)
{
    executeShell(cmd);
}

void execJava(string[] cmd)
{
    version(Posix)
    {
        execv(cmd[0], cmd);
        throw new Exception("Failed to execute program : " ~ cmd[0]);
    }
    else version (Windows)
    {
        import core.stdc.stdlib: exit;
        
        wait(spawnProcess(cmd));
        exit(0);
    }
}

void resolveTags(in ref Vars vars)
{
    string cmd = [vars.javaCmd,
                  "-Xmx256m -classpath",
                  vars.toolsCp,
                  "clojure.main -m clojure.tools.deps.alpha.script.resolve-tags --deps-file=deps.edn"
                 ].join(" ");

    runJava(cmd);
}

string determineUserConfigDir()
{
    string dir = environment.get("CLJ_CONFIG");
    if (!dir.empty)
        return dir;

    dir = environment.get("XDG_CONFIG_HOME");
    if (!dir.empty)
        return buildPath(dir, "clojure");
    
    version (Posix) dir = environment.get("HOME");
    version (Windows) dir = environment.get("HOMEDRIVE") ~ environment.get("HOMEPATH");

    if (!dir.empty)
        return buildPath(dir, ".clojure");
    else
        return dir;
}

void createUserConfigDir(in ref Vars vars)
{
    import std.file: mkdirRecurse, copy;

    if (!vars.configDir.isDir)
        mkdirRecurse(vars.configDir);

    if (!buildPath(vars.configDir, "deps.edn").exists)
       copy(buildPath(vars.installDir, "example-deps.edn"), 
            buildPath(vars.configDir, "deps.edn"));
}

string determineUserCacheDir(string configDir)
{
    string dir = environment.get("CLJ_CAHCE");
    if (!dir.empty)
        return dir;

    dir = environment.get("XDG_CACHE_HOME");
    if (!dir.empty)
        return buildPath(dir, "clojure");
    else
        return buildPath(configDir, ".cpcache");
}

string makeChecksum(in ref Vars vars, in ref Opts opts)
{
    string val = [opts.resolveAliases.join(),
                  opts.classpathAliases.join(),
                  opts.allAliases.join(),
                  opts.jvmAliases.join(),
                  opts.mainAliases.join(),
                  opts.depsData
                 ].join("|");

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
    writeln("config_paths = ", vars.configPaths.join(" "));
    writeln("cache_dir    = ", vars.cacheDir);
    writeln("cp_file      = ", vars.cpFile);
    writeln();
}

string[] makeToolsArgs(in ref Vars vars, in ref Opts opts)
{
    string[] toolsArgs;

    if (!vars.depsData.empty())
        toolsArgs ~= ["--config-data", vars.depsData];

    if (!opts.resolveAliases.empty)
        toolsArgs ~= ["-R" ~ opts.resolveAliases.join()];
    if (!opts.classpathAliases.empty)
        toolsArgs ~= ["-C" ~ opts.classpathAliases.join()];
    if (!opts.jvmAliases.empty)
        toolsArgs ~= ["-J" ~ opts.jvmAliases.join()];
    if (!opts.mainAliases.empty)
        toolsArgs ~= ["-M" ~ opts.mainAliases.join()];
    if (!opts.allAliases.empty)
        toolsArgs ~= ["-A" ~ opts.allAliases.join()];
    if (!opts.forceCp.empty)
        toolsArgs ~= ["--skip-cp"];

    return toolsArgs;
}

void makeClasspath(in ref Vars vars)
{
    string cmd = [vars.javaCmd, 
                  "-Xmx256m",
                  "-classpath", vars.toolsCp, 
                  "clojure.main -m clojure.tools.deps.alpha.script.make-classpath",
                  "--config-files", vars.configStr,
                  "--libs-file", vars.libsFile,
                  "--cp-file", vars.cpFile,
                  "--jvm-file", vars.jvmFile,
                  "--main-file", vars.mainFile,
                  vars.toolsArgs.join()
                 ].join(" ");

    runJava(cmd);
}

void generateManifest(in ref Vars vars)
{
    string[] cmd = [vars.javaCmd,
                    "-Xmx256m",
                    "-classpath", vars.toolsCp,
                    "clojure.main", "-m", "clojure.tools.deps.alpha.script.generate-manifest",
                    "--config-files", vars.configStr,
                    "--gen=pom",
                    vars.toolsArgs.join()
                   ].filter!(str => !str.empty).array;

    execJava(cmd);
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
    writefln(` :resolve-aliases "%s"`, opts.resolveAliases.join(" "));
    writefln(` :classpath-aliases "%s"`, opts.classpathAliases.join(" "));
    writefln(` :jvm-aliases "%s"`, opts.jvmAliases.join(" "));
    writefln(` :main-aliases "%s"`, opts.mainAliases.join(" "));
    writefln(` :all-aliases "%s"}`, opts.allAliases.join(" "));
}

void printTree(ref Vars vars)
{
    string[] cmd = [vars.javaCmd,
                    "-Xmx256m",
                    "-classpath", vars.toolsCp,
                    "clojure.main", "-m", "clojure.tools.deps.alpha.script.print-tree",
                    "--libs-file", vars.libsFile
                   ].filter!(str => !str.empty).array;

    execJava(cmd);
}

void runClojure(in ref Vars vars, in ref Opts opts)
{
    string[] cmd = [vars.javaCmd,
                    vars.jvmCacheOpts.join(),
                    opts.jvmOpts.join(),
                    "-Dclojure.libfile=" ~ vars.libsFile,
                    "-classpath", vars.cp,
                    "clojure.main", vars.mainCacheOpts.join(),
                    vars.args.join(" ")
                   ].filter!(str => !str.empty).array;

    execJava(cmd);
}

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

void printHelp()
{
    writeln(helpMessage);
}

// for internal debugging
void printStruct(S)(S s)
{
    auto fields = __traits(allMembers, typeof(s));
    auto values = s.tupleof;

    writeln();
    foreach (index, value; values)
    {
        writefln("%s = %s", fields[index], value);
    }
 }
