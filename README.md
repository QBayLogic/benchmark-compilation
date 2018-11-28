# Ranking

* Building Clash

1. 450,43: Machine 1; Configuration 1; `cabal new-build clash-ghc --ghc-options=-j4 -j8`
1. 460,95: Machine 2; Configuration 1; `cabal new-build clash-ghc --ghc-options=-j2 -j16`
1.
1.
1.

* Clash testsuite

1. 70,54: Machine 2; Configuration 1; `cabal new-run -- testsuite -p clash -j32`
1. 168.78: Machine 1; Configuration 1; `cabal new-run -- testsuite -p clash -j8`
1.
1.

* Building stack

1. 444,75: Machine 2; Configuration 1; `GHC_THREADS=16 cabal new-install stack -j16`
1. 468.2: Machine 1; Configuration 1; `GHC_THREADS=8 cabal new-install stack -j8`
1.
1.

* Building GHC

1. 685,94: Machine 2; Configuration 1; `make -j64`
1. 1683.62: Machine 1; Configuration 1; `make -j16`
1.
1.

* GHC testsuite

1. 324.21: Machine 1; Configuration 1; `THREADS=16 ./validate --no-clean --testsuite-only`
1.
1.
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

  Fastests runs:

  * Building Clash: 450,43 `cabal new-build clash-ghc --ghc-options=-j4 -j8`
  * Clash testsuite: 168.78 `cabal new-run -- testsuite -p clash -j8`
  * Building stack: 468.2 `GHC_THREADS=8 cabal new-install stack -j8`
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

  Fastests runs:

  * Building Clash: 460,95 `cabal new-build clash-ghc --ghc-options=-j2 -j16`
  * Clash testsuite: 70,54 `cabal new-run -- testsuite -p clash -j32`
  * Building stack: 444,75 `GHC_THREADS=16 cabal new-install stack -j16`
  * Building GHC: 685,94 `make -j64`
  * GHC testsuite:

  [Results](results/0002.csv)

## Machine 3

  * CPU: Core i7-7700K
  * Motherboard: Asus PRIME Z270-P
  * Memory: CMK64GX4M4B2800C14
  * SSD: Samsung 960 EVO 1TB

### Configuration 1

  * OS: Ubuntu 18.04.1 LTS
  * Memory: 64 GB DD4-2800 14-16-16-36
  * `uname -vr`: 4.15.0-39-generic #42-Ubuntu SMP Tue Oct 23 15:48:01 UTC 2018
  * Governer: performance

  [Results]()


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

  [Results]()
