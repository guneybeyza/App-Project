using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace TaskApp.Infrastructure.Data;

public class TaskAppDbContextFactory : IDesignTimeDbContextFactory<TaskAppDbContext>
{
    public TaskAppDbContext CreateDbContext(string[] args)
    {
        var optionsBuilder = new DbContextOptionsBuilder<TaskAppDbContext>();
        const string connectionString = "Server=localhost;Database=TaskApp;Trusted_Connection=True;TrustServerCertificate=True;MultipleActiveResultSets=true";

        optionsBuilder.UseSqlServer(connectionString);

        return new TaskAppDbContext(optionsBuilder.Options);
    }
}
