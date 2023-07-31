using Azure.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Npgsql;
using SimpleTodo.Repo;
using System.Reflection;

namespace SimpleTodo.Repo.PgSql
{
    public class TodoContextFactory : IDesignTimeDbContextFactory<TodoDb>
    {
        public TodoDb CreateDbContext(string[] args)
        {
            ConfigurationBuilder configBuilder = new ConfigurationBuilder();
            configBuilder.AddJsonFile("appsettings.json");
            IConfigurationRoot config = configBuilder.Build();

            ServiceCollection services = new ServiceCollection();
            services.AddDbContext<TodoDb>(options =>
            {
                options.UseNpgsql(GetConnectionString(config), optionsBuilder =>
                optionsBuilder
                    .MigrationsAssembly(Assembly.GetExecutingAssembly().FullName)
                    .UseAzureADAuthentication(new DefaultAzureCredential()));
            });

            var serviceProvider = services.BuildServiceProvider();
            return serviceProvider.GetRequiredService<TodoDb>();
        }

        private static string GetConnectionString(IConfiguration configuration)
        {
            return configuration.GetConnectionString("DefaultConnection") ?? throw new InvalidOperationException("Could not find a connection string named 'DefaultConnection'.");
        }
    }
}