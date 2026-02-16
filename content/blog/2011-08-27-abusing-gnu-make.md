+++
title = "Abusing GNU Make"
date = 2011-08-27
+++

At work, when I started to work on the existing projects, I found that the core libraries were committed into the
repository of every other SDK. For instance, if liba.so is used by SDK1 and SDK2, the library was found both in SDK1's
repo and in SDK2's repo. Since we had varieties of core libraries (which are inturn SDKs to me) cattering different
purposes like image decoding, enhancement, extraction, and so on, you can imagine the amount of repo space wasted in
having the duplicate copy of these libraries in every repository. Also, whenever my friends in Tokyo release a new
version of the library, the convention was to push that library into the repo, there by creating its own changeset. My
basic idea was to have a seamless build system for all of the components that we develop and deliver, which will
integrate well with the core libraries at build time as well as at runtime. The goal was to build

1. On 32 and 64 bit Linux.
2. Using specific versions of the core libraries.

Since this is a very common and simple problem on Linux, I thought I can address this by resorting to the pkg-confing. I
tried a couple of examples with it and it worked well. But once the integration of core library version is taken into
account, pkgconfig stuff was getting complicated.

So I decided to have a separate directory structure for the core libraries.

```
LibraryA
|-- doc
|   |-- chm
|   |-- man
|   `-- pdf
|-- include
|-- lib
|   `-- linux
|       |-- 32
|       |   `-- gcc412
|       |       |-- dynamic
|       |       |   |-- debug
|       |       |   `-- release
|       |       `-- static
|       |           |-- debug
|       |           `-- release
|       `-- 64
|           `-- gcc412
|               |-- dynamic
|               |   |-- debug
|               |   `-- release
|               `-- static
|                   |-- debug
|                   `-- release
`-- sample
```

I had two advantages with this approach.

1. No duplicate copies in the SDKs.
2. No confusion over the core library version differences across SDKs.

In addition, every SDK can hold a core library version control file, which I termed as `corelibs.cfg`. At runtime,
preferably during initialization, the SDKs can invoke the `get_version` API on every library which can be cross
verified against its version in the `corelibs.cfg`. If there is a version mismatch, the SDK may not proceed further,
throwing an exception.

Based on all these the created Makefile is as follows:

