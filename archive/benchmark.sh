#!/bin/bash
set -e
set -x

cd $(mktemp -d)

export PATH="$HOME/.local/bin:$HOME/.cabal/bin:/opt/ghc/bin:/usr/local/bin/:$PATH"

THREAD_STEPS="64 32 16 8 4 2 1"
TIMEF="%C,%x,%e,%U,%S,"
RESULT=$(mktemp --tmpdir="$HOME" benchmark-results.XXXX.csv)
RESULT_INFO="$RESULT.info"
lsb_release -d >> "$RESULT_INFO"
uname -vr >> "$RESULT_INFO"
cpupower frequency-info >> "$RESULT_INFO"

FASTRUN=0

echo "command,exit,real,user,sys,comment" > ${RESULT}

# Benchmark building clash-ghc
git clone --recursive https://github.com/clash-lang/clash-compiler.git -q
cd clash-compiler
git checkout 5f9dd26825fb912896d7d1837238117131f0c37f # this commit merged dependant tests into master

cabal new-update

# Just for warming the download cache..
cabal new-build clash-ghc || true

for ghc_threads in ${THREAD_STEPS}; do
       for cabal_threads in ${THREAD_STEPS}; do
               rm -rf ~/.cabal/store
               rm -rf dist-newstyle
               echo "=========== clash-ghc, ghc=${ghc_threads}, cabal=${cabal_threads} ==========="
               /usr/bin/time --quiet -p -f ${TIMEF} -o ${RESULT} -a -- cabal new-build clash-ghc --ghc-options="-j${ghc_threads}" -j${cabal_threads} || true
               [ $FASTRUN == 1 ] && break
       done
       [ $FASTRUN == 1 ] && break
done

# Disable testing cosim
cat >> cabal.project.local << END_CABAL_PROJECT_LOCAL
package clash-testsuite
  flags: -cosim
END_CABAL_PROJECT_LOCAL

# Benchmark testsuite
cabal new-run testsuite -- -p nosuchtest || true

for threads in ${THREAD_STEPS}; do
       echo "=========== testsuite, threads=${threads} ==========="
       /usr/bin/time --quiet -p -f ${TIMEF} -o ${RESULT} -a -- cabal new-run -- testsuite -p clash -j${threads} || true
       [ $FASTRUN == 1 ] && break
done

cd ..

# We can't use --ghc-options on new-install to set the GHC threads,
# so we set the ghc-options in ~/.cabal/config
sed -i 's/^  -- ghc-options:.*/  ghc-options:/g' ~/.cabal/config
grep -q "^  ghc-options:" ~/.cabal/config || echo "Error: ~/.cabal/config doesn't have a ghc-options that we can rewrite" || exit 1

# Just for warming the download cache..
cabal new-install stack-1.9.1.1 || true
rm -rf ~/.cabal/store
GHC_VERSION="$(ghc --numeric-version)"
# something on openSUSE needs a package.db in your store
ghc-pkg init ~/.cabal/store/ghc-$GHC_VERSION/package.db

# Compile Stack
for ghc_threads in ${THREAD_STEPS}; do
       for cabal_threads in ${THREAD_STEPS}; do
           rm -rf ~/.cabal/store
           ghc-pkg init ~/.cabal/store/ghc-$GHC_VERSION/package.db
           sed -i "s/^  ghc-options:.*/  ghc-options: -j${ghc_threads}/g" ~/.cabal/config
           echo "=========== stack, ghc=${ghc_threads}, cabal=${cabal_threads} ==========="
           /usr/bin/time --quiet -p -f "${TIMEF}GHC_THREADS=${ghc_threads}" -o ${RESULT} -a -- cabal new-install stack-1.9.1.1 -j${cabal_threads} || true
           [ $FASTRUN == 1 ] && break
       done
       [ $FASTRUN == 1 ] && break
done

#unset ghc options in cabal config
sed -i 's/^  ghc-options:.*/  -- ghc-options:/g' ~/.cabal/config

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
cat >> mk/build.mk << END_BUILD_MK
BUILD_SPHINX_HTML = NO
BUILD_SPHINX_PDF  = NO
END_BUILD_MK

# Remove need for Sphinx & co
cp mk/validate.mk.sample mk/validate.mk
sed -i 's/^#HADDOCK/HADDOCK/g' mk/validate.mk
sed -i 's/^#BUILD/BUILD/g' mk/validate.mk

# Build GHC with various number of threads
for threads in ${THREAD_STEPS}; do
        make clean
        ./configure
        echo "=========== make ghc, threads=${threads} ==========="
        THREADS=${threads} /usr/bin/time --quiet -p -f ${TIMEF} -o ${RESULT} -a -- make -j${threads} || true
        [ $FASTRUN == 1 ] && break
done

make maintainer-clean
./validate --build-only

for threads in ${THREAD_STEPS}; do
        echo "=========== validate ghc, threads=${threads} ==========="
        THREADS=${threads} /usr/bin/time --quiet -p -f "${TIMEF}THREADS=${threads}" -o ${RESULT} -a -- ./validate --no-clean --testsuite-only || true
        [ $FASTRUN == 1 ] && break
done

rm -rf $(pwd)
