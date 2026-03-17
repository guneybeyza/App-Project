using Microsoft.EntityFrameworkCore;
using TaskApp.Infrastructure.Data;
using TaskApp.Infrastructure.Repositories.Interfaces;
using TaskEntity = TaskApp.Domain.Task;

namespace TaskApp.Infrastructure.Repositories;

public class TaskRepository : Repository<TaskEntity>, ITaskRepository
{
    public TaskRepository(TaskAppDbContext context)
        : base(context)
    {
    }

    public async System.Threading.Tasks.Task<IReadOnlyList<TaskEntity>> GetByProjectIdAsync(int projectId, CancellationToken cancellationToken = default)
    {
        return await DbSet.Where(t => t.ProjectId == projectId).ToListAsync(cancellationToken);
    }

    public async System.Threading.Tasks.Task<IReadOnlyList<TaskEntity>> GetByStatusAsync(string status, CancellationToken cancellationToken = default)
    {
        return await DbSet.Where(t => t.Status == status).ToListAsync(cancellationToken);
    }

    public async System.Threading.Tasks.Task<IReadOnlyList<TaskEntity>> GetOverdueTasksAsync(DateTime now, CancellationToken cancellationToken = default)
    {
        return await DbSet.Where(t => t.DueDate < now && t.Status != "Done").ToListAsync(cancellationToken);
    }

    public async System.Threading.Tasks.Task UpdateStatusAsync(int taskId, string status, CancellationToken cancellationToken = default)
    {
        var task = await GetByIdAsync(taskId, cancellationToken);
        if (task is null)
            return;

        task.Status = status;
        DbSet.Update(task);
        await SaveChangesAsync(cancellationToken);
    }
}
