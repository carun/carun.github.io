---
layout: post
---

This is a simple test to compare the increment operation between D atomics and C++ atomics.

## Introduction

When comparing the std.experimental.logger module in phobos with spdlog I noticed that
the atomic increment operation with C++ takes longer than that in D.

C++11 introduced atomic variables. By default it enforces sequential consistency.

D achieves this by not tieing the atomicity to the variable declaration, but by
implementing it as a function (the operation is performed on a _normal_ variable).
To me this looks like a clean design as the atomicity is not tied to the type.

## Performance

Without arguing which design is best, let's look at the difference in performance.

C++ STL [documentation on atomics]() and D's Phobos [documentation on atomics](https://dlang.org/phobos/core_atomic.html#.atomicLoad)
states that the default memory ordering is sequential consistency.

C++ STL calls `__atomic_fetch_add` that's implemented by [GCC](https://gcc.gnu.org/onlinedocs/gcc/_005f_005fatomic-Builtins.html).

* Build and run C++

```sh
$ g++ atomic-test.cpp -o atomic-test -march=native -Wall -Wextra -pedantic -std=c++11 -pthread -O3 -flto -DNDEBUG
$ time ./atomic-test 8 100000000

real    0m3.167s
user    0m25.215s
sys     0m0.004s
```

* Build and run D

```sh
$ ldc2 -of std-log-benchmark -release -enable-inlining -Hkeep-all-bodies -O3 -w app.d -vcolumns
$ time ./std-log-benchmark 8 100000000 > /dev/null

real    0m2.527s
user    0m20.124s
sys     0m0.000s
```

Surprisingly D code is 20% faster than C++ version. Time to dig into the details.

## C++ code

```c++
#include <atomic>
#include <thread>
#include <vector>

using namespace std;

int main(int argc, char *argv[])
{
    using namespace std::chrono;

    int thread_count = 8;
    int howmany = 1000000;

    std::atomic<int> msg_counter{0};
    std::vector<thread> threads;

    for (int t = 0; t < thread_count; ++t)
    {
        threads.push_back(std::thread([&]() {
            while (true)
            {
                auto counter = ++msg_counter;
                if (counter > howmany)
                    break;
            }
        }));
    }

    for (auto &t : threads)
    {
        t.join();
    }
    return 0;
}
```

* Godbolt output

    With G++ 8.2, [Godbolt online compiler](https://godbolt.org/z/JjfTyw) showed that the assembly generated for the lambda function is
```asm
        mov     rdx, QWORD PTR [rdi+8]
        mov     eax, 1
        lock xadd       DWORD PTR [rdx], eax
        mov     rdx, QWORD PTR [rdi+16]
        add     eax, 1
        cmp     eax, DWORD PTR [rdx]
        jle     .L2
        ret
```

* Disassembly output on Ubuntu with G++ 7.3

```asm
Disassembly of section .text:

0000000000000000 <foo()>:
   0:   b8 01 00 00 00          mov    $0x1,%eax
   5:   f0 0f c1 05 00 00 00    lock xadd %eax,0x0(%rip)        # d <foo()+0xd>
   c:   00
   d:   83 c0 01                add    $0x1,%eax
  10:   39 05 00 00 00 00       cmp    %eax,0x0(%rip)        # 16 <foo()+0x16>
  16:   7d e8                   jge    0 <foo()>
  18:   c3                      retq
```

## D code

```d
import core.atomic;
import core.thread;

import std.experimental.all;

shared int msgCounter = 0;
shared int maxCount = 100_000_000;

void main(string[] args)
{
    if (args.length != 3)
    {
        writefln("Usage: %s <thread-count> <loop-count>", args[0]);
        return;
    }

    const threadCount = to!int(args[1]);
    maxCount = to!int(args[2]) - threadCount;
    auto pool = new TaskPool(threadCount);
    foreach (tid; 0 .. threadCount)
        pool.put(task!logMe(tid + 1));
    pool.finish;
}

void logMe(const int tid)
{
    while (true)
    {
        atomicOp!"+="(msgCounter, 1);
        if (atomicLoad!(MemoryOrder.seq)(msgCounter) > maxCount)
            break;
    }
}
```

* Godbolt output

    With LDC 1.10.0 [Godbolt online compiler](https://godbolt.org/z/JjfTyw) showed that the assembly generated for the `logMe` function is

```asm
void example.logMe(const(int)):
        mov     rax, qword ptr [rip + shared(int) example.msgCounter@GOTPCREL]
        mov     rcx, qword ptr [rip + shared(int) example.maxCount@GOTPCREL]
.LBB5_1:
        lock            add     dword ptr [rax], 1
        mov     edx, dword ptr [rax]
        cmp     edx, dword ptr [rcx]
        jle     .LBB5_1
        ret
```

* Disassembly output

```asm
0000000000000000 <void app.logMe(const(int))>:
   0:   48 8b 05 00 00 00 00    mov    0x0(%rip),%rax        # 7 <void app.logMe(const(int))+0x7>
   7:   48 8b 0d 00 00 00 00    mov    0x0(%rip),%rcx        # e <void app.logMe(const(int))+0xe>
   e:   66 90                   xchg   %ax,%ax
  10:   f0 83 00 01             lock addl $0x1,(%rax)
  14:   8b 10                   mov    (%rax),%edx
  16:   3b 11                   cmp    (%rcx),%edx
  18:   7e f6                   jle    10 <void app.logMe(const(int))+0x10>
  1a:   c3                      retq
```

## Summary

Even though the assembly generated is exactly same, I'm still not clear on why
D's atomicOp and atomicLoad are much faster than C++ version.  It could be
possible that the assembly generated by g++ is not optimized. My guess is that
the assembly generated in the final ELF is not the same as the one generated in
the standalone function.
