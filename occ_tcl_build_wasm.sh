#!/bin/bash

# This is helpful script to perform building of Tcl for WebAssembly platform
# https://www.tcl.tk/software/tcltk/download.html

# go to the script directory
aScriptPath=${BASH_SOURCE%/*}
if [ -d "$aScriptPath" ]; then
  cd "$aScriptPath"
fi

# define number of jobs from available CPU cores
aNbJobs="$(getconf _NPROCESSORS_ONLN)"

aPathBak="$PATH"
aTclRoot="$PWD"

OUTPUT_FOLDER="/opt/3rdparty/tcl-wasm32"
rm -f -r "$OUTPUT_FOLDER"
mkdir -p "$OUTPUT_FOLDER"
cp -f    "$aTclRoot/license.terms" "$OUTPUT_FOLDER"
cp -f    "$aTclRoot/README.md"     "$OUTPUT_FOLDER"
echo "Output directory: $OUTPUT_FOLDER"

#export "PATH=$EMSDK_ROOT/upstream/bin:$aPathBak"
#export "CC=emcc"
#export "AR=llvm-ar"
#export "RANLIB=llvm-ranlib"
#export "CFLAGS=$aCFlags"
pushd "$aTclRoot/unix"
#./configure --build x86_64-linux --host wasm32 --prefix=${OUTPUT_FOLDER} 2>&1 | tee $OUTPUT_FOLDER/config-wasm32.log
emconfigure ./configure --prefix=${OUTPUT_FOLDER} --enable-shared=no --enable-threads=no 2>&1 | tee $OUTPUT_FOLDER/config-wasm32.log
aResult=$?; if [[ $aResult != 0 ]]; then echo "FAILED configure"; exit $aResult; fi
emmake make clean
emmake make -j$aNbJobs
aResult=$?; if [[ $aResult != 0 ]]; then echo "FAILED make"; exit $aResult; fi
emmake make install
popd
