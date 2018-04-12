# Original Copyright:
# Copyright (C) 2015-2017, Illumina, inc.
#
# Based on
# https://github.com/Illumina/interop/tree/master/cmake/Modules

function(csharp_add_project name)
    if(CSBUILD_PROJECT_DIR)
        set(CURRENT_TARGET_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/${CSBUILD_PROJECT_DIR}")
    else()
        set(CURRENT_TARGET_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}")
    endif()
    set(CSBUILD_PROJECT_DIR "")
    file(MAKE_DIRECTORY ${CURRENT_TARGET_BINARY_DIR})
    cmake_parse_arguments(_csharp_add_project
        "EXECUTABLE"
        ""
        "SOURCES;INCLUDE_DLLS;INCLUDE_NUPKGS;INCLUDE_REFERENCES"
        ${ARGN}
    )

    set(
        _csharp_sources
        ${_csharp_add_project_SOURCES}
        ${_csharp_add_project_UNPARSED_ARGUMENTS}
    )

    foreach(it ${_csharp_add_project_INCLUDE_DLLS})
        file(TO_NATIVE_PATH ${it} nit)
        set(refs "${refs} <Reference Include=\"${nit}\" />\n")
    endforeach()

    foreach(it ${_csharp_add_project_INCLUDE_NUPKGS})
        file(TO_NATIVE_PATH ${it} nit)
        set(pkgs "${pkgs} <package id=\"${nit}\" version= />\n")
    endforeach()

    foreach(it ${_csharp_add_project_INCLUDE_REFERENCES})
        string(REPLACE "=" ";" PACKAGE_ID "${it}")
        list(GET PACKAGE_ID 0 PACKAGE_NAME)
        list(GET PACKAGE_ID 1 PACKAGE_VERSION)
        set(packages "${packages}<PackageReference Include=\"${PACKAGE_NAME}\" Version=\"${PACKAGE_VERSION}\" />\n")
        set(legacy_packages "${legacy_packages}<package id=\"${PACKAGE_NAME}\" version=\"${PACKAGE_VERSION}\" />\n")
        file(TO_NATIVE_PATH "${CURRENT_TARGET_BINARY_DIR}/${PACKAGE_NAME}.${PACKAGE_VERSION}/lib/**/*.dll" hint_path)
        set(refs "${refs}<Reference Include=\"${hint_path}\" ></Reference>\n")

        file(TO_NATIVE_PATH "${CURRENT_TARGET_BINARY_DIR}/${PACKAGE_NAME}.${PACKAGE_VERSION}/build/${PACKAGE_NAME}.targets" target_path)
        set(imports "${imports}<Import Project=\"${target_path}\" Condition=\"Exists('${target_path}')\" />\n")
    endforeach()

    foreach(it ${_csharp_sources})
        if(EXISTS "${it}")
            file(TO_NATIVE_PATH ${it} nit)
            set(sources "${sources}<Compile Include=\"${nit}\" />\n")
            list(APPEND sources_dep ${it})
        elseif(EXISTS "${CSBUILD_SOURCE_DIRECTORY}/${it}")
            file(TO_NATIVE_PATH ${CSHARP_SOURCE_DIRECTORY}/${it} nit)
            set(sources "${sources}<Compile Include=\"${nit}\" />\n")
            list(APPEND sources_dep ${CSHARP_SOURCE_DIRECTORY}/${it})
        elseif(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${it}")
            file(TO_NATIVE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/${it} nit)
            set(sources "${sources}<Compile Include=\"${nit}\" />\n")
            list(APPEND sources_dep ${CMAKE_CURRENT_SOURCE_DIR}/${it})
        elseif(${it} MATCHES "[*]")
            file(TO_NATIVE_PATH ${it} nit)
            FILE(GLOB it_glob ${it})
            set(sources "${sources}<Compile Include=\"${nit}\" />\n")
            list(APPEND sources_dep ${it_glob})
        else()
            get_property(_is_generated SOURCE ${it} PROPERTY GENERATED)
            if(_is_generated)
                file(TO_NATIVE_PATH ${it} nit)
                FILE(GLOB it_glob ${it})
                set(sources "${sources}<Compile Include=\"${nit}\" />\n")
                list(APPEND sources_dep ${it_glob})
            else()
                message(WARNING "not found ${it}")
            endif()
        endif()
    endforeach()
    list(LENGTH sources SOURCE_FILE_COUNT)
    list(LENGTH refs REFERENCE_COUNT)
    list(LENGTH packages PACKAGE_COUNT)
    list(LENGTH imports IMPORT_COUNT)
    if(SOURCE_FILE_COUNT GREATER 0)
        set(CSHARP_BUILDER_SOURCES "${sources}")
    else()
        message(FATAL_ERROR "No C# source files for library")
    endif()
    if(REFERENCE_COUNT GREATER 0)
        set(CSHARP_BUILDER_ADDITIONAL_REFERENCES "${refs}")
    else()
        set(CSHARP_BUILDER_ADDITIONAL_REFERENCES "")
    endif()
    if(PACKAGE_COUNT GREATER 0)
        set(CSHARP_PACKAGE_REFERENCES "${packages}")
    else()
        set(CSHARP_PACKAGE_REFERENCES "")
    endif()
    if(PACKAGE_COUNT GREATER 0)
        set(CSHARP_LEGACY_PACKAGE_REFERENCES "${legacy_packages}")
    else()
        set(CSHARP_LEGACY_PACKAGE_REFERENCES "")
    endif()
    if(IMPORT_COUNT GREATER 0)
        set(CSHARP_IMPORTS "${imports}")
    else()
        set(CSHARP_IMPORTS "")
    endif()

    if(${_csharp_add_project_EXECUTABLE} AND NOT DOTNET_CORE_FOUND)
        set(ext "exe")
    else()
        set(ext "dll")
    endif()

    if(${_csharp_add_project_EXECUTABLE})
        set(output_type "Exe")
    else()
        set(output_type "library")
    endif()
    # TODO: <RuntimeIdentifier>osx.10.11-x64</RuntimeIdentifier>
    set(CSBUILD_${name}_BINARY "${CSHARP_BUILDER_OUTPUT_PATH}/${CSBUILD_OUPUT_PREFIX}${name}${CSBUILD_OUTPUT_SUFFIX}.${ext}")
    set(CSBUILD_${name}_BINARY_NAME "${name}${CSBUILD_OUTPUT_SUFFIX}.${ext}")
    if(CSHARP_NUGET_SOURCE)
        set(CSHARP_NUGET_SOURCE_CMD -source ${CSHARP_NUGET_SOURCE})
    endif()

    if(RESTORE_EXE AND CSHARP_NUGET_SOURCE_CMD)
        set(RESTORE_CMD ${RESTORE_EXE} install ${CSHARP_NUGET_SOURCE_CMD})
    else()
        set(RESTORE_CMD ${CMAKE_COMMAND} -version)
    endif()

    set(CSBUILD_${name}_CSPROJ "${name}_${CSBUILD_CSPROJ}")
    file(TO_NATIVE_PATH ${CSHARP_BUILDER_OUTPUT_PATH} CSHARP_BUILDER_OUTPUT_PATH_NATIVE)

    set(CSHARP_BUILDER_OUTPUT_TYPE "${output_type}")
    set(CSHARP_BUILDER_OUTPUT_PATH "${CSHARP_BUILDER_OUTPUT_PATH_NATIVE}")
    set(CSHARP_BUILDER_OUTPUT_NAME "${name}${CSBUILD_OUTPUT_SUFFIX}")
    set(MSBUILD_TOOLSET "${MSBUILD_TOOLSET}")
    set(CSHARP_IMPORTS "${CSHARP_IMPORTS}")

    configure_file(
        ${CSBUILD_CSPROJ_IN}
        ${CURRENT_TARGET_BINARY_DIR}/${CSBUILD_${name}_CSPROJ} @ONLY
    )

    set(CSHARP_PACKAGE_REFERENCES "${CSHARP_LEGACY_PACKAGE_REFERENCES}")

    configure_file(
        ${dotnet_cmake_module_DIR}/Modules/dotnet/packages.config.in
        ${CURRENT_TARGET_BINARY_DIR}/packages.config @ONLY
    )

    add_custom_command(
        OUTPUT ${CSBUILD_${name}_BINARY}

        COMMAND ${RESTORE_CMD}

        COMMAND ${CSBUILD_EXECUTABLE} ${CSBUILD_RESTORE_FLAGS} ${CSBUILD_${name}_CSPROJ}
        COMMAND ${CSBUILD_EXECUTABLE} ${CSBUILD_BUILD_FLAGS} ${CSBUILD_${name}_CSPROJ}
        WORKING_DIRECTORY ${CURRENT_TARGET_BINARY_DIR}
        COMMENT "${RESTORE_CMD};${CSBUILD_EXECUTABLE} ${CSBUILD_RESTORE_FLAGS} ${CSBUILD_${name}_CSPROJ}; ${CSBUILD_EXECUTABLE} ${CSBUILD_BUILD_FLAGS} ${CSBUILD_${name}_CSPROJ} -> ${CURRENT_TARGET_BINARY_DIR}"
        DEPENDS ${sources_dep} ${CURRENT_TARGET_BINARY_DIR}/${CSBUILD_${name}_CSPROJ} ${CURRENT_TARGET_BINARY_DIR}/packages.config
    )

    add_custom_target(${name} ALL DEPENDS ${CSBUILD_${name}_BINARY})

    set_target_properties(${name}
        PROPERTIES
        EXECUTABLE
        ${_csharp_add_project_EXECUTABLE}
        OUTPUT_PATH
        ${CSBUILD_${name}_BINARY}
        DOTNET_CORE
        ${DOTNET_CORE_FOUND}
    )
endfunction()
