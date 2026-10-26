cmake_minimum_required(VERSION 3.21)
project(samsh5pf VERSION 0.1.0 LANGUAGES C CXX)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# The neogeorecomp toolkit: the submodule, or a checkout next to this repo.
if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/neogeorecomp/CMakeLists.txt)
    set(ng_default ${CMAKE_CURRENT_SOURCE_DIR}/neogeorecomp)
else()
    set(ng_default ${CMAKE_CURRENT_SOURCE_DIR}/../neogeorecomp)
endif()
set(NEOGEORECOMP_DIR ${ng_default} CACHE PATH "neogeorecomp checkout")
add_subdirectory(${NEOGEORECOMP_DIR} neogeorecomp_build)

# Your ROM files (the "samsh5pf" set plus the "neogeo" system ROMs, unzipped).
# Without it the player builds interpreter-only.
set(SAMSH5PF_ROM_DIR "" CACHE PATH "Directory with your samsh5pf and Neo Geo BIOS ROM files")
# Optional: entry points a previous run found at runtime (--dump-misses).
set(SAMSH5PF_ENTRIES "${CMAKE_BINARY_DIR}/entries.txt" CACHE FILEPATH "Extra entry points for the recompiler")


# Stage 1: the generator.
add_executable(samsh5pf_recomp src/recomp_main.c src/game.c)
target_link_libraries(samsh5pf_recomp PRIVATE m68krecomp_core)
target_include_directories(samsh5pf_recomp PRIVATE src)

# Stage 2: the player, with the generated C when ROMs are available.
set(GAME_SOURCES src/main.c)
set(GEN_DIR ${CMAKE_BINARY_DIR}/generated)
set(GEN_FILES 16)
if(SAMSH5PF_ROM_DIR)
    set(GEN_SOURCES ${GEN_DIR}/recomp_table.c)
    math(EXPR last "${GEN_FILES} - 1")
    foreach(i RANGE ${last})
        if(i LESS 10)
            list(APPEND GEN_SOURCES ${GEN_DIR}/recomp_0${i}.c)
        else()
            list(APPEND GEN_SOURCES ${GEN_DIR}/recomp_${i}.c)
        endif()
    endforeach()
    # The entry list starts empty; the `profile` target fills it from a
    # scripted play session and the next build regenerates with it.
    if(NOT EXISTS ${SAMSH5PF_ENTRIES})
        file(WRITE ${SAMSH5PF_ENTRIES} "")
    endif()
    file(MAKE_DIRECTORY ${GEN_DIR})
    add_custom_command(
        OUTPUT ${GEN_SOURCES} ${GEN_DIR}/recomp_common.h
        COMMAND samsh5pf_recomp --rom-path ${SAMSH5PF_ROM_DIR} --out ${GEN_DIR} --files ${GEN_FILES}
                --entries ${SAMSH5PF_ENTRIES}
        DEPENDS samsh5pf_recomp ${SAMSH5PF_ENTRIES}
        COMMENT "Recompiling samsh5pf from ${SAMSH5PF_ROM_DIR}")
    list(APPEND GAME_SOURCES ${GEN_SOURCES})
endif()

add_executable(samsh5pf ${GAME_SOURCES} src/game.c)
target_link_libraries(samsh5pf PRIVATE neogeorecomp)
target_include_directories(samsh5pf PRIVATE src ${GEN_DIR})
if(SAMSH5PF_ROM_DIR)
    # Optional: play the soak script and record the entry points that only
    # show up at runtime (computed jumps into unrolled code), then rebuild.
    add_custom_target(profile
        COMMAND samsh5pf --headless --rom-path ${SAMSH5PF_ROM_DIR} --frames 6000 --dump-misses ${SAMSH5PF_ENTRIES}
        COMMAND samsh5pf --headless --rom-path ${SAMSH5PF_ROM_DIR} --frames 19000
                --input ${CMAKE_CURRENT_SOURCE_DIR}/tests/play_long.txt --dump-misses ${SAMSH5PF_ENTRIES}
        DEPENDS samsh5pf
        COMMENT "Profiling a scripted session for runtime-only entry points")
    target_compile_definitions(samsh5pf PRIVATE SAMSH5PF_HAVE_RECOMP)
    if(MSVC)
        # Generated routines are large; /bigobj lifts the section limit.
        set_source_files_properties(${GEN_SOURCES} PROPERTIES COMPILE_OPTIONS "/bigobj")
    endif()
endif()
if(MSVC)
    target_compile_definitions(samsh5pf PRIVATE _CRT_SECURE_NO_WARNINGS)
    target_compile_definitions(samsh5pf_recomp PRIVATE _CRT_SECURE_NO_WARNINGS)
endif()

# Ship the SDL2 DLL (when the window is built) next to the executable.
if(WIN32 AND TARGET SDL2::SDL2)
    add_custom_command(TARGET samsh5pf POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different $<TARGET_RUNTIME_DLLS:samsh5pf> $<TARGET_FILE_DIR:samsh5pf>
        COMMAND_EXPAND_LISTS)
endif()
