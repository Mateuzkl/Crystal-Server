cmake_minimum_required(VERSION 3.22 FATAL_ERROR)

# *****************************************************************************
# CMake Features
# *****************************************************************************
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_DISABLE_SOURCE_CHANGES ON)
set(CMAKE_DISABLE_IN_SOURCE_BUILD ON)
set(Boost_NO_WARN_NEW_VERSIONS ON)

# Make will print more details
set(CMAKE_VERBOSE_MAKEFILE OFF)

# *****************************************************************************
# Packages / Libs
# *****************************************************************************
find_package(CURL REQUIRED)
find_package(GMP REQUIRED)
find_package(LuaJIT REQUIRED)
find_package(Protobuf REQUIRED)
find_package(Threads REQUIRED)
find_package(ZLIB REQUIRED)
find_package(absl CONFIG REQUIRED)
find_package(fmt CONFIG REQUIRED)
find_package(Boost REQUIRED COMPONENTS locale)
if(FEATURE_METRICS)
    find_package(opentelemetry-cpp CONFIG REQUIRED)
    find_package(prometheus-cpp CONFIG REQUIRED)
endif()
find_package(asio CONFIG QUIET)
if(NOT TARGET asio::asio)
    find_path(ASIO_INCLUDE_DIR NAMES asio.hpp REQUIRED)
    add_library(asio INTERFACE)
    target_include_directories(asio INTERFACE ${ASIO_INCLUDE_DIR})
    add_library(asio::asio ALIAS asio)
endif()

find_package(eventpp CONFIG QUIET)
if(NOT TARGET eventpp::eventpp)
    find_path(EVENTPP_INCLUDE_DIR NAMES eventpp/eventdispatcher.h REQUIRED)
    add_library(eventpp INTERFACE)
    target_include_directories(eventpp INTERFACE ${EVENTPP_INCLUDE_DIR})
    add_library(eventpp::eventpp ALIAS eventpp)
endif()

find_package(magic_enum CONFIG QUIET)
find_path(MAGIC_ENUM_COMPAT_INCLUDE_DIR NAMES magic_enum/magic_enum.hpp)
if(NOT MAGIC_ENUM_COMPAT_INCLUDE_DIR)
    message(FATAL_ERROR "magic_enum/magic_enum.hpp was not found. Run ./build.sh again so it can install the compatible header layout in $HOME/.local/include.")
endif()
if(NOT TARGET magic_enum::magic_enum)
    add_library(magic_enum INTERFACE)
    target_include_directories(magic_enum INTERFACE ${MAGIC_ENUM_COMPAT_INCLUDE_DIR})
    add_library(magic_enum::magic_enum ALIAS magic_enum)
endif()
set(MAGIC_ENUM_INCLUDE_DIRS ${MAGIC_ENUM_COMPAT_INCLUDE_DIR})

find_package(mio CONFIG QUIET)
if(NOT TARGET mio::mio)
    find_path(MIO_INCLUDE_DIR NAMES mio/mmap.hpp REQUIRED)
    add_library(mio INTERFACE)
    target_include_directories(mio INTERFACE ${MIO_INCLUDE_DIR})
    add_library(mio::mio ALIAS mio)
endif()

find_package(pugixml CONFIG QUIET)
if(NOT TARGET pugixml::pugixml)
    find_package(PugiXML REQUIRED)
    add_library(pugixml::pugixml UNKNOWN IMPORTED)
    set_target_properties(pugixml::pugixml PROPERTIES
            IMPORTED_LOCATION "${PUGIXML_LIBRARIES}"
            INTERFACE_INCLUDE_DIRECTORIES "${PUGIXML_INCLUDE_DIR}"
    )
endif()

find_package(spdlog REQUIRED)
find_package(nlohmann_json CONFIG REQUIRED)
find_package(unofficial-argon2 CONFIG QUIET)
if(NOT TARGET unofficial::argon2::libargon2)
    find_path(ARGON2_INCLUDE_DIR NAMES argon2.h REQUIRED)
    find_library(ARGON2_LIBRARY NAMES argon2 REQUIRED)
    add_library(unofficial::argon2::libargon2 UNKNOWN IMPORTED)
    set_target_properties(unofficial::argon2::libargon2 PROPERTIES
            IMPORTED_LOCATION "${ARGON2_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${ARGON2_INCLUDE_DIR}"
    )
endif()

find_package(unofficial-libmariadb CONFIG QUIET)
if(NOT TARGET unofficial::libmariadb)
    find_package(MySQL REQUIRED)
    add_library(unofficial::libmariadb INTERFACE IMPORTED)
    set_target_properties(unofficial::libmariadb PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${MYSQL_INCLUDE_DIR}"
            INTERFACE_LINK_LIBRARIES "${MYSQL_CLIENT_LIBS}"
    )
