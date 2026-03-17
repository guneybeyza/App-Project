using TaskEntity = TaskApp.Domain.Task;

namespace TaskApp.Infrastructure.Repositories.Interfaces;

public interface ITaskRepository : IRepository<TaskEntity>
{
}
