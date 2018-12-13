__This is a blog post about pitting different CPUs against each other where compiling Haskell projects is the benchmarked workload; it is *not* about benchmarking Haskell programs, profiling in order to improve the run-time of your Haskell program, improving GHC to lower compile times, etc.__

This project started when we acquired two new machines for the office, a "workstation" and a "server" machine.
Since we were busy with projects, and the workstation was mostly an upgrade to an existing machine, we decided to run some benchmarks on them before taking them into production.
Not just any random benchmark though, we wanted to see how well they performed at the job at hand: compiling Haskell projects.
When we picked the parts for our workstation, we had to make our decision based on benchmarks found on sites like [Phoronix](https://phoronix.com) and [https://openbenchmarking.org/](https://openbenchmarking.org/), specifically benchmarks such as [these compilation benchmarks](https://www.phoronix.com/scan.php?page=article&item=intel-core-9900k-linux&num=4).
Those benchmarks are C compile time benchmarks though, and so all we could hope for is that the numbers would translate to Haskell/GHC compile times.

In [the compilation benchmarks @ Phoronix](https://www.phoronix.com/scan.php?page=article&item=intel-core-9900k-linux&num=4), AMD's Ryzen 7 2700X seemed pretty much on par with Intel's Core i7-8700k; so we decided to build our workstation around the 2700X hoping that its 8 cores would give it a leg up over the i7-8700k's 6 cores in our highly parallel test suites.
As we will see in this blog post, however, it turns out that for compiling Haskell projects the Intel Core i7-8700K would have been the better choice.

Our [benchmark script](https://github.com/QBayLogic/benchmark-compilation/blob/146f8a2d55266a8663de64fa06811ad4e772acb4/benchmark2.sh), and [collected results](https://github.com/QBayLogic/benchmark-compilation/tree/master/results), can all be found on [the github project hosthing this blog](https://github.com/QBayLogic/benchmark-compilation)

# Haskell workstation benchmarks

In your day-to-day development cycle you probably execute the following compile tasks:

1. Compile the module you're currently working on (very often)
2. Compile your project and run the (fast) test suite (frequent); slow tests are for you CI.
3. Compile your project and all its dependencies (infrequent)

Tasks 2. and 3. are likely to benefit from CPUs that have more cores, which can then exploit the available parallelism; while task 1 will likely benefit from higher single-core performance.
Given the dependencies between modules and packages, the available parallelism might be limited, and so a CPU with fewer cores but higher single-threaded performance might outperform a CPU that has more cores but lower single-thread performance on task 2. and 3.

## Haskell test environment

All of the tests were run using *GHC 8.4.4* in combination with *cabal-install 2.4.1.0* which were acquired through [ghcup](https://github.com/haskell/ghcup):

```
$ ( mkdir -p ~/.ghcup/bin && curl https://raw.githubusercontent.com/haskell/ghcup/master/ghcup > ~/.ghcup/bin/ghcup && chmod +x ~/.ghcup/bin/ghcup) && echo "Success"
$ export PATH="$HOME/.cabal/bin:$HOME/.ghcup/bin:$PATH"
$ ghcup install 8.4.4
$ ghcup set 8.4.4
$ ghcup install-cabal
```

## The tests

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
* `+RTS -qn8 -A32M -RTS`: These settings where given to us by Ben Gamari, GHC maintainer, after we discovered very poor performance at higher thread counts. The [`-qn8` settings](https://downloads.haskell.org/~ghc/latest/docs/html/users_guide/runtime_control.html#rts-flag--qn%20%E2%9F%A8x%E2%9F%A9) limits the number of threads participating in garbage-collection(GC) to 8; GC is bandwidth-bound, so over-saturation in terms of cores participating in GC can hurt performance; additionally, synchronization between a large amount of GC threads also hurts performance. To give an indication, for one of the benchmarked machines, running the test with `64` GHC threads, and `64` Cabal threads, the runtime went from [1742s](https://github.com/QBayLogic/benchmark-compilation/blob/master/results/02-04.csv) to [377.14s](https://github.com/QBayLogic/benchmark-compilation/blob/master/results/02-05.csv) using the updated RTS settings. The [`-A32M` setting](https://downloads.haskell.org/~ghc/latest/docs/html/users_guide/runtime_control.html#rts-flag--A%20%E2%9F%A8size%E2%9F%A9) sets the allocation area to 32MB, reducing the number of collections and promotions. Benchmarking the effect of these setting different values for these options would be a blog post on its own. Given that the chosen values gave performance improvements across the board kept them fixed for all variations of `GHC_THREADS` and `CABAL_THREADS`. Really, you want to check the productivity number by running GHC with `+RTS -s -RTS` to check how/if RTS parameters improve compiler performance.

We'll be comparing the following results between the different machines:

1. `GHC_THREADS=1 CABAL_THREADS=1` to compare single-threaded performance which is important for task 1.
2. `GHC_THREADS=N CABAL_THREADS=1` to compare multi-core performance which is important for task 2. The clash compiler, and its dependencies, are of various sizes and inter-module dependencies, so these numbers represent the *average* multi-core performance of the CPUs.
3. `GHC_THREADS=X CABAL_THREADS=Y` to compare multi-core performance which is important for task 3. These number represent the *peak* multi-core performance of the CPUs.

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

where we run `make clean` and `./configure` before every run. We'll compare results for `THREADS=1` for single-core performance (task 3), and `THREADS=N` for multi-core performance (task 2. and 3.).

### 4. GHC Testsuite

This runs the fast testsuite of GHC. We start with the the above-mentioned checkout of the GHC compiler. Run a `make maintainer-clean`  to clear ALL the build artifect, then run `./validate --build-only` to build a version of GHC that will execute the test suite, and then run:

```
THREADS={NUMTHREADS} ./validate --no-clean --testsuite-only
```

Although the script iterates over multiple `NUMTHREADS`, for this blog post, we'll just be looking at `THREADS=N`, i.e. only compare multi-core performance.

### 5. Clash Testsuite

The Clash integration tests converts Haskell to HDL, and then runs the HDL simulator to see whether the generated HDL is correct. Because setting up these simulators can be a pain, for this benchmark we only run the convert-to-hdl part. The command that we run will be:

```
cabal new-run -- clash-testsuite -p clash -j{THREADS}
```

Although the script iterates over multiple `THREADS`, for this blog post, we'll just be looking at `-jN`, i.e. only compare multi-core performance.

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

We are including two server type machines as well, mostly to see how much more parallelism is available in the GHC and Clash test suites.
For the Clash, Stack, and GHC compile benchmarks, they are under-utilized; i.e. to make a better comparison we should be looking at compiles-per-day where the server machines are configured to execute multiple compiles in parallel.
Perhaps something for a follow-up blog post.

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

## Peak multi-core performance

We start by comparing absolute, multi-core, performance:

#### Building Clash

| Machine | Time (s) | Compiles / Day | vs #1 | vs N-1 | Configuration |
| --- | --- | --- | --- | --- | --- |
| Intel Core i7-8700K        | 289.65 | 298 | -            | -            | `GHC_THREADS=12` `CABAL_THREADS=8`  |
| Intel Core i7-7700K@4.8GHz | 306.53 | 282 | 1.06x slower | 1.65x slower | `GHC_THREADS=4`  `CABAL_THREADS=4`  |
| 2x Intel Xeon Gold 6140M   | 369.72 | 234 | 1.28x slower | 1.21x slower | `GHC_THREADS=8`  `CABAL_THREADS=72` |
| AMD Ryzen 2700X            | 372.79 | 232 | 1.29x slower | 1.01x slower | `GHC_THREADS=16` `CABAL_THREADS=16` |
| AMD Threadripper 2990wx    | 375.59 | 230 | 1.30x slower | 1.01x slower | `GHC_THREADS=32` `CABAL_THREADS=32` |

#### Building Stack

| Machine | Time(s) | Compiles / Day | vs #1 | vs N-1 | Configuration |
| --- | --- | --- | --- | --- | --- |
| Intel Core i7-8700K        | 289.42 | 298 | -            | -           | `GHC_THREADS=4`  `CABAL_THREADS=8`  |
| 2x Intel Xeon Gold 6140M   | 315.74 | 273 | 1.09x slower | 1.09x slower | `GHC_THREADS=8`  `CABAL_THREADS=18` |
| AMD Threadripper 2990wx    | 329.23 | 262 | 1.14x slower | 1.04x slower | `GHC_THREADS=32` `CABAL_THREADS=8`  |
| Intel Core i7-7700K@4.8GHz | 342.92 | 251 | 1.18x slower | 1.04x slower | `GHC_THREADS=4`  `CABAL_THREADS=8`  |
| AMD Ryzen 2700X            | 360.02 | 239 | 1.24x slower | 1.05x slower | `GHC_THREADS=16` `CABAL_THREADS=8`  |

#### Building GHC

| Machine | Time(s) | Compiles / Day | vs #1 | vs N-1 | Configuration |
| --- | --- | --- | --- | --- | --- |
| Intel Core i7-8700K        | 1205.29 | 72 | -            | -            | `THREADS=8`  |
| Intel Core i7-7700K@4.8GHz | 1305.27 | 66 | 1.08x slower | 1.08x slower | `THREADS=8`  |
| 2x Intel Xeon Gold 6140M   | 1328.3  | 65 | 1.10x slower | 1.02x slower | `THREADS=72` |
| AMD Threadripper 2990wx    | 1382.93 | 62 | 1.15x slower | 1.04x slower | `THREADS=64` |
| AMD Ryzen 2700X            | 1572.71 | 55 | 1.30x slower | 1.14x slower | `THREADS=16` |

#### GHC Testsuite

| Machine | Time(s) | Runs / Day | vs #1 | vs N-1 | Configuration |
| --- | --- | --- | --- | --- | --- |
| 2x Intel Xeon Gold 6140M   | 106.44 | 812 | -            | -            | `THREADS=72` |
| AMD Threadripper 2990wx    | 159.48 | 542 | 1.50x slower | 1.50x slower | `THREADS=64` |
| Intel Core i7-8700K        | 265.16 | 326 | 2.49x slower | 1.66x slower | `THREADS=12` |
| AMD Ryzen 2700X            | 293.69 | 294 | 2.76x slower | 1.11x slower | `THREADS=16` |
| Intel Core i7-7700K@4.8GHz | 343.06 | 252 | 3.22x slower | 1.17x slower | `THREADS=8`  |

#### Clash Testsuite

| Machine | Time(s) | Runs / Day | vs #1 | vs N-1 | Configuration |
| --- | --- | --- | --- | --- |
| 2x Intel Xeon Gold 6140M   | 45.63  | 1893 | -            | -            | `THREADS=72` |
| AMD Threadripper 2900wx    | 64.84  | 1333 | 1.42x slower | 1.42x slower | `THREADS=32` |
| Intel Core i7-8700K        | 134.27 | 643  | 2.94x slower | 2.07x slower | `THREADS=8`  |
| AMD Ryzen 2700X            | 157.87 | 547  | 3.46x slower | 1.18x slower | `THREADS=16` |
| Intel Core i7-7700K@4.8GHz | 177.77 | 486  | 3.90x slower | 1.13x slower | `THREADS=8`  |

# Effect of faster RAM

When picking parts for a new workstation, we always wondered whether faster RAM would have a significant impact.
So we swapped the DDR4-2400 RAM from our AMD Ryzen 7 2700X workstation with the DDR4-3000 RAM from our Intel Core i7-7700k workstation, and observed the following differences.

### Intel Core i7-7700K@4.8GHz

Across the board, the Intel Core i7-7700K does *not* benefit from the faster RAM.

#### Building Clash

| Memory | Time(s) | Compiles / Day | vs other | Configuration |
| --- | --- | --- | --- | --- |
| 2x 16GB DDR4-3000 16-17-17-35 | 306.53 | 282 | - | `GHC_THREADS=4` `CABAL_THREADS=4` |
| 2x 16GB DDR4-2400 15-15-15-39 | 306.88 | 282 | - | `GHC_THREADS=4` `CABAL_THREADS=4` |

#### Building Stack

| Memory | Time(s) | Compiles / Day | vs other | Configuration |
| --- | --- | --- | --- | --- |
| 2x 16GB DDR4-3000 16-17-17-35 | 342.92 | 252 | -            | `GHC_THREADS=4` `CABAL_THREADS=8` |
| 2x 16GB DDR4-2400 15-15-15-39 | 346.59 | 249 | 1.01x slower | `GHC_THREADS=4` `CABAL_THREADS=8` |

#### Building GHC

| Memory | Time(s) | Compiles / Day | vs other | Configuration |
| --- | --- | --- | --- | --- |
| 2x 16GB DDR4-3000 16-17-17-35 | 1305.27 | 66 | -            | `THREADS=8` |
| 2x 16GB DDR4-2400 15-15-15-39 | 1331.31 | 65 | 1.02x slower | `THREADS=8` |

#### GHC Testsuite

| Memory | Time(s) | Runs / Day | vs other | Configuration |
| --- | --- | --- | --- | --- |
| 2x 16GB DDR4-3000 16-17-17-35 | 343.06 | 252 | -            | `THREADS=8` |
| 2x 16GB DDR4-2400 15-15-15-39 | 349.64 | 247 | 1.02x slower | `THREADS=8` |

#### Clash Testsuite

| Memory | Time(s) | Runs / Day | vs other | Configuration |
| --- | --- | --- | --- | --- |
| 2x 16GB DDR4-3000 16-17-17-35 | 177.77 | 486 | -            | `THREADS=8` |
| 2x 16GB DDR4-2400 15-15-15-39 | 184.04 | 469 | 1.04x slower | `THREADS=8` |

### AMD Ryzen 7 2700X

It's quite a different story for our AMD Ryzen 7 2700X machine:

#### Building Clash

| Memory | Time(s) | Compiles / Day | vs other | Configuration |
| --- | --- | --- | --- | --- |
| 2x 16GB DDR4-3000 16-17-17-35 | 372.79 | 232 | -            | `GHC_THREADS=16` `CABAL_THREADS=16` |
| 2x 16GB DDR4-2400 15-15-15-39 | 384.68 | 225 | 1.03x slower | `GHC_THREADS=16` `CABAL_THREADS=16` |

#### Building Stack

| Memory | Time(s) | Compiles / Day | vs other | Configuration |
| --- | --- | --- | --- | --- |
| 2x 16GB DDR4-3000 16-17-17-35 | 360.02 | 240 | -            | `GHC_THREADS=8` `CABAL_THREADS=8` |
| 2x 16GB DDR4-2400 15-15-15-39 | 382.71 | 226 | 1.06x slower | `GHC_THREADS=16` `CABAL_THREADS=8` |

#### Building GHC

| Memory | Time(s) | Compiles / Day | vs other | Configuration |
| --- | --- | --- | --- | --- |
| 2x 16GB DDR4-3000 16-17-17-35 | 1572.71 | 55 | -            | `THREADS=16` |
| 2x 16GB DDR4-2400 15-15-15-39 | 1693.69 | 51 | 1.08x slower | `THREADS=16` |

#### GHC Testsuite

| Memory | Time(s) | Runs / Day | vs other | Configuration |
| --- | --- | --- | --- | --- |
| 2x 16GB DDR4-3000 16-17-17-35 | 293.69 | 294 | -            | `THREADS=16` |
| 2x 16GB DDR4-2400 15-15-15-39 | 326.18 | 265 | 1.11x slower | `THREADS=16` |

#### Clash Testsuite

| Memory | Time(s) | Runs / Day | vs other | Configuration |
| --- | --- | --- | --- | --- |
| 2x 16GB DDR4-3000 16-17-17-35 | 157.87 | 547 | -            | `THREADS=16` |
| 2x 16GB DDR4-2400 15-15-15-39 | 171.09 | 505 | 1.08x slower | `THREADS=8` |

# Haskell workstation buyer's guide

So let's say you're in a similar situation as us, you need to get a new Haskell workstation, what do you get?

## Costs (on 12-Dec-2018)

First we check the costs of the Intel option and the AMD option.
Note that for the component/price selection I went for:

1. A respectable vendor
2. The "cheapest" component that had decent reviews, from brands that haven't failed me (your experience may differ!).

So there might be cheaper options, but at what cost?

Also, the prices listed are basically only valid at the time of collection: December 12th 2018.
And, being from the Netherlands, we are ineligible for cashback/discounts available to e.g. those that live in the US.

### Upgrade only

Let's say you have an existing case and video card, and your previous machine used DDR3 memory, what are the costs for your upgrade path?.
We picked DDR4-3000 for both the AMD and Intel option because we saw that the Ryzen 7 2700X definitely benefits from faster RAM; we use DDR4-3000 for our Core i7-8700K as well because that's what our benchmarked i7-8700K machine had.
Also, the difference in price compared to e.g. DDR4-2400 is worth it in terms of the performance improvement.

| Option | Configuration | Price | Price vs other |
| --- | --- | --- | --- |
| AMD | CPU: AMD Ryzen 2700X |  | |
| | Motherboard: Asrock B450M Pro4 | |
| | Memory: Corsair CMK16GX4M2B3000C15 | |
| | **Total** | [€548,75](https://azerty.nl/basket/?code=YTozOntpOjI0NDYxODg7aToxO2k6MjYzMDM1MztpOjE7aTo0NTQyODA7aToxO30=) | - |
| Intel | CPU: Intel Core i7 8700K | | |
| | Motherboard: MSI 370-A PRO | |
| | Memory: Corsair CMK16GX4M2B3000C15  | |
| | **Total** | [€694,80](https://azerty.nl/basket/?code=YTozOntpOjQ1NDI4MDtpOjE7aToyMjIxODIzO2k6MTtpOjIyMzQ3OTY7aToxO30=) | 27% more expensive |

Although AMD allows memory overclock (DDR4-3000) at its midrage B450 motherboard chipsets, Intel only support memory overclock at its higher-end Z370/Z390 motherboard chipsets. Combined with the higher price of the i7-8700K itself, the higher price of the motherboard makes the Intel option 27% more expensive than the AMD option.

### Complete system

A requirement that we set for the full system is that it should be able to handle a 4K@60Hz monitor, whether through HDMI or Display port; and that it is silent.

* Case: Cooler Master Silencio 452; used in the benchmarked i7-8700K machine; inaudible in a quiet office environment.
* PSU: Seasonic Focus 450 Gold; unlike some other brands, Seasonic's single 12V-rail PSUs have never failed me.
* CPU cooler: Cooler Master Hyper 212 Evo (for Intel) machine; used in the benchmarked i7-8700K; inaudible in a quiet office environment.
* Video card: Gigabyte GeForce GT 1030 Silent Low Profile 2G (for AMD); brand never failed me.
* SSD: WD Black NVMe SSD 1TB; has good reviews, slightly cheaper than the Samsung 970 EVO 1TB.

| Option | Configuration | Price | Price vs N-1 |
| --- | --- | --- | --- |
| Intel | CPU: AMD Ryzen 2700X | | |
| | Motherboard: Asrock B450M Pro4 | |
| | Memory: Corsair CMK16GX4M2B3000C15 | |
| | Videocard: Gigabyte GeForce GT 1030 Silent Low Profile 2G | |
| | SSD: WD Black NVMe SSD 1TB | |
| | Case: Cooler Master Silencio 452 | |
| | PSU: Seasonic Focus 450 Gold | |
| | Assembly | |
| | **Total** | [€1.066,74](https://azerty.nl/basket/?code=YTo4OntpOjQ1NDI4MDtpOjE7aTo3MTg4OTtpOjE7aToyNDkxMDQ1O2k6MTtpOjE5NTgxOTtpOjE7aToyNjMwMzUzO2k6MTtpOjI0NDYxODg7aToxO2k6MTY2MTUwNztpOjE7aToyMjk1OTk1O2k6MTt9) | - |
| Intel | CPU: Intel Core i7 8700K | | |
| | Motherboard: MSI 370-A PRO | |
| | Memory: Corsair CMK16GX4M2B3000C15 | |
| | CPU cooler: Cooler Master Hyper 212 Evo | |
| | SSD: WD Black NVMe SSD 1TB | |
| | Case: Cooler Master Silencio 452 | |
| | PSU: Seasonic Focus 450 Gold | |
| | Assembly | |
| | **Total** | [€1.167,80](https://azerty.nl/basket/?code=YTo4OntpOjQ1NDI4MDtpOjE7aToyMjIxODIzO2k6MTtpOjIyMzQ3OTY7aToxO2k6NzE4ODk7aToxO2k6NzEwMzk7aToxO2k6MjI5NTk5NTtpOjE7aToyNDkxMDQ1O2k6MTtpOjE5NTgxOTtpOjE7fQ==) | 9% more expensive |

The relative cost difference for the full system change somewhat to the upgrade-only path due to:

* The total costs being higher for both, thus lowering the relative differences.
* The fact that the Intel Core i7-8700K has an onboard GPU which can drive the 4K@60Hz screen, where the AMD Ryzen 7 2700X needs a discrete GPU.

Here we see that the Intel Core i7-8700K system is only 9% more expensive compared to the AMD Ryzen 7 2700X system.

## Value for money
We are using compiler per year per euro as our criteria, as the numbers for compiler per day per euro are too small.

### Building Clash
For building Clash, the two options are on par for the upgrade path, while for the full system path, the Intel Core i7-8700K is clearly better.

#### Upgrade

| Machine | Time(s) | Compiles / Year / € | vs other | Configuration |
| --- | --- | --- | --- | --- |
| Intel Core i7-8700K | 289.65 | 157 | 1.02x better | `GHC_THREADS=12` `CABAL_THREADS=8`  |
| AMD Ryzen 2700X     | 372.79 | 154 | -            | `GHC_THREADS=16` `CABAL_THREADS=16` |

#### Full system

| Machine | Time(s) | Compiles / Year / € | vs other | Configuration |
| --- | --- | --- | --- | --- |
| Intel Core i7-8700K | 289.65 | 93 | 1.18x better | `GHC_THREADS=12` `CABAL_THREADS=8`  |
| AMD Ryzen 2700X     | 372.79 | 79 | -            | `GHC_THREADS=16` `CABAL_THREADS=16` |

### Building Stack
And we see similar results for building Stack.

#### Upgrade

| Machine | Time(s) | Compiles / Year / € | vs other | Configuration |
| --- | --- | --- | --- | --- |
| AMD Ryzen 2700X     | 360.02 | 160 | 1.02x better | `GHC_THREADS=16` `CABAL_THREADS=8` |
| Intel Core i7-8700K | 289.42 | 157 | -            | `GHC_THREADS=4` `CABAL_THREADS=8`  |

#### Full system

| Machine | Time(s) | Compiles / Year / € | vs other | Configuration |
| --- | --- | --- | --- | --- |
| Intel Core i7-8700K | 289.42 | 93 | 1.14x better | `GHC_THREADS=4` `CABAL_THREADS=8`  |
| AMD Ryzen 2700X     | 360.02 | 82 | -            | `GHC_THREADS=16` `CABAL_THREADS=8` |

### Building GHC
And also for building GHC.

#### Upgrade

| Machine | Time(s) | Compiles / Year / € | vs other | Configuration |
| --- | --- | --- | --- | --- |
| Intel Core i7-8700K | 1205.29 | 38 | 1.03x better | `THREADS=8` |
| AMD Ryzen 2700X     | 1572.71 | 37 | - | `THREADS=16` |

#### Full system

| Machine | Time(s) | Compiles / Year / € | vs other | Configuration |
| --- | --- | --- | --- | --- |
| Intel Core i7-8700K | 1205.29 | 22 | 1.19x better | `THREADS=8` |
| AMD Ryzen 2700X     | 1572.71 | 19 | - | `THREADS=16` |

### GHC Testsuite
For the GHC test suite, for the upgrade path, the AMD Ryzen 7 2700X offers the better value for money, while they're on par for the full system path.

#### Upgrade

| Machine | Time(s) | Runs / Year / € | vs other | Configuration |
| --- | --- | --- | --- | --- |
| AMD Ryzen 2700X     | 293.69 | 196 | 1.14x better | `THREADS=16 ` |
| Intel Core i7-8700K | 265.16 | 171 | - | `THREADS=12` |

#### Full system

| Machine | Time(s) | Runs / Year / € | vs other | Configuration |
| --- | --- | --- | --- | --- |
| Intel Core i7-8700K | 265.16 | 102 | 1.01x better | `THREADS=12` |
| AMD Ryzen 2700X     | 293.69 | 101 | - | `THREADS=16 ` |

### Clash Testsuite
For the Clash test suite, the Intel Core i7-8700K and the AMD Ryzen 7 2700X trade places between the upgrade path and the fully system path.
The AMD Ryzen 7 2700X gives better value for money at the upgrade path, while the Intel Core i7-8700K does better for the full system path.

#### Upgrade

| Machine | Time(s) | Runs / Year / € | vs other | Configuration |
| --- | --- | --- | --- | --- |
| AMD Ryzen 2700X     | 157.87 | 364 | 1.08x better | `THREADS=16` |
| Intel Core i7-8700K | 134.27 | 338 | - | `THREADS=8` |

#### Full system

| Machine | Time(s) | Runs / Year / € | vs other | Configuration |
| --- | --- | --- | --- | --- |
| Intel Core i7-8700K | 134.27 | 201 | 1.07x better | `THREADS=8` |
| AMD Ryzen 2700X     | 157.87 | 187 | - | `THREADS=16` |

# Conclusions

We think it is safe to conclude that for building Haskell projects, the Intel Core i7-8700K is the better CPU in terms of absolute performance, and performance per Euro, compared to the AMD Ryzen 7 2700X.
For the compile tasks, the Intel i7-8700K performs between 25%-30% better than the AMD Ryzen 7 2700X in terms of absolute performance, and it performs 7%-19% better in terms of performance per Euro.
