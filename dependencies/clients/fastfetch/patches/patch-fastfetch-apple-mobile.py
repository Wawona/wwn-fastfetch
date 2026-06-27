#!/usr/bin/env python3
"""App Store–safe fastfetch on Apple mobile: no fork/exec/posix_spawn/system."""
from pathlib import Path

cmake_anchor = "    check_function_exists(malloc_usable_size HAVE_MALLOC_USABLE_SIZE)"
cmake_patch = """    if(WAWONA_APPLE_MOBILE)
        set(HAVE_MALLOC_USABLE_SIZE FALSE)
    else()
        check_function_exists(malloc_usable_size HAVE_MALLOC_USABLE_SIZE)
    endif()"""

path = Path("src/options/general.c")
text = path.read_text()
if "WAWONA_APPLE_MOBILE_PRERUN" not in text:
    anchor = "#include <unistd.h>"
    if anchor not in text:
        raise SystemExit("general.c unistd include missing")
    hdr = """
#if defined(__APPLE__)
#include <TargetConditionals.h>
#define WAWONA_APPLE_MOBILE_PRERUN() (TARGET_OS_IPHONE || TARGET_OS_TV || TARGET_OS_WATCH)
#else
#define WAWONA_APPLE_MOBILE_PRERUN() 0
#endif
"""
    text = text.replace(anchor, anchor + hdr, 1)
    old = """        } else if (unsafe_yyjson_equals_str(key, "preRun")) {
            if (!yyjson_is_str(val)) {
                return "general.preRun must be a string";
            }
            if (system(unsafe_yyjson_get_str(val)) < 0) {
                return "Failed to execute preRun command";
            }"""
    new = """        } else if (unsafe_yyjson_equals_str(key, "preRun")) {
            if (!yyjson_is_str(val)) {
                return "general.preRun must be a string";
            }
#if !WAWONA_APPLE_MOBILE_PRERUN()
            if (system(unsafe_yyjson_get_str(val)) < 0) {
                return "Failed to execute preRun command";
            }
#endif"""
    if old not in text:
        raise SystemExit("general.c preRun block anchor missing")
    path.write_text(text.replace(old, new, 1))

cmake = Path("CMakeLists.txt")
text = cmake.read_text()
if "WAWONA_APPLE_MOBILE" not in text.split("malloc_usable_size")[0]:
    if cmake_anchor not in text:
        raise SystemExit("CMakeLists malloc_usable_size anchor missing")
    cmake.write_text(text.replace(cmake_anchor, cmake_patch, 1))

opencl = Path("src/detection/opencl/opencl.c")
text = opencl.read_text()
opencl_anchor = """#if !defined(FF_HAVE_OPENCL) && defined(__APPLE__) && defined(MAC_OS_X_VERSION_10_15)
    #define FF_HAVE_OPENCL 1
#endif"""
opencl_patch = """#if !defined(FF_HAVE_OPENCL) && defined(__APPLE__) && defined(MAC_OS_X_VERSION_10_15)
#include <TargetConditionals.h>
#if !(TARGET_OS_IPHONE || TARGET_OS_TV || TARGET_OS_WATCH)
    #define FF_HAVE_OPENCL 1
#endif
#endif"""
if "TARGET_OS_IPHONE" not in text.split("FF_HAVE_OPENCL")[0]:
    if opencl_anchor not in text:
        raise SystemExit("opencl.c FF_HAVE_OPENCL anchor missing")
    opencl.write_text(text.replace(opencl_anchor, opencl_patch, 1))

ogl_shared = Path("src/detection/opengl/opengl_shared.c")
text = ogl_shared.read_text()
ogl_anchor = """#if __has_include(<GL/gl.h>)
    #include <GL/gl.h>
#elif __APPLE__
    #define GL_SILENCE_DEPRECATION 1
    #include <OpenGL/gl.h>
#else
    #define FF_HAVE_NO_GL 1
#endif"""
ogl_patch = """#if __has_include(<GL/gl.h>)
    #include <GL/gl.h>
#elif defined(__APPLE__)
#include <TargetConditionals.h>
#if TARGET_OS_IPHONE || TARGET_OS_TV || TARGET_OS_WATCH
    #define FF_HAVE_NO_GL 1
#else
    #define GL_SILENCE_DEPRECATION 1
    #include <OpenGL/gl.h>
#endif
#else
    #define FF_HAVE_NO_GL 1
#endif"""
if "TARGET_OS_IPHONE" not in text:
    if ogl_anchor not in text:
        raise SystemExit("opengl_shared.c GL include anchor missing")
    ogl_shared.write_text(text.replace(ogl_anchor, ogl_patch, 1))

ogl_apple = Path("src/detection/opengl/opengl_apple.c")
text = ogl_apple.read_text()
if "OpenGL not available on Apple mobile" not in text:
    ogl_apple_anchor = """#include "fastfetch.h"
#include "opengl.h"

#define GL_SILENCE_DEPRECATION
#include <OpenGL/gl.h>
#include <OpenGL/OpenGL.h> // This brings in CGL, not GL"""
    ogl_apple_patch = """#include "fastfetch.h"
#include "opengl.h"

#if defined(__APPLE__)
#include <TargetConditionals.h>
#endif

#if defined(__APPLE__) && (TARGET_OS_IPHONE || TARGET_OS_TV || TARGET_OS_WATCH)

const char* ffDetectOpenGL(FFOpenGLOptions* options, FFOpenGLResult* result) {
    (void)options;
    (void)result;
    return "OpenGL not available on Apple mobile";
}

#else

#define GL_SILENCE_DEPRECATION
#include <OpenGL/gl.h>
#include <OpenGL/OpenGL.h> // This brings in CGL, not GL"""
    if ogl_apple_anchor not in text:
        raise SystemExit("opengl_apple.c include anchor missing")
    text = text.replace(ogl_apple_anchor, ogl_apple_patch, 1)
    if not text.rstrip().endswith("#endif"):
        text = text.rstrip() + "\n\n#endif\n"
    ogl_apple.write_text(text)

cmake = Path("CMakeLists.txt")
text = cmake.read_text()
snippet = Path(__file__).with_name("cmake-apple-mobile-sources.snippet").read_text()
src_anchor = "elseif(APPLE)\n    list(APPEND LIBFASTFETCH_SRC"
if "elseif(WAWONA_APPLE_MOBILE)" not in text:
    if src_anchor not in text:
        raise SystemExit("CMakeLists APPLE source anchor missing")
    text = text.replace(src_anchor, snippet + src_anchor, 1)

link_anchor = """elseif(APPLE)
    target_link_libraries(libfastfetch
        PRIVATE "-framework AVFoundation\""""
link_patch = """elseif(WAWONA_APPLE_MOBILE)
    target_link_libraries(libfastfetch
        PRIVATE "-framework CoreFoundation"
        PRIVATE "-framework Foundation"
        PRIVATE "-framework IOKit"
        PRIVATE "-framework VideoToolbox"
    )
""" + link_anchor
if "WAWONA_APPLE_MOBILE)\n    target_link_libraries" not in text:
    if link_anchor not in text:
        raise SystemExit("CMakeLists APPLE link anchor missing")
    text = text.replace(link_anchor, link_patch, 1)

cmake.write_text(text)
