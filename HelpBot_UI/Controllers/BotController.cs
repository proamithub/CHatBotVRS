using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using HelpBot_Model.DTO;
using HelpBot_Repo;

namespace HelpBot_UI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class BotController : ControllerBase
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly IWebHostEnvironment _env;
        private readonly IConfiguration _config;

        public BotController(IUnitOfWork unitOfWork, IWebHostEnvironment env, IConfiguration config)
        {
            _unitOfWork = unitOfWork;
            _env = env;
            _config = config;
        }

        // GET: api/bot/questions
        [HttpGet("questions")]
        public async Task<IActionResult> GetQuestions()
        {
            try
            {
                var questions = await _unitOfWork.BotRepo.GetBotQuestionsAsync();
                return Ok(new { success = true, data = questions });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = ex.Message });
            }
        }

        // GET: api/bot/categories
        [HttpGet("categories")]
        public async Task<IActionResult> GetCategories()
        {
            try
            {
                var categories = await _unitOfWork.BotRepo.GetComplaintTypesAsync();
                return Ok(new { success = true, data = categories });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = ex.Message });
            }
        }

        // POST: api/bot/save-response
        [HttpPost("save-response")]
        public async Task<IActionResult> SaveResponse([FromBody] SaveResponseRequestDTO model)
        {
            try
            {
                if (model == null || model.SessionId == Guid.Empty)
                {
                    return BadRequest(new { success = false, message = "Invalid session data" });
                }

                var result = await _unitOfWork.BotRepo.SaveBotResponseAsync(model);
                return Ok(new { success = true, data = result });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = ex.Message });
            }
        }

        // POST: api/bot/create-ticket
        [HttpPost("create-ticket")]
        public async Task<IActionResult> CreateTicket([FromBody] CreateTicketRequestDTO model)
        {
            try
            {
                // --- TICKET CREATION LOCK ---
                // Admin can toggle this in appsettings.json → AppSettings:NewTicketCreationLocked
                bool isLocked = _config.GetValue<bool>("AppSettings:NewTicketCreationLocked", false);
                if (isLocked)
                {
                    return StatusCode(423, new
                    {
                        success = false,
                        locked = true,
                        message = "New ticket creation is currently disabled by the admin. Please try again later or contact support directly."
                    });
                }

                if (string.IsNullOrWhiteSpace(model.Name) || string.IsNullOrWhiteSpace(model.Subject))
                {
                    return BadRequest(new { success = false, message = "Name and Problem details are required." });
                }

                var createdTicket = await _unitOfWork.BotRepo.CreateTicketAsync(model);
                return Ok(new { success = true, data = createdTicket });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = ex.Message });
            }
        }

        // GET: api/bot/track-ticket?searchTerm=MVVU-2600101
        [HttpGet("track-ticket")]
        public async Task<IActionResult> TrackTicket([FromQuery] string searchTerm)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(searchTerm))
                {
                    return BadRequest(new { success = false, message = "Please enter Ticket ID or Roll No." });
                }

                var tickets = await _unitOfWork.BotRepo.GetTicketStatusAsync(searchTerm.Trim());
                return Ok(new { success = true, data = tickets });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = ex.Message });
            }
        }

        // POST: api/bot/request-agent
        [HttpPost("request-agent")]
        public async Task<IActionResult> RequestLiveAgent([FromBody] LiveSessionDTO model)
        {
            try
            {
                if (model == null || model.SessionId == Guid.Empty)
                {
                    return BadRequest(new { success = false, message = "Session ID is required." });
                }

                var session = await _unitOfWork.AgentRepo.RequestLiveAgentAsync(
                    model.SessionId, 
                    model.UserName, 
                    model.UserContact, 
                    model.FatherName, 
                    model.RollNo
                );
                return Ok(new { 
                    success = true, 
                    data = session,
                    agentOnline = session != null && session.OnlineAgentCount > 0,
                    onlineAgentCount = session?.OnlineAgentCount ?? 0
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = ex.Message });
            }
        }

        // POST: api/bot/send-message
        [HttpPost("send-message")]
        public async Task<IActionResult> SendUserMessage([FromBody] SendChatMessageRequestDTO model)
        {
            try
            {
                if (model == null || string.IsNullOrWhiteSpace(model.MessageText))
                {
                    return BadRequest(new { success = false, message = "Message is required." });
                }

                model.SenderType = "User";
                if (string.IsNullOrWhiteSpace(model.SenderName)) model.SenderName = "Student";

                var msg = await _unitOfWork.AgentRepo.SendChatMessageAsync(model);
                return Ok(new { success = true, data = msg });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = ex.Message });
            }
        }

        // GET: api/bot/messages?sessionId=...&lastId=...
        [HttpGet("messages")]
        public async Task<IActionResult> GetMessages([FromQuery] Guid sessionId, [FromQuery] long lastId = 0)
        {
            try
            {
                var messages = await _unitOfWork.AgentRepo.GetChatMessagesAsync(sessionId, lastId);
                return Ok(new { success = true, data = messages });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = ex.Message });
            }
        }

        // GET: api/bot/session-status?sessionId=...
        [HttpGet("session-status")]
        public async Task<IActionResult> GetSessionStatus([FromQuery] Guid sessionId)
        {
            try
            {
                var session = await _unitOfWork.AgentRepo.GetSessionDetailsAsync(sessionId);
                return Ok(new { success = true, data = session });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = ex.Message });
            }
        }

        // POST: api/bot/upload-file
        [HttpPost("upload-file")]
        public async Task<IActionResult> UploadFile([FromForm] Guid sessionId, [FromForm] IFormFile? file, [FromForm] string? senderName = null)
        {
            try
            {
                if (sessionId == Guid.Empty || file == null || file.Length == 0)
                {
                    return BadRequest(new { success = false, message = "Valid session ID and file are required." });
                }

                // Check if agent has activated file upload permission
                var session = await _unitOfWork.AgentRepo.GetSessionDetailsAsync(sessionId);
                if (session == null)
                {
                    return BadRequest(new { success = false, message = "Session not found." });
                }

                if (!session.IsUploadAllowed)
                {
                    return BadRequest(new { success = false, message = "File upload is not currently requested by the agent." });
                }

                // Check file size (max 2MB limit: 2 * 1024 * 1024 bytes)
                const long maxFileSize = 2 * 1024 * 1024;
                if (file.Length > maxFileSize)
                {
                    return BadRequest(new { success = false, message = "File size exceeds the 2MB limit. Please upload a file under 2MB." });
                }

                // Extension check
                var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".webp", ".gif", ".pdf", ".doc", ".docx", ".xls", ".xlsx", ".txt", ".zip" };
                var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
                if (!allowedExtensions.Contains(ext))
                {
                    return BadRequest(new { success = false, message = "Unsupported file type. Please upload images, PDFs, or office documents." });
                }

                // Determine folder & file paths
                string webRoot = _env.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
                string uploadsDir = Path.Combine(webRoot, "uploads", "chat");
                if (!Directory.Exists(uploadsDir))
                {
                    Directory.CreateDirectory(uploadsDir);
                }

                string safeFileName = Path.GetFileName(file.FileName);
                string uniqueFileName = $"{Guid.NewGuid():N}_{safeFileName}";
                string physicalPath = Path.Combine(uploadsDir, uniqueFileName);

                using (var stream = new FileStream(physicalPath, FileMode.Create))
                {
                    await file.CopyToAsync(stream);
                }

                string relativeUrl = $"/uploads/chat/{uniqueFileName}";
                bool isImage = ext == ".jpg" || ext == ".jpeg" || ext == ".png" || ext == ".webp" || ext == ".gif";
                string attachmentType = isImage ? "image" : "document";

                // Save message into Chat_Messages and immediately reset IsUploadAllowed to 0
                var saveDto = new SaveUploadedFileDTO
                {
                    SessionId = sessionId,
                    SenderType = "User",
                    SenderName = string.IsNullOrWhiteSpace(senderName) ? (session.UserName ?? "Student") : senderName,
                    MessageText = $"[Attachment] {safeFileName}",
                    AttachmentUrl = relativeUrl,
                    AttachmentType = attachmentType,
                    AttachmentName = safeFileName
                };

                var savedMessage = await _unitOfWork.AgentRepo.SaveUploadedFileMessageAsync(saveDto);

                return Ok(new
                {
                    success = true,
                    data = savedMessage,
                    message = "File uploaded successfully."
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = ex.Message });
            }
        }
    }
}
