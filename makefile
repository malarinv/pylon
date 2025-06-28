# Default CXX, can be overridden
CXX_DEFAULT := $(shell which clang++ g++ c++ 2>/dev/null | head -n 1)

# Default to native build if TARGETPLATFORM is not set
TARGETPLATFORM ?= native/$(shell uname -m)

ifeq ($(TARGETPLATFORM),linux/arm64)
  export CC := aarch64-linux-gnu-gcc
  export CXX := aarch64-linux-gnu-g++
  export LD := aarch64-linux-gnu-ld
  export AR := aarch64-linux-gnu-ar
  export RANLIB := aarch64-linux-gnu-ranlib
  # We are hoping build.sh uses these env vars and still outputs to a 'host' suffixed dir,
  # or that the wildcard below is sufficient.
  LIBZT_BUILD_PARAM := host
  LIBZT_DIST_PATH_GLOB := *-host
else
  # For non-ARM64 or native builds, use default compilers and host params
  export CC := $(shell which gcc cc 2>/dev/null | head -n 1)
  export CXX := $(CXX_DEFAULT)
  # No need to export LD, AR, RANLIB for native if they are not explicitly set.
  LIBZT_BUILD_PARAM := host
  LIBZT_DIST_PATH_GLOB := *-host
endif

INCLUDES?=-Iext/libzt/ext/ZeroTierOne/osdep -Iext/libzt/ext/ZeroTierOne/ext/prometheus-cpp-lite-1.0/core/include -Iext/libzt/ext/ZeroTierOne/ext-prometheus-cpp-lite-1.0/3rdparty/http-client-lite/include -Iext/libzt/ext/ZeroTierOne/ext/prometheus-cpp-lite-1.0/simpleapi/include


release:
	git submodule update --init
	git -C ext/libzt submodule update --init
	cd ext/libzt && ./build.sh $(LIBZT_BUILD_PARAM) "release"
	$(CXX) -O3 $(INCLUDES) -Wno-deprecated -std=c++11 pylon.cpp -o pylon ext/libzt/dist/$(LIBZT_DIST_PATH_GLOB)-release/lib/libzt.a -Iext/libzt/include

debug:
	git submodule update --init
	git -C ext/libzt submodule update --init
	cd ext/libzt && ./build.sh $(LIBZT_BUILD_PARAM) "debug"
	$(CXX) -O3 $(INCLUDES) -DPYLON_DEBUG=1 -g -Wno-deprecated -std=c++11 pylon.cpp -o pylon-debug ext/libzt/dist/$(LIBZT_DIST_PATH_GLOB)-debug/lib/libzt.a -Iext/libzt/include
	#-fsanitize=address -DASAN_OPTIONS=symbolize=1

clean:
	rm -rf pylon pylon-*
	rm -f *.o tcp-proxy *.dSYM

lint:
	clang-format -i pylon.cpp -style file --dry-run --Werror || (echo "\nPlease run make fmt and resubmit\n" && exit 1)

fmt:
	clang-format -i pylon.cpp -style file
