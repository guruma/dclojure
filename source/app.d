import  std.stdio,
        std.exception,
        dclojure.file;

void main()
{
    if(test_file('e', "dclojure")) writeln("exist");
 
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
    
    version (POSIX) dir = environment.get("HOME");
    version (WINDOWS) dir = environment.get("HOMEDRIVE") ~ environment.get("HOMEPATH");
    if (dir != "")
        return buildPath(dir, ".clojure");
    else
        return dir;
}

bool test_file(char opt, string fname)
{
    stat_t st;
    bool is_exist = (0 == stat(cast(char*)fname, &st));

    if('e' == opt)
    {
        return is_exist;
    }

    if (is_exist) 
    {
        switch(opt) 
        {
            case 'f':
                return (0 != (st.st_mode & S_IFREG));
            case 'x':
                return (0 != (st.st_mode & S_IXUSR));
            case 'd':
                return (0 != (st.st_mode & S_IFDIR));
            default:
                break;
        }
    }

    return false;
}
