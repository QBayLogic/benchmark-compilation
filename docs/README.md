# Tests

| Name | Command | Comment |
| --- | --- | --- |
| Building Clash | `cabal new-build clash-ghc` | Empty Cabal store, cached download, haddock=yes |
| Clash testsuite | `clash new-run -- testsuite -p clash` | Only runs Clash compilation, fails one test[¹] |
| Building stack | `cabal new-build stack` | Empty Cabal store, cached download, haddock=no, builds `stack-1.9.1`, fails at the very end[²] |
| Building GHC | `make` | `perf` build, sphinx_docs=no, haddock=yes |
| GHC testsuite | `./validate --no-clean --testsuite-only` | Preceded by a `./validate --build-only` |

#### ¹ Note One
[¹]:#-note-one
Building `Main.hs` fails the same way it does on the [hackage builder](http://hackage.haskell.org/package/stack-1.9.1/reports/3)

#### ² Note Two
[²]:#-note-two
Clash-cosim is not installed, so the cosim tests fails

# Ranking

#### Building Clash

| Rank | Time (s) | Machine + Configuration | command |
| --- | --- | --- | --- |
| 1.  | 289.65 | [Machine 4; Configuration 1](#configuration-1-3) | `cabal new-build clash-ghc --ghc-options="+RTS -qn8 -A32M -RTS -j12" -j8` |
| 2.  | 306.53 | [Machine 6; Configuration 1](#configuration-1-5) | `cabal new-build clash-ghc --ghc-options="+RTS -qn8 -A32M -RTS -j4" -j4` |
| 3.  | 369.72 | [Machine 5; Configuration 1](#configuration-1-4) | `cabal new-build clash-ghc --ghc-options="+RTS -qn8 -A32M -RTS -j8" -j72` |
| 4.  | 372.79 | [Machine 1; Configuration 4](#configuration-4)   | `cabal new-build clash-ghc --ghc-options="+RTS -qn8 -A32M -RTS -j16" -j16` |
| 5.  | 375.59 | [Machine 2; Configuration 4](#configuration-4-1) | `cabal new-build clash-ghc --ghc-options="+RTS -qn8 -A32M -RTS -j32" -j32` |

#### Building stack

| Rank | Time (s) | Machine + Configuration | command |
| --- | --- | --- | --- |
| 1. | 286.33 | [Machine 4; Configuration 1](#configuration-1-3) | `GHC_OPTIONS="+RTS -qn8 -A32M -RTS -j4" cabal new-install stack-1.9.1 -j8`  |
| 2. | 310.77 | [Machine 5; Configuration 1](#configuration-1-4) | `GHC_OPTIONS="+RTS -qn8 -A32M -RTS -j8" cabal new-install stack-1.9.1 -j18` |
| 3. | 335.20 | [Machine 6; Configuration 1](#configuration-1-5) | `GHC_OPTIONS="+RTS -qn8 -A32M -RTS -j4" cabal new-install stack-1.9.1 -j8` |
| 4. | 361.37 | [Machine 1; Configuration 4](#configuration-4)   | `GHC_OPTIONS="+RTS -qn8 -A32M -RTS -j8" cabal new-install stack-1.9.1 -j8` |
| 5. | 394.57 | [Machine 2; Configuration 3](#configuration-4-1) | `GHC_OPTIONS="+RTS -qn8 -A32M -RTS -j64" cabal new-install stack-1.9.1 -j32` |

#### Building GHC

| Rank | Time (s) | Machine + Configuration | command |
| --- | --- | --- | --- |
| 1.| 1205.29 | [Machine 4; Configuration 1](#configuration-1-3) | `make -j8`  |
| 2.| 1305.27 | [Machine 6; Configuration 1](#configuration-1-5) | `make -j8`  |
| 3.| 1328.30 | [Machine 5; Configuration 1](#configuration-1-4) | `make -j72` |
| 4.| 1382.93 | [Machine 2; Configuration 4](#configuration-4-1) | `make -j64` |
| 5.| 1572.71 | [Machine 1; Configuration 4](#configuration-4)   | `make -j16` |

#### Clash testsuite

| Rank | Time (s) | Machine + Configuration | command |
| --- | --- | --- | --- |
| 1. | 44.47  | [Machine 5; Configuration 1](#configuration-1-4) | `cabal new-run -- testsuite -p clash -j72` |
| 2. | 62.66  | [Machine 2; Configuration 4](#configuration-4-1) | `cabal new-run -- testsuite -p clash -j32` |
| 3. | 128.63 | [Machine 4; Configuration 1](#configuration-1-3) | `cabal new-run -- testsuite -p clash -j8`  |
| 5. | 155.13 | [Machine 1; Configuration 4](#configuration-4)   | `cabal new-run -- testsuite -p clash -j16` |
| 4. | 165.56 | [Machine 6; Configuration 1](#configuration-1-5) | `cabal new-run -- testsuite -p clash -j8`  |

#### GHC testsuite

| Rank | Time (s) | Machine + Configuration | command |
| --- | --- | --- | --- |
| 1. | 106.44 | [Machine 5; Configuration 1](#configuration-1-4) | `THREADS=72 ./validate --no-clean --testsuite-only` |
| 2. | 159.48 | [Machine 2; Configuration 4](#configuration-4-1) | `THREADS=64 ./validate --no-clean --testsuite-only` |
| 3. | 265.16 | [Machine 4; Configuration 1](#configuration-1-3) | `THREADS=12 ./validate --no-clean --testsuite-only` |
| 4. | 293.69 | [Machine 1; Configuration 4](#configuration-4)   | `THREADS=16 ./validate --no-clean --testsuite-only` |
| 5. | 343.06 | [Machine 6; Configuration 1](#configuration-1-5) | `THREADS=8 ./validate --no-clean --testsuite-only`  |

# Configurations

## Machine 1

  * CPU: Ryzen 2700X (physical cores: 8)
  * Motherboard: ASRock X470 Master SLI
  * Memory: G.Skill Fortis F4-2400C15Q-64GFT
  * SSD: Samsung 970 Evo 1TB

### Configuration 1

  * Overclock settings: none
  * Memory settings: 64 GB DDR4-2400 15-15-15-39
  * OS: Ubuntu 18.04.1 LTS
  * `uname -vr`: 4.15.0-39-generic #42-Ubuntu SMP Tue Oct 23 15:48:01 UTC 2018
  * Governer: performance

  [Results](results/01-01.csv)

  Fastest runs:

  * Building Clash: 450,43 `cabal new-build clash-ghc --ghc-options=-j4 -j8`
  * Clash testsuite: 168.78 `cabal new-run -- testsuite -p clash -j8`
  * Building stack: 468.2 `GHC_OPTIONS=-j2 cabal new-install stack -j8`
  * Building GHC: 1683.62 `make -j16`
  * GHC testsuite: 324.21 `THREADS=16 ./validate --no-clean --testsuite-only`

### Configuration 2

  * Overclock settings: none
  * Memory settings: 64 GB DDR4-2400 15-15-15-39
  * OS: Ubuntu 18.04.1 LTS
  * `uname -vr`: 4.15.0-39-generic #42-Ubuntu SMP Tue Oct 23 15:48:01 UTC 2018
  * Governer: ondemand

  [Results](results/01-02.csv)

  Fastest runs:

  * Building Clash: 459.84 `cabal new-build clash-ghc --ghc-options=-j2 -j16`
  * Clash testsuite: 169.95 `cabal new-run -- testsuite -p clash -j8`
  * Building stack: 472.77 `cabal new-install stack -j8`
  * Building GHC: 1721.35 `make -j16`
  * GHC testsuite: 328.07 `THREADS=16 ./validate --no-clean --testsuite-only`

  ### Configuration 3

  * Overclock settings: none
  * Memory settings: 64 GB DDR4-2400 15-15-15-39
  * OS: Ubuntu 18.04.1 LTS
  * `uname -vr`: 4.15.0-39-generic #42-Ubuntu SMP Tue Oct 23 15:48:01 UTC 2018
  * Governer: performance
  * SMT: disabled

  [Results](results/01-03.csv)

  * Building Clash: 452.77 `cabal new-build clash-ghc --ghc-options=-j2 -j4`
  * Clash testsuite: 158.02 `cabal new-run -- testsuite -p clash -j8`
  * Building stack: 475.62 `GHC_OPTIONS=-j2 cabal new-install stack -j8`
  * Building GHC: 1679.46 `make -j8`
  * GHC testsuite: 359.05 `THREADS=8 ./validate --no-clean --testsuite-only`

  ### Configuration 4

  * Overclock settings: none
  * Memory: Corsair CMK32GX4M2B3000C15
  * Memory settings: 32 GB DDR4-3000 16-17-17-35
  * OS: Ubuntu 18.04.1 LTS
  * `uname -vr`: 4.15.0-39-generic #42-Ubuntu SMP Tue Oct 23 15:48:01 UTC 2018
  * Governer: performance
  * SMT: disabled
  
  [Results Benchmark 1](results/01-04.csv)
  
  * Building Clash: 439.33 `cabal new-build clash-ghc --ghc-options=-j4 -j4`
  * Clash testsuite: 155.13 `cabal new-run -- testsuite -p clash -j16`
  * Building stack: 445.30 `GHC_OPTIONS=-j2 cabal new-install stack -j8`
  * Building GHC: 1572.71 `make -j16`
  * GHC testsuite: 293.69 `THREADS=16 ./validate --no-clean --testsuite-only`
  
  [Results Benchmark 2](results/01-05.csv)
   
  * Building Clash: 372.79 `cabal new-build clash-ghc --ghc-options="+RTS -qn8 -A32M -RTS -j16" -j16`
  * Building stack: 361.37 `GHC_OPTIONS="+RTS -qn8 -A32M -RTS -j8" cabal new-install stack-1.9.1 -j8`

## Machine 2

  * CPU: Threadripper 2990wx (physical cores: 32)
  * Motherboard: ASRock X399 Taichi
  * Memory: 8x Samsung M391A2K43BB1-CRC
  * SSD: Samsung 970 Pro 1TB

### Configuration 1

  * Overclock settings: none
  * Memory settings: 128 GB DDR4-2400 17-17-17-32 ECC
  * OS: OpenSUSE Tumbleweed
  * `uname -vr`: 4.19.2-1-default #1 SMP PREEMPT Tue Nov 13 20:56:49 UTC 2018
  * Governer: performance

  [Results](results/02-01.csv)

  Fastest runs:

  * Building Clash: 460,95 `cabal new-build clash-ghc --ghc-options=-j2 -j16`
  * Clash testsuite: 70,54 `cabal new-run -- testsuite -p clash -j32`
  * Building stack: 444,75 `GHC_OPTIONS=-j4 cabal new-install stack -j16`
  * Building GHC: 1516.89 `make -j64`
  * GHC testsuite: 208.32 `THREADS=32 ./validate --no-clean --testsuite-only`

### Configuration 2

  * Overclock settings: none
  * Memory settings: 128 GB DDR4-2400 17-17-17-32 ECC
  * OS: OpenSUSE Tumbleweed
  * `uname -vr`: 4.19.2-1-default #1 SMP PREEMPT Tue Nov 13 20:56:49 UTC 2018
  * Governer: performance
  * SMT: disabled

  [Results](results/02-02.csv)

  * Building Clash: 475.32 `cabal new-build clash-ghc --ghc-options=-j2 -j16`
  * Clash testsuite: 70.59 `cabal new-run -- testsuite -p clash -j32`
  * Building stack: 446.68 `GHC_OPTIONS=-j4 cabal new-install stack -j8`
  * Building GHC: 1561.22 `make -j32`
  * GHC testsuite: 196.53 `THREADS=32 ./validate --no-clean --testsuite-only`

### Configuration 3

  * Overclock settings: none
  * Memory settings: 128 GB DDR4-2666 18-19-19-43 ECC
  * OS: OpenSUSE Tumbleweed
  * `uname -vr`: 4.19.2-1-default #1 SMP PREEMPT Tue Nov 13 20:56:49 UTC 2018
  * Governer: performance

  [Results](results/02-03.csv)

  * Building Clash: 453.63 `cabal new-build clash-ghc --ghc-options=-j2 -j64`
  * Clash testsuite: 63.87 `cabal new-run -- testsuite -p clash -j32`
  * Building stack: 432.9 `GHC_OPTIONS=-j4 cabal new-install stack -j8`
  * Building GHC: 1483.15 `make -j32`
  * GHC testsuite: 186 `THREADS=32 ./validate --no-clean --testsuite-only`

### Configuration 4

  * Overclock settings: none
  * Memory settings: 128 GB DDR4-2666 18-19-19-43 ECC
  * OS: Ubuntu 18.04.1 LTS
  * `uname -vr`: 4.15.0-42-generic #45-Ubuntu SMP Thu Nov 15 19:32:57 UTC 2018
  * Governer: performance

  [Results benchmark 1](results/02-04.csv)

  * Building Clash: 432.02 `cabal new-build clash-ghc --ghc-options=-j4 -j16`
  * Clash testsuite: 62.66 `cabal new-run -- testsuite -p clash -j32`
  * Building stack: 394.57 `GHC_OPTIONS=-j4 cabal new-install stack -j8`
  * Building GHC: 1382.93  `make -j64`
  * GHC testsuite: 159.48  `THREADS=64 ./validate --no-clean`

  [Results benchmark 2](results/02-05.csv)

  * Building Clash: 375.59 `cabal new-build clash-ghc --ghc-options="+RTS -qn8 -A32M -RTS -j32" -j32`
  * Building stack: 394.57 `GHC_OPTIONS="+RTS -qn8 -A32M -RTS -j64" cabal new-install stack-1.9.1 -j32`

## Machine 3

  * CPU: Core i7-7700K (physical cores: 4)
  * Motherboard: Asus PRIME Z270-P
  * Memory: Corsair CMK64GX4M4B2800C14
  * SSD: Samsung 960 EVO 1TB

### Configuration 1

  * Overclock: 4.8 GHz
  * OS: Ubuntu 18.04.1 LTS
  * Memory settings: 64 GB DD4-2800 14-16-16-36
  * `uname -vr`: 4.15.0-39-generic #42-Ubuntu SMP Tue Oct 23 15:48:01 UTC 2018
  * Governer: performance

  [Results](results/03-01.csv)

  Fastest runs:

  * Building Clash: 339.22 `cabal new-build clash-ghc --ghc-options=-j2 -j4`
  * Clash testsuite: 161.8 `cabal new-run -- testsuite -p clash -j8`
  * Building stack: 372.12 `GHC_OPTIONS=-j2 cabal new-install stack -j8`
  * Building GHC: 1310.44 `make -j8`
  * GHC testsuite: 338.17 `THREADS=8 ./validate --no-clean --testsuite-only`

### Configuration 2

  * Overclock: 4.8 GHz
  * OS: Ubuntu 18.04.1 LTS
  * Memory settings: 64 GB DD4-2133 15-15-15-36
  * `uname -vr`: 4.15.0-39-generic #42-Ubuntu SMP Tue Oct 23 15:48:01 UTC 2018
  * Governer: performance

  [Results](results/03-02.csv)

  * Building Clash: 370.94 `cabal new-build clash-ghc --ghc-options=-j4 -j4`
  * Clash testsuite: 211.74 `cabal new-run -- testsuite -p clash -j4`
  * Building stack: 430.83 `GHC_OPTIONS=-j2 cabal new-install stack-1.9.1 -j8`
  * Building GHC: 1441.14 `make -j8`
  * GHC testsuite: 376.00 `THREADS=8 ./validate --no-clean --testsuite-only`

## Machine 4

  * CPU: Core i7-8700K (physical cores: 6)
  * Motherboard: Asus PRIME Z370-P II
  * Memory: 4x Corsair CM4X16GC3000C15K4
  * SSD: Samsung 970 EVO 1TB

### Configuration 1

  * OS: Ubuntu 18.04.1 LTS
  * Memory settings: 64 GB DDR4-3000 15-17-17-35
  * `uname -vr`: 4.15.0-39-generic #42-Ubuntu SMP Tue Oct 23 15:48:01 UTC 2018
  * Governer: performance

  [Results Benchmark 1](results/04-01.csv)

  Fastest runs:

  * Building Clash: 325.55 `cabal new-build clash-ghc --ghc-options=-j3 -j6`
  * Clash testsuite: 128.63 `cabal new-run -- testsuite -p clash -j8`
  * Building stack: 335.27 `GHC_OPTIONS=-j3 cabal new-install stack -j6`
  * Building GHC: 1205.29 `make -j8`
  * GHC testsuite: 265.16 `THREADS=12 ./validate --no-clean --testsuite-only`

  [Results Benchmark 2](resuls/04-02.csv)

  Fastest runs:

  * Building Clash: 289.65 `cabal new-build clash-ghc --ghc-options="+RTS -qn8 -A32M -RTS -j12" -j8`
  * Building stack: 286.33 `GHC_OPTIONS="+RTS -qn8 -A32M -RTS -j4" cabal new-install stack-1.9.1 -j8`

## Machine 5

  * CPU: 2x Xeon Gold 6140M (physical cores: 2x 18)
  * Motherboard: Intel S2600STB
  * Memory: 16x Kingston KSM26RS4/16HAI

### Configuration 1

  * Overclock: none
  * Memory settings: 256 GB DDR4-2666 19-19-19-32 ECC
  * OS: Ubuntu 18.04.1 LTS
  * `uname -vr`: 4.15.0-36-generic #39-Ubuntu SMP Mon Sep 24 16:19:09 UTC 2018
  * Governer: performance

  [Results Benchmark 1](results/05-01.csv)

  Fastest runs:

  * Building Clash: 418.91 `cabal new-build clash-ghc --ghc-options=-j4 -j36`
  * Clash testsuite: 44.47 `cabal new-run -- testsuite -p clash -j72`
  * Building stack: 376.49 `GHC_OPTIONS=-j4 cabal new-install stack -j18`
  * Building GHC: 1328.30 `make -j72`
  * GHC testsuite: 106.44 `THREADS=72 ./validate --no-clean --testsuite-only`

  [Results Benchmark 2](results/05-02.csv)

  Fastest runs:

  * Building Clash: 369.72 `cabal new-build clash-ghc --ghc-options="+RTS -qn8 -A32M -RTS -j8" -j72`
  * Building stack: 310.77 `GHC_OPTIONS="+RTS -qn8 -A32M -RTS -j8" cabal new-install stack-1.9.1 -j18`
  
## Machine 6

  * CPU: Core i7-7700k (physical cores: 4)
  * Motherboard: Asus Prime Z270-A
  * SSD: Samsung 960 Pro 512GB + Samsung 960 EVO 250GB

### Configuration 1

  * Overclock settings: 4.8GHz
  * Memory: Corsair CMK32GX4M2B3000C15
  * Memory settings: 32 GB DDR4-3000 16-17-17-35
  * OS: Ubuntu 18.04.1 LTS
  * `uname -vr`: 4.15.0-42-generic #45-Ubuntu SMP Thu Nov 15 19:32:57 UTC 2018
  * Governer: performance
  
  [Results Benchmark 2](results/06-01.csv)
  
  * Building Clash: 306.53 `cabal new-build clash-ghc --ghc-options="+RTS -qn8 -A32M -RTS -j4" -j4`
  * Clash testsuite: 165.56 `cabal new-run -- testsuite -p clash -j8`
  * Building stack: 335.20 `GHC_OPTIONS="+RTS -qn8 -A32M -RTS -j4" cabal new-install stack-1.9.1 -j8`
  * Building GHC: 1305.27 `make -j8`
  * GHC testsuite: 343.06 `THREADS=8 ./validate --no-clean --testsuite-only`
  
### Configuration 2

  * Overclock settings: 4.8GHz
  * Memory: G.Skill Fortis F4-2400C15Q-64GFT
  * Memory settings: 32 GB DDR4-2400 15-15-15-39
  * OS: Ubuntu 18.04.1 LTS
  * `uname -vr`: 4.15.0-42-generic #45-Ubuntu SMP Thu Nov 15 19:32:57 UTC 2018
  * Governer: performance
  
  [Results Benchmark 2](results/06-02.csv)
  
  * Building Clash: 306.88 `cabal new-build clash-ghc --ghc-options="+RTS -qn8 -A32M -RTS -j4" -j4`
  * Clash testsuite: 170.74 `cabal new-run -- testsuite -p clash -j8`
  * Building stack: 338.47 `GHC_OPTIONS="+RTS -qn8 -A32M -RTS -j4" cabal new-install stack-1.9.1 -j8`
  * Building GHC: 1331.31 `make -j8`
  * GHC testsuite: 349.64 `THREADS=8 ./validate --no-clean --testsuite-only`
