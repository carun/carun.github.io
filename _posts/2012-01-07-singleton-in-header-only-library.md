---
layout: post
---

Whether singleton pattern is evil or not is a different discussion. This post about C++03. Static member variables are
inevitable in singleton implementations. If we define the static member variable in the header file and include it in
more than one source file, the linker would throw multiple definition errors when trying to link the translation units.
So it is a little tricky to design the singleton in header only implementations. Nevertheless it is not difficult.

C++ allows static members variables of class templates to be defined in more than one translation unit. The linker would
merge multiple definitions into one. This is found abundant in the Boost library.

If we don't want to use the templates, but stick with the definite class approach, then this is one way to achieve
singleton in the header only library implementation.

```c++
#include <iostream>
 
namespace home { namespace arun {
 
class Log
{
public:
    static void Init(std::string& logPath, std::string& logFilename,
                     int maxFileSize);
    static Log* Instance();
    static void Destroy();
 
private:
    static Log* MyInstance(Log* pLog);
 
    Log(std::string& logPath, std::string& logFilename, int maxFileSize) :
        m_logPath(logPath),
        m_logFile(logFilename),
        m_maxSize(maxFileSize)
    { }
 
    ~Log()
    { }
 
    Log(const Log& log);
    Log operator=(const Log& log);
 
    std::string m_logPath;
    std::string m_logFile;
    int m_maxSize;
};
 
inline void Log::Init(std::string& logPath, std::string& logFilename,
                      int maxFileSize)
{
    Log* ptr = new Log(logPath, logFilename, maxFileSize);
    MyInstance(ptr);
}
 
inline Log* Log::Instance()
{
    return MyInstance(NULL);
}
 
inline Log* Log::MyInstance(Log* ptr)
{
    static Log* myInstance = NULL;
    if (ptr)
        myInstance = ptr;
    return myInstance;
}
 
inline void Log::Destroy()
{
    Log* pLog = MyInstance(NULL);
    if (pLog)
        delete pLog;
}
 
} }
```

```c++
#include "Log.hpp"
 
using namespace home::arun;
 
int main()
{
    std::string logPath = ".";
    std::string logFile = "Test.log";
    Log::Init(logPath, logFile, 1024*1024);
    Log* pLogInst = Log::Instance();
    std::cout << pLogInst << std::endl;
    Log::Destroy();
}
```