```make
mode       := release
CC         := gcc
v          := 0
cov        := 0
arc        := 64
ifeq ($(cov), 0)
else
	COV_CFLAGS = -fprofile-arcs -ftest-coverage
	COV_LFLAGS = -lgcov
endif

DEFINES =

# Make sure CORE_LIB_PATH is available.
CORE_LIB_FILE = "corelibs.cfg"

# Include variables corresponding to the corelibs. Populate it from the corelibs version control file.
CORE_COMMON := $$CORE_LIB_PATH/Common/include
A_INC  := $$CORE_LIB_PATH/A/$(shell awk -F" = " '/^A/ { print $$2 }' $(CORE_LIB_FILE) 2>/dev/null)/include
B_INC  := $$CORE_LIB_PATH/B/$(shell awk -F" = " '/^B/ { print $$2 }' $(CORE_LIB_FILE) 2>/dev/null)/include
C_INC  := $$CORE_LIB_PATH/C/$(shell awk -F" = " '/^C/ { print $$2 }' $(CORE_LIB_FILE) 2>/dev/null)/include
D_INC  := $$CORE_LIB_PATH/D/$(shell awk -F" = " '/^D/ { print $$2 }' $(CORE_LIB_FILE) 2>/dev/null)/include
E_INC  := $$CORE_LIB_PATH/E/$(shell awk -F" = " '/^E/ { print $$2 }' $(CORE_LIB_FILE) 2>/dev/null)/include
F_INC  := $$CORE_LIB_PATH/F/$(shell awk -F" = " '/^F/ { print $$2 }' $(CORE_LIB_FILE) 2>/dev/null)/include
# End variable formation

INCPATH = -isystem $(CORE_COMMON) -isystem $(A_INC) -isystem $(F_INC) \
		  -isystem $(C_INC) -isystem $(D_INC) -isystem $(E_INC) \
		  -isystem $(B_INC)

A_LIB  := -L$$CORE_LIB_PATH/A/$(shell awk -F" = " '/^A/ { print $$2 }' $(CORE_LIB_FILE) 2>/dev/null)/lib/linux/$(arch)/gcc412/dynamic/release
B_LIB  := -L$$CORE_LIB_PATH/B/$(shell awk -F" = " '/^B/ { print $$2 }' $(CORE_LIB_FILE) 2>/dev/null)/lib/linux/$(arch)/gcc412/dynamic/release
C_LIB  := -L$$CORE_LIB_PATH/C/$(shell awk -F" = " '/^C/ { print $$2 }' $(CORE_LIB_FILE) 2>/dev/null)/lib/linux/$(arch)/gcc412/dynamic/release
D_LIB  := -L$$CORE_LIB_PATH/D/$(shell awk -F" = " '/^D/ { print $$2 }' $(CORE_LIB_FILE) 2>/dev/null)/lib/linux/$(arch)/gcc412/dynamic/release
E_LIB  := -L$$CORE_LIB_PATH/E/$(shell awk -F" = " '/^E/ { print $$2 }' $(CORE_LIB_FILE) 2>/dev/null)/lib/linux/$(arch)/gcc412/dynamic/release
F_LIB  := -L$$CORE_LIB_PATH/F/$(shell awk -F" = " '/^F/ { print $$2 }' $(CORE_LIB_FILE) 2>/dev/null)/lib/linux/$(arch)/gcc412/dynamic/release

ifeq ($(mode), release)
	flag := -O2
else
	flag := -g3
endif
CFLAGS += $(flag) -Wall -W -Wextra -Wno-override-init -Werror -std=gnu99

OBJDIR := .objs
OBJS = $(addprefix $(OBJDIR)/, genutils.o string-funcs.o thread.o http-receiver.o \
         heartbeat.o read-config.o config-settings.o log.o http.o)

CORE_LIBS = $(A_LIB) -la $(B_LIB) -lb $(C_LIB) -lc $(D_LIB) -ld $(E_LIB) -le $(F_LIB) -lf
EXTERNAL_LIBS = -lcurl
SYSTEM_LIBS = -lpthread
TARGET = sdk1

.PHONY: all
all: $(TARGET)

$(OBJS): | $(OBJDIR)

$(OBJDIR):
	@mkdir -p $(OBJDIR)

$(OBJDIR)/%.o: %.c
	@if test ! -d $$CORE_LIB_PATH; then echo "Invalid CORE_LIB_PATH: $$CORE_LIB_PATH. Please make sure the directory exists."; exit 1; fi
	@if test ! -f $(CORE_LIB_FILE); then echo "Invalid $(CORE_LIB_FILE). Please make sure the core library version control file exists."; exit 1; fi
ifeq ($(v), 0)
	@echo "[$(CC)]	$(@F)"
	@$(CC) -c -m$(arch) $(CFLAGS) $(INCPATH) $(COV_CFLAGS) $(DEFINES) -o $@ $^
else
	$(CC) -c -m$(arch) $(CFLAGS) $(INCPATH) $(COV_CFLAGS) $(DEFINES) -o $@ $^
endif

$(TARGET): $(OBJS)
ifeq ($(v), 0)
	@echo "[$(CC)]	$(@F)"
	@$(CC) -m$(arch) $(LD_FLAGS) -o $@ $(OBJS) $(SYSTEM_LIBS) $(EXTERNAL_LIBS) $(CORE_LIBS) $(COV_LFLAGS)
else
	$(CC) -m$(arch) $(LD_FLAGS) -o $@ $(OBJS) $(SYSTEM_LIBS) $(EXTERNAL_LIBS) $(CORE_LIBS) $(COV_LFLAGS)
endif

clean:
	find . -name "*.o" -o -name "*.gcno" -o -name "*.gcda" -o -name "*.info" | xargs rm -f
	rm -f $(TARGET)
```

As seen, the Makefile takes care of most of the things, starting from linking with the version of
the libraries mentioned in the `corelibs.cfg`, code coverage, building debug or release version of the SDK. When we need
to run the above SDK, we can have a shell script that parses the `corelibs.cfg` and sets its `LD_LIBRARY_PATH` to the
corresponding paths.

Although it may seem a little convoluted for beginners, this will become simple if we understand the GNU make's
variables and conventions.

1. `$$VAR` - An environment variable that needs to be used inside the makefile will have this notation. ie, you override the $ with a $$.
2. `$(VAR)` - Normal variable in Makefile.
3. shell - invokes a shell
4. ifeq, else, endif - GNU make internal variables to branch the execution.

I didn't want to include the unit tests into the Makefile and make it look cluttered, as we have the habit of copying
a standardized Makefile like this across the projects.

Usage:

```sh
make clean && make # default build
make clean && make mode=debug arch=32 v=1 cov=1 # builds for specific combo
```
