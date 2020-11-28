#!/bin/sh

$sudo yum -y install autoconf automake cmake freetype-devel gcc gcc-c++ git libtool make mercurial pkgconfig zlib-devel

#alias make='make -j 4'

# if cmake version < 3.5
#sudo yum -y install wget
#sudo yum remove cmake
#wget https://cmake.org/files/v3.17/cmake-3.17.2.tar.gz
#tar xvzf cmake-3.17.2.tar.gz
#cd cmake-3.17.2
#./bootstrap
#make
#sudo make install


mkdir ~/ffmpeg_sources

#Yasm
cd ~/ffmpeg_sources
git clone --depth 1 git://github.com/yasm/yasm.git
cd yasm
autoreconf -fiv
./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin"
make
make install


#nasm
cd ~/ffmpeg_sources
wget https://www.nasm.us/pub/nasm/releasebuilds/2.14.02/nasm-2.14.02.tar.xz
tar xvfJ nasm-2.14.02.tar.xz
cd nasm-2.14.02
./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin"
make
make install


#AV1
#    cd ~/ffmpeg_sources
#    git clone --depth 1 https://aomedia.googlesource.com/aom
#    mkdir aom_build
#    cd aom_build
#    cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" -DENABLE_SHARED=off -DENABLE_NASM=on ../aom
#    make
#    make install


#libx265
#    cd ~/ffmpeg_sources
#    hg clone https://bitbucket.org/multicoreware/x265
#    cd ~/ffmpeg_sources/x265/build/linux
#    cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" -DENABLE_SHARED=off ../../source
#    make
#    make install


#libx264
cd ~/ffmpeg_sources
git clone --depth 1 https://code.videolan.org/videolan/x264.git
cd x264
PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" --enable-static
make
make install

#libfdk_aac
cd ~/ffmpeg_sources
git clone --depth 1 git://git.code.sf.net/p/opencore-amr/fdk-aac
cd fdk-aac
autoreconf -fiv
./configure --prefix="$HOME/ffmpeg_build" --disable-shared
make
make install


#libmp3lame
cd ~/ffmpeg_sources
curl -O -L http://downloads.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz
tar xzvf lame-3.100.tar.gz
cd lame-3.100
./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" --disable-shared --enable-nasm
make
make install


#libopus
cd ~/ffmpeg_sources
curl -O -L https://archive.mozilla.org/pub/opus/opus-1.3.1.tar.gz
tar xzvf opus-1.3.1.tar.gz
cd opus-1.3.1
./configure --prefix="$HOME/ffmpeg_build" --disable-shared
make
make install


#libogg
cd ~/ffmpeg_sources
curl -O https://ftp.osuosl.org/pub/xiph/releases/ogg/libogg-1.3.4.tar.gz
tar xzvf libogg-1.3.4.tar.gz
cd libogg-1.3.4
./configure --prefix="$HOME/ffmpeg_build" --disable-shared
make
make install

#libvorbis
cd ~/ffmpeg_sources
curl -O https://ftp.osuosl.org/pub/xiph/releases/vorbis/libvorbis-1.3.6.tar.gz
tar xzvf libvorbis-1.3.6.tar.gz
cd libvorbis-1.3.6
LDFLAGS="-L$HOME/ffmeg_build/lib" CPPFLAGS="-I$HOME/ffmpeg_build/include" ./configure --prefix="$HOME/ffmpeg_build" --with-ogg="$HOME/ffmpeg_build" --disable-shared
make
make install

#libvpx
cd ~/ffmpeg_sources
git clone --depth 1 https://chromium.googlesource.com/webm/libvpx.git
cd libvpx
./configure --prefix="$HOME/ffmpeg_build" --disable-examples
make
make install

#FFmpeg
cd ~/ffmpeg_sources
wget http://ffmpeg.org/releases/ffmpeg-4.2.3.tar.xz
tar Jxfv ffmpeg-4.2.3.tar.xz
cd ffmpeg*
#PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig:$HOME/ffmpeg_build/lib64/pkgconfig" ./configure --prefix="$HOME/ffmpeg_build" --extra-cflags="-I$HOME/ffmpeg_build/include" --extra-ldflags="-L$HOME/ffmpeg_build/lib" --bindir="$HOME/bin" --pkg-config-flags="--static" --enable-gpl --enable-nonfree --enable-libfdk-aac --enable-libfreetype --enable-libmp3lame --enable-libopus --enable-libvorbis --enable-libvpx --enable-libx264 --enable-libx265 --enable-libaom --extra-libs=-lpthread --extra-libs=-lm
PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig:$HOME/ffmpeg_build/lib64/pkgconfig" ./configure --prefix="$HOME/ffmpeg_build" --extra-cflags="-I$HOME/ffmpeg_build/include" --extra-ldflags="-L$HOME/ffmpeg_build/lib" --bindir="$HOME/bin" --pkg-config-flags="--static" --enable-gpl --enable-nonfree --enable-libfdk-aac --enable-libmp3lame --enable-libopus --enable-libvorbis --enable-libvpx --enable-libx264  --extra-libs=-lpthread --extra-libs=-lm
make
make install
hash -r





