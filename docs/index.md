__This is a blog post about pitting different CPUs againts eachother where compiling Haskell projects is the benchmarked workload; it is *not* about benchmarking Haskell programs, improving the run-time of your Haskell program, improving GHC to lower compile times, etc.__

This project started when we acquired two new machines for the office, a "workstation" and a "server".
Since we were busy with projects, and the workstation was mostly an upgrade to an existing machine, we decided to run some benchmarks.
Not just any random benchmark though, we wanted to see how well they performed at the job we use them for: compiling Haskell projects.
Another reason is that we picked the parts for our workstation based on benchmarks found on sites like [Phoronix](https://phoronix.com) and [https://openbenchmarking.org/](https://openbenchmarking.org/), specifically benchmarks which seem related to the task at hand, such as [these compilation benchmarks](https://www.phoronix.com/scan.php?page=article&item=intel-core-9900k-linux&num=4); but "of course" those compilation benchmarks did not include Haskell/GHC.

In [the compilation benchmarks @ Phoronix](https://www.phoronix.com/scan.php?page=article&item=intel-core-9900k-linux&num=4), AMD's Ryzen 7 2700X seemed pretty much on par with Intel's Core i7-8700k; so we decided to build our workstation around the 2700X hoping that its 8 cores would give it a leg up over the i7-8700k's 6 cores in our highly parallel test suites.
Our benchmarks, however, show that we should've bought an i7-8700k instead.

Our [benchmark script](https://github.com/QBayLogic/benchmark-compilation/blob/146f8a2d55266a8663de64fa06811ad4e772acb4/benchmark2.sh), and [collected results](https://github.com/QBayLogic/benchmark-compilation/tree/master/results), can all be found on [the github project hosthing this blog](https://github.com/QBayLogic/benchmark-compilation)

# Haskell workstation benchmarks

In your day-to-day development cycle you probably execute the following compile tasks:

1. Compile your project and all its dependencies (infrequent)
2. Compile your project and run the (fast) test suite (frequent)
3. Compile the module you're currently working on (very often)

Tasks 1. and 2. are likely to benifit from CPUs that have more cores, which can then exploit the available parallelism; while task 3 will likely benefit from higher single-core performance.
Given then dependencies between modules and packages, the available parallelism might be limited, and so a CPU with fewer cores but higher single-threaded performance might outperform a CPU that has more cores but lower single-thread performance on task 1. and 2.

__All of these benchmarks are executed with *GHC 8.4.4* and *cabal-install 2.4.1.0*__

To benchmark all three compile task, we have created the following tests.

### 1. Building the Clash compiler

This builds the clash compiler, and all of its dependencies, including haddock.
The Clash compiler has many dependencies, large and small, so it gives us a large range of Haskell project where we can exercise different levels of parallelism.

We make a checkout of a [fixed commit](https://github.com/clash-lang/clash-compiler/commits/5f9dd26825fb912896d7d1837238117131f0c37f), build it once to populate the download cache, then delete the Cabal store and `dist-newstyle` directory, and subsequently run:

```
cabal new-build clash-ghc --ghc-options="+RTS -qn8 -A32M -RTS -j{GHC_THREADS}" -j{CABAL_THREADS}
```

we repeat this process for different values of `GHC_THREADS` and `CABAL_THREADS`, deleting the Cabal store and `dist-newstyle` directories between runs. Some additional info on the flags:

* `-j{GHC_THREADS}`: we compile with multiple GHC threads, i.e. exploit the available compile-parallelism within a single package.
* `-j{CABAL_THREADS}`: we compile with multiple Cabal threads, i.e. exploit the available compile-parallelism between packages.
* `+RTS -qn8 -A32M -RTS`: These settings where given to us by Ben Gamari, GHC maintainer, after we discovered very poor performance at higher thread counts. The [`-qn8` settings](https://downloads.haskell.org/~ghc/latest/docs/html/users_guide/runtime_control.html#rts-flag--qn%20%E2%9F%A8x%E2%9F%A9) limits the number of threads participating in garbage-collection(GC) to 8; GC is bandwidth-bound, so over-saturation in terms of cores participating in GC can hurt performance; additionally, synchronisation between a large amount of GC threads also hurts performance. To give an indication, for one of the benchmarked machines, running the test with `64` GHC threads, and `64` Cabal threads, the runtime went from [1742s](https://github.com/QBayLogic/benchmark-compilation/blob/master/results/02-04.csv) to [377.14s](https://github.com/QBayLogic/benchmark-compilation/blob/master/results/02-05.csv) using the update RTS settings. The [`-A32M` setting](https://downloads.haskell.org/~ghc/latest/docs/html/users_guide/runtime_control.html#rts-flag--A%20%E2%9F%A8size%E2%9F%A9) sets the allocation area to 32MB, reducing the number of collections and promotions. Benchmarking the effect of these setting different values for these options would be a blog post on its own. Given that the chosen values gave peformance improvements across the board kept them fixed for all variations of `GHC_THREADS` and `CABAL_THREADS`. Really, you want to check the productivity number by running GHC with `+RTS -s -RTS` to check how/if RTS parameters improve compiler performance.

We'll be comparing the following results between the different machines:

1. `GHC_THREADS=1 CABAL_THREADS=1` to compare single-threaded performance which is important for task 3.
2. `GHC_THREADS=N CABAL_THREADS=1` to compare multi-core performance which is important for task 2.
3. `GHC_THREADS=X CABAL_THREADS=Y` to compare multi-core performance which is important for task 1.

### 2. Building the Stack executable

This builds the stack-1.9.3 executable, without haddock.
It has even more dependencies than the Clash compiler, and probably holds more weight in terms of projects-haskellers-care-about.
We build it once to populate the download cache, then delete the Cabal store and subsequently:

1. Edit the global `~/.cabal/config` to set: `ghc-options: +RTS -qn8 -A32M -RTS -j{GHC_THREADS}`
2. Run `cabal new-install stack-1.9.3 -j{CABAL_THREADS}`

We repeat this process for different values of `GHC_THREADS` and `CABAL_THREADS`, deleting the Cabal store between runs. The flags have the same meaning as in the "Building Clash" test, and we'll be comparing the results for the same variation of `GHC_THREADS` and `CABAL_THREADS` as we do for the "Building Clash" test.

### 3. Building GHC

This builds an almost "perf" build of GHC, i.e. the one that's included in binary distributions, for a [specific commit](https://github.com/ghc/ghc/commit/47bbc709cb221e32310c6e28eb2f33acf78488c7). The almost part is that we do not build the documentation.
The command that we run for the test is:

```
make -j{THREADS}
```

where we run `make clean` and `./configure` before every run. We'll compare results for `THREADS=1` for single-core performance (task 3), and `THREADS=N` for multi-core performance (task 1. and 2.).

### 4. GHC Testsuite

This runs the fast testsuite of GHC. We start with the the above-mentioned checkout of the GHC compiler. Run a `make maintainer-clean`  to clear ALL the build artifect, then run `./validate --build-only` to build a version of GHC that will execute the test suite, and then run:

```
THREADS={NUMTHREADS} ./validate --no-clean --testsuite-only
```

Although the script iterates over multiple `NUMTHREADS`, for this blog post, we'll just be looking at `THREADS=N`, i.e. only compare multi-core performance.

### 5. Clash Testsuite

The Clash integration tests converts Haskell to HDL, and then runs the HDL simulator to see whether the generated HDL is correct. Because setting up these simulators can be a pain, for this benchmark we only run the convert-to-hdl part. The command that we run will be:

```
cabal new-run -0- clash-testsuite -p clash -j{NUMTHREADS}
```

Although the script iterates over multiple `NUMTHREADS`, for this blog post, we'll just be looking at `-jN`, i.e. only compare multi-core performance.

# Systems

We had several systems at our disposal for this benchmark.
We'll classify them under "workstation" and "server" given their intended use.

### Workstations

#### AMD Ryzen 7 2700X

This is the workstation that we acquired as an upgrade, it has the following specs:

  * CPU: Ryzen 2700X (physical cores: 8)
  * Motherboard: ASRock X470 Master SLI
  * Memory: Corsair CMK32GX4M2B3000C15
  * SSD: Samsung 970 Evo 1TB
  
Note that we actually ordered the above machine with some G.Skill Fortis F4-2400C15Q-64GFT memory, but for this performance shootout we'll be comparing it using the faster Corsair CMK32GX4M2B3000C15 memory.
We'll discuss the effect of faster memory in a different section.

We configured this machine as follows:
  
  * Memory settings: 32 GB (2x16GB) DDR4-3000 16-17-17-35
  * OS: Ubuntu 18.04.1 LTS
  * `uname -vr`: 4.15.0-39-generic #42-Ubuntu SMP Tue Oct 23 15:48:01 UTC 2018
  * CPU power governer: performance
  
 Where the "CPU power governer" is the value that set using:
 
 ```
 cpupower frequency-set -g {GOVERNER}
 ```
 
 and ensures that the linux kernel picks operating frequencies such that the CPU can perform at its very best (at the cost of power efficiency).

#### Intel Core i7-8700K

One of our clients gratiously allowed us to use one of their workstations to run this benchmark.
It's roughly equal to the machine we would've picked as the counter part to the above Ryzen 7 2700X machine.
It has the following specifications:

  * CPU: Core i7-8700K (physical cores: 6)
  * Motherboard: Asus PRIME Z370-P II
  * Memory: 4x Corsair CM4X16GC3000C15K4
  * SSD: Samsung 970 EVO 1TB
  
And is configured as follows:
  
  * Memory settings: 64 GB (4x16GB) DDR4-3000 15-17-17-35
  * OS: Ubuntu 18.04.1 LTS
  * `uname -vr`: 4.15.0-39-generic #42-Ubuntu SMP Tue Oct 23 15:48:01 UTC 2018
  * CPU power governer: performance

#### Intel Core i7-7700K

This is one of our own machines again.
We used the RAM from this machine in the Ryzen 7 2700X machine for the purposes of this benchmark.

  * CPU: Core i7-7700k (physical cores: 4)
  * Motherboard: Asus Prime Z270-A
  * Memory: Corsair CMK32GX4M2B3000C15
  * SSD: Samsung 960 Pro 512GB + Samsung 960 EVO 250GB
  
It's configured as follows, using a vendor overclock setting all cores to run at 4.8GHz.
  
  * Overclock: all cores 4.8GHz
  * Memory settings: 32 GB (2x16GB) DDR4-3000 16-17-17-35
  * OS: Ubuntu 18.04.1 LTS
  * `uname -vr`: 4.15.0-42-generic #45-Ubuntu SMP Thu Nov 15 19:32:57 UTC 2018
  * CPU power governer: performance  

### Servers

#### AMD Threadripper 2990wx

Our new build server:

  * CPU: Threadripper 2990wx (physical cores: 32)
  * Motherboard: ASRock X399 Taichi
  * Memory: 8x Samsung M391A2K43BB1-CRC
  * SSD: Samsung 970 Pro 1TB
  
Which for the purposes of this benchmark was configured as follows:
  
  * Memory settings: 128 GB (8x16GB) DDR4-2666 18-19-19-43 ECC
  * OS: Ubuntu 18.04.1 LTS
  * `uname -vr`: 4.15.0-42-generic #45-Ubuntu SMP Thu Nov 15 19:32:57 UTC 2018
  * CPU power governer: performance
  
#### Intel Xeon Gold 6140M

One of our clients gratiously allowed us to use one of their beefy servers to run this benchmark.

  * CPU: 2x Xeon Gold 6140M (physical cores: 2x 18)
  * Motherboard: Intel S2600STB
  * Memory: 16x Kingston KSM26RS4/16HAI
  
Which for the purposes of this benchmark was configured as follows:

  * Memory settings: 256 GB (16x16GB) DDR4-2666 19-19-19-32 ECC
  * OS: Ubuntu 18.04.1 LTS
  * `uname -vr`: 4.15.0-36-generic #39-Ubuntu SMP Mon Sep 24 16:19:09 UTC 2018
  * CPU power governer: performance
  
# Shootout

We start by comparing absolute, multi-core, performance:

#### Building Clash

| Time (s) | Machine | Performance vs #1 | Performance vs N-1 | Command |
| --- | --- | --- | --- | --- |
| 289.65 | Intel Core i7-8700K | 0% | 0% | `cabal new-build clash-ghc --ghc-options="+RTS -qn8 -A32M -RTS -j12" -j8` | 
| 306.53 | Intel Core i7-7700K@4.8GHz | -6%% | -6% | `cabal new-build clash-ghc --ghc-options="+RTS -qn8 -A32M -RTS -j4" -j4` | 
| 369.72 | 2x Intel Xeon Gold 6140M | -21.7% | -17.1% | `cabal new-build clash-ghc --ghc-options="+RTS -qn8 -A32M -RTS -j8" -j72` |
| 372.79 | AMD Ryzen 2700X | -22.3% | -0.9% | `cabal new-build clash-ghc --ghc-options="+RTS -qn8 -A32M -RTS -j16" -j16` |
| 375.59 | AMD Threadripper 2990wx | -22.9% | -0.7% | `cabal new-build clash-ghc --ghc-options="+RTS -qn8 -A32M -RTS -j32" -j32` |

#### Building Stack

| Time (s) | Machine | Performance vs #1 | Performance vs N-1 | Command |
| --- | --- | --- | --- | --- |
| 289.42 | Intel Core i7-8700K | 0% | 0% | `GHC_OPTIONS="+RTS -qn8 -A32M -RTS -j4"  cabal new-install stack-1.9.3 -j8` |
| 315.74 | 2x Intel Xeon Gold 6140M | -8.3% | -8.3% | `GHC_OPTIONS="+RTS -qn8 -A32M -RTS -j8"  cabal new-install stack-1.9.3 -j18` |
| 329.23 | AMD Threadripper 2990wx | -12.1% | -4.1% | `GHC_OPTIONS="+RTS -qn8 -A32M -RTS -j32"  cabal new-install stack-1.9.3 -j8` |
| 342.92 | Intel Core i7-7700K@4.8GHz | -15.6% | -4% | `GHC_OPTIONS="+RTS -qn8 -A32M -RTS -j4"  cabal new-install stack-1.9.3 -j8` |
| 360.02 | AMD Ryzen 2700X | -19.6% | -4.7% | `GHC_OPTIONS="+RTS -qn8 -A32M -RTS -j16"  cabal new-install stack-1.9.3 -j8` |

#### Building GHC

| Time (s) | Machine | Performance vs #1 | Performance vs N-1 | Command |
| --- | --- | --- | --- | --- |
| 1205.29 | Intel Core i7-8700K | 0% | 0% | `make -j8` |
| 1305.27 | Intel Core i7-7700K@4.8GHz | -7.7% | -7.7% | `make -j8` |
| 1328.3 | 2x Intel Xeon Gold 6140M | -9.3% | -1.7% | `make -j72` |
| 1382.93 | AMD Threadripper 2990wx | -12.8% | -4% | `make -j64` |
| 1572.71 | AMD Ryzen 2700X | -23.3% | -12.1% | `make -j16` |

#### GHC Testsuite

| Time (s) | Machine | Performance vs #1 | Performance vs N-1 | Command |
| --- | --- | --- | --- | --- |
| 106.44 | 2x Intel Xeon Gold 6140M | 0% | 0% | `THREADS=72 ./validate --no-clean --testsuite-only` |
| 159.48 | AMD Threadripper 2990wx | -33.3% | -33.3% | `THREADS=64 ./validate --no-clean --testsuite-only` |
| 265.16 | Intel Core i7-8700K | -59.9% | -39.9 | `THREADS=12 ./validate --no-clean --testsuite-only` |
| 293.69 | AMD Ryzen 2700X | -63.8% | -9.7% | `THREADS=16 ./validate --no-clean --testsuite-only` |
| 343.06 | Intel Core i7-7700K@4.8GHz | -69% | -14.4% | `THREADS=8 ./validate --no-clean --testsuite-only` |

#### Clash Testsuite

| Time (s) | Machine | Performance vs #1 | Performance vs N-1 | Command |
| --- | --- | --- | --- | --- |
| 45.63 | 2x Intel Xeon Gold 6140M | 0% | 0% | `cabal new-run -- testsuite -p clash -j72` |
| 64.84 | AMD Threadripper 2900wx | -29.6% | -29.6% | `cabal new-run -- testsuite -p clash -j32` |
| 134.27 | Intel Core i7-8700K | -66.0% | -51.7% | `cabal new-run -- testsuite -p clash -j8` |
| 157.87 | AMD Ryzen 2700X | -71.1% | -14.9% | `cabal new-run -- testsuite -p clash -j16` |
| 177.77 | Intel Core i7-7700K@4.8GHz | -74.3% | -11.2% | `cabal new-run -- testsuite -p clash -j8` |

# Effect of faster RAM

When picking parts for a new workstation, we always wondered whether faster RAM would have a significant impact.
So we swapped the DDR4-2400 RAM from our Ryzen 7 2700X workstation with the DDR4-3000 RAM from our Intel Core i7-7700k workstation, and observed the following differences.

### Intel Core i7-7700K@4.8GHz

Across the board, the Intel Core i7-7700K hardly seems to benifit from the faster RAM.

#### Building Clash

| Time (s) | Memory | Performance vs N+1 | Command |
| --- | --- | --- | --- |
| 306.53 | 2x 16GB DDR4-3000 16-17-17-35 | +0% | `cabal new-build clash-ghc --ghc-options="+RTS -qn8 -A32M -RTS -j4" -j4` | 
| 306.88 | 2x 16GB DDR4-2400 15-15-15-39 | 0% | `cabal new-build clash-ghc --ghc-options="+RTS -qn8 -A32M -RTS -j4" -j4` | 

#### Building Stack

| Time (s) | Memory | Performance vs N+1 | Command |
| --- | --- | --- | --- |
| 342.92 | 2x 16GB DDR4-3000 16-17-17-35 | +1.1% | `GHC_OPTIONS="+RTS -qn8 -A32M -RTS -j4"  cabal new-install stack-1.9.3 -j8` |
| 346.59 | 2x 16GB DDR4-2400 15-15-15-39 | 0% | `GHC_OPTIONS="+RTS -qn8 -A32M -RTS -j4"  cabal new-install stack-1.9.3 -j8` |

#### Building GHC

| Time (s) | Memory | Performance vs N+1 | Command |
| --- | --- | --- | --- |
| 1305.27 | 2x 16GB DDR4-3000 16-17-17-35| +2% | `make -j8` |
| 1331.31 | 2x 16GB DDR4-2400 15-15-15-39 | 0% | `make -j8` |

#### GHC Testsuite

| Time (s) | Memory | Performance vs N+1 | Command |
| --- | --- | --- | --- |
| 343.06 | 2x 16GB DDR4-3000 16-17-17-35 | +2% |`THREADS=8 ./validate --no-clean --testsuite-only` |
| 349.64 | 2x 16GB DDR4-2400 15-15-15-39 | 0% | `THREADS=8 ./validate --no-clean --testsuite-only` |

#### Clash Testsuite

| Time (s) | Memory | Performance vs N+1 | Command |
| --- | --- | --- | --- |
| 177.77 | 2x 16GB DDR4-3000 16-17-17-35 | +3.5% | `cabal new-run -- testsuite -p clash -j8` |
| 184.04 | 2x 16GB DDR4-2400 15-15-15-39 | 0% | `cabal new-run -- testsuite -p clash -j8` |

### AMD Ryzen 7 2700X

It's quite a different story for our AMD Ryzen 7 2700X machine:

#### Building Clash

| Time (s) | Memory | Performance vs N+1 | Command |
| --- | --- | --- | --- |
| 372.79 | 2x 16GB DDR4-3000 16-17-17-35 | 0% | `cabal new-build clash-ghc --ghc-options="+RTS -qn8 -A32M -RTS -j16" -j16` | 

#### Building Stack

| Time (s) | Memory | Performance vs N+1 | Command |
| --- | --- | --- | --- |
| 360.02 | 2x 16GB DDR4-3000 16-17-17-35 | 0% | `GHC_OPTIONS="+RTS -qn8 -A32M -RTS -j16"  cabal new-install stack-1.9.3 -j8` |

#### Building GHC

| Time (s) | Memory | Performance vs N+1 | Command |
| --- | --- | --- | --- |
| 1572.71 | 2x 16GB DDR4-3000 16-17-17-35| 0% | `make -j16` |

#### GHC Testsuite

| Time (s) | Memory | Performance vs N+1 | Command |
| --- | --- | --- | --- |
| 293.69 | 2x 16GB DDR4-3000 16-17-17-35 | +10.8% |`THREADS=16 ./validate --no-clean --testsuite-only` |
| 324.21 | 4x 16GB DDR4-2400 15-15-15-39 | 0% | `THREADS=16 ./validate --no-clean --testsuite-only` |

#### Clash Testsuite

| Time (s) | Memory | Performance vs N+1 | Command |
| --- | --- | --- | --- |
| 157.87 | 2x 16GB DDR4-3000 16-17-17-35 | 0% | `cabal new-run -- testsuite -p clash -j8` |

# Haskell workstation buyer's guide

So let's say you're in a similar situation as us, you need to get a new Haskell workstation, what do you get?

## Costs (on 12-Dec-2018)

First we check the costs of the Intel option and the AMD option.
Note that for the components where our options differ I've tried to pick the cheapest option from a respectable vendor.
Also, the prices listed are basically only valid at the time of collection: December 12th 2018.
And, being from the Netherlands, we are inelligible for cashback/discounts potentially available to e.g. those that live in the US.

### Upgrade only

Let's say you have an existing case and video card, and you previous CPU used DDR3 memory, what are the costs of your upgrade path?.
We picked DDR4-3000 for both options because we saw that the Ryzen 7 2700X definitely benifits from faster RAM; we use DDR4-3000 for our Core i7-8700K as well because that's what our benchmark i7-8700K machine had.

| Vendor | Configuration | Price | Price vs N-1 |
| --- | --- | --- | --- |
| AMD | CPU: AMD Ryzen 2700X | [€548,75](https://azerty.nl/basket/?code=YTozOntpOjI0NDYxODg7aToxO2k6MjYzMDM1MztpOjE7aTo0NTQyODA7aToxO30=) | 0% |
| | Motherboard: Asrock B450M Pro4 | |
| | Memory: Corsair CMK16GX4M2B3000C15 | |
| Intel | CPU: Intel Core i7 8700K | [€694,80](https://azerty.nl/basket/?code=YTozOntpOjQ1NDI4MDtpOjE7aToyMjIxODIzO2k6MTtpOjIyMzQ3OTY7aToxO30=) | +26.6% |
| | Motherboard: MSI 370-A PRO | |
| | Memory: Corsair CMK16GX4M2B3000C15  | |

Although AMD allows memory overclock (DDR4-3000) at its midrage B450 motherboard chipsets, Intel only support memory overclock at its higher-end Z370/Z390 motherboard chipsets. Combined with the higher price of the i7-8700K itself, the higher price of the motherboard makes the Intel options 26.6% more expensive. 

### Complete system

A requirement that we set for the full system is that it should be able to handle a 4K@60Hz monitor, whether through HDMI or Display port; and that it is silent.

| Vendor | Configuration | Price | Price vs N-1 |
| --- | --- | --- | --- |
| Intel | CPU: AMD Ryzen 2700X | [€1.066,74](https://azerty.nl/basket/?code=YTo4OntpOjQ1NDI4MDtpOjE7aTo3MTg4OTtpOjE7aToyNDkxMDQ1O2k6MTtpOjE5NTgxOTtpOjE7aToyNjMwMzUzO2k6MTtpOjI0NDYxODg7aToxO2k6MTY2MTUwNztpOjE7aToyMjk1OTk1O2k6MTt9) | 0% |
| | Motherboard: Asrock B450M Pro4 | |
| | Memory: Corsair CMK16GX4M2B3000C15 | |
| | Videocard: Gigabyte GeForce GT 1030 Silent Low Profile 2G | |
| | SSD: WD Black NVMe SSD 1TB | |
| | Case: Cooler Master Silencio 452 | |
| | PSU: Seasonic Focus 450 Gold | |
| | Assembly | |
| Intel | CPU: Intel Core i7 8700K | [€1.167,80](https://azerty.nl/basket/?code=YTo4OntpOjQ1NDI4MDtpOjE7aToyMjIxODIzO2k6MTtpOjIyMzQ3OTY7aToxO2k6NzE4ODk7aToxO2k6NzEwMzk7aToxO2k6MjI5NTk5NTtpOjE7aToyNDkxMDQ1O2k6MTtpOjE5NTgxOTtpOjE7fQ==) | +9.5% |
| | Motherboard: MSI 370-A PRO | |
| | Memory: Corsair CMK16GX4M2B3000C15 | |
| | CPU cooler: Cooler Master Hyper 212 Evo | |
| | SSD: WD Black NVMe SSD 1TB | |
| | Case: Cooler Master Silencio 452 | |
| | PSU: Seasonic Focus 450 Gold | |
| | Assembly | |

The relative cost difference for the full system change somewhat to the upgrade-only path due to:

* The total costs being heigher for both, thus lowering the relative differences.
* The fact that the Intel Core i7-8700K has an onboard GPU which can drive the 4K@60Hz screen, where the AMD Ryzen 7 2700X needs a discrete GPU.

Here we see that the Intel Core i7-8700K is only 9.5% more expensive than the AMD Ryzen 7 2700X system.

## Performance

#### Building Clash

| Time (s) | Memory | Performance vs N+1 | Command |
| --- | --- | --- | --- |
| 289.65 | Intel Core i7-8700K | +28.7% | `cabal new-build clash-ghc --ghc-options="+RTS -qn8 -A32M -RTS -j12" -j8` | 
| 372.79 | AMD Ryzen 2700X | 0% | `cabal new-build clash-ghc --ghc-options="+RTS -qn8 -A32M -RTS -j16" -j16` | 

#### Building Stack

| Time (s) | Memory | Performance vs N+1 | Command |
| --- | --- | --- | --- |
| 289.42 | Intel Core i7-8700K | +24.4% | `GHC_OPTIONS="+RTS -qn8 -A32M -RTS -j4"  cabal new-install stack-1.9.3 -j8` |
| 360.02 | AMD Ryzen 2700X | 0% | `GHC_OPTIONS="+RTS -qn8 -A32M -RTS -j16"  cabal new-install stack-1.9.3 -j8` |

#### Building GHC

| Time (s) | Memory | Performance vs N+1 | Command |
| --- | --- | --- | --- |
| 1205.29 | Intel Core i7-8700K | +30.5% | `make -j8` |
| 1572.71 | AMD Ryzen 2700X | 0% | `make -j16` |

#### GHC Testsuite

| Time (s) | Memory | Performance vs N+1 | Command |
| --- | --- | --- | --- |
| 265.16 | Intel Core i7-8700K | +10.8% |`THREADS=12 ./validate --no-clean --testsuite-only` |
| 293.69 | AMD Ryzen 2700X | 0% | `THREADS=16 ./validate --no-clean --testsuite-only` |

#### Clash Testsuite

| Time (s) | Memory | Performance vs N+1 | Command |
| --- | --- | --- | --- |
| 134.27 | Intel Core i7-8700K | +17.6% | `cabal new-run -- testsuite -p clash -j8` |
| 157.87 | AMD Ryzen 2700X | 0% | `cabal new-run -- testsuite -p clash -j16` |
