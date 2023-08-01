using Azure.Identity;
using Microsoft.EntityFrameworkCore;
using Pomelo.EntityFrameworkCore.MySql.Infrastructure;
using SimpleTodo.Repo;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddScoped<ListsRepository>();
builder.Services.AddDbContext<TodoDb>(options =>
{
    switch (builder.Configuration["TargetDb"])
    {
        case "MySql":
            string mysqlConnString = builder.Configuration.GetConnectionString("MySqlConnection") ?? throw new InvalidOperationException("MySqlConnection must be set in the configuration");
            var serverVersion = ServerVersion.Parse("5.7", ServerType.MySql);
            options
                .UseMySql(mysqlConnString, serverVersion)
                .UseAzureADAuthentication(new DefaultAzureCredential());
            break;
        case "Postgresql":
            string npgConnString = builder.Configuration.GetConnectionString("PgSqlConnection") ?? throw new InvalidOperationException("PgSqlConnection must be set in the configuration");
            options
                .UseNpgsql(npgConnString, options => options.UseAzureADAuthentication(new DefaultAzureCredential()));
            break;
        default:
            throw new InvalidOperationException("TargetDb must be set to either MySql or Postgresql");
    }
});

builder.Services.AddControllers();
builder.Services.AddApplicationInsightsTelemetry(builder.Configuration);

var app = builder.Build();

await using (var scope = app.Services.CreateAsyncScope())
{
    var db = scope.ServiceProvider.GetRequiredService<TodoDb>();
    await db.Database.EnsureCreatedAsync();
}

app.UseCors(policy =>
{
    policy.AllowAnyOrigin();
    policy.AllowAnyHeader();
    policy.AllowAnyMethod();
});

// Swagger UI
app.UseSwaggerUI(options =>
{
    options.SwaggerEndpoint("./openapi.yaml", "v1");
    options.RoutePrefix = "";
});

app.UseStaticFiles(new StaticFileOptions
{
    // Serve openapi.yaml file
    ServeUnknownFileTypes = true,
});

app.MapControllers();
app.Run();