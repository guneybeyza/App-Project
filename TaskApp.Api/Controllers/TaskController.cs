using Microsoft.AspNetCore.Mvc;
using System.Linq;
using TaskApp.Domain;
using TaskApp.Infrastructure.Repositories.Interfaces;
using TaskEntity = TaskApp.Domain.Task;

namespace TaskApp.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class TaskController : ControllerBase
{
    private readonly ITaskRepository _taskRepository;
    private readonly IProjectRepository _projectRepository;

    public TaskController(ITaskRepository taskRepository, IProjectRepository projectRepository)
    {
        _taskRepository = taskRepository;
        _projectRepository = projectRepository;
    }

    /// <summary>
    /// Tüm görevleri getirir
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<TaskEntity>>> GetAllTasks(CancellationToken cancellationToken = default)
    {
        try
        {
            var tasks = await _taskRepository.GetAllAsync(cancellationToken);
            return Ok(tasks);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Görevleri alırken hata oluştu", error = ex.Message });
        }
    }

    /// <summary>
    /// Kullanıcı ID'sine göre tüm görevleri getirir
    /// </summary>
    [HttpGet("user/{userId}")]
    public async Task<ActionResult<IReadOnlyList<TaskEntity>>> GetTasksByUserId(int userId, CancellationToken cancellationToken = default)
    {
        try
        {
            // Kullanıcının projelerini bul
            var projects = await _projectRepository.FindAsync(p => p.UserId == userId, cancellationToken);
            var projectIds = projects.Select(p => p.Id).ToList();

            if (!projectIds.Any())
            {
                return Ok(new List<TaskEntity>());
            }

            // Bu projelere ait görevleri bul
            var tasks = await _taskRepository.FindAsync(t => projectIds.Contains(t.ProjectId), cancellationToken);
            return Ok(tasks);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Kullanıcı görevleri alınırken hata oluştu", error = ex.Message });
        }
    }

    /// <summary>
    /// ID'ye göre görev getirir
    /// </summary>
    [HttpGet("{id}")]
    public async Task<ActionResult<TaskEntity>> GetTaskById(int id, CancellationToken cancellationToken = default)
    {
        try
        {
            var task = await _taskRepository.GetByIdAsync(id, cancellationToken);

            if (task is null)
            {
                return NotFound(new { message = "Görev bulunamadı" });
            }

            return Ok(task);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Görev alınırken hata oluştu", error = ex.Message });
        }
    }

    /// <summary>
    /// Proje ID'sine göre görevleri getirir
    /// </summary>
    [HttpGet("project/{projectId}")]
    public async Task<ActionResult<IReadOnlyList<TaskEntity>>> GetTasksByProjectId(int projectId, CancellationToken cancellationToken = default)
    {
        try
        {
            // Önce projenin var olduğunu kontrol et
            var project = await _projectRepository.GetByIdAsync(projectId, cancellationToken);
            if (project is null)
            {
                return NotFound(new { message = "Proje bulunamadı" });
            }

            var tasks = await _taskRepository.FindAsync(t => t.ProjectId == projectId, cancellationToken);
            return Ok(tasks);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Proje görevleri alınırken hata oluştu", error = ex.Message });
        }
    }

