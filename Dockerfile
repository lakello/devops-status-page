FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY app/*.csproj ./app/
RUN dotnet restore ./app/DevOpsStatusPage.csproj

COPY app/ ./app/
RUN dotnet publish ./app/DevOpsStatusPage.csproj -c Release -o /out

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app

RUN useradd -m appuser
USER appuser

COPY --from=build /out .

ENV ASPNETCORE_URLS=http://0.0.0.0:8080
EXPOSE 8080

ENTRYPOINT ["dotnet", "DevOpsStatusPage.dll"]
