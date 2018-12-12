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

| Time (s) | Machine | -% of #1 | -% of N-1 | Command |
| --- | --- | --- | --- | --- |
| 289.65 | Intel Core i7-8700K | 0% | 0% | `cabal new-build clash-ghc --ghc-options="+RTS -qn8 -A32M -RTS -j12" -j8` | 
| 306.53 | Intel Core i7-7700K@4.8GHz | -6%% | -6% | `cabal new-build clash-ghc --ghc-options="+RTS -qn8 -A32M -RTS -j4" -j4` | 
| 369.72 | 2x Intel Xeon Gold 6140M | -21.7% | -17.1% | `cabal new-build clash-ghc --ghc-options="+RTS -qn8 -A32M -RTS -j8" -j72` |
| 372.79 | AMD Ryzen 2700X | -22.3% | -0.9% | `cabal new-build clash-ghc --ghc-options="+RTS -qn8 -A32M -RTS -j16" -j16` |
| 375.59 | AMD Threadripper 2990wx | -22.9% | -0.7% | `cabal new-build clash-ghc --ghc-options="+RTS -qn8 -A32M -RTS -j32" -j32` |


#### Building Stack

| Time (s) | Machine | -% of #1 | -% of N-1 | Command |
| --- | --- | --- | --- | --- |
| 289.42 | Intel Core i7-8700K | 0% | 0% | `GHC_OPTIONS="+RTS -qn8 -A32M -RTS -j4"  cabal new-install stack-1.9.3 -j8` |
| 315.74 | 2x Intel Xeon Gold 6140M | -8.3% | -8.3% | `GHC_OPTIONS="+RTS -qn8 -A32M -RTS -j8"  cabal new-install stack-1.9.3 -j18` |
| 329.23 | AMD Threadripper 2990wx | -12.1% | -4.1% | `GHC_OPTIONS="+RTS -qn8 -A32M -RTS -j32"  cabal new-install stack-1.9.3 -j8` |
| 342.92 | Intel Core i7-7700K@4.8GHz | -15.6% | -4% | `GHC_OPTIONS="+RTS -qn8 -A32M -RTS -j4"  cabal new-install stack-1.9.3 -j8` |
| 360.02 | AMD Ryzen 2700X | -19.6% | -4.7% | `GHC_OPTIONS="+RTS -qn8 -A32M -RTS -j16"  cabal new-install stack-1.9.3 -j8` |

#### Building GHC

| Time (s) | Machine | -% of #1 | -% of N-1 | Command |
| --- | --- | --- | --- | --- |
| 1205.29 | Intel Core i7-8700K | 0% | 0% | `make -j8` |
| 1305.27 | Intel Core i7-7700K@4.8GHz | -7.7% | -7.7% | `make -j8` |
| 1328.3 | 2x Intel Xeon Gold 6140M | -9.3% | -1.7% | `make -j72` |
| 1382.93 | AMD Threadripper 2990wx | -12.8% | -4% | `make -j64` |
| 1572.71 | AMD Ryzen 2700X | -23.3% | -12.1% | `make -j16` |

#### GHC Testsuite

| Time (s) | Machine | -% of #1 | -% of N-1 | Command |
| --- | --- | --- | --- | --- |
| 106.44 | 2x Intel Xeon Gold 6140M | 0% | 0% | `THREADS=72 ./validate --no-clean --testsuite-only` |
| 159.48 | AMD Threadripper 2990wx | -33.3% | -33.3% | `THREADS=64 ./validate --no-clean --testsuite-only` |
| 265.16 | Intel Core i7-8700K | -59.9% | -39.9 | `THREADS=12 ./validate --no-clean --testsuite-only` |
| 293.69 | AMD Ryzen 2700X | -63.8% | -9.7% | `THREADS=16 ./validate --no-clean --testsuite-only` |
| 343.06 | Intel Core i7-7700K@4.8GHz | -69% | -14.4% | `THREADS=8 ./validate --no-clean --testsuite-only` |


#### Clash Testsuite

