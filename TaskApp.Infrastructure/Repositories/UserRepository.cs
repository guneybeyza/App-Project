using TaskApp.Domain;
using TaskApp.Infrastructure.Data;
using TaskApp.Infrastructure.Repositories.Interfaces;

namespace TaskApp.Infrastructure.Repositories;

public class UserRepository : Repository<User>, IUserRepository
{
    public UserRepository(TaskAppDbContext context)
        : base(context)
    {
    }
}
