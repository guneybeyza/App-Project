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
}
