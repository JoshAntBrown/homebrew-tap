class AblLink < Formula
  desc "C11 wrapper for Ableton Link, a technology for synchronizing musical beat"
  homepage "https://github.com/Ableton/link"
  url "https://github.com/Ableton/link/archive/refs/tags/Link-3.1.5.tar.gz"
  sha256 "e2c0071669855325f4efdf4b0a4ecdf98a78ea55790284faa9d8df7af9bd99be"
  license "GPL-2.0-or-later"

  depends_on "cmake" => :build

  # ASIO standalone (git submodule)
  resource "asio" do
    url "https://github.com/chriskohlhoff/asio/archive/231cb29bab30f82712fcd54faaea42424cc6e710.tar.gz"
    sha256 "5def09efbd4be199dd6ddca53a2c99b9eef696f6b430910d896594b04ff59108"
  end

  def install
    # Install asio submodule
    (buildpath/"modules/asio-standalone").install resource("asio")

    # Create a custom CMakeLists.txt that builds abl_link as a SHARED library
    (buildpath/"build_shared/CMakeLists.txt").write <<~CMAKE
      cmake_minimum_required(VERSION 3.10)
      project(abl_link_shared)

      # Include the Ableton Link configuration
      include(${CMAKE_CURRENT_SOURCE_DIR}/../AbletonLinkConfig.cmake)

      # Build abl_link as a SHARED library instead of STATIC
      add_library(abl_link SHARED
        ${CMAKE_CURRENT_SOURCE_DIR}/../extensions/abl_link/src/abl_link.cpp
      )

      target_include_directories(abl_link PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/../extensions/abl_link/include
      )

      set_property(TARGET abl_link PROPERTY CXX_STANDARD 11)

      target_link_libraries(abl_link Ableton::Link)

      # Set library version
      set_target_properties(abl_link PROPERTIES
        VERSION #{version}
        SOVERSION #{version.major}
      )

      install(TARGETS abl_link
        LIBRARY DESTINATION lib
      )

      install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/../extensions/abl_link/include/abl_link.h
        DESTINATION include
      )
    CMAKE

    mkdir "build_shared/build" do
      system "cmake", "..", *std_cmake_args
      system "make"
      system "make", "install"
    end
  end

  test do
    (testpath/"test.c").write <<~C
      #include <abl_link.h>
      #include <stddef.h>

      int main() {
        abl_link link = abl_link_create(120.0);
        if (link.impl == NULL) {
          return 1;
        }
        abl_link_destroy(link);
        return 0;
      }
    C

    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-labl_link", "-o", "test"
    system "./test"
  end
end
