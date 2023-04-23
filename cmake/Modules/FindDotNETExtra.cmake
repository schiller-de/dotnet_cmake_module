# Copyright 2016-2018 Esteve Fernandez <esteve@apache.org>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

find_package(CSBuild REQUIRED)
include(${CSBUILD_USE_FILE})

function(add_dotnet_library _TARGET_NAME)
  cmake_parse_arguments(_add_dotnet_library
    ""
    ""
    "SOURCES;INCLUDE_DLLS;INCLUDE_NUPKGS;INCLUDE_REFERENCES"
    ${ARGN}
  )

  csharp_add_project(${_TARGET_NAME}
    SOURCES
    ${_add_dotnet_library_SOURCES}
    ${_add_dotnet_library_UNPARSED_ARGUMENTS}
    INCLUDE_DLLS
    ${_add_dotnet_library_INCLUDE_DLLS}
    INCLUDE_NUPKGS
    ${_add_dotnet_library_INCLUDE_NUPKGS}
    INCLUDE_REFERENCES
    ${_add_dotnet_library_INCLUDE_REFERENCES}
  )
endfunction()

function(add_dotnet_executable _TARGET_NAME)
  cmake_parse_arguments(_add_dotnet_executable
    ""
    ""
    "SOURCES;INCLUDE_DLLS;INCLUDE_NUPKGS;INCLUDE_REFERENCES"
    ${ARGN}
  )

  csharp_add_project(${_TARGET_NAME}
    EXECUTABLE
    SOURCES
    ${_add_dotnet_executable_SOURCES}
    ${_add_dotnet_executable_UNPARSED_ARGUMENTS}
    INCLUDE_DLLS
    ${_add_dotnet_executable_INCLUDE_DLLS}
    INCLUDE_NUPKGS
    ${_add_dotnet_executable_INCLUDE_NUPKGS}
    INCLUDE_REFERENCES
    ${_add_dotnet_executable_INCLUDE_REFERENCES}
  )
endfunction()

