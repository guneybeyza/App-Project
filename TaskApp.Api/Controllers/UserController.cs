using Microsoft.AspNetCore.Mvc;
using TaskApp.Domain;
using TaskApp.Infrastructure.Repositories.Interfaces;

namespace TaskApp.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class UserController : ControllerBase
{
    private readonly IUserRepository _userRepository;

    public UserController(IUserRepository userRepository)
    {
        _userRepository = userRepository;
    }

    /// <summary>
    /// Tüm kullanıcıları getirir
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<User>>> GetAllUsers(CancellationToken cancellationToken = default)
    {
        try
        {
            var users = await _userRepository.GetAllAsync(cancellationToken);
            return Ok(users);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Kullanıcıları alırken hata oluştu", error = ex.Message });
        }
    }

    /// <summary>
    /// ID'ye göre kullanıcı getirir
    /// </summary>
    [HttpGet("{id}")]
    public async Task<ActionResult<User>> GetUserById(int id, CancellationToken cancellationToken = default)
    {
        try
        {
            var user = await _userRepository.GetByIdAsync(id, cancellationToken);
            
            if (user is null)
            {
                return NotFound(new { message = "Kullanıcı bulunamadı" });
            }

            return Ok(user);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Kullanıcı alırken hata oluştu", error = ex.Message });
        }
    }

    /// <summary>
    /// Email'e göre kullanıcı bulur (Login için kullanışlı)
    /// </summary>
    [HttpGet("search/email")]
    public async Task<ActionResult<User>> GetUserByEmail(string email, CancellationToken cancellationToken = default)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(email))
            {
                return BadRequest(new { message = "Email boş olamaz" });
            }

            var user = await _userRepository.FindAsync(u => u.Email.ToLower() == email.ToLower(), cancellationToken);
            
            if (user.Count == 0)
            {
                return NotFound(new { message = "Kullanıcı bulunamadı" });
            }

            return Ok(user.FirstOrDefault());
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Kullanıcı aranırken hata oluştu", error = ex.Message });
        }
    }

    /// <summary>
    /// Yeni kullanıcı oluşturur
    /// </summary>
    [HttpPost]
    public async Task<ActionResult<User>> CreateUser([FromBody] CreateUserRequest request, CancellationToken cancellationToken = default)
    {
        try
        {
            // Validasyon
            if (string.IsNullOrWhiteSpace(request.Name))
            {
                return BadRequest(new { message = "Ad boş olamaz" });
            }

            if (string.IsNullOrWhiteSpace(request.Email))
            {
                return BadRequest(new { message = "Email boş olamaz" });
            }

            if (string.IsNullOrWhiteSpace(request.Password))
            {
                return BadRequest(new { message = "Şifre boş olamaz" });
            }

            // Email'in eşsiz olduğunu kontrol et
            var existingUser = await _userRepository.FindAsync(u => u.Email.ToLower() == request.Email.ToLower(), cancellationToken);
            if (existingUser.Count > 0)
            {
                return BadRequest(new { message = "Bu email adresine sahip kullanıcı zaten mevcut" });
            }

            var user = new User
            {
                Name = request.Name,
                Email = request.Email,
                Password = request.Password,
                LastLogin = DateTime.UtcNow
            };

            var createdUser = await _userRepository.AddAsync(user, cancellationToken);
            await _userRepository.SaveChangesAsync(cancellationToken);

            return CreatedAtAction(nameof(GetUserById), new { id = createdUser.Id }, createdUser);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Kullanıcı oluştururken hata oluştu", error = ex.Message });
        }
    }

    /// <summary>
    /// Mevcut kullanıcıyı günceller
    /// </summary>
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateUser(int id, [FromBody] UpdateUserRequest request, CancellationToken cancellationToken = default)
    {
        try
        {
            var user = await _userRepository.GetByIdAsync(id, cancellationToken);
            
            if (user is null)
            {
                return NotFound(new { message = "Kullanıcı bulunamadı" });
            }

            // Validasyon
            if (string.IsNullOrWhiteSpace(request.Name) && string.IsNullOrWhiteSpace(request.Email) && string.IsNullOrWhiteSpace(request.Password))
            {
                return BadRequest(new { message = "Güncellenecek en az bir alan gereklidir" });
            }

            // Email değişiyorsa, başka kullanıcı tarafından kullanılmadığını kontrol et
            if (!string.IsNullOrWhiteSpace(request.Email) && request.Email != user.Email)
            {
                var existingUser = await _userRepository.FindAsync(u => u.Email.ToLower() == request.Email.ToLower() && u.Id != id, cancellationToken);
                if (existingUser.Count > 0)
                {
                    return BadRequest(new { message = "Bu email adresine sahip kullanıcı zaten mevcut" });
                }
                user.Email = request.Email;
            }

            if (!string.IsNullOrWhiteSpace(request.Name))
            {
                user.Name = request.Name;
            }

            if (!string.IsNullOrWhiteSpace(request.Password))
            {
                user.Password = request.Password;
            }

            await _userRepository.UpdateAsync(user, cancellationToken);
            await _userRepository.SaveChangesAsync(cancellationToken);

            return Ok(new { message = "Kullanıcı başarıyla güncellendi", user });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Kullanıcı güncellenirken hata oluştu", error = ex.Message });
        }
    }

    /// <summary>
    /// Kullanıcıyı siler
    /// </summary>
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteUser(int id, CancellationToken cancellationToken = default)
    {
        try
        {
            var user = await _userRepository.GetByIdAsync(id, cancellationToken);
            
            if (user is null)
            {
                return NotFound(new { message = "Kullanıcı bulunamadı" });
            }

            await _userRepository.DeleteAsync(user, cancellationToken);
            await _userRepository.SaveChangesAsync(cancellationToken);

            return Ok(new { message = "Kullanıcı başarıyla silindi" });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Kullanıcı silinirken hata oluştu", error = ex.Message });
        }
    }

    /// <summary>
    /// Kullanıcı giriş yapmışken LastLogin günceller (Authentication sonrası)
    /// </summary>
    [HttpPost("{id}/update-last-login")]
    public async Task<IActionResult> UpdateLastLogin(int id, CancellationToken cancellationToken = default)
    {
        try
        {
            var user = await _userRepository.GetByIdAsync(id, cancellationToken);
            
            if (user is null)
            {
                return NotFound(new { message = "Kullanıcı bulunamadı" });
            }

            user.LastLogin = DateTime.UtcNow;

            await _userRepository.UpdateAsync(user, cancellationToken);
            await _userRepository.SaveChangesAsync(cancellationToken);

            return Ok(new { message = "Son giriş zamanı güncellendi", user });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Son giriş zamanı güncellenirken hata oluştu", error = ex.Message });
        }
    }

    /// <summary>
    /// Kullanıcı kimlik doğrulama (Login)
    /// </summary>
    [HttpPost("authenticate")]
    public async Task<ActionResult<User>> AuthenticateUser([FromBody] LoginRequest request, CancellationToken cancellationToken = default)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Password))
            {
                return BadRequest(new { message = "Email ve şifre gerekli" });
            }

            var users = await _userRepository.FindAsync(u => u.Email.ToLower() == request.Email.ToLower(), cancellationToken);
            
            if (users.Count == 0)
            {
                return Unauthorized(new { message = "Email veya şifre hatalı" });
            }

            var user = users.FirstOrDefault();
            
            if (user?.Password != request.Password)
            {
                return Unauthorized(new { message = "Email veya şifre hatalı" });
            }

            // LastLogin'i güncelle
            user.LastLogin = DateTime.UtcNow;
            await _userRepository.UpdateAsync(user, cancellationToken);
            await _userRepository.SaveChangesAsync(cancellationToken);

            return Ok(user);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Kimlik doğrulama sırasında hata oluştu", error = ex.Message });
        }
    }
}

/// <summary>
/// Kullanıcı oluştururken gönderilen veriler
/// </summary>
public class CreateUserRequest
{
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}

/// <summary>
/// Kullanıcı güncellenirken gönderilen veriler
/// </summary>
public class UpdateUserRequest
{
    public string? Name { get; set; }
    public string? Email { get; set; }
    public string? Password { get; set; }
}

/// <summary>
/// Login için gönderilen veriler
/// </summary>
public class LoginRequest
{
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}
