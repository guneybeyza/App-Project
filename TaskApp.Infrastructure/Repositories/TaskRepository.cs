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
}
