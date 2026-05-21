var builder = WebApplication.CreateBuilder(args);

var app = builder.Build();

app.MapGet("/", () =>
{
    var response = new
    {
        app = "devops-status-page",
        version = Environment.GetEnvironmentVariable("APP_VERSION") ?? "local",
        hostname = Environment.MachineName,
        status = "ok",
        time = DateTimeOffset.UtcNow
    };

    return Results.Json(response);
});

app.MapGet("/health", () =>
{
    return Results.Json(new
    {
        status = "healthy"
    });
});

app.Run("http://0.0.0.0:8080");
