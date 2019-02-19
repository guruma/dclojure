import  std.stdio, 
        std.string, 
        std.path, 
        std.process,
        std.algorithm,
        core.sys.posix.sys.stat;


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

    if(test_file('e', "dclojure")) writeln("exist");
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
