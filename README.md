Parts of this project based on code by Illumina.

For more info:

https://github.com/Illumina/interop

## `.csproj` support
It is possible to include eg. a C# project `.csproj` file with the `add_dotnet_project` function.
This `.csproj` file must include a line

```xml
<Import Project="obj/CMake.g.props"/>
```

as this is where CMake generates references to other ROS 2 packages in, as well as the output path and the assembly name.
