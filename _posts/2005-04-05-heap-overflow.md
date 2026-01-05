---
layout: post
title: Heap overflow
---

This article was an inspiration from [Hacking: The Art of Exploitation](https://en.wikipedia.org/wiki/Hacking:_The_Art_of_Exploitation).
It should give you a general idea of the principles of a heap-based buffer overflow with a small contrived example.
At the end I will talk about defending heap-based overflows (mainly the ideas adopted in the Windows XP SP2 heap based overflow protection crap).

## Introduction

In a program we know there are 4 main memory segmentations. You have the text, or code; the data, or bss; the heap; and
the stack. The text is the portion of memory where the actual source code (in assembly) is located. The bss is the
portion of memory where your global variables reside. The stack is that FILO structure that deals with all your
temporary variables. The heap is the segmentation of memory that stores any dynamically allocated variables. So when you
use that good old malloc call, you are grabbing a chunk of memory from the heap. The heap is basically a bunch of
free/used doubly linked lists of various memory sizes. The heap grows from lower memory to higher memory while the stack
grows from higher memory to lower memory. Unlike stack overflows, where we focus on overwriting a return address,
heap-based overflows focus on overflowing a buffer that contains important variables *after* the buffer. Sounds a
little tricky (or maybe my wording just sucks) but let's look at it in code.

### Example

```c
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[])
{
    FILE *filed;
    char *userinput = malloc(20);
    char *outputfile = malloc(20);

    if (argc != 2)
    {
        printf("Usage: %s \n", argv[0]);
        exit(0);
    }


    strcpy(outputfile, "/tmp/notes");
    strcpy(userinput, argv[1]);

    // lets check out the memory addresses of userinput and outputfile
    printf("userinput @ %p: %s\n", userinput, userinput);
    printf("outputfile @ %p: %s\n",outputfile, outputfile);


    filed = fopen(outputfile, "a");
    if (filed == NULL)
    {
        fprintf(stderr, "error opening file %s\n", outputfile);
        exit(1);
    }

    fprintf(filed, "%s\n", userinput);
    fclose(filed);
    return 0;
}
```

All this program does is writes (appends) whatever the user inputs into the file /tmp/notes. Notice that when we
allocated the memory, we allocated the userinput first, followed by the outputfile and that outputfile was copied over
first. This will play a key role in allowing the heap overflow. This program needs suid privilages (so it runs as root)
in order for us to usefully exploit it.

### Building the code

```
# gcc -o heap-based-of heap-based-of.c
# chown root.root heap-based-of
# chmod u+s heap-based-of


# ./heap-based-of antionline
userinput @ 0x80498d0: antionline
outputfile @ 0x80498e8: /tmp/notes


# cat /tmp/notes
antionline


# ./heap-based-of WorkSucks
userinput @ 0x80498d0: WorkSucks
outputfile @ 0x80498e8: /tmp/notes


# cat /tmp/notes
antionline
WorkSucks
```

## Explanation

See how the program works?? Now, this is an extremely contrived example, but it will show you how a heap-based-overflow
works. Remember how I mentioned that userinput was allocated first, followed by outputfile?? This can be seen by the
memory addresses displayed (heap grows from lower to higher). If we have a hex calc handy (or can do this in your head),
you know the distance between userinput and outputfile on the heap is 24 bytes. OK, so we know that outputfile
resides 24 bytes after userinput, and the userinput is, obviously, based upon our input. Let's test out some 23
and 24 byte arguments to verify our finding.

```
# ./heap-based-of 12345678901234567890123
userinput @ 0x80498d0: 12345678901234567890123
outputfile @ 0x80498e8: /tmp/notes

# cat /tmp/notes
antionline
WorkSucks
12345678901234567890123

# ./heap-based-of 123456789012345678901234
userinput @ 0x80498d0: 123456789012345678901234
outputfile @ 0x80498e8: /tmp/notes
error opening

# cat /tmp/notes
antionline
WorkSucks
12345678901234567890123
```

Let's try to understand what happened here. userinput is a null terminated string. When we entered our 23 byte string
it actually became a 24 byte string because of the added NULL terminator. This 24 byte, NULL terminated string
worked fine and was written to /tmp/notes. Now, when we tried the 24 byte string, it actually became a 25 byte
string because of the NULL terminator. This caused the program to error while trying to open the file. This prooves
that 23 bytes of user input is maximum the buffer can hold. When we entered 24 bytes (25 with the null terminator)
the userinput buffer overflowed into the beginning of outputfile. Because we only overflowed the buffer by 1 byte
(the last byte), the NULL terminator overflows into outputfile. I will attempt a poor visual. We will assume for the
sake of space that outputfile is 5 bytes after userinput in memory Here is what the heap looks like if we entered
"good" (no quotes, "/0" is the NULL terminator)

* Heap

```
----------------
[ g ] <----- userinput
[ o ]
[ o ]
[ d ]
[ /0 ]
[ / ] <------ outputfile
[ t ]
[ m ]
[ p ]
[ / ]
[ n ]
[ o ]
[ t ]
[ e ]
[ s ]
[ /0 ]
```

Our program will have no trouble writing userinput to outputfile. Now lets looks at memory if we used the word "happy"
(no quotes again, "/0" is our NULL terminator).

* Heap

```
----------------
[ h ] <----- userinput
[ a ]
[ p ]
[ p ]
[ y ]
[ /0 ] <------ outputfile
[ t ]
[ m ]
[ p ]
[ / ]
[ n ]
[ o ]
[ t ]
[ e ]
[ s ]
[ /0 ]
```

Now our program will not run successfully, because the file it is trying to open begins with a NULL terminator. This is
why the error occurs, and is how we can overflow the userinput buffer to corrupt the outputfile buffer. In stack based
overflows, we could attempt to execute shellcode to spawn a remote shell, however that doesn't appear possible given our
situation with the heap-based overflow. How can we manipulate the outputfile buffer to get what we want (root shell??).
Think about it. If we can craft our userinput correctly, and then overflow outputfile with a different filename, we
could end up writing our userinput to a completely different file. Since the program has the SUID bit set, what file
immediately comes to mind?? /etc/passwd. Everyone should know what a line in /etc/passwd looks like/means, so I wont go
into it. If we can add the following line to /etc/passwd, we would be in business.

```
rooted::0:0:me:/root:/bin/bash
```

However, let's check the length of this string - 30 bytes. This string will overflow the last 6 bytes - "n/bash" into
the outputfile buffer. Well this doesn't help because n/bash isnt the /etc/passwd file we wanted to overwrite. So we see
now that our string must end with /etc/passwd and the bytes must line up so that /etc/passwd is overflown into the
outputfile buffer. First, how can we make the string end with /etc/passwd, yet actually be referring to the bash
shell........SYM LINK. Check it out.

```
# mkdir /tmp/etc
# ln -s /bin/bash /tmp/etc/passwd
```

So now /tmp/etc/passwd is a symlink to /bin/bash. Our input string would now look like:

```
rooted::0:0:me:/root:/tmp/etc/passwd
```

Now we need to make sure the overflown buffer will correctly aligned. In other words, we need to make sure that
/etc/passwd is exactly overflown into the buffer. Well we know that 24 bytes separate our userinput from our outputfile,
so we can make sure that everything before '/etc/passwd' equates to 24 bytes. This will ensure that the only thing
to overflow the outputfile buffer will be /etc/passwd from the end of our input string. Right now, the number of
character before '/etc/passwd' is 25 (count em). If we shrink this to 24, we might be in business. New input string

```
rooted::0:0:m:/root:/tmp/etc/passwd
```

24 bytes before /etc/passwd. OK now i am doing to draw this out in memory (like my crappy drawings before) so you
can see what is exactly happening, and then I will tell you how the program handles this string. Take a look
(this time I will show all 24 bytes for userinput so you get the whole picture, "/0" still means the NULL terminator).

* Heap

```
----------------
[ r ] <----- userinput
[ o ]
[ o ]
[ t ]
[ e ]
[ d ]
[ : ]
[ : ]
[ 0 ]
[ : ]
[ 0 ]
[ : ]
[ m ]
[ : ]
[ / ]
[ r ]
[ o ]
[ o ]
[ t ]
[ : ]
[ / ]
[ t ]
[ m ]
[ p ]
[ / ] <----- outputfile
[ e ]
[ t ]
[ c ]
[ / ]
[ p ]
[ a ]
[ s ]
[ s ]
[ w ]
[ d ]
[ /0 ]
```

Wow.. ok, so here is what this looks like in memory, now let's understand how the program reads this and how the exploit
happens. When we run the program as follows

```
# ./heap-based-of rooted::0:0:m:/root:/tmp/etc/passwd
```

The input is a NULL terminated string, so it is going to end with that NULL terminator - seen at the bottom of my little
picture. The program starts placing the string we entered into memory and overflows the buffer, so memory looks exactly
like the picture. Now, output file is opened so that the writing my occur. The program looks at the first memory element
pointed to by outputfile (which happens to be the '/' from '/etc/passwd'). Now, since these are NULL terminated string,
the outputfile string is obtained by progressing through memory until the NULL terminator is spotted. Once the
NULL terminator is spotted, the string is complete. So the outputfile becomes (progressing through my memory picture from outputfile)
/etc/passwd. Just start at outputfile and progress until we hit the NULL terminator and there is the string the
program uses as outputfile. Success, the program has now opened /etc/passwd and will begin to append something
to it. Now the program will start to write to /etc/passwd from userinput. So the program starts at userinput and
progresses through memory until a NULL terminator is hit. Since we overflew the buffer, the entire string we
entered will be appened to /etc/passwd (because we hit the NULL terminator at the very end). So now the program
is done and has written `rooted::0:0:m:/root:/tmp/etc/passwd` to `/etc/passwd`, effectively giving us a
non-passworded root account with the /bin/bash shell (SYM linked from /tmp/etc/passwd). I hope you followed
this. This is how a very simple heap based overflow works. Heap based overflow are usually harder to spot
because one must visualize the layout of memory and how it can be manipulated. Now let's look at some prevention
techniques.

## Preventing heap overflows

Alright. I know everyone here LOVES microsoft so much (I don't mind them), so as a good example I will use their new
Buffer Overflow protection methods in SP2 to give you an idea of how buffer overflows can be prevented. I hope you
understand the previous example of a heap based overflow. I don't like writing just about how code can be cracked, I
like to talk about prevention techniques as well, so here we go. On Intel 64 and AMD 64 chips there is a new feature
called Execution Protection (NX). This feature functions on a per-virtual memory page basis. For those not familiar with
virtual memory, I will briefly explain. The OS divides memory into a pages, each a specific size. The specific page size
can vary between OS. Anyways, when a process wants to run, the OS sticks it into memory by asigning different pieces of
code to different pages. Memory addresses and their associated pages are kept track of in the process's page table. This
a very very brief and lacking explination, but basically virtual memory eliminates external fragmentation (read more on
virtual memory if interested).

```
-----------------------
|
| 10K page
|
|----------------------|
|
| 10K page
|
|----------------------|
|
| 10K page
|
|----------------------|
|
| 10K page
|
------------------------
```

Here is memory that the OS as split into 4 10K pages (theoretically). Now a process comes along and needs... 7K of
space. So the OS will stick it in a page.

```
-----------------------
|
| 10K page
|
|----------------------|
|
| Process 1
|
|----------------------|
|
| 10K page
|
|----------------------|
|
| 10K page
|
------------------------
```

Process 1 now has a page table that tells it what page it is in. Now let's say a process comes along that needs 30K of
space and that this process has 3 functions. The OS will now break up process 2 and stick it in the remaining memory
spaces. Process 2 will still operate correctly because the page table keeps track of what page it resides in.

```
-----------------------
|
| Process 2
| function 1
|----------------------|
|
| Process 1
|
|----------------------|
|
| Process 2
| function 2
|----------------------|
|
| Process 2
| function 3
------------------------
```

Due to virtual memory, we can place Process 2's code in different physical memory locations, and everything is kept in
order due to the page table. Process 2's page table will say, if you want to run code from function 1, look in page 1;
if you want to run code from function 2, look in page 3; and if you want to run code from function 3, look in page 4. OK
this isn't an article on virtual memory, but a brief understanding of it is necessary to understand NX. When I said NX
functions on a per-virtual memory page basis, this means that NX associates a bit with the execution privileges of a
virtual memory page. This is exactly what Windows XP SP2 does. It will mark pages by raising their NX bit to indicate
that these pages are NON-executable. The NX bit is set for pages that content only data (stack, heap). If a program
attempts to execute code on a virtual page with the NX bit set, the hardware will throw an exception immediately and
prevent the code from executing. This prevents attackers from overflowing a buffer with code and then executing the code
(shellcode). However, right now this NX support is only seen in 64 bit processors.

The NX feature is nice for protecting against stack overflows, but what about heap overflows??
Microsoft calls their heap/stack overflow feature (for 32bit processors) sandboxing. Small "cookies" mark the beginning
and end of allocated buffers. These "cookies" are generated based on the heap header. Before memory is allocated and
freed, these cookies are checked for consistency. If they are not consistent, then an exception is thrown. Let's dig in
a little deeper.

As I mentioned earlier, the heap is a double linked list of various free memory. SO, each free piece of memory on the
heap must have a header with various information (pointers, size, flags). The main areas of interest here are the
pointers. Each free block of memory has a pointer to the next, and previous piece of free memory. Back in the day, if a
buffer was overflown, and the neighboring block exsists, and is free, then the next and previous pointers could be
overwritten. When this free block is removed from from the list (calls to the next and previous pointers will occur) and
execution could jump to shellcode. Quick visual

```
LOW MEMORY
-----------------------
|
| block header
|
|----------------------|
|
|
|
| buffer
|
|
|
|----------------------|
|
| block header
|
------------------------
| next pointer
------------------------
| previous pointer
------------------------
HIGH MEMORY
```

The buffer would overflow into the pointers of the neighboring free node. Make sense??? So what Microsoft did with SP2
is to, before each allocation and freeing of heap memory, a quick sanity check is made on the next and previous pointers
by using the following concepts of a doubly linked list:

```
Free_Node -> next -> previous = Free_Node -> previous -> next
Free_Node -> previous -> next = Free_Node
```

If one of these checks fails, then an exception is thrown and execution stops. The cookies are in the block headers, and
are checked to ensure that the buffer hasnt been overflown.

## Conclusion

Well there you have it. I showed you a very simple heap based overflow in order to give you an idea of the concept behind
a heap based overflow, and I also demonstrated a few methods that have been utilized to prevent heap based overflows. I
hope this was an understanding and helpful article.