function(add_dotnet_test _TARGET_NAME)
  cmake_parse_arguments(_add_dotnet_test
    ""
    "TARGET_FRAMEWORK"
    "SOURCES;INCLUDE_DLLS;INCLUDE_NUPKGS;INCLUDE_REFERENCES"
    ${ARGN}
  )

  if(_add_dotnet_test_TARGET_FRAMEWORK)
    set(CSHARP_TARGET_FRAMEWORK ${_add_dotnet_test_TARGET_FRAMEWORK})
  else()
    set(CSHARP_TARGET_FRAMEWORK "net6.0")
  endif()

  set(XUNIT_INCLUDE_REFERENCES
    "Microsoft.NET.Test.Sdk=15.9.0"
    "xunit=2.4.1"
    "xunit.runner.visualstudio=2.4.1"
  )

  csharp_add_project(${_TARGET_NAME}
    EXECUTABLE
    SOURCES
    ${_add_dotnet_test_SOURCES}
    ${_add_dotnet_test_UNPARSED_ARGUMENTS}
    INCLUDE_DLLS
    ${_add_dotnet_test_INCLUDE_DLLS}
    INCLUDE_NUPKGS
    ${_add_dotnet_test_INCLUDE_NUPKGS}
    INCLUDE_REFERENCES
    ${_add_dotnet_test_INCLUDE_REFERENCES}
    ${XUNIT_INCLUDE_REFERENCES}
  )

  if(CSBUILD_PROJECT_DIR)
      set(CURRENT_TARGET_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/${CSBUILD_PROJECT_DIR}")
  else()
      set(CURRENT_TARGET_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}")
  endif()

  ament_add_test(
    ${name}_test
    GENERATE_RESULT_FOR_RETURN_CODE_ZERO
    WORKING_DIRECTORY ${CURRENT_TARGET_BINARY_DIR}/${_TARGET_NAME}
    COMMAND dotnet test "${CURRENT_TARGET_BINARY_DIR}/${_TARGET_NAME}/${_TARGET_NAME}_${CSBUILD_CSPROJ}"
  )

endfunction()

function(add_dotnet_library_project _TARGET_NAME)
  cmake_parse_arguments(_add_dotnet_library_project
    ""
    ""
    "PROJ;INCLUDE_DLLS"
    ${ARGN}
  )

  csharp_add_existing_project(${_TARGET_NAME}
    PROJ
    ${_add_dotnet_library_project_PROJ}
    ${_add_dotnet_library_project_UNPARSED_ARGUMENTS}
    INCLUDE_DLLS
    ${_add_dotnet_library_project_INCLUDE_DLLS}
  )
endfunction()

function(add_dotnet_executable_project _TARGET_NAME)
  cmake_parse_arguments(_add_dotnet_executable_project
    ""
    ""
    "PROJ;INCLUDE_DLLS"
    ${ARGN}
  )

  csharp_add_existing_project(${_TARGET_NAME}
    EXECUTABLE
    PROJ
    ${_add_dotnet_executable_project_PROJ}
    ${_add_dotnet_executable_project_UNPARSED_ARGUMENTS}
    INCLUDE_DLLS
    ${_add_dotnet_executable_project_INCLUDE_DLLS}
  )
endfunction()

function(add_dotnet_test_project _TARGET_NAME)
  # TODO: (sh) It seems the test project gets build twice with different output directories
  # e.g.: the same output files are contained in "build/<package>/<target>/net6.0/" and "build/<package>/<target>/net6.0/linux-x64"
  # But this seems to be the case with other projects as well (package rcldotnet and targets rcldotnet_assemblies and test_messages).
  # So maybe this is how it should be, but why?

  cmake_parse_arguments(_add_dotnet_test_project
    ""
    ""
    "PROJ;INCLUDE_DLLS"
    ${ARGN}
  )

  csharp_add_existing_project(${_TARGET_NAME}
    EXECUTABLE
    PROJ
    ${_add_dotnet_test_project_PROJ}
    ${_add_dotnet_test_project_UNPARSED_ARGUMENTS}
    INCLUDE_DLLS
    ${_add_dotnet_test_project_INCLUDE_DLLS}
  )

  if(CSBUILD_PROJECT_DIR)
    set(CURRENT_TARGET_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/${CSBUILD_PROJECT_DIR}")
  else()
    set(CURRENT_TARGET_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}")
  endif()

  get_filename_component(_add_dotnet_test_project_PROJ_ABSOLUTE ${_add_dotnet_test_project_PROJ} ABSOLUTE)

  ament_add_test(
    ${_TARGET_NAME}
    GENERATE_RESULT_FOR_RETURN_CODE_ZERO
    WORKING_DIRECTORY ${CURRENT_TARGET_BINARY_DIR}/${_TARGET_NAME}
    COMMAND dotnet test ${_add_dotnet_test_project_PROJ_ABSOLUTE}
  )
endfunction()

function(install_dotnet _TARGET_NAME)
    get_target_property(_target_executable ${_TARGET_NAME} EXECUTABLE)
    get_target_property(_target_path ${_TARGET_NAME} OUTPUT_PATH)
    get_target_property(_target_name ${_TARGET_NAME} OUTPUT_NAME)
    get_target_property(_target_dotnet_core ${_TARGET_NAME} DOTNET_CORE)

    if (ARGC EQUAL 2)
      set (_DESTINATION ${ARGV1})
    else()
      cmake_parse_arguments(_install_dotnet
        "CD_TO_EXECUTABLE"
        "DESTINATION;ENTRY_POINT_NAME"
        ""
        ${ARGN})
      if (_install_dotnet_DESTINATION)
        set (_DESTINATION ${_install_dotnet_DESTINATION})
      else()
        message(SEND_ERROR "install_dotnet: ${_TARGET_NAME}: DESTINATION must be specified.")
      endif()
    endif()
    install(DIRECTORY ${_target_path}/ DESTINATION ${_DESTINATION})

    if(_target_executable)
      if (_install_dotnet_ENTRY_POINT_NAME)
        set(_ENTRY_POINT_NAME ${_install_dotnet_ENTRY_POINT_NAME})
      else()
        # default to _TARGET_NAME
        set(_ENTRY_POINT_NAME ${_TARGET_NAME})
      endif()
      set(DOTNET_DLL_PATH ${_target_name})
      if(WIN32)
        if (_install_dotnet_CD_TO_EXECUTABLE)
          configure_file(${dotnet_cmake_module_DIR}/Modules/dotnet/entry_point_with_cd.windows.in lib/${_ENTRY_POINT_NAME}.bat @ONLY)
        else()
          configure_file(${dotnet_cmake_module_DIR}/Modules/dotnet/entry_point.windows.in lib/${_ENTRY_POINT_NAME}.bat @ONLY)
        endif()
        install(FILES ${CMAKE_CURRENT_BINARY_DIR}/lib/${_ENTRY_POINT_NAME}.bat
          DESTINATION
          lib/${PROJECT_NAME})
      else()
        if (_install_dotnet_CD_TO_EXECUTABLE)
          configure_file(${dotnet_cmake_module_DIR}/Modules/dotnet/entry_point_with_cd.unix.in lib/${_ENTRY_POINT_NAME} @ONLY)
        else()
          configure_file(${dotnet_cmake_module_DIR}/Modules/dotnet/entry_point.unix.in lib/${_ENTRY_POINT_NAME} @ONLY)
        endif()
        install(FILES ${CMAKE_CURRENT_BINARY_DIR}/lib/${_ENTRY_POINT_NAME}
          DESTINATION
          lib/${PROJECT_NAME}
          PERMISSIONS
          OWNER_READ
          OWNER_WRITE
          OWNER_EXECUTE
          GROUP_READ
          GROUP_EXECUTE
          WORLD_READ
          WORLD_EXECUTE
        )
      endif()
    endif()
endfunction()
