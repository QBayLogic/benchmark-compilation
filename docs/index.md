__This is a blog post about pitting different CPUs againts eachother where compiling Haskell projects is the benchmarked workload; it is *not* about benchmarking Haskell programs, improving the run-time of your Haskell program, improving GHC to lower compile times, etc.__

This project started when we acquired two new machines for the office, a "workstation" and a "server".
Since we were busy with projects, and the workstation was mostly an upgrade to an existing machine, we decided to run some benchmarks.
Not just any random benchmark though, we wanted to see how well they performed at the job we use them for: compiling Haskell projects.
Another reason is that we picked the parts for our workstation based on benchmarks found on sites like [Phoronix](https://phoronix.com) and [https://openbenchmarking.org/](https://openbenchmarking.org/), specifically benchmarks which seem related to the task at hand, such as [these compilation benchmarks](https://www.phoronix.com/scan.php?page=article&item=intel-core-9900k-linux&num=4); but "of course" those compilation benchmarks did not include Haskell/GHC.

In [the compilation benchmarks @ Phoronix](https://www.phoronix.com/scan.php?page=article&item=intel-core-9900k-linux&num=4), AMD's Ryzen 2700X seemed pretty much on par with Intel's Core i7-8700k; so we decided to build our workstation around the 2700X hoping that its 8 cores would give it a leg up over the i7-8700k's 6 cores in our highly parallel test suites.
Our benchmarks, however, show that we should've bought an i7-8700k instead.

Our [benchmark script](https://github.com/QBayLogic/benchmark-compilation/blob/146f8a2d55266a8663de64fa06811ad4e772acb4/benchmark2.sh), and [collected results](https://github.com/QBayLogic/benchmark-compilation/tree/master/results), can all be found on [the github project hosthing this blog](https://github.com/QBayLogic/benchmark-compilation)

# The benchmarks

### Building the Clash compiler

This builds the clash compiler, and all of its dependencies, including haddock; with a populated download cache, and an empty Cabal store.
The Clash compiler has many dependencies, large and small, so it gives us a large range of Haskell project where we can exercise different levels of parallelism.

### Building the Stack executable

This builds the stack-1.9.3 executable, without haddock.
It has even more dependencies than the Clash compiler, and probably holds more weight in terms of projects-haskellers-care-about. 

### Building GHC

This builds an almost "perf" build of GHC, i.e. the one that's included in binary distributions. The almost part is that we do not build the documentation.

### GHC Testsuite

### Clash Testsuite

# Systems

### Workstations

#### AMD Ryzen 2700X

  * CPU: Ryzen 2700X (physical cores: 8)
  * Motherboard: ASRock X470 Master SLI
  * Memory: Corsair CMK32GX4M2B3000C15
  * SSD: Samsung 970 Evo 1TB
  
  * Memory settings: 32 GB DDR4-3000 16-17-17-35
  * OS: Ubuntu 18.04.1 LTS
  * `uname -vr`: 4.15.0-39-generic #42-Ubuntu SMP Tue Oct 23 15:48:01 UTC 2018
  * CPU power governer: performance

#### Intel Core i7-8700K

  * CPU: Core i7-8700K (physical cores: 6)
  * Motherboard: Asus PRIME Z370-P II
  * Memory: 4x Corsair CM4X16GC3000C15K4
  * SSD: Samsung 970 EVO 1TB
  
  * Memory settings: 64 GB DDR4-3000 15-17-17-35
  * OS: Ubuntu 18.04.1 LTS
  * `uname -vr`: 4.15.0-39-generic #42-Ubuntu SMP Tue Oct 23 15:48:01 UTC 2018
  * CPU power governer: performance

#### Intel Core i7-7700K

  * CPU: Core i7-7700k (physical cores: 4)
  * Motherboard: Asus Prime Z270-A
  * Memory: Corsair CMK32GX4M2B3000C15
  * SSD: Samsung 960 Pro 512GB + Samsung 960 EVO 250GB
  
  * Overclock: all cores 4.8GHz
  * Memory settings: 32 GB DDR4-3000 16-17-17-35
  * OS: Ubuntu 18.04.1 LTS
  * `uname -vr`: 4.15.0-42-generic #45-Ubuntu SMP Thu Nov 15 19:32:57 UTC 2018
  * CPU power governer: performance  

### Servers

#### AMD Threadripper 2990wx

  * CPU: Threadripper 2990wx (physical cores: 32)
  * Motherboard: ASRock X399 Taichi
  * Memory: 8x Samsung M391A2K43BB1-CRC
  * SSD: Samsung 970 Pro 1TB
  
  * Memory settings: 128 GB DDR4-2666 18-19-19-43 ECC
  * OS: Ubuntu 18.04.1 LTS
  * `uname -vr`: 4.15.0-42-generic #45-Ubuntu SMP Thu Nov 15 19:32:57 UTC 2018
  * CPU power governer: performance
  
#### Intel Xeon Gold 6140M

  * CPU: 2x Xeon Gold 6140M (physical cores: 2x 18)
  * Motherboard: Intel S2600STB
  * Memory: 16x Kingston KSM26RS4/16HAI
  
  * Memory settings: 256 GB DDR4-2666 19-19-19-32 ECC
  * OS: Ubuntu 18.04.1 LTS
  * `uname -vr`: 4.15.0-36-generic #39-Ubuntu SMP Mon Sep 24 16:19:09 UTC 2018
  * CPU power governer: performance
  
# Results

#### Building Clash

| Time (s) | Machine | Compared to #1 | Command |
| --- | --- | --- | --- |
| 372.79 | AMD Ryzen 2700X | `cabal new-build clash-ghc --ghc-options="+RTS -qn8 -A32M -RTS -j16" -j16` |


#### Building Stack

| Rank | Time (s) | Machine | Compared to #1 | Command |
| --- | --- | --- | --- |
| 360.02 | AMD Ryzen 2700X |  | `GHC_OPTIONS="+RTS -qn8 -A32M -RTS -j16"  cabal new-install stack-1.9.3 -j8` |


#### Building GHC

| Rank | Time (s) | Machine | Compared to #1 |
| --- | --- | --- | --- |
| 1572.71 | AMD Ryzen 2700X |  | `make -j16` |

#### GHC Testsuite

| Rank | Time (s) | Machine | Compared to #1 |
| --- | --- | --- | --- |
| 293.69 | AMD Ryzen 2700X |  | `THREADS=16 ./validate --no-clean --testsuite-only` |