    /// <summary>
    /// Statüye göre görevleri getirir
    /// </summary>
    [HttpGet("status/{status}")]
    public async Task<ActionResult<IReadOnlyList<TaskEntity>>> GetTasksByStatus(string status, CancellationToken cancellationToken = default)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(status))
            {
                return BadRequest(new { message = "Statü boş olamaz" });
            }

            var tasks = await _taskRepository.FindAsync(t => t.Status.ToLower() == status.ToLower(), cancellationToken);
            return Ok(tasks);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Statüye göre görevler alınırken hata oluştu", error = ex.Message });
        }
    }

    /// <summary>
    /// Yeni görev oluşturur
    /// </summary>
    [HttpPost]
    public async Task<ActionResult<TaskEntity>> CreateTask([FromBody] CreateTaskRequest request, CancellationToken cancellationToken = default)
    {
        try
        {
            // Validasyon
            if (string.IsNullOrWhiteSpace(request.Title))
            {
                return BadRequest(new { message = "Görev başlığı boş olamaz" });
            }

            if (string.IsNullOrWhiteSpace(request.Status))
            {
                return BadRequest(new { message = "Görev durumu boş olamaz" });
            }

            // Projenin var olduğunu kontrol et
            var project = await _projectRepository.GetByIdAsync(request.ProjectId, cancellationToken);
            if (project is null)
            {
                return BadRequest(new { message = "Geçersiz proje ID" });
            }

            var task = new TaskEntity
            {
                Title = request.Title,
                Description = request.Description ?? string.Empty,
                Status = request.Status,
                DueDate = request.DueDate,
                ProjectId = request.ProjectId
            };

            var createdTask = await _taskRepository.AddAsync(task, cancellationToken);
            await _taskRepository.SaveChangesAsync(cancellationToken);

            return CreatedAtAction(nameof(GetTaskById), new { id = createdTask.Id }, createdTask);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Görev oluşturulurken hata oluştu", error = ex.Message });
        }
    }

    /// <summary>
    /// Mevcut görevi günceller
    /// </summary>
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateTask(int id, [FromBody] UpdateTaskRequest request, CancellationToken cancellationToken = default)
    {
        try
        {
            var task = await _taskRepository.GetByIdAsync(id, cancellationToken);

            if (task is null)
            {
                return NotFound(new { message = "Görev bulunamadı" });
            }

            // Validasyon
            if (string.IsNullOrWhiteSpace(request.Title) && string.IsNullOrWhiteSpace(request.Description) &&
                string.IsNullOrWhiteSpace(request.Status) && !request.DueDate.HasValue && !request.ProjectId.HasValue)
            {
                return BadRequest(new { message = "Güncellenecek en az bir alan gereklidir" });
            }

            // Proje ID değişiyorsa, yeni projenin var olduğunu kontrol et
            if (request.ProjectId.HasValue && request.ProjectId.Value != task.ProjectId)
            {
                var project = await _projectRepository.GetByIdAsync(request.ProjectId.Value, cancellationToken);
                if (project is null)
                {
                    return BadRequest(new { message = "Geçersiz proje ID" });
                }
                task.ProjectId = request.ProjectId.Value;
            }

            if (!string.IsNullOrWhiteSpace(request.Title))
            {
                task.Title = request.Title;
            }

            if (!string.IsNullOrWhiteSpace(request.Description))
            {
                task.Description = request.Description;
            }

            if (!string.IsNullOrWhiteSpace(request.Status))
            {
                task.Status = request.Status;
            }

            if (request.DueDate.HasValue)
            {
                task.DueDate = request.DueDate.Value;
            }

            await _taskRepository.UpdateAsync(task, cancellationToken);
            await _taskRepository.SaveChangesAsync(cancellationToken);

            return Ok(new { message = "Görev başarıyla güncellendi", task });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Görev güncellenirken hata oluştu", error = ex.Message });
        }
    }

    /// <summary>
    /// Görevi siler
    /// </summary>
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteTask(int id, CancellationToken cancellationToken = default)
    {
        try
        {
            var task = await _taskRepository.GetByIdAsync(id, cancellationToken);

            if (task is null)
            {
                return NotFound(new { message = "Görev bulunamadı" });
            }

            await _taskRepository.DeleteAsync(task, cancellationToken);
            await _taskRepository.SaveChangesAsync(cancellationToken);

            return Ok(new { message = "Görev başarıyla silindi" });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Görev silinirken hata oluştu", error = ex.Message });
        }
    }

    /// <summary>
    /// Görev durumunu günceller (sürükle-bırak için kullanışlı)
    /// </summary>
    [HttpPatch("{id}/status")]
    public async Task<IActionResult> UpdateTaskStatus(int id, [FromBody] UpdateTaskStatusRequest request, CancellationToken cancellationToken = default)
    {
        try
        {
            var task = await _taskRepository.GetByIdAsync(id, cancellationToken);

            if (task is null)
            {
                return NotFound(new { message = "Görev bulunamadı" });
            }

            if (string.IsNullOrWhiteSpace(request.Status))
            {
                return BadRequest(new { message = "Yeni durum boş olamaz" });
            }

            task.Status = request.Status;

            await _taskRepository.UpdateAsync(task, cancellationToken);
            await _taskRepository.SaveChangesAsync(cancellationToken);

            return Ok(new { message = "Görev durumu güncellendi", task });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Görev durumu güncellenirken hata oluştu", error = ex.Message });
        }
    }

    /// <summary>
    /// Yaklaşan görevleri getirir (son teslim tarihi yaklaşan)
    /// </summary>
    [HttpGet("upcoming/{days}")]
    public async Task<ActionResult<IReadOnlyList<TaskEntity>>> GetUpcomingTasks(int days, CancellationToken cancellationToken = default)
    {
        try
        {
            if (days <= 0)
            {
                return BadRequest(new { message = "Gün sayısı pozitif olmalıdır" });
            }

            var futureDate = DateTime.UtcNow.AddDays(days);
            var tasks = await _taskRepository.FindAsync(t => t.DueDate <= futureDate && t.DueDate >= DateTime.UtcNow, cancellationToken);

            return Ok(tasks);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Yaklaşan görevler alınırken hata oluştu", error = ex.Message });
        }
    }
}

/// <summary>
/// Görev oluştururken gönderilen veriler
/// </summary>
public class CreateTaskRequest
{
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime DueDate { get; set; }
    public int ProjectId { get; set; }
}

/// <summary>
/// Görev güncellenirken gönderilen veriler
/// </summary>
public class UpdateTaskRequest
{
    public string? Title { get; set; }
    public string? Description { get; set; }
    public string? Status { get; set; }
    public DateTime? DueDate { get; set; }
    public int? ProjectId { get; set; }
}

/// <summary>
/// Görev durumu güncellenirken gönderilen veriler
/// </summary>
public class UpdateTaskStatusRequest
{
    public string Status { get; set; } = string.Empty;
}