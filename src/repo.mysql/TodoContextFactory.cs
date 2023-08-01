using Azure.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using MySqlConnector;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;
using Pomelo.EntityFrameworkCore.MySql.Infrastructure;

using SimpleTodo.Repo;

namespace SimpleTodo.Repo.MySql
{
    public class TodoDbContextFactory : IDesignTimeDbContextFactory<TodoDb>
    {
        public TodoDb CreateDbContext(string[] args)
        {
            ConfigurationBuilder configBuilder = new ConfigurationBuilder();
            configBuilder.AddJsonFile("appsettings.json");
            IConfigurationRoot config = configBuilder.Build();
            ServiceCollection services = new ServiceCollection();
            services.AddDbContext<TodoDb>(options =>
            {
                string connectionString = GetConnectionString(config);
                var serverVersion = ServerVersion.Parse("5.7", ServerType.MySql);
                options.UseMySql(connectionString, serverVersion, 
                    optionsBuilder => optionsBuilder.MigrationsAssembly(Assembly.GetExecutingAssembly().FullName)
                        .EnableRetryOnFailure(3))
                .UseAzureADAuthentication(new DefaultAzureCredential());
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
