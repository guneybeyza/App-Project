using Microsoft.AspNetCore.Mvc;
using TaskApp.Domain;
using TaskApp.Infrastructure.Repositories.Interfaces;

namespace TaskApp.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ProjectController : ControllerBase
{
    private readonly IProjectRepository _projectRepository;
    private readonly IUserRepository _userRepository;
    private readonly ITaskRepository _taskRepository;

    public ProjectController(IProjectRepository projectRepository, IUserRepository userRepository, ITaskRepository taskRepository)
    {
        _projectRepository = projectRepository;
        _userRepository = userRepository;
        _taskRepository = taskRepository;
    }

    /// <summary>
    /// Tüm projeleri getirir
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<Project>>> GetAllProjects(CancellationToken cancellationToken = default)
    {
        try
        {
            var projects = await _projectRepository.GetAllAsync(cancellationToken);
            return Ok(projects);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Projeleri alırken hata oluştu", error = ex.Message });
        }
    }

    /// <summary>
    /// ID'ye göre proje getirir
    /// </summary>
    [HttpGet("{id}")]
    public async Task<ActionResult<Project>> GetProjectById(int id, CancellationToken cancellationToken = default)
    {
        try
        {
            var project = await _projectRepository.GetByIdAsync(id, cancellationToken);

            if (project is null)
            {
                return NotFound(new { message = "Proje bulunamadı" });
            }

            return Ok(project);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Proje alınırken hata oluştu", error = ex.Message });
        }
    }

    /// <summary>
    /// Kullanıcı ID'sine göre projeleri getirir
    /// </summary>
    [HttpGet("user/{userId}")]
    public async Task<ActionResult<IReadOnlyList<Project>>> GetProjectsByUserId(int userId, CancellationToken cancellationToken = default)
    {
        try
        {
            // Önce kullanıcının var olduğunu kontrol et
            var user = await _userRepository.GetByIdAsync(userId, cancellationToken);
            if (user is null)
            {
                return NotFound(new { message = "Kullanıcı bulunamadı" });
            }

            var projects = await _projectRepository.FindAsync(p => p.UserId == userId, cancellationToken);
            return Ok(projects);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Kullanıcı projeleri alınırken hata oluştu", error = ex.Message });
        }
    }

    /// <summary>
    /// Proje detaylarını görevleriyle birlikte getirir
    /// </summary>
    [HttpGet("{id}/details")]
    public async Task<ActionResult<ProjectDetailsResponse>> GetProjectDetails(int id, CancellationToken cancellationToken = default)
    {
        try
        {
            var project = await _projectRepository.GetByIdAsync(id, cancellationToken);

            if (project is null)
            {
                return NotFound(new { message = "Proje bulunamadı" });
            }

            var tasks = await _taskRepository.FindAsync(t => t.ProjectId == id, cancellationToken);

            var response = new ProjectDetailsResponse
            {
                Project = project,
                Tasks = tasks,
                TotalTasks = tasks.Count,
                CompletedTasks = tasks.Count(t => t.Status.ToLower() == "completed" || t.Status.ToLower() == "tamamlandı"),
                PendingTasks = tasks.Count(t => t.Status.ToLower() != "completed" && t.Status.ToLower() != "tamamlandı")
            };

            return Ok(response);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Proje detayları alınırken hata oluştu", error = ex.Message });
        }
    }

    /// <summary>
    /// Yeni proje oluşturur
    /// </summary>
    [HttpPost]
    public async Task<ActionResult<Project>> CreateProject([FromBody] CreateProjectRequest request, CancellationToken cancellationToken = default)
    {
        try
        {
            // Validasyon
            if (string.IsNullOrWhiteSpace(request.Name))
            {
                return BadRequest(new { message = "Proje adı boş olamaz" });
            }

            // Kullanıcının var olduğunu kontrol et
            var user = await _userRepository.GetByIdAsync(request.UserId, cancellationToken);
            if (user is null)
            {
                return BadRequest(new { message = "Geçersiz kullanıcı ID" });
            }

            var project = new Project
            {
                Name = request.Name,
                Description = request.Description ?? string.Empty,
                UserId = request.UserId
            };

            var createdProject = await _projectRepository.AddAsync(project, cancellationToken);
            await _projectRepository.SaveChangesAsync(cancellationToken);

            return CreatedAtAction(nameof(GetProjectById), new { id = createdProject.Id }, createdProject);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Proje oluşturulurken hata oluştu", error = ex.Message });
        }
    }

