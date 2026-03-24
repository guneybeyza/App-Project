using TaskApp.Domain;

namespace TaskApp.Infrastructure.Repositories.Interfaces;

public interface IProjectRepository : IRepository<Project>
{
    System.Threading.Tasks.Task<IReadOnlyList<Project>> GetByUserIdAsync(int userId, CancellationToken cancellationToken = default);
    System.Threading.Tasks.Task<Project?> GetByNameAsync(string name, CancellationToken cancellationToken = default);
    System.Threading.Tasks.Task<Project> CreateProjectAsync(Project project, CancellationToken cancellationToken = default);
    System.Threading.Tasks.Task UpdateProjectAsync(Project project, CancellationToken cancellationToken = default);
}