| Time (s) | Machine | -% of #1 | -% of N-1 | Command |
| --- | --- | --- | --- | --- |
| 45.63 | 2x Intel Xeon Gold 6140M | 0% | 0% | `cabal new-run -- testsuite -p clash -j72` |
| 64.84 | AMD Threadripper 2900wx | -29.6% | -29.6% | `cabal new-run -- testsuite -p clash -j32` |
| 134.27 | Intel Core i7-8700K | -66.0% | -51.7% | `cabal new-run -- testsuite -p clash -j8` |
| 157.87 | AMD Ryzen 2700X | -71.1% | -14.9% | `cabal new-run -- testsuite -p clash -j16` |
| 177.77 | Intel Core i7-7700K@4.8GHz | -74.3% | -11.2% | `cabal new-run -- testsuite -p clash -j8` |

# Effect of faster RAM

### Intel Core i7-7700K@4.8GHz

#### Building Clash

| Time (s) | Memory | +% of N+1 | Command |
| --- | --- | --- | --- |
| 306.53 | 2x 16GB DDR4-3000 16-17-17-35 | +0% | `cabal new-build clash-ghc --ghc-options="+RTS -qn8 -A32M -RTS -j4" -j4` | 
| 306.88 | 2x 16GB DDR4-2400 15-15-15-39 | 0% | `cabal new-build clash-ghc --ghc-options="+RTS -qn8 -A32M -RTS -j4" -j4` | 

#### Building Stack

| Time (s) | Memory | +% of N+1 | Command |
| --- | --- | --- | --- |
| 342.92 | 2x 16GB DDR4-3000 16-17-17-35 | +1.1% | `GHC_OPTIONS="+RTS -qn8 -A32M -RTS -j4"  cabal new-install stack-1.9.3 -j8` |
| 346.59 | 2x 16GB DDR4-2400 15-15-15-39 | 0% | `GHC_OPTIONS="+RTS -qn8 -A32M -RTS -j4"  cabal new-install stack-1.9.3 -j8` |

#### Building GHC

| Time (s) | Memory | +% of N+1 | Command |
| --- | --- | --- | --- |
| 1305.27 | 2x 16GB DDR4-3000 16-17-17-35| +2% | `make -j8` |
| 1331.31 | 2x 16GB DDR4-2400 15-15-15-39 | 0% | `make -j8` |

#### GHC Testsuite

| Time (s) | Memory | +% of N+1 | Command |
| --- | --- | --- | --- |
| 343.06 | 2x 16GB DDR4-3000 16-17-17-35 | +2% |`THREADS=8 ./validate --no-clean --testsuite-only` |
| 349.64 | 2x 16GB DDR4-2400 15-15-15-39 | 0% | `THREADS=8 ./validate --no-clean --testsuite-only` |

#### Clash Testsuite

| Time (s) | Memory | +% of N+1 | Command |
| --- | --- | --- | --- |
| 177.77 | 2x 16GB DDR4-3000 16-17-17-35 | +3.5% | `cabal new-run -- testsuite -p clash -j8` |
| 184.04 | 2x 16GB DDR4-2400 15-15-15-39 | 0% | `cabal new-run -- testsuite -p clash -j8` |

### AMD Ryzen 2700X

#### Building Clash

| Time (s) | Memory | +% of N+1 | Command |
| --- | --- | --- | --- |
| 372.79 | 2x 16GB DDR4-3000 16-17-17-35 | 0% | `cabal new-build clash-ghc --ghc-options="+RTS -qn8 -A32M -RTS -j16" -j16` | 

#### Building Stack

| Time (s) | Memory | +% of N+1 | Command |
| --- | --- | --- | --- |
| 360.02 | 2x 16GB DDR4-3000 16-17-17-35 | 0% | `GHC_OPTIONS="+RTS -qn8 -A32M -RTS -j16"  cabal new-install stack-1.9.3 -j8` |

#### Building GHC

| Time (s) | Memory | +% of N+1 | Command |
| --- | --- | --- | --- |
| 1572.71 | 2x 16GB DDR4-3000 16-17-17-35| 0% | `make -j16` |

#### GHC Testsuite

| Time (s) | Memory | +% of N+1 | Command |
| --- | --- | --- | --- |
| 293.69 | 2x 16GB DDR4-3000 16-17-17-35 | +10.8% |`THREADS=16 ./validate --no-clean --testsuite-only` |
| 324.21 | 4x 16GB DDR4-2400 15-15-15-39 | 0% | `THREADS=16 ./validate --no-clean --testsuite-only` |

#### Clash Testsuite

