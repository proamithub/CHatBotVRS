using System;
using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using HelpBot_Model.DTO;
using HelpBot_Repo;

namespace HelpBot_UI.Controllers
{
    [Authorize]
    public class AgentController : Controller
    {
        private readonly IUnitOfWork _unitOfWork;

        public AgentController(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        // GET: /Agent/Dashboard
        [HttpGet]
        public async Task<IActionResult> Dashboard()
        {
            ViewBag.AgentName = User.Identity?.Name ?? "Support Agent";
            ViewBag.AgentEmail = User.FindFirst(ClaimTypes.Email)?.Value ?? "";
            string agentIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0";
            ViewBag.AgentId = agentIdStr;
            ViewBag.IsAdmin = User.IsInRole("Admin");

            if (int.TryParse(agentIdStr, out int agentId) && agentId > 0)
            {
                // Always mark active agent as online in DB
                await _unitOfWork.AgentRepo.SetAgentOnlineStatusAsync(agentId, true);

                // Fetch fresh theme from DB
                var agent = await _unitOfWork.AgentRepo.GetAgentByIdAsync(agentId);
                ViewBag.AgentTheme = agent?.ThemeColor ?? "emerald";
            }
            else
            {
                ViewBag.AgentTheme = "emerald";
            }

            return View();
        }

        // GET: /api/agent/queue
        [HttpGet("/api/agent/queue")]
        public async Task<IActionResult> GetQueue()
        {
            try
            {
                if (int.TryParse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value, out int agentId) && agentId > 0)
                {
                    // Active heartbeat: keep online while dashboard is open
                    await _unitOfWork.AgentRepo.SetAgentOnlineStatusAsync(agentId, true);
                }

                var queue = await _unitOfWork.AgentRepo.GetLiveChatQueueAsync(agentId > 0 ? agentId : (int?)null);
                return Ok(new { success = true, data = queue });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = ex.Message });
            }
        }

        // POST: /api/agent/accept
        [HttpPost("/api/agent/accept")]
        public async Task<IActionResult> AcceptChat([FromBody] AcceptChatRequestDTO model)
        {
            try
            {
                if (model == null || model.SessionId == Guid.Empty)
                {
                    return BadRequest(new { success = false, message = "Invalid session." });
                }

                int agentId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
                string agentName = User.Identity?.Name ?? "Support Agent";

                var session = await _unitOfWork.AgentRepo.AcceptChatSessionAsync(model.SessionId, agentId, agentName);
                if (session == null || session.AssignedAgentId != agentId)
                {
                    return Ok(new { success = false, message = "This chat has already been accepted by another agent." });
                }
                return Ok(new { success = true, data = session });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = ex.Message });
            }
        }

        // GET: /api/agent/available-agents
        [HttpGet("/api/agent/available-agents")]
        public async Task<IActionResult> GetAvailableAgents()
        {
            try
            {
                int.TryParse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value, out int currentAgentId);
                var agents = await _unitOfWork.AgentRepo.GetAvailableAgentsAsync(currentAgentId > 0 ? currentAgentId : (int?)null);
                return Ok(new { success = true, data = agents });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = ex.Message });
            }
        }

        // POST: /api/agent/transfer
        [HttpPost("/api/agent/transfer")]
        public async Task<IActionResult> TransferChat([FromBody] TransferChatRequestDTO model)
        {
            try
            {
                if (model == null || model.SessionId == Guid.Empty || model.ToAgentId <= 0)
                {
                    return BadRequest(new { success = false, message = "Invalid transfer request." });
                }

                int currentAgentId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
                string currentAgentName = User.Identity?.Name ?? "Support Agent";

                model.FromAgentId = currentAgentId;
                model.FromAgentName = currentAgentName;

                var targetAgent = await _unitOfWork.AgentRepo.GetAgentByIdAsync(model.ToAgentId);
                if (targetAgent == null)
                {
                    return BadRequest(new { success = false, message = "Selected agent was not found." });
                }
                model.ToAgentName = targetAgent.Name;

                var ok = await _unitOfWork.AgentRepo.TransferChatSessionAsync(model);
                if (ok)
                {
                    return Ok(new { success = true, message = $"Chat transferred to {targetAgent.Name} successfully." });
                }

                return StatusCode(500, new { success = false, message = "Failed to transfer chat." });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = ex.Message });
            }
        }

        // GET: /api/agent/messages?sessionId=...&lastId=...
        [HttpGet("/api/agent/messages")]
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

        // POST: /api/agent/send
        [HttpPost("/api/agent/send")]
        public async Task<IActionResult> SendMessage([FromBody] SendChatMessageRequestDTO model)
        {
            try
            {
                if (model == null || string.IsNullOrWhiteSpace(model.MessageText))
                {
                    return BadRequest(new { success = false, message = "Message is empty." });
                }

                model.SenderType = "Agent";
                model.SenderName = User.Identity?.Name ?? "Support Agent";
                if (string.IsNullOrWhiteSpace(model.ThemeColor))
                {
                    model.ThemeColor = User.FindFirst("ThemeColor")?.Value ?? "emerald";
                }

                var sent = await _unitOfWork.AgentRepo.SendChatMessageAsync(model);
                return Ok(new { success = true, data = sent });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = ex.Message });
            }
        }

        // POST: /api/agent/update-theme
        [HttpPost("/api/agent/update-theme")]
        public async Task<IActionResult> UpdateTheme([FromBody] UpdateThemeRequestDTO model)
        {
            try
            {
                int agentId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
                if (agentId == 0) return Unauthorized();

                var updated = await _unitOfWork.AgentRepo.UpdateAgentThemeAsync(agentId, model.ThemeColor ?? "emerald");
                return Ok(new { success = true, data = updated });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = ex.Message });
            }
        }

        // POST: /api/agent/toggle-status
        [HttpPost("/api/agent/toggle-status")]
        public async Task<IActionResult> ToggleStatus([FromBody] System.Text.Json.JsonElement body)
        {
            try
            {
                if (int.TryParse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value, out int agentId))
                {
                    bool isOnline = body.GetProperty("isOnline").GetBoolean();
                    await _unitOfWork.AgentRepo.SetAgentOnlineStatusAsync(agentId, isOnline);
                    return Ok(new { success = true, isOnline });
                }
                return Unauthorized();
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = ex.Message });
            }
        }

        // POST: /api/agent/request-upload
        [HttpPost("/api/agent/request-upload")]
        public async Task<IActionResult> RequestUpload([FromBody] RequestUploadDTO model)
        {
            try
            {
                if (model == null || model.SessionId == Guid.Empty)
                {
                    return BadRequest(new { success = false, message = "Invalid session." });
                }

                string agentName = User.Identity?.Name ?? "Support Agent";
                var ok = await _unitOfWork.AgentRepo.RequestUserUploadAsync(model.SessionId, agentName, model.Prompt);
                return Ok(new { success = ok, message = "File upload requested. Student can now upload a document/image." });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = ex.Message });
            }
        }

        // POST: /api/agent/close
        [HttpPost("/api/agent/close")]
        public async Task<IActionResult> CloseChat([FromBody] CloseChatRequestDTO model)
        {
            try
            {
                string closedBy = User.Identity?.Name ?? "Support Agent";
                var res = await _unitOfWork.AgentRepo.CloseChatSessionAsync(model.SessionId, closedBy);
                return Ok(new { success = true, data = res });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = ex.Message });
            }
        }
    }
}
