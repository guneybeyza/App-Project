using Microsoft.EntityFrameworkCore;
using TaskApp.Domain;
using TaskApp.Infrastructure.Data;
using TaskApp.Infrastructure.Repositories.Interfaces;

namespace TaskApp.Infrastructure.Repositories;

public class ProjectRepository : Repository<Project>, IProjectRepository
{
    public ProjectRepository(TaskAppDbContext context)
        : base(context)
    {
    }

    public async System.Threading.Tasks.Task<IReadOnlyList<Project>> GetByUserIdAsync(int userId, CancellationToken cancellationToken = default)
    {
        return await DbSet.Where(p => p.UserId == userId).ToListAsync(cancellationToken);
    }

    public async System.Threading.Tasks.Task<Project?> GetByNameAsync(string name, CancellationToken cancellationToken = default)
    {
        return await DbSet.FirstOrDefaultAsync(p => p.Name == name, cancellationToken);
    }

    public async System.Threading.Tasks.Task<Project> CreateProjectAsync(Project project, CancellationToken cancellationToken = default)
    {
        await DbSet.AddAsync(project, cancellationToken);
        await SaveChangesAsync(cancellationToken);
        return project;
    }

    public async System.Threading.Tasks.Task UpdateProjectAsync(Project project, CancellationToken cancellationToken = default)
    {
        DbSet.Update(project);
        await SaveChangesAsync(cancellationToken);
    }
}
