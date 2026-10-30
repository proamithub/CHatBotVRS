using System;
using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using HelpBot_Model.DTO;
using HelpBot_Repo;

namespace HelpBot_UI.Controllers
{
    [Authorize(Roles = "Admin")]
    public class AdminController : Controller
    {
        private readonly IUnitOfWork _unitOfWork;

        public AdminController(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        // GET: /Admin/Dashboard
        [HttpGet]
        public async Task<IActionResult> Dashboard()
        {
            ViewBag.AdminName = User.Identity?.Name ?? "Administrator";
            ViewBag.AdminEmail = User.FindFirst(ClaimTypes.Email)?.Value ?? "";
            string agentIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0";
            ViewBag.AgentId = agentIdStr;

            if (int.TryParse(agentIdStr, out int agentId) && agentId > 0)
            {
                await _unitOfWork.AgentRepo.SetAgentOnlineStatusAsync(agentId, true);
            }

            return View();
        }

        // GET: /api/admin/stats
        [HttpGet("/api/admin/stats")]
        public async Task<IActionResult> GetDashboardStats()
        {
            try
            {
                var stats = await _unitOfWork.AdminRepo.GetDashboardStatsAsync();
                return Ok(new { success = true, data = stats });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = ex.Message });
            }
        }

        // GET: /api/admin/history
        [HttpGet("/api/admin/history")]
        public async Task<IActionResult> GetChatHistory(
            [FromQuery] int? agentId = null,
            [FromQuery] string? status = null,
            [FromQuery] string? searchTerm = null,
            [FromQuery] DateTime? startDate = null,
            [FromQuery] DateTime? endDate = null)
        {
            try
            {
                var history = await _unitOfWork.AdminRepo.GetChatHistoryAsync(agentId, status, searchTerm, startDate, endDate);
                return Ok(new { success = true, data = history });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = ex.Message });
            }
        }

        // GET: /api/admin/session-transcript?sessionId=...
        [HttpGet("/api/admin/session-transcript")]
        public async Task<IActionResult> GetSessionTranscript([FromQuery] Guid sessionId)
        {
            try
            {
                if (sessionId == Guid.Empty)
                {
                    return BadRequest(new { success = false, message = "Session ID is required." });
                }

                var session = await _unitOfWork.AgentRepo.GetSessionDetailsAsync(sessionId);
                var messages = await _unitOfWork.AgentRepo.GetChatMessagesAsync(sessionId, 0);

                return Ok(new { success = true, session, messages });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = ex.Message });
            }
        }

        // GET: /api/admin/agents
        [HttpGet("/api/admin/agents")]
        public async Task<IActionResult> GetAllAgents()
        {
            try
            {
                var agents = await _unitOfWork.AdminRepo.GetAllAgentsAsync();
                return Ok(new { success = true, data = agents });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = ex.Message });
            }
        }

        // POST: /api/admin/create-agent
        [HttpPost("/api/admin/create-agent")]
        public async Task<IActionResult> CreateAgent([FromBody] CreateAgentRequestDTO model)
        {
            try
            {
                if (model == null || string.IsNullOrWhiteSpace(model.Name) || string.IsNullOrWhiteSpace(model.Email) || string.IsNullOrWhiteSpace(model.Password))
                {
                    return BadRequest(new { success = false, message = "Name, Email, and Password are required." });
                }

                var created = await _unitOfWork.AdminRepo.CreateAgentAsync(model);
                return Ok(new { success = true, data = created, message = "Agent created successfully." });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = ex.Message });
            }
        }

        // POST: /api/admin/update-agent
        [HttpPost("/api/admin/update-agent")]
        public async Task<IActionResult> UpdateAgent([FromBody] UpdateAgentRequestDTO model)
        {
            try
            {
                if (model == null || model.AgentId <= 0 || string.IsNullOrWhiteSpace(model.Name) || string.IsNullOrWhiteSpace(model.Email))
                {
                    return BadRequest(new { success = false, message = "Valid Agent ID, Name, and Email are required." });
                }

                var updated = await _unitOfWork.AdminRepo.UpdateAgentAsync(model);
                return Ok(new { success = true, data = updated, message = "Agent updated successfully." });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = ex.Message });
            }
        }

        // POST: /api/admin/toggle-agent-status
        [HttpPost("/api/admin/toggle-agent-status")]
        public async Task<IActionResult> ToggleAgentStatus([FromBody] System.Text.Json.JsonElement body)
        {
            try
            {
                int agentId = body.GetProperty("agentId").GetInt32();
                bool isActive = body.GetProperty("isActive").GetBoolean();

                int currentAdminId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
                if (agentId == currentAdminId && !isActive)
                {
                    return BadRequest(new { success = false, message = "You cannot deactivate your own admin account." });
                }

                var ok = await _unitOfWork.AdminRepo.ToggleAgentActiveAsync(agentId, isActive);
                return Ok(new { success = ok, isActive, message = isActive ? "Agent activated." : "Agent deactivated." });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = ex.Message });
            }
        }

        // POST: /api/admin/delete-agent
        [HttpPost("/api/admin/delete-agent")]
        public async Task<IActionResult> DeleteAgent([FromBody] System.Text.Json.JsonElement body)
        {
            try
            {
                int agentId = body.GetProperty("agentId").GetInt32();
                int currentAdminId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
                if (agentId == currentAdminId)
                {
                    return BadRequest(new { success = false, message = "You cannot delete your own admin account." });
                }

                var ok = await _unitOfWork.AdminRepo.DeleteAgentAsync(agentId);
                return Ok(new { success = ok, message = "Agent removed successfully." });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = ex.Message });
            }
        }

        // POST: /api/admin/reset-agent-password
        [HttpPost("/api/admin/reset-agent-password")]
        public async Task<IActionResult> ResetAgentPassword([FromBody] System.Text.Json.JsonElement body)
        {
            try
            {
                int agentId = body.GetProperty("agentId").GetInt32();
                string newPassword = body.GetProperty("newPassword").GetString() ?? "";

                if (string.IsNullOrWhiteSpace(newPassword))
                {
                    return BadRequest(new { success = false, message = "Password cannot be empty." });
                }

                var ok = await _unitOfWork.AdminRepo.ResetAgentPasswordAsync(agentId, newPassword.Trim());
                return Ok(new { success = ok, message = "Password reset successfully." });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = ex.Message });
            }
        }

        // POST: /api/admin/transfer-chat
        [HttpPost("/api/admin/transfer-chat")]
        public async Task<IActionResult> TransferChat([FromBody] TransferChatRequestDTO model)
        {
            try
            {
                if (model == null || model.SessionId == Guid.Empty || model.ToAgentId <= 0)
                {
                    return BadRequest(new { success = false, message = "Invalid transfer request." });
                }

                int adminId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
                string adminName = User.Identity?.Name ?? "Administrator";

                model.FromAgentId = adminId;
                model.FromAgentName = $"Admin ({adminName})";

                var targetAgent = await _unitOfWork.AgentRepo.GetAgentByIdAsync(model.ToAgentId);
                if (targetAgent == null)
                {
                    return BadRequest(new { success = false, message = "Target agent not found." });
                }
                model.ToAgentName = targetAgent.Name;

                var ok = await _unitOfWork.AgentRepo.TransferChatSessionAsync(model);
                return Ok(new { success = ok, message = $"Chat transferred to {targetAgent.Name}." });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = ex.Message });
            }
        }

        // POST: /api/admin/close-chat
        [HttpPost("/api/admin/close-chat")]
        public async Task<IActionResult> CloseChat([FromBody] CloseChatRequestDTO model)
        {
            try
            {
                string adminName = User.Identity?.Name ?? "Administrator";
                var res = await _unitOfWork.AgentRepo.CloseChatSessionAsync(model.SessionId, $"Admin ({adminName})");
                return Ok(new { success = true, data = res });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = ex.Message });
            }
        }
    }
}
