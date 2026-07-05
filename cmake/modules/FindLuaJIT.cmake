# Once done these will be defined:
#
#  LUAJIT_FOUND
#  LUAJIT_INCLUDE_DIRS
#  LUAJIT_LIBRARIES
#
# For use in OBS: 
#
#  LUAJIT_INCLUDE_DIR

IF(CMAKE_SIZEOF_VOID_P EQUAL 8)
	SET(_LIB_SUFFIX 64)
ELSE()
	SET(_LIB_SUFFIX 32)
ENDIF()

FIND_PATH(LUAJIT_INCLUDE_DIR
	NAMES luajit.h
	HINTS
		ENV LuajitPath${_LIB_SUFFIX}
		ENV LuajitPath
		ENV DepsPath${_LIB_SUFFIX}
		ENV DepsPath
		${LuajitPath${_LIB_SUFFIX}}
		${LuajitPath}
		${DepsPath${_LIB_SUFFIX}}
		${DepsPath}
		${_LUAJIT_INCLUDE_DIRS}
	PATHS
		/usr/local/include
		/usr/include
		/opt/local/include
		/opt/local
		/sw/include
		~/Library/Frameworks
		/Library/Frameworks
	PATH_SUFFIXES
		luajit-2.1
		include/luajit-2.1
		luajit2.1
		include/luajit2.1
		luajit-2.0
		include/luajit-2.0
		luajit2.0
		include/luajit2.0
		luajit
		luajit/src
		include/luajit
		include/luajit/src
		)

if(NOT LUAJIT_INCLUDE_DIR)
	FIND_PATH(LUAJIT_INCLUDE_DIR
		NAMES lua.h lualib.h
		HINTS
			ENV LuajitPath${_LIB_SUFFIX}
			ENV LuajitPath
			ENV DepsPath${_LIB_SUFFIX}
			ENV DepsPath
			${LuajitPath${_LIB_SUFFIX}}
			${LuajitPath}
			${DepsPath${_LIB_SUFFIX}}
			${DepsPath}
			${_LUAJIT_INCLUDE_DIRS}
		PATHS
			/usr/local/include
			/usr/include
			/opt/local/include
			/opt/local
			/sw/include
			~/Library/Frameworks
			/Library/Frameworks
		PATH_SUFFIXES
			luajit-2.1
			include/luajit-2.1
			luajit2.1
			include/luajit2.1
			luajit-2.0
			include/luajit-2.0
			luajit2.0
			include/luajit2.0
			luajit
			luajit/src
			include/luajit
			include/luajit/src
			)
endif()

find_library(LUAJIT_LIB
	NAMES ${_LUAJIT_LIBRARIES} luajit luajit-51 luajit-5.1 lua51
	HINTS
		ENV LuajitPath${_LIB_SUFFIX}
		ENV LuajitPath
		ENV DepsPath${_LIB_SUFFIX}
		ENV DepsPath
		${LuajitPath${_LIB_SUFFIX}}
		${LuajitPath}
		${DepsPath${_LIB_SUFFIX}}
		${DepsPath}
		${_LUAJIT_LIBRARY_DIRS}
	PATHS
		/usr/lib
		/usr/local/lib
		/opt/local/lib
		/opt/local
		/sw/lib
		~/Library/Frameworks
		/Library/Frameworks
	PATH_SUFFIXES
		lib${_LIB_SUFFIX} lib
		libs${_LIB_SUFFIX} libs
		bin${_LIB_SUFFIX} bin
		../lib${_LIB_SUFFIX} ../lib
		../libs${_LIB_SUFFIX} ../libs
		../bin${_LIB_SUFFIX} ../bin)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(LuaJIT DEFAULT_MSG LUAJIT_LIB LUAJIT_INCLUDE_DIR)
mark_as_advanced(LUAJIT_INCLUDE_DIR LUAJIT_LIB)

if(LUAJIT_FOUND)
	set(LUAJIT_INCLUDE_DIRS ${LUAJIT_INCLUDE_DIR})
	set(LUAJIT_LIBRARIES ${LUAJIT_LIB})
endif()
