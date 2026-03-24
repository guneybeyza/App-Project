using TaskApp.Domain;

namespace TaskApp.Infrastructure.Repositories.Interfaces;

public interface IUserRepository : IRepository<User>
{
    System.Threading.Tasks.Task<User?> GetByEmailAsync(string email, CancellationToken cancellationToken = default);
    System.Threading.Tasks.Task<bool> IsEmailTakenAsync(string email, CancellationToken cancellationToken = default);
    System.Threading.Tasks.Task<User?> AuthenticateAsync(string email, string password, CancellationToken cancellationToken = default);
    System.Threading.Tasks.Task<User> RegisterAsync(User user, CancellationToken cancellationToken = default);
    System.Threading.Tasks.Task UpdateLastLoginAsync(int userId, CancellationToken cancellationToken = default);
}
