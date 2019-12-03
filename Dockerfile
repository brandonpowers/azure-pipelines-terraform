FROM mcr.microsoft.com/dotnet/core/sdk:3.0 AS build
WORKDIR /app

# Copy the solution, project and code files
COPY *.sln .

#TODO: Change these if your solution uses a different directory structure
COPY src src/
COPY tests tests/

# Restore the nuget packages
RUN dotnet restore

WORKDIR /app/src

# Build and publish the main project
RUN dotnet publish MyWebApp.Api/MyWebApp.Api.csproj -c Release -o out

# Build runtime image
FROM mcr.microsoft.com/dotnet/core/aspnet:3.0 AS runtime
WORKDIR /app
COPY --from=build /app/src/out .

#TODO: Set the main Web API dll as the application entrypoint
ENTRYPOINT ["dotnet", "MyWebApp.Api.dll"]
