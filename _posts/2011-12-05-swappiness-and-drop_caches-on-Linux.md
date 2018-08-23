---
layout: post
---

In high performance computing somtimes it is common for applications to have all of the data in the physical memory to meet performance criticality. When multiple processes communicate, as we know, shared memory serves as the fastest way of IPC. Any such typical application would initialize the shared memory by loading the data from the disk into the shared memory. Now a question arises - what is the maximum data size that an application can hold in the physical memory, of course, without swapping.

For the sake of discussion, if we are given a 64 GB of RAM, at max, how many giga byte of physical memory (RAM) can I allocate to my data, keeping in mind that the fewer I allocate, the more boxes I would require to split the data gallery.

As a test, I wrote a small app to do what I described above. As it loaded around 19 GB of data into the RAM, the kernel started using swap. After loading 25 GB, the swap usage exponentially increased and at one point in time, it stopped responding and I had to physically bounce the box (plug off and plug in again). This din't make sense to me at the beginning.

At first, why would the kernel swap if there is enough RAM? I did a `man proc` and searched for "swap". I happened to read about `/proc/sys/vm/swappiness` - a parameter which defines the kernel's tendency to swap. The default value of swappiness on RHEL5 is 60. As the "used" RAM size reaches 60% of the total RAM size, the kernel would being to swap.

In my case, 60% of 64 GB is 38.4 GB. But my data size was 19 GB when the kernel started to swap. Where did the remaining 19 GB go, eventually leaving my box in a non-responsive state?! Again intriguing. I could not find the relation between the data size and the memory required to store it.

Few more runs and a close memory monitoring showed that the kernel caches all the data (yes, almost all the data that are used very recently). If an application has loaded 2 GB of data into the memory, the kernel would cache 4 GB. 2 GB for the actual shared memory data and 2 GB of unused cache using which the data was read/copied into the shared memory. On a typical server environment (runlevel 3), you wouldn't expect this to happen, since apart from the main apps no other applications will be running (like `yum-updatesd`, vlc, rhythmbox, etc). One would expect the kernel to drop the unused cache immediately. proc man page again showed one other important parameter - `/proc/sys/vm/drop_caches`. This entry point is helpful in instructing the kernel to drop the unused cache.

To free pagecache:

```sh
# echo 1 > /proc/sys/vm/drop_caches
```

To free dentries and inodes:

```sh
# echo 2 > /proc/sys/vm/drop_caches
```

To free pagecache, dentries and inodes:

```
# echo 3 > /proc/sys/vm/drop_caches
```

Mind the space between before the > symbol.

When an application loads all the data into the memory during its initialization and then never tends to read the disk, `drop_caches` is a real boon if you can't change the code (in my case, at the data center). In my case above, I was able to load 60 GB of data into the shared memory and share it with the other processes. The technique was to clear the cache frequently as the application initialized.

```sh
while :; do
    echo 3 > /proc/sys/vm/drop_caches
    sleep 30
done
```

As a thumb rule, swappiness must be set to 0 (`echo 0 > /proc/sys/vm/swappiness` or via `sysctl.conf`) before the application starts and the `drop_caches` must be set to 3 periodically to avoid any kind of swaps and performance degradations.

Once the app has been initialized and all the 60 GB has been loaded into the memory, the while loop to drop the unused cache is not needed and it can be terminated safely. But the moment you do a huge file read, don't forget to run the script in the background, of course, as root. The need to `drop_caches` entirely depends on your application. Setting swappiness to 0 is ideal in my opinion for all the server environments.
[vmstat log](http://codepad.org/6pXz0UOH) for the below content, when the swappiness was set to 60 and `drop_caches` was *not* triggered (by default its value will be 0).

```
18:46:22 ~/MySpace/files-to-load# ls -l
total 4198384
-rw-r--r-- 1 root root 1073731945 Jan 2 18:39 7
-rw-r--r-- 1 root root 1073731945 Jan 2 18:39 8
-rw-r--r-- 1 root root 1073731945 Jan 2 18:40 9
-rw-r--r-- 1 root root 1073731945 Jan 2 18:40 10
18:46:22 ~/MySpace/files-to-load#
```

For the same content, [vmstat log](http://codepad.org/9bNwcdbW) when swappiness is set to 0 and frequent echo 3 on `drop_caches`.

If it is not possible to do this `drop_cache` thing system wide, it can also be done programmatically via `posix_fadvice` API with the `POSIX_FADV_NOREUSE` option. A simple wrapper like this can be employed to use across all the services. At minimum, I have observed that services that generate lot of logs will benefit from this as the logs need not be cached by the kernel.

```c++
void discardKernelCache(FILE* fp)
{
    if (fp != null)
    {
        int fd = ::fileno(fp);
        ::fdatasync(fd);
        ::posix_fadvise(fd, 0, 0, POSIX_FADV_DONTNEED);
    }
}

template <class T>
void writeFile(std::string filename, const T& buffer, bool discardKernelBuffer = true)
{
    FILE* fp = ::fopen(filename.data(), "w");
    if (discardKernelBuffer)
        discardKernelCache(fp);
    ::fwrite(buffer.data(), 1, buffer.size(), fp);
    ::fflush(fp);
    ::fclose(fp);
}

template <class T>
void readFile(std::string filename, T& buffer, bool discardKernelBuffer = true)
{
    FILE* fp = ::fopen(filename.data(), "r");
    if (discardKernelBuffer)
        discardKernelCache(fp);
    ::fseek(fp, 0, SEEK_END);
    size_t fileSize = ::ftell(fp);
    ::rewind(fp);
    buffer.resize(fileSize);
    ::fread(buffer.data(), 1, buffer.size(), fp);
    ::fclose(fp);
}
```

