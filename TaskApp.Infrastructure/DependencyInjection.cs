using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using TaskApp.Infrastructure.Data;
using TaskApp.Infrastructure.Repositories;
using TaskApp.Infrastructure.Repositories.Interfaces;

namespace TaskApp.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("TaskAppConnection")
            ?? "Server=localhost;Database=TaskApp;Trusted_Connection=True;TrustServerCertificate=True;MultipleActiveResultSets=true";

        services.AddDbContext<TaskAppDbContext>(options =>
            options.UseSqlServer(connectionString));

        services.AddScoped(typeof(IRepository<>), typeof(Repository<>));
        services.AddScoped<IUserRepository, UserRepository>();
        services.AddScoped<IProjectRepository, ProjectRepository>();
        services.AddScoped<ITaskRepository, TaskRepository>();

        return services;
    }
}
