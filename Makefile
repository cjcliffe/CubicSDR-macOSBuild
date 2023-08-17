INSTALL_DIR := $(CURDIR)/install_dir
NPROC := $(shell sysctl -n hw.logicalcpu)
SOAPY_SDR_ROOT := $(CURDIR)/install_dir
SOAPY_ABI_VERSION := 0.8-3

all: CubicSDR

clean:
	rm -rf build_stage install_dir

build_stage:
	mkdir build_stage || true
	chmod +x scripts/*.sh


install_dir:
	mkdir install_dir || true


CubicSDR: build_stage install_dir liquid-dsp SoapySDR wxWidgets all_modules
	scripts/update_repo.sh build_stage/CubicSDR https://github.com/cjcliffe/CubicSDR.git
	mkdir -p build_stage/CubicSDR/build || true
	cmake -S build_stage/CubicSDR -B build_stage/CubicSDR/build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} -DLIQUID_INCLUDES=${INSTALL_DIR}/include -DLIQUID_LIBRARIES=${INSTALL_DIR}/lib/libliquid.dylib -DwxWidgets_CONFIG_EXUTABLE=${INSTALL_DIR}/wxWidgets-staticlib/bin/wx-config -DSoapySDR_DIR=${INSTALL_DIR}/share/cmake/SoapySDR -DBUNDLE_APP=1 -DBUNDLE_SOAPY_MODS=1 -DCPACK_BINARY_DRAGNDROP=1 -DSOAPY_SDR_ROOT=${INSTALL_DIR} -DCMAKE_PREFIX_PATH=${INSTALL_DIR}
	# TODO: symlinked libs not being handled correctly with cpack; just move it manually for now
	cp ${INSTALL_DIR}/lib/*.dylib build_stage/CubicSDR/build/x64/CubicSDR.app/Contents/MacOS/
	cd build_stage/CubicSDR/build && make -j${NPROC} && cpack


wxWidgets: build_stage install_dir install_dir/wxWidgets-staticlib/bin/wx-config
install_dir/wxWidgets-staticlib/bin/wx-config:
	cd build_stage && wget https://github.com/wxWidgets/wxWidgets/releases/download/v3.2.1/wxWidgets-3.2.1.tar.bz2 
	cd build_stage && tar -xvjf wxWidgets-3.2.1.tar.bz2
	cd build_stage/wxWidgets-3.2.1 && ./configure --with-opengl --with-libjpeg --disable-shared --enable-monolithic --with-libtiff --with-libpng --with-zlib --disable-sdltest --enable-unicode --enable-display --enable-propgrid --disable-webview --disable-webviewwebkit --prefix=${INSTALL_DIR}/wxWidgets-staticlib CXXFLAGS="-std=c++0x"
	cd build_stage/wxWidgets-3.2.1 && make -j${NPROC} && make install


liquid-dsp: build_stage install_dir install_dir/lib/libliquid.dylib
install_dir/lib/libliquid.dylib:
	scripts/update_repo.sh build_stage/liquid-dsp https://github.com/jgaeddert/liquid-dsp.git
	cd build_stage/liquid-dsp && \
	./bootstrap.sh && \
	./configure --prefix=${INSTALL_DIR} && \
	make -j${NPROC} install

SoapySDR: build_stage install_dir install_dir/lib/libSoapySDR.dylib
install_dir/lib/libSoapySDR.dylib:
	scripts/update_repo.sh build_stage/SoapySDR https://github.com/pothosware/SoapySDR.git
	mkdir -p build_stage/SoapySDR/build || true
	cmake -S build_stage/SoapySDR -B build_stage/SoapySDR/build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} -DCMAKE_PREFIX_PATH=${INSTALL_DIR}
	cd build_stage/SoapySDR/build && make -j${NPROC} && make install

all_modules: SoapyRTLSDR SoapyAudio

SoapyRTLSDR: SoapySDR install_dir/lib/SoapySDR/modules${SOAPY_ABI_VERSION}/librtlsdrSupport.so
install_dir/lib/SoapySDR/modules${SOAPY_ABI_VERSION}/librtlsdrSupport.so:
	scripts/update_repo.sh build_stage/SoapyRTLSDR https://github.com/pothosware/SoapyRTLSDR.git
	mkdir -p build_stage/SoapyRTLSDR/build || true
	cmake -S build_stage/SoapyRTLSDR -B build_stage/SoapyRTLSDR/build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} -DCMAKE_PREFIX_PATH=${INSTALL_DIR}
	cd build_stage/SoapyRTLSDR/build && make -j${NPROC} && make install
	ls -la install_dir/lib/SoapySDR/modules${SOAPY_ABI_VERSION}/librtlsdrSupport.so

SoapyAudio: SoapySDR install_dir/lib/SoapySDR/modules${SOAPY_ABI_VERSION}/libaudioSupport.so
install_dir/lib/SoapySDR/modules${SOAPY_ABI_VERSION}/libaudioSupport.so:
	scripts/update_repo.sh build_stage/SoapyAudio https://github.com/pothosware/SoapyAudio.git
	mkdir -p build_stage/SoapyAudio/build || true
	cmake -S build_stage/SoapyAudio -B build_stage/SoapyAudio/build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} -DCMAKE_PREFIX_PATH=${INSTALL_DIR}
	cd build_stage/SoapyAudio/build && make -j${NPROC} && make install
	ls -la install_dir/lib/SoapySDR/modules${SOAPY_ABI_VERSION}/libaudioSupport.so

