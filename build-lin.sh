#/bin/sh

# ./build-lin.sh all: do the gyp, download, build, normal and copy steps

# ./build-lin.sh gyp : download and installs gyp
# ./build-lin.sh download : download pdfium
# ./build-lin.sh build: build pdfium
# ./build-lin.sh normal : make a static library from the build
# ./build-lin.sh copy : copy static library to install prefix

# ./build-lin.sh link : make a pseudo install with symbolic links

# You may edit the following variables:

SUDO=
PREFIX=$HOME/pdfium/install
#SUDO=sudo
#PREFIX=/usr/local

PROCS=4

BUILDTYPE=Release
#BUILDTYPE=Debug


set -e

if [ "$1" = "" ]; then
    echo "'./build-lin.sh all' will install into $PREFIX"
    exit 1
fi

if [ "$1" = "gyp" -o "$1" = "all" ]; then
  mkdir pdfium_deps
  cd pdfium_deps
  git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
  git clone https://chromium.googlesource.com/external/gyp.git
  cd depot_tools
  export PATH=`pwd`:$PATH
  cd ..
  cd gyp
  #./setup.py install
  ./setup.py build
  cd ..
  cd .. # outside of pdfium_deps
  if [ "$1" != "all" ]; then
    exit 0
  fi
fi

if [ "$1" = "download" -o "$1" = "all" ]; then
  # Download pdfium
  git clone https://github.com/klokantech/pdfium
  if [ "$1" != "all" ]; then
    exit 0
  fi
fi

if [ "$1" = "build" -o "$1" = "all" ]; then
    export PATH=`pwd`/pdfium_deps/depot_tools:$PATH
    export PYTHONPATH=$PWD/pdfium_deps/gyp/build/`ls $PWD/pdfium_deps/gyp/build`

    cd pdfium
    ./build/gyp_pdfium

    make -j$PROCS BUILDTYPE=$BUILDTYPE \
    pdfium \
    fdrm \
    fpdfdoc \
    fpdfapi \
    fpdftext \
    fxcodec \
    fxcrt \
    fxge \
    fxedit \
    pdfwindow \
    formfiller

    # third_party targets
    make -j$PROCS BUILDTYPE=$BUILDTYPE \
    bigint \
    freetype \
    fx_agg \
    fx_lcms2 \
    fx_zlib \
    pdfium_base \
    fx_libjpeg \
    fx_libopenjpeg

    cd ..

    if [ "$1" != "all" ]; then
      exit 0
    fi
fi

# Transform to normal static libraries
if [ "$1" = "normal" -o "$1" = "all" ]; then
  cd pdfium/out/$BUILDTYPE/obj.target
  for lib in `find -name '*.a'`;
      do ar -t $lib | xargs ar rvs $lib.new && mv -v $lib.new $lib;
  done
  cd third_party
  for lib in `find -name '*.a'`;
      do ar -t $lib | xargs ar rvs $lib.new && mv -v $lib.new $lib;
  done
  cd ../../../../..

  if [ "$1" != "all" ]; then
    exit 0
  fi
fi

if [ "$1" = "copy" -o "$1" = "all" ]; then
  # Copy libraries into $PREFIX
  $SUDO mkdir -p $PREFIX/lib/pdfium
  $SUDO cp pdfium/out/$BUILDTYPE/obj.target/lib*.a $PREFIX/lib/pdfium/
  $SUDO cp pdfium/out/$BUILDTYPE/obj.target/third_party/lib*.a $PREFIX/lib/pdfium/
  
  # Copy all headers
  $SUDO mkdir -p $PREFIX/include/pdfium/fpdfsdk/include
  $SUDO mkdir -p $PREFIX/include/pdfium/core/include
  $SUDO mkdir -p $PREFIX/include/pdfium/third_party/base/numerics
  $SUDO mkdir -p $PREFIX/include/pdfium/public
  $SUDO cp -r pdfium/public/*.h $PREFIX/include/pdfium/
  $SUDO cp -r pdfium/public/*.h $PREFIX/include/pdfium/public
  $SUDO cp -r pdfium/fpdfsdk/include/* $PREFIX/include/pdfium/fpdfsdk/include/
  $SUDO cp -r pdfium/core/include/* $PREFIX/include/pdfium/core/include
  $SUDO cp -r pdfium/third_party/base/numerics/* $PREFIX/include/pdfium/third_party/base/numerics
  $SUDO cp -r pdfium/third_party/base/* $PREFIX/include/pdfium/third_party/base/

  echo "./configure --with-pdfium=$PREFIX"
fi

if [ "$1" = "link" ]; then
  cd pdfium

  # Link public to include
  ln -s public include
  cd include
  ln -s ../fpdfsdk
  ln -s ../core
  ln -s ../third_party
  cd ..

  # Make lib directory structure with symlinks to out folder
  # Output is thin library, we need object files
  mkdir -p lib && cd lib
  ln -s ../out/$BUILDTYPE/obj.target/* .
  rm -f pdfium && mkdir pdfium && cd pdfium
  ln -s ../../out/$BUILDTYPE/obj.target/* .
  ln -s ../../out/$BUILDTYPE/obj.target/third_party/*.a .
  cd ..

  echo "./configure --with-pdfium=`pwd`"

  cd ..
fi
