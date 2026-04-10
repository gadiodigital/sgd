FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY ./Directory.Build.props ./
COPY ./global.json ./
COPY ./Gdms.sln ./
COPY ./src/Gdms.Api/Gdms.Api.csproj ./src/Gdms.Api/
COPY ./src/Gdms.Application/Gdms.Application.csproj ./src/Gdms.Application/
COPY ./src/Gdms.Domain/Gdms.Domain.csproj ./src/Gdms.Domain/
COPY ./src/Gdms.Infrastructure/Gdms.Infrastructure.csproj ./src/Gdms.Infrastructure/
COPY ./src/Gdms.Contracts/Gdms.Contracts.csproj ./src/Gdms.Contracts/
COPY ./tests/Gdms.ArchitectureTests/Gdms.ArchitectureTests.csproj ./tests/Gdms.ArchitectureTests/
COPY ./tests/Gdms.UnitTests/Gdms.UnitTests.csproj ./tests/Gdms.UnitTests/
COPY ./tests/Gdms.IntegrationTests/Gdms.IntegrationTests.csproj ./tests/Gdms.IntegrationTests/
COPY ./tests/Gdms.ApiContractTests/Gdms.ApiContractTests.csproj ./tests/Gdms.ApiContractTests/
COPY ./tests/Gdms.E2eSmokeTests/Gdms.E2eSmokeTests.csproj ./tests/Gdms.E2eSmokeTests/

RUN dotnet restore ./Gdms.sln

COPY ./src ./src
COPY ./tests ./tests
RUN dotnet publish ./src/Gdms.Api/Gdms.Api.csproj -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish .

ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080

ENTRYPOINT ["dotnet", "Gdms.Api.dll"]
