# Ranking

#### Building Clash (empty Cabal store)

1. 325.55: Machine 4; Configuration 1; `cabal new-build clash-ghc --ghc-options=-j3 -j6`
1. 339.22: Machine 3; Configuration 1; `cabal new-build clash-ghc --ghc-options=-j2 -j4`
1. 450,43: Machine 1; Configuration 1; `cabal new-build clash-ghc --ghc-options=-j4 -j8`
1. 460,95: Machine 2; Configuration 1; `cabal new-build clash-ghc --ghc-options=-j2 -j16`

#### Clash testsuite

1. 70,54: Machine 2; Configuration 1; `cabal new-run -- testsuite -p clash -j32`
1. 128.63: Machine 4; Configuration 1; `cabal new-run -- testsuite -p clash -j8`
1. 161.8: Machine 3; Configuration 1; `cabal new-run -- testsuite -p clash -j8`
1. 168.78: Machine 1; Configuration 1; `cabal new-run -- testsuite -p clash -j8`

#### Building stack (empty Cabal store)

1. 325.55: Machine 4; Configuration 1; `GHC_THREADS=3 cabal new-install stack -j6`
1. 372.12: Machine 3; Configuration 1; `GHC_THREADS=2 cabal new-install stack -j8`
1. 444,75: Machine 2; Configuration 1; `GHC_THREADS=4 cabal new-install stack -j16`
1. 468.2: Machine 1; Configuration 1; `GHC_THREADS=2 cabal new-install stack -j8`

#### Building GHC

~~1. 685,94: Machine 2; Configuration 1; `make -j64`~~ Exit code: 2
1. 1683.62: Machine 1; Configuration 1; `make -j16`

#### GHC testsuite

1. 324.21: Machine 1; Configuration 1; `THREADS=16 ./validate --no-clean --testsuite-only`
1.

# Configurations

## Machine 1

  * CPU: Ryzen 2700X
  * Motherboard: ASRock X470 Master SLI
  * Memory: G.Skill Fortis F4-2400C15Q-64GFT
  * SSD: Samsung 970 Evo 1TB

### Configuration 1

  * Overclock settings: none
  * Memory: 64 GB DDR4-2400 15-15-15-39
  * OS: Ubuntu 18.04.1 LTS
  * `uname -vr`: 4.15.0-39-generic #42-Ubuntu SMP Tue Oct 23 15:48:01 UTC 2018
  * Governer: performance

  Fastest runs:

  * Building Clash: 450,43 `cabal new-build clash-ghc --ghc-options=-j4 -j8`
  * Clash testsuite: 168.78 `cabal new-run -- testsuite -p clash -j8`
  * Building stack: 468.2 `GHC_THREADS=2 cabal new-install stack -j8`
  * Building GHC: 1683.62 `make -j16`
  * GHC testsuite: 324.21 `THREADS=16 ./validate --no-clean --testsuite-only`

  [Results](results/0001.csv)

## Machine 2

  * CPU: Threadripper 2990wx
  * Motherboard: ASRock X399 Taichi
  * Memory: 8x Samsung M391A2K43BB1-CRC
  * SSD: Samsung 970 Pro 1TB

### Configuration 1

  * Overclock settings: none
  * Memory: 128 GB DDR4-2400 17-17-17-32 ECC
  * OS: OpenSUSE Tumbleweed
  * `uname -vr`: 4.19.2-1-default #1 SMP PREEMPT Tue Nov 13 20:56:49 UTC 2018
  * Governer: performance

  Fastest runs:

  * Building Clash: 460,95 `cabal new-build clash-ghc --ghc-options=-j2 -j16`
  * Clash testsuite: 70,54 `cabal new-run -- testsuite -p clash -j32`
  * Building stack: 444,75 `GHC_THREADS=4 cabal new-install stack -j16`
  * Building GHC: 685,94 `make -j64`
  * GHC testsuite:

  [Results](results/0002.csv)

## Machine 3

  * CPU: Core i7-7700K
  * Motherboard: Asus PRIME Z270-P
  * Memory: CMK64GX4M4B2800C14
  * SSD: Samsung 960 EVO 1TB

### Configuration 1

  * Overclock: 4.8 GHz
  * OS: Ubuntu 18.04.1 LTS
  * Memory: 64 GB DD4-2800 14-16-16-36
  * `uname -vr`: 4.15.0-39-generic #42-Ubuntu SMP Tue Oct 23 15:48:01 UTC 2018
  * Governer: performance

  Fastest runs:

  * Building Clash: 339.22 `cabal new-build clash-ghc --ghc-options=-j2 -j4`
  * Clash testsuite: 161.8 `cabal new-run -- testsuite -p clash -j8`
  * Building stack: 372.12 `GHC_THREADS=2 cabal new-install stack -j8`
  * Building GHC:
  * GHC testsuite:

  [Results](results/0003.csv)


## Machine 4

  * CPU: Core i7-8700K
  * Motherboard: Asus PRIME Z370-P II
  * Memory: 4x Corsair CM4X16GC3000C15K4
  * SSD: Samsung 970 EVO 1TB

### Configuration 1

  * OS: Ubuntu 18.04.1 LTS
  * Memory: 64 GB DDR4-3000 15-17-17-35
  * `uname -vr`: 4.15.0-39-generic #42-Ubuntu SMP Tue Oct 23 15:48:01 UTC 2018
  * Governer: performance

  Fastest runs:

  * Building Clash: 325.55 `cabal new-build clash-ghc --ghc-options=-j3 -j6`
  * Clash testsuite: 128.63 `cabal new-run -- testsuite -p clash -j8`
  * Building stack: 335.27 `GHC_THREADS=3 cabal new-install stack -j6`
  * Building GHC:
  * GHC testsuite:

  [Results](results/0004.csv)

## Machine 5

  * CPU: 2x Xeon Gold 6140M
  * Motherboard: Intel S2600STB
  * Memory: 16x Kingston 9965589-001.E00G

### Configuration 1

  * Overclock: none
  * Memory: 256 GB DDR4-2666 ECC
  * OS: Ubuntu 18.04.1 LTS
  * `uname -vr`: 4.15.0-36-generic #39-Ubuntu SMP Mon Sep 24 16:19:09 UTC 2018
  * Governer: performance
