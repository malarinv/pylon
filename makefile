# Default CXX, can be overridden
CXX_DEFAULT := $(shell which clang++ g++ c++ 2>/dev/null | head -n 1)
TARGET_ARCH_SIMPLE := $(subst linux/,,$(TARGETPLATFORM)) # E.g., "arm64" or "amd64"

# Determine lib name part based on TARGETPLATFORM
# This is a guess; build.sh might use 'aarch64' or the full 'linux/arm64' or something else.
# We'll try with TARGET_ARCH_SIMPLE for now, e.g. 'arm64' or 'amd64'.
# If TARGETPLATFORM is not set, default to 'host'.
LIBZT_ARCH_DIR_PART := $(if $(TARGETPLATFORM),$(TARGET_ARCH_SIMPLE),host)

ifeq ($(TARGETPLATFORM),linux/arm64)
  CXX := aarch64-linux-gnu-g++
  # Adjust LIBZT_ARCH_DIR_PART specifically if needed, e.g. if build.sh uses 'aarch64' for 'linux/arm64'
  # For now, relying on TARGET_ARCH_SIMPLE which would be 'arm64'
  LIBZT_BUILD_PARAM := arm64 # Parameter for build.sh
  LIBZT_DIST_DIR_ARCH_PART := arm64 # Part of the dist path, e.g., dist/arm64-release
else
  CXX := $(CXX_DEFAULT)
  LIBZT_BUILD_PARAM := host
  LIBZT_DIST_DIR_ARCH_PART := host # Part of the dist path, e.g., dist/*-host-release
endif

INCLUDES?=-Iext/libzt/ext/ZeroTierOne/osdep -Iext/libzt/ext/ZeroTierOne/ext/prometheus-cpp-lite-1.0/core/include -Iext/libzt/ext/ZeroTierOne/ext-prometheus-cpp-lite-1.0/3rdparty/http-client-lite/include -Iext/libzt/ext/ZeroTierOne/ext/prometheus-cpp-lite-1.0/simpleapi/include


release:
	git submodule update --init
	git -C ext/libzt submodule update --init
	cd ext/libzt && ./build.sh $(LIBZT_BUILD_PARAM) "release"
	$(CXX) -O3 $(INCLUDES) -Wno-deprecated -std=c++11 pylon.cpp -o pylon ext/libzt/dist/$(LIBZT_DIST_DIR_ARCH_PART)-release/lib/libzt.a -Iext/libzt/include

debug:
	git submodule update --init
	git -C ext/libzt submodule update --init
	cd ext/libzt && ./build.sh $(LIBZT_BUILD_PARAM) "debug"
	$(CXX) -O3 $(INCLUDES) -DPYLON_DEBUG=1 -g -Wno-deprecated -std=c++11 pylon.cpp -o pylon-debug ext/libzt/dist/$(LIBZT_DIST_DIR_ARCH_PART)-debug/lib/libzt.a -Iext/libzt/include
	#-fsanitize=address -DASAN_OPTIONS=symbolize=1

clean:
	rm -rf pylon pylon-*
	rm -f *.o tcp-proxy *.dSYM

lint:
	clang-format -i pylon.cpp -style file --dry-run --Werror || (echo "\nPlease run make fmt and resubmit\n" && exit 1)

fmt:
	clang-format -i pylon.cpp -style file