endif()

find_path(BOOST_DI_INCLUDE_DIRS NAMES boost/di.hpp REQUIRED)
find_path(PARALLEL_HASHMAP_INCLUDE_DIRS NAMES parallel_hashmap/phmap.h REQUIRED)
find_path(ATOMIC_QUEUE_INCLUDE_DIRS NAMES atomic_queue/atomic_queue.h REQUIRED)
find_path(BS_THREAD_POOL_INCLUDE_DIRS NAMES BS_thread_pool.hpp REQUIRED)

set(CRYSTAL_ABSL_LIBS absl::any absl::base)
foreach(ABSL_TARGET
        absl::bits
        absl::int128
        absl::log
        absl::stacktrace
        absl::symbolize
)
    if(TARGET ${ABSL_TARGET})
        list(APPEND CRYSTAL_ABSL_LIBS ${ABSL_TARGET})
    endif()
endforeach()

# *****************************************************************************
# Sanity Checks
# *****************************************************************************
# === GCC Minimum Version ===
if (CMAKE_COMPILER_IS_GNUCXX)
    message("-- Compiler: GCC - Version: ${CMAKE_CXX_COMPILER_VERSION}")
    if (CMAKE_CXX_COMPILER_VERSION VERSION_LESS 11)
        message(FATAL_ERROR "GCC version must be at least 11!")
    endif()
endif()

# === Minimum required version for visual studio ===
if(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    message("-- Compiler: Visual Studio - Version: ${CMAKE_CXX_COMPILER_VERSION}")
    if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS "19.32")
        message(FATAL_ERROR "Visual Studio version must be at least 19.32")
    endif()
endif()

# *****************************************************************************
# Options
# *****************************************************************************
option(TOGGLE_BIN_FOLDER "Use build/bin folder for generate compilation files" ON)
option(OPTIONS_ENABLE_OPENMP "Enable Open Multi-Processing support." ON)
option(DEBUG_LOG "Enable Debug Log" OFF)
option(ASAN_ENABLED "Build this target with AddressSanitizer" OFF)
option(VALGRIND_ENABLED "Build this target with Valgrind-friendly diagnostics" OFF)
option(BUILD_STATIC_LIBRARY "Build using static libraries" OFF)
option(SPEED_UP_BUILD_UNITY "Compile using build unity for speed up build" ON)
option(USE_PRECOMPILED_HEADER "Compile using precompiled header" ON)

if(ASAN_ENABLED AND VALGRIND_ENABLED)
    message(FATAL_ERROR "ASAN_ENABLED and VALGRIND_ENABLED cannot be enabled together")
endif()

# === TOGGLE_BIN_FOLDER ===
if(TOGGLE_BIN_FOLDER)
    log_option_enabled("TOGGLE_BIN_FOLDER")
else()
    log_option_disabled("TOGGLE_BIN_FOLDER")
endif()

# === OPTIONS_ENABLE_OPENMP ===
if(OPTIONS_ENABLE_OPENMP)
    log_option_enabled("OPTIONS_ENABLE_OPENMP")
else()
    log_option_disabled("OPTIONS_ENABLE_OPENMP")
endif()

# === DEBUG LOG ===
# cmake -DDEBUG_LOG=ON ..
if(DEBUG_LOG)
    add_definitions(-DDEBUG_LOG=ON)
    add_definitions(-DSPDLOG_ACTIVE_LEVEL=SPDLOG_LEVEL_TRACE)
    log_option_enabled("DEBUG LOG")
else()
    log_option_disabled("DEBUG LOG")
endif()

# === ASAN ===
if(ASAN_ENABLED)
    log_option_enabled("asan")
    if(MSVC)
        add_compile_options(/fsanitize=address)
        add_link_options(/fsanitize=address)
    else()
        add_compile_options(-fsanitize=address -fno-omit-frame-pointer -fno-optimize-sibling-calls)
        add_link_options(-fsanitize=address)
    endif()
else()
    log_option_disabled("asan")
endif()

# === VALGRIND ===
if(VALGRIND_ENABLED)
    log_option_enabled("valgrind")
    if(NOT MSVC)
        add_compile_options(-fno-omit-frame-pointer)
    endif()
else()
    log_option_disabled("valgrind")
endif()