| Time (s) | Memory | +% of N+1 | Command |
| --- | --- | --- | --- |
| 157.87 | 2x 16GB DDR4-3000 16-17-17-35 | 0% | `cabal new-run -- testsuite -p clash -j8` |

# AMD vs Intel

## Costs (on 12-Dec-2018)

### Upgrade
| CPU | Configuration | Cost | +% of N-1 |
| --- | --- | --- | --- |
| AMD Ryzen 2700X |  CPU: AMD Ryzen 2700X | [€ 548,75](https://azerty.nl/basket/?code=YTozOntpOjI0NDYxODg7aToxO2k6MjYzMDM1MztpOjE7aTo0NTQyODA7aToxO30=) | 0% |
| | Motherboard: Asrock B450M Pro4 | |
| | Memory: Corsair CMK16GX4M2B3000C15 | |
| Intel Core i7-8700K | CPU: Intel Core i7 8700K | [€ 694,80](https://azerty.nl/basket/?code=YTozOntpOjQ1NDI4MDtpOjE7aToyMjIxODIzO2k6MTtpOjIyMzQ3OTY7aToxO30=) | +26.6% |
| | Motherboard: MSI 370-A PRO | |
| | Memory: Corsair CMK16GX4M2B3000C15  | |

### Full system
| Vendor | Cost | +% of N-1 |
| --- | --- | --- |
| AMD | [€ 1.002,19](https://azerty.nl/basket/?code=YTo3OntpOjQ1NDI4MDtpOjE7aTo3MTg4OTtpOjE7aToyNDkxMDQ1O2k6MTtpOjE5NTgxOTtpOjE7aToyNjMwMzUzO2k6MTtpOjI0NDYxODg7aToxO2k6MTY2MTUwNztpOjE7fQ==) | 0% |
| Intel | [€ 1.167,80](https://azerty.nl/basket/?code=YTo4OntpOjQ1NDI4MDtpOjE7aToyMjIxODIzO2k6MTtpOjIyMzQ3OTY7aToxO2k6NzE4ODk7aToxO2k6NzEwMzk7aToxO2k6MjI5NTk5NTtpOjE7aToyNDkxMDQ1O2k6MTtpOjE5NTgxOTtpOjE7fQ==) | +16.4% |

## Performance

#### Building Clash

| Time (s) | Memory | +% of N+1 | Command |
| --- | --- | --- | --- |
| 289.65 | Intel Core i7-8700K | +28.7% | `cabal new-build clash-ghc --ghc-options="+RTS -qn8 -A32M -RTS -j12" -j8` | 
| 372.79 | AMD Ryzen 2700X | 0% | `cabal new-build clash-ghc --ghc-options="+RTS -qn8 -A32M -RTS -j16" -j16` | 

#### Building Stack

| Time (s) | Memory | +% of N+1 | Command |
| --- | --- | --- | --- |
| 289.42 | Intel Core i7-8700K | +24.4% | `GHC_OPTIONS="+RTS -qn8 -A32M -RTS -j4"  cabal new-install stack-1.9.3 -j8` |
| 360.02 | AMD Ryzen 2700X | 0% | `GHC_OPTIONS="+RTS -qn8 -A32M -RTS -j16"  cabal new-install stack-1.9.3 -j8` |

#### Building GHC

| Time (s) | Memory | +% of N+1 | Command |
| --- | --- | --- | --- |
| 1205.29 | Intel Core i7-8700K | +30.5% | `make -j8` |
| 1572.71 | AMD Ryzen 2700X | 0% | `make -j16` |

#### GHC Testsuite

| Time (s) | Memory | +% of N+1 | Command |
| --- | --- | --- | --- |
| 265.16 | Intel Core i7-8700K | +10.8% |`THREADS=12 ./validate --no-clean --testsuite-only` |
| 293.69 | AMD Ryzen 2700X | 0% | `THREADS=16 ./validate --no-clean --testsuite-only` |

#### Clash Testsuite

| Time (s) | Memory | +% of N+1 | Command |
| --- | --- | --- | --- |
| 134.27 | Intel Core i7-8700K | +17.6% | `cabal new-run -- testsuite -p clash -j8` |
| 157.87 | AMD Ryzen 2700X | 0% | `cabal new-run -- testsuite -p clash -j16` |
