FROM emscripten/emsdk:3.1.3 AS build-stage

# To avoid all sort of prompts from apt-get
# ENV DEBIAN_FRONTEND=noninteractive
ENV THIRDPARTY_DIR /opt/3rdparty

# Use aliyun apt source
# RUN sed -i s@/archive.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list
RUN apt-get clean && apt-get update

# Install tool and dependencies
RUN apt-get -y install build-essential \
	git wget vim\
	cmake automake libtool autoconf\
	tcl tcl-dev tk tk-dev libfreeimage-dev \
	libxmu-dev libxi-dev \
	libglfw3-dev libgl1-mesa-dev libglu1-mesa-dev \
	xvfb

# Build RapidJson
WORKDIR $THIRDPARTY_DIR

RUN git clone --depth 1 --branch v1.1.0 https://github.com/Tencent/rapidjson.git rapidjson-1.1.0

# Build Freetype
WORKDIR $THIRDPARTY_DIR

RUN wget https://download.savannah.gnu.org/releases/freetype/freetype-2.7.1.tar.gz

RUN tar -zxvf freetype-2.7.1.tar.gz >> installed_freetype271_files.txt

WORKDIR $THIRDPARTY_DIR/freetype-2.7.1

RUN sh autogen.sh
WORKDIR $THIRDPARTY_DIR/freetype-2.7.1/build
RUN cmake -G "Unix Makefiles" \
    -DCMAKE_TOOLCHAIN_FILE:FILEPATH="/emsdk/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake" \
    -DCMAKE_INSTALL_PREFIX=$THIRDPARTY_DIR/freetype-2.7.1-wasm ..

RUN make -j4 && make install

# Build Draco
WORKDIR $THIRDPARTY_DIR

RUN git clone --depth 1 --branch 1.4.1 https://github.com/google/draco.git draco-1.4.1
RUN cd draco-1.4.1 && \
    git checkout 1.4.1 -b build

WORKDIR $THIRDPARTY_DIR/draco-1.4.1/build

ENV EMSCRIPTEN /emsdk/upstream/emscripten
RUN cmake -G "Unix Makefiles" \
    -DCMAKE_TOOLCHAIN_FILE:FILEPATH="/emsdk/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake" \
    -DCMAKE_INSTALL_PREFIX=$THIRDPARTY_DIR/draco-1.4.1-wasm \
	-DCMAKE_BUILD_TYPE:STRING="Release" \
	-DDRACO_WASM:BOOL=ON \
	-DBUILD_LIBRARY_TYPE:STRING="Static" \
	-DDRACO_JS_GLUE:BOOL=OFF ..
RUN make -j4 && make install

# Build tcl
WORKDIR $THIRDPARTY_DIR

RUN git clone --depth 1 https://github.com/gkv311/tcl.git
WORKDIR tcl
ADD occ_tcl_build_wasm.sh .
RUN /bin/bash occ_tcl_build_wasm.sh

# Build OCCT
WORKDIR /opt
RUN git clone --depth 1 --branch IR-2022-02-04 https://git.dev.opencascade.org/repos/occt.git opencascade

ARG pthread

WORKDIR /opt/opencascade/build
RUN emcmake cmake \
	-DCMAKE_CXX_FLAGS="${pthread}" \
	-DINSTALL_DIR=/opt/occt \
	-DBUILD_MODULE_Draw:BOOL=ON \
	-DBUILD_LIBRARY_TYPE="Static" \
	-DBUILD_DOC_Overview:BOOL=FALSE \
	-DCMAKE_BUILD_TYPE=release \
	-DUSE_FREETYPE:BOOL=ON \
	-D3RDPARTY_FREETYPE_DIR:PATH=$THIRDPARTY_DIR/freetype-2.7.1-wasm \
	-D3RDPARTY_FREETYPE_INCLUDE_DIR_freetype2=$THIRDPARTY_DIR/freetype-2.7.1-wasm/include \
	-D3RDPARTY_FREETYPE_INCLUDE_DIR_ft2build=$THIRDPARTY_DIR/freetype-2.7.1-wasm/include/freetype2 \
	-D3RDPARTY_FREETYPE_LIBRARY_DIR=$THIRDPARTY_DIR/freetype-2.7.1-wasm/lib \
	-DUSE_RAPIDJSON:BOOL=ON \
	-D3RDPARTY_RAPIDJSON_DIR:PATH=$THIRDPARTY_DIR/rapidjson-1.1.0 \
	-D3RDPARTY_RAPIDJSON_INCLUDE_DIR:PATH=$THIRDPARTY_DIR/rapidjson-1.1.0/include \
	-DUSE_DRACO:BOOL=ON \
	-D3RDPARTY_DRACO_DIR:PATH=$THIRDPARTY_DIR/draco-1.4.1-wasm \
	-D3RDPARTY_DRACO_INCLUDE_DIR:FILEPATH=$THIRDPARTY_DIR/draco-1.4.1-wasm/include \
	-D3RDPARTY_DRACO_LIBRARY_DIR:PATH=$THIRDPARTY_DIR/draco-1.4.1-wasm/lib \
	-D3RDPARTY_DRACO_LIBRARY_DIR:FILEPATH=$THIRDPARTY_DIR/draco-1.4.1-wasm/lib/libdraco.a \
	-DUSE_TK:BOOL=OFF \
	-D3RDPARTY_TCL_DIR:PATH=$THIRDPARTY_DIR/tcl-wasm32 \
	-D3RDPARTY_TCL_INCLUDE_DIR:PATH=$THIRDPARTY_DIR/tcl-wasm32/include \
	-D3RDPARTY_TCL_LIBRARY_DIR:PATH=$THIRDPARTY_DIR/tcl-wasm32/lib \
	-D3RDPARTY_TCL_LIBRARY:FILEPATH=$THIRDPARTY_DIR/tcl-wasm32/lib/libtcl8.6.a \
	-DUSE_GLES2:BOOL=OFF \
	..

RUN emmake make -j8
# RUN emmake make install

# Output wasm file
FROM scratch AS export-stage
COPY --from=build-stage /opt/opencascade/build/lin32/clang/bin /output