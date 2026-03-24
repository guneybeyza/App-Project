using TaskEntity = TaskApp.Domain.Task;

namespace TaskApp.Infrastructure.Repositories.Interfaces;

public interface ITaskRepository : IRepository<TaskEntity>
{
    System.Threading.Tasks.Task<IReadOnlyList<TaskEntity>> GetByProjectIdAsync(int projectId, CancellationToken cancellationToken = default);
    System.Threading.Tasks.Task<IReadOnlyList<TaskEntity>> GetByStatusAsync(string status, CancellationToken cancellationToken = default);
    System.Threading.Tasks.Task<IReadOnlyList<TaskEntity>> GetOverdueTasksAsync(DateTime now, CancellationToken cancellationToken = default);
    System.Threading.Tasks.Task UpdateStatusAsync(int taskId, string status, CancellationToken cancellationToken = default);
}
