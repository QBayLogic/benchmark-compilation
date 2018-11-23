#!/bin/bash
set -e
set -x

cd $(mktemp -d)

export PATH="$HOME/.local/bin:$HOME/.cabal/bin:/opt/ghc/bin:/usr/local/bin/:$PATH"
 
TIMEF="%C,%x,%e,%U,%S,"
RESULT=$HOME/$(lsb_release -d -s | tr ' ' '_' | tr -d '"').csv
FASTRUN=0

echo "command,exit,real,user,sys,comment" > ${RESULT}
 
# Benchmark building clash-ghc
git clone --recursive https://github.com/clash-lang/clash-compiler.git -q  
cd clash-compiler
git checkout feature-dependent-tests
 
cabal new-update
 
for ghc_threads in 64 32 16 8 4 2 1; do
       for cabal_threads in 64 32 16 8 4 2 1; do
               rm -rf ~/.cabal/store
               rm -rf dist-newstyle
               echo "=========== clash-ghc, ghc=${ghc_threads}, cabal=${cabal_threads} ==========="
               /usr/bin/time --quiet -p -f ${TIMEF} -o ${RESULT} -a -- cabal new-build clash-ghc --ghc-options="-j${ghc_threads}" -j${cabal_threads} || true
               [ $FASTRUN == 1 ] && break
       done
       [ $FASTRUN == 1 ] && break
done
 
# Benchmark testsuite
cabal new-run testsuite -- -p nosuchtest
 
for threads in 64 32 16 8 4 2 1; do
       echo "=========== testsuite, threads=${threads} ==========="
       /usr/bin/time --quiet -p -f ${TIMEF} -o ${RESULT} -a -- cabal new-run -- testsuite -p clash -j${threads} || true
       [ $FASTRUN == 1 ] && break
done

cd ..

# Just for warming the download cache..
cabal new-install stack
rm -rf ~/.cabal/store

# Compile Stack
for ghc_threads in 64 32 16 8 4 2 1; do
       for cabal_threads in 64 32 16 8 4 2 1; do
           rm -rf ~/.cabal/store
           echo "=========== stack, ghc=${ghc_threads}, cabal=${cabal_threads} ==========="
           /usr/bin/time --quiet -p -f ${TIMEF} -o ${RESULT} -a -- cabal new-install stack --ghc-options="-j${ghc_threads}" -j${cabal_threads} || true
           [ $FASTRUN == 1 ] && break
       done
       [ $FASTRUN == 1 ] && break
done

# Setup GHC..
git clone --jobs 16 --recursive git://git.haskell.org/ghc.git -q
cd ghc
git checkout 47bbc709cb221e32310c6e28eb2f33acf78488c7
#rm -rf *
git submodule update --init
./boot

# Use intree GMP
cp mk/build.mk.sample mk/build.mk
sed -i 's/^#BuildFlavour = perf$/BuildFlavour = perf/g' mk/build.mk
sed -i 's/^#libraries/libraries/g' mk/build.mk

# Remove need for Sphinx & co
cp mk/validate.mk.sample mk/validate.mk
sed -i 's/^#HADDOCK/HADDOCK/g' mk/validate.mk
sed -i 's/^#BUILD/BUILD/g' mk/validate.mk

# Build GHC with various number of threads
for threads in 64 32 16 8 4 2 1; do
        make clean 
        ./configure
        echo "=========== make ghc, threads=${threads} ==========="
        THREADS=${threads} /usr/bin/time --quiet -p -f ${TIMEF} -o ${RESULT} -a -- make -j${threads} || true
        [ $FASTRUN == 1 ] && break
done

make maintainer-clean
./validate --build-only

for threads in 64 32 16 8 4 2 1; do
        echo "=========== validate ghc, threads=${threads} ==========="
        THREADS=${threads} /usr/bin/time --quiet -p -f "${TIMEF}THREADS=${threads}" -o ${RESULT} -a -- ./validate --no-clean --testsuite-only || true
        [ $FASTRUN == 1 ] && break
done

rm -rf $(pwd)