# === BUILD_STATIC_LIBRARY ===
if(BUILD_STATIC_LIBRARY)
    log_option_enabled("STATIC_LIBRARY")
    if(MSVC)
        set(CMAKE_FIND_LIBRARY_SUFFIXES ".lib")
    elseif(UNIX AND NOT APPLE)
        set(CMAKE_FIND_LIBRARY_SUFFIXES ".a")
    elseif(APPLE)
        set(CMAKE_FIND_LIBRARY_SUFFIXES ".a" ".dylib")
    endif()
else()
    log_option_disabled("STATIC_LIBRARY")
endif()

# === SPEED_UP_BUILD_UNITY ===
if(SPEED_UP_BUILD_UNITY)
    log_option_enabled("SPEED_UP_BUILD_UNITY")
else()
    log_option_disabled("SPEED_UP_BUILD_UNITY")
endif()

# === USE_PRECOMPILED_HEADER ===
if(USE_PRECOMPILED_HEADER)
    log_option_enabled("USE_PRECOMPILED_HEADER")
else()
    log_option_disabled("USE_PRECOMPILED_HEADER")
endif()

# === IPO Configuration ===
function(configure_linking target_name)
    if(ASAN_ENABLED OR VALGRIND_ENABLED)
        log_option_disabled("IPO/LTO disabled for diagnostic target ${target_name}.")
        return()
    endif()

    if(OPTIONS_ENABLE_IPO)
        # Check if IPO/LTO is supported
        include(CheckIPOSupported)
        check_ipo_supported(RESULT ipo_supported OUTPUT ipo_output LANGUAGES CXX)

        # Get the GCC compiler version, if applicable
        if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
            execute_process(
                    COMMAND ${CMAKE_CXX_COMPILER} -dumpversion
                    OUTPUT_VARIABLE GCC_VERSION
                    OUTPUT_STRIP_TRAILING_WHITESPACE
            )
        endif()

        if(ipo_supported)
            set_property(TARGET ${target_name} PROPERTY INTERPROCEDURAL_OPTIMIZATION TRUE)
            log_option_enabled("IPO/LTO enabled for target ${target_name}.")

            if(MSVC)
                target_compile_options(${target_name} PRIVATE /GL)
                target_link_options(${target_name} PRIVATE /LTCG)
            elseif(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
                # Check if it's running on Linux, using GCC 14, and in Debug mode
                if(CMAKE_SYSTEM_NAME STREQUAL "Linux" AND
                        CMAKE_CXX_COMPILER_ID STREQUAL "GNU" AND
                        GCC_VERSION VERSION_EQUAL "14" AND
                        CMAKE_BUILD_TYPE STREQUAL "Debug")
                    log_option_disabled("LTO disabled for GCC 14 in Debug mode on Linux for target ${target_name}.")
                    # Disable LTO for Debug builds with GCC 14
                    target_compile_options(${target_name} PRIVATE -fno-lto)
                    target_link_options(${target_name} PRIVATE -fno-lto)
                else()
                    target_compile_options(${target_name} PRIVATE -flto=auto)
                    target_link_options(${target_name} PRIVATE -flto=auto)
                endif()
            endif()
        else()
            log_option_disabled("IPO/LTO is not supported for target ${target_name}: ${ipo_output}")
        endif()
    endif()
endfunction()

# *****************************************************************************
# Compiler Options
# *****************************************************************************
if (MSVC)
    foreach(type RELEASE DEBUG RELWITHDEBINFO MINSIZEREL)
        string(REPLACE "/Zi" "/Z7" CMAKE_CXX_FLAGS_${type} "${CMAKE_CXX_FLAGS_${type}}")
        string(REPLACE "/Zi" "/Z7" CMAKE_C_FLAGS_${type} "${CMAKE_C_FLAGS_${type}}")
    endforeach(type)
    add_compile_options(/MP /FS /Zf /EHsc)
else()
    add_compile_options(-Wno-unused-parameter -Wno-sign-compare -Wno-switch -Wno-implicit-fallthrough -Wno-extra)
endif()

# === Compiler Features ===
add_library(project_options INTERFACE)
target_compile_features(project_options INTERFACE cxx_std_23)

# *****************************************************************************
# Output Directory Function
# *****************************************************************************
function(set_output_directory target_name)
    if (TOGGLE_BIN_FOLDER)
        set_target_properties(${target_name}
                PROPERTIES
                RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
        )
    else()
        set_target_properties(${target_name}
                PROPERTIES
                RUNTIME_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}/"
        )
    endif()
endfunction()

# *****************************************************************************
# Setup Target Function
# *****************************************************************************
function(setup_target TARGET_NAME)
    if (MSVC AND BUILD_STATIC_LIBRARY)
        set_property(TARGET ${TARGET_NAME} PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
    endif()
    target_link_libraries(${TARGET_NAME} PUBLIC project_options)
endfunction()
