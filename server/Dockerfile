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

RUN dotnet restore ./Gdms.sln

COPY ./src ./src
RUN dotnet publish ./src/Gdms.Api/Gdms.Api.csproj -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish .

ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080

ENTRYPOINT ["dotnet", "Gdms.Api.dll"]
