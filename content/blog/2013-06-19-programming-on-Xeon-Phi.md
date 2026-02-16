+++
title = "Working with Xeon Phi"
date = 2013-06-19
+++

Yesterday China has announced that it has the worlds fastest super computer that uses Intel Xeon Phi MIC. So I thought
it might be better to write about programming for it.

The Xeon Phi is a co-processor that can speed up numerical calculations. It cannot operate without a main processor. The
many core server is based on the Intel Many Integrated Cores (MIC) architecture. It consists of two parts. A bunch of
Xeon processors (not Phi) and another bunch of Xeon Phi processors (MIC). Xeon processors serve as the main processor
whereas the Xeon Phi serves as the co-processors.

## High-level architecture

There will be two operating systems that will be running on the many core server.

* The Xeon host processors will run RHEL 6 or other platforms as mentioned in the Intel website.
* The Xeon Phi co-processors will run uClinux, a version of Linux that is optimized for embedded platforms.

To access or run application on the Phi, we will have to first connect to the host and then do a ssh to the MIC. As said earlier, the
Xeon Phi has its instructions and architecture optimized for numerical computations (eg: Fourier transform, etc) making
it an ideal candidate for building super computers. The application and the data structures that are used in it and the
computations should be suitable for such an architecture.

To utilize the full capabilities of the Xeon Phi, the following are the prerequisites of an application.

1. The application architecture must be vertically scalable (scale-up). Adding a new worker thread and tying it to a Xeon processor should give a linear improvement in the performance. Adding more cores to the box should result in performance improvement in a _linear_ fashion. Having more worker threads than the number of cores will only degrade the performance.
1. The algorithms must be SIMD optimized for [vectorized data processing](https://en.wikipedia.org/wiki/Vectorization_(parallel_computing)).
1. The application should be optimized for high [locality of reference](https://en.wikipedia.org/wiki/Locality_of_reference).

## Measuring performance on host

1. On the Xeon processor, measure the performance of the application with few threads/processes (based on the application architecture).
1. Add few more threads/processes and tie it to its own CPU and measure the performance (latency and throughput). My consideration is about worst case latency of few milliseconds.
1. If the performance has not increased, then there are bottlenecks in the application. Fix it and tune it before it can be taken to MIC.
1. Repeat this procedure until it is vertically scalable on the host processor.
1. Once the metrics prove that the application is scalable on the Xeon processor, it can be taken to the MIC and tune it further.
1. You will be able to achieve at least 3 to 5 times the performance (of course, depending on the application architecture) with the above procedure.
1. The above procedure addresses only the vertical scalability (up-scaling).
1. Run the application via cachegrind to make sure the data structures fit within the cache line and there are no cache misses.
1. Look at the compiler generated assembly and make sure the instructions are vectorized. Intel has many other tools to support you in this front.

## Measuring performance on MIC

In general, benchmark the algorithm many times on MIC to make sure the metrics are consistent.
If the application does data transformation like JSON/XML or other general purpose computing, the performance will be
worse than what's observed on the host.

As of now, uCLinux that runs on the MIC comes with Linux 2.6.38.
Linux 3.10 has [`SO_REUSEPORT`](https://lwn.net/Articles/542629/) feature that will let the kernel dispatch the
messages, and it remove the bottlenecks caused by the parent/master thread.
