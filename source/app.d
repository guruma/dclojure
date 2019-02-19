import 	std.stdio, 
	std.process,
	std.string, 
	std.path, 
	std.process, 
	std.algorithm;
	core.sys.posix.sys.stat;

import std.stdio, std.string, std.path, std.process, std.algorithm;


void main()
{
    auto home = environment.get("HOME");
    writeln("HOME = ", home); 

    auto javaHome = environment.get("JAVA_HOME");
    writeln("JAVA_HOME = ", javaHome);

    auto pwd = environment.get("PWD");
    writeln("PWD = ", pwd);

    string paths = environment.get("PATH");

    foreach (path; paths.split(pathSeparator).map!(path => asAbsolutePath(path))) {
      writeln(path);
    }

    if(test_file('e', "dclojure")) writeln("exist");
}

bool test_file(char b, string fname)
{
    stat_t st;
    int ret = stat(cast(char*)fname, &st);

    if( ret != 0 ) return false;

    switch(b) {
    case 'e':
	return (ret == 0);
    case 'f':
        return (0 != (st.st_mode & S_IFREG));
    case 'x':
        return (0 != (st.st_mode & S_IXUSR));
    case 'd':
        return (0 != (st.st_mode & S_IFDIR));
    default:
	break;
    }

    return false;
}
