using Microsoft.AspNetCore.Mvc;

namespace API.Controllers;

[Route("api/files")]
[ApiController]
public class FilesController : ControllerBase
{
    private readonly string _uploadsPath = Path.Combine(Directory.GetCurrentDirectory(), "uploads");

    [HttpGet]
    public ActionResult<IEnumerable<string>> GetFiles()
    {
        try
        {
            var files = Directory.GetFiles(_uploadsPath)
                .Select(file => $"{Request.Scheme}://{Request.Host}/uploads/{Path.GetFileName(file)}")
                .ToList();

            return Ok(new { fileUrls = files });
        }
        catch (Exception ex)
        {
            return StatusCode(500, $"Internal server error: {ex.Message}");
        }
    }
}