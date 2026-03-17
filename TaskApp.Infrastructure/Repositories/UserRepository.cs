using Microsoft.EntityFrameworkCore;
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

    public async System.Threading.Tasks.Task<User?> GetByEmailAsync(string email, CancellationToken cancellationToken = default)
    {
        return await DbSet.FirstOrDefaultAsync(u => u.Email == email, cancellationToken);
    }

    public async System.Threading.Tasks.Task<bool> IsEmailTakenAsync(string email, CancellationToken cancellationToken = default)
    {
        return await DbSet.AnyAsync(u => u.Email == email, cancellationToken);
    }

    public async System.Threading.Tasks.Task<User?> AuthenticateAsync(string email, string password, CancellationToken cancellationToken = default)
    {
        // NOT: Şu anda şifreler açık metin saklanıyor. Üretimde hash ve salt kullanın.
        return await DbSet.FirstOrDefaultAsync(u => u.Email == email && u.Password == password, cancellationToken);
    }

    public async System.Threading.Tasks.Task<User> RegisterAsync(User user, CancellationToken cancellationToken = default)
    {
        user.LastLogin = DateTime.UtcNow;
        await DbSet.AddAsync(user, cancellationToken);
        await SaveChangesAsync(cancellationToken);
        return user;
    }

    public async System.Threading.Tasks.Task UpdateLastLoginAsync(int userId, CancellationToken cancellationToken = default)
    {
        var user = await GetByIdAsync(userId, cancellationToken);
        if (user is null)
            return;

        user.LastLogin = DateTime.UtcNow;
        DbSet.Update(user);
        await SaveChangesAsync(cancellationToken);
    }
}
