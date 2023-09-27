INSTALL_DIR := $(CURDIR)/install_dir
NPROC := $(shell sysctl -n hw.logicalcpu)
SOAPY_SDR_DIR := $(INSTALL_DIR)/share/cmake/SoapySDR
SOAPY_ABI_VERSION := $(shell sed -n 's/^\#define SOAPY_SDR_ABI_VERSION "\([0-9\.-]*\)"/\1/p' $(INSTALL_DIR)/include/SoapySDR/Version.h)
SOAPY_MOD_PATH := install_dir/lib/SoapySDR/modules$(SOAPY_ABI_VERSION)

all: CubicSDR

clean:
	rm -rf build_stage install_dir

build_stage:
	mkdir -p build_stage

install_dir:
	mkdir -p install_dir

CubicSDR: build_stage install_dir liquid-dsp SoapySDR wxWidgets all_modules
	scripts/update_repo.sh build_stage/CubicSDR https://github.com/cjcliffe/CubicSDR.git
	mkdir -p build_stage/CubicSDR/build
	cmake -S build_stage/CubicSDR -B build_stage/CubicSDR/build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} -DLIQUID_INCLUDES=${INSTALL_DIR}/include -DLIQUID_LIBRARIES=${INSTALL_DIR}/lib/libliquid.dylib -DwxWidgets_CONFIG_EXECUTABLE=${INSTALL_DIR}/wxWidgets-staticlib/bin/wx-config -DSoapySDR_DIR=${INSTALL_DIR}/share/cmake/SoapySDR -DSOAPY_SDR_INCLUDE_DIR=${INSTALL_DIR}/include -DBUNDLE_APP=1 -DBUNDLE_SOAPY_MODS=1 -DCPACK_BINARY_DRAGNDROP=1 -DCMAKE_PREFIX_PATH=${INSTALL_DIR}
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

# Macro for for cloning, building, and installing soapy modules with CMake
define BUILD_AND_INSTALL
scripts/update_repo.sh build_stage/$(1) $(2)
mkdir -p build_stage/$(1)/build
cmake -S build_stage/$(1) -B build_stage/$(1)/build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} -DSoapySDR_DIR=${SOAPY_SDR_DIR} $(3)
cd build_stage/$(1)/build && make -j${NPROC} && make install
endef

SoapySDR: build_stage install_dir install_dir/lib/libSoapySDR.dylib
install_dir/lib/libSoapySDR.dylib:
	$(call BUILD_AND_INSTALL,SoapySDR,https://github.com/pothosware/SoapySDR.git)

all_modules: SoapyRTLSDR SoapyAudio SoapyRemote SoapyAirspy SoapyAirspyHF SoapyHackRF SoapyRedPitaya SoapyBladeRF LimeSuite SoapySDRPlay SoapyNetSDR SoapyRTLTCP

SoapyRTLSDR: SoapySDR $(SOAPY_MOD_PATH)/librtlsdrSupport.so
$(SOAPY_MOD_PATH)/librtlsdrSupport.so:
	$(call BUILD_AND_INSTALL,SoapyRTLSDR,https://github.com/pothosware/SoapyRTLSDR.git)

SoapyAudio: SoapySDR $(SOAPY_MOD_PATH)/libaudioSupport.so
$(SOAPY_MOD_PATH)/libaudioSupport.so:
	$(call BUILD_AND_INSTALL,SoapyAudio,https://github.com/pothosware/SoapyAudio.git)

SoapyRemote: SoapySDR $(SOAPY_MOD_PATH)/libremoteSupport.so
$(SOAPY_MOD_PATH)/libremoteSupport.so:
	$(call BUILD_AND_INSTALL,SoapyRemote,https://github.com/pothosware/SoapyRemote.git)

SoapyAirspy: SoapySDR $(SOAPY_MOD_PATH)/libairspySupport.so
$(SOAPY_MOD_PATH)/libairspySupport.so:
	$(call BUILD_AND_INSTALL,SoapyAirspy,https://github.com/pothosware/SoapyAirspy.git)

SoapyAirspyHF: SoapySDR $(SOAPY_MOD_PATH)/libairspyhfSupport.so
$(SOAPY_MOD_PATH)/libairspyhfSupport.so:
	$(call BUILD_AND_INSTALL,SoapyAirspyHF,https://github.com/pothosware/SoapyAirspyHF.git)

SoapyHackRF: SoapySDR $(SOAPY_MOD_PATH)/libHackRFSupport.so
$(SOAPY_MOD_PATH)/libHackRFSupport.so:
	$(call BUILD_AND_INSTALL,SoapyHackRF,https://github.com/pothosware/SoapyHackRF.git)

SoapyRedPitaya: SoapySDR $(SOAPY_MOD_PATH)/libRedPitaya.so
$(SOAPY_MOD_PATH)/libRedPitaya.so:
	$(call BUILD_AND_INSTALL,SoapyRedPitaya,https://github.com/pothosware/SoapyRedPitaya.git)

SoapyBladeRF: SoapySDR $(SOAPY_MOD_PATH)/libbladeRFSupport.so
$(SOAPY_MOD_PATH)/libbladeRFSupport.so:
	$(call BUILD_AND_INSTALL,SoapyBladeRF,https://github.com/pothosware/SoapyBladeRF.git)

LimeSuite: SoapySDR $(SOAPY_MOD_PATH)/libLMS7Support.so
$(SOAPY_MOD_PATH)/libLMS7Support.so:
	$(call BUILD_AND_INSTALL,LimeSuite,https://github.com/myriadrf/LimeSuite.git)

SoapySDRPlay: SoapySDR $(SOAPY_MOD_PATH)/libsdrplaySupport.so
$(SOAPY_MOD_PATH)/libsdrplaySupport.so:
	$(call BUILD_AND_INSTALL,SoapySDRPlay,https://github.com/pothosware/SoapySDRPlay.git)

SoapyNetSDR : SoapySDR $(SOAPY_MOD_PATH)/libnetSDRSupport.so
$(SOAPY_MOD_PATH)/libnetSDRSupport.so:
	$(call BUILD_AND_INSTALL,SoapyNetSDR,https://github.com/pothosware/SoapyNetSDR.git)

SoapyRTLTCP : SoapySDR $(SOAPY_MOD_PATH)/librtltcpSupport.so
$(SOAPY_MOD_PATH)/librtltcpSupport.so:
	$(call BUILD_AND_INSTALL,SoapyRTLTCP,https://github.com/pothosware/SoapyRTLTCP.git)

