using Microsoft.AspNetCore.Mvc;
using System.Diagnostics;

namespace API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class UploadController : ControllerBase
{
    private readonly IWebHostEnvironment _env;
    private readonly ILogger<UploadController> _logger;
    private readonly string _fileUrlStoragePath;

    public UploadController(IWebHostEnvironment env, ILogger<UploadController> logger)
    {
        _env = env;
        _logger = logger;
        _fileUrlStoragePath = Path.Combine(_env.ContentRootPath, "uploads", "fileUrls.txt"); // Dateipfad für die Speicherung der URLs
    }

    [HttpPost]
    [Route("upload")]
    public async Task<IActionResult> UploadFiles(IFormFile[] files)
    {
        if (files == null || files.Length == 0)
        {
            _logger.LogInformation("Upload leer");
            return BadRequest("No files uploaded.");
        }

        var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".mp4", ".mov" };
        var uploadedFileUrls = new List<string>();

        // Lade die bisherigen URLs aus der Datei (falls vorhanden)
        if (System.IO.File.Exists(_fileUrlStoragePath))
        {
            uploadedFileUrls = System.IO.File.ReadAllLines(_fileUrlStoragePath).ToList();
        }

        foreach (var file in files)
        {
            var extension = Path.GetExtension(file.FileName).ToLower();
            if (!allowedExtensions.Contains(extension))
            {
                _logger.LogInformation("Unsupported file type.");
                return BadRequest($"Unsupported file type: {extension}");
            }

            var uploads = Path.Combine(_env.ContentRootPath, "uploads");
            if (!Directory.Exists(uploads))
            {
                Directory.CreateDirectory(uploads);
            }

            var uniqueFileName = $"{Guid.NewGuid()}{extension}";
            var filePath = Path.Combine(uploads, uniqueFileName);
            var fileUrl = $"{Request.Scheme}://{Request.Host}/uploads/{uniqueFileName}";

            // Speichere die Datei sofort
            using (var fileStream = new FileStream(filePath, FileMode.Create))
            {
                await file.CopyToAsync(fileStream);
            }

            // Wenn die Datei .mov ist, konvertiere sie sofort
            if (extension == ".mov")
            {
                var mp4FileName = $"{Guid.NewGuid()}.mp4";
                var mp4FilePath = Path.Combine(uploads, mp4FileName);
                var mp4FileUrl = $"{Request.Scheme}://{Request.Host}/uploads/{mp4FileName}";

                // Konvertiere die Datei und warte auf das Ergebnis
                var conversionResult = await Task.Run(() => ConvertMovToMp4(filePath, mp4FilePath));
                if (conversionResult)
                {
                    System.IO.File.Delete(filePath); // Lösche die ursprüngliche .mov-Datei
                    uploadedFileUrls.Add(mp4FileUrl);
                }
                else
                {
                    return StatusCode(500, "Error converting .mov to .mp4");
                }
            }
            else
            {
                uploadedFileUrls.Add(fileUrl);
            }
        }

        // Speichere die kombinierten URLs in der Datei
        System.IO.File.WriteAllLines(_fileUrlStoragePath, uploadedFileUrls);

        _logger.LogInformation("Files uploaded successfully.");
        return Ok(new { fileUrls = uploadedFileUrls });
    }

    [HttpGet("files")]
    public IActionResult GetUploadedFiles()
    {
        // Lade die URLs aus der Datei (falls vorhanden)
        if (!System.IO.File.Exists(_fileUrlStoragePath))
        {
            return NotFound("No files found.");
        }

        var fileUrls = System.IO.File.ReadAllLines(_fileUrlStoragePath).ToList();
        return Ok(new { fileUrls });
    }

    private bool ConvertMovToMp4(string inputFilePath, string outputFilePath)
    {
        var ffmpegPath = "ffmpeg"; // Ensure ffmpeg is in your system PATH

        var process = new Process
        {
            StartInfo = new ProcessStartInfo
            {
                FileName = ffmpegPath,
                Arguments = $"-i \"{inputFilePath}\" \"{outputFilePath}\"",
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
                CreateNoWindow = true,
            }
        };

        process.Start();

        string output = process.StandardOutput.ReadToEnd();
        string error = process.StandardError.ReadToEnd();

        process.WaitForExit();

        if (process.ExitCode != 0)
        {
            Console.WriteLine($"FFmpeg Error: {error}");
            return false;
        }

        return true;
    }
}