    /// <summary>
    /// Mevcut projeyi günceller
    /// </summary>
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateProject(int id, [FromBody] UpdateProjectRequest request, CancellationToken cancellationToken = default)
    {
        try
        {
            var project = await _projectRepository.GetByIdAsync(id, cancellationToken);

            if (project is null)
            {
                return NotFound(new { message = "Proje bulunamadı" });
            }

            // Validasyon
            if (string.IsNullOrWhiteSpace(request.Name) && string.IsNullOrWhiteSpace(request.Description) && !request.UserId.HasValue)
            {
                return BadRequest(new { message = "Güncellenecek en az bir alan gereklidir" });
            }

            // Kullanıcı ID değişiyorsa, yeni kullanıcının var olduğunu kontrol et
            if (request.UserId.HasValue && request.UserId.Value != project.UserId)
            {
                var user = await _userRepository.GetByIdAsync(request.UserId.Value, cancellationToken);
                if (user is null)
                {
                    return BadRequest(new { message = "Geçersiz kullanıcı ID" });
                }
                project.UserId = request.UserId.Value;
            }

            if (!string.IsNullOrWhiteSpace(request.Name))
            {
                project.Name = request.Name;
            }

            if (!string.IsNullOrWhiteSpace(request.Description))
            {
                project.Description = request.Description;
            }

            await _projectRepository.UpdateAsync(project, cancellationToken);
            await _projectRepository.SaveChangesAsync(cancellationToken);

            return Ok(new { message = "Proje başarıyla güncellendi", project });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Proje güncellenirken hata oluştu", error = ex.Message });
        }
    }

    /// <summary>
    /// Projeyi siler (İlişkili görevleri de siler)
    /// </summary>
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteProject(int id, CancellationToken cancellationToken = default)
    {
        try
        {
            var project = await _projectRepository.GetByIdAsync(id, cancellationToken);

            if (project is null)
            {
                return NotFound(new { message = "Proje bulunamadı" });
            }

            // İlişkili görevleri kontrol et ve sil
            var tasks = await _taskRepository.FindAsync(t => t.ProjectId == id, cancellationToken);
            foreach (var task in tasks)
            {
                await _taskRepository.DeleteAsync(task, cancellationToken);
            }

            await _projectRepository.DeleteAsync(project, cancellationToken);
            await _projectRepository.SaveChangesAsync(cancellationToken);

            return Ok(new { message = "Proje ve ilişkili görevler başarıyla silindi" });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Proje silinirken hata oluştu", error = ex.Message });
        }
    }

    /// <summary>
    /// Kullanıcının proje istatistiklerini getirir
    /// </summary>
    [HttpGet("user/{userId}/statistics")]
    public async Task<ActionResult<ProjectStatisticsResponse>> GetUserProjectStatistics(int userId, CancellationToken cancellationToken = default)
    {
        try
        {
            var user = await _userRepository.GetByIdAsync(userId, cancellationToken);
            if (user is null)
            {
                return NotFound(new { message = "Kullanıcı bulunamadı" });
            }

            var projects = await _projectRepository.FindAsync(p => p.UserId == userId, cancellationToken);

            var statistics = new ProjectStatisticsResponse
            {
                TotalProjects = projects.Count,
                Projects = new List<ProjectWithTaskCount>()
            };

            foreach (var project in projects)
            {
                var tasks = await _taskRepository.FindAsync(t => t.ProjectId == project.Id, cancellationToken);
                statistics.Projects.Add(new ProjectWithTaskCount
                {
                    Project = project,
                    TotalTasks = tasks.Count,
                    CompletedTasks = tasks.Count(t => t.Status.ToLower() == "completed" || t.Status.ToLower() == "tamamlandı"),
                    PendingTasks = tasks.Count(t => t.Status.ToLower() != "completed" && t.Status.ToLower() != "tamamlandı")
                });
            }

            return Ok(statistics);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Proje istatistikleri alınırken hata oluştu", error = ex.Message });
        }
    }
}

/// <summary>
/// Proje oluştururken gönderilen veriler
/// </summary>
public class CreateProjectRequest
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public int UserId { get; set; }
}

/// <summary>
/// Proje güncellenirken gönderilen veriler
/// </summary>
public class UpdateProjectRequest
{
    public string? Name { get; set; }
    public string? Description { get; set; }
    public int? UserId { get; set; }
}

/// <summary>
/// Proje detayları yanıtı
/// </summary>
public class ProjectDetailsResponse
{
    public Project Project { get; set; } = null!;
    public IReadOnlyList<TaskApp.Domain.Task> Tasks { get; set; } = null!;
    public int TotalTasks { get; set; }
    public int CompletedTasks { get; set; }
    public int PendingTasks { get; set; }
}

/// <summary>
/// Proje istatistikleri yanıtı
/// </summary>
public class ProjectStatisticsResponse
{
    public int TotalProjects { get; set; }
    public List<ProjectWithTaskCount> Projects { get; set; } = new();
}

/// <summary>
/// Görev sayısı ile birlikte proje
/// </summary>
public class ProjectWithTaskCount
{
    public Project Project { get; set; } = null!;
    public int TotalTasks { get; set; }
    public int CompletedTasks { get; set; }
    public int PendingTasks { get; set; }
}