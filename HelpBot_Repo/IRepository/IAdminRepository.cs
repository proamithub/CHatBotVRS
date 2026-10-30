using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using HelpBot_Model.DTO;

namespace HelpBot_Repo.IRepository
{
    public interface IAdminRepository
    {
        Task<AdminDashboardStatsDTO> GetDashboardStatsAsync();
        Task<IEnumerable<ChatHistoryItemDTO>> GetChatHistoryAsync(int? agentId = null, string? status = null, string? searchTerm = null, DateTime? startDate = null, DateTime? endDate = null);
        Task<IEnumerable<AgentManageDTO>> GetAllAgentsAsync();
        Task<AgentManageDTO?> CreateAgentAsync(CreateAgentRequestDTO request);
        Task<AgentManageDTO?> UpdateAgentAsync(UpdateAgentRequestDTO request);
        Task<bool> ToggleAgentActiveAsync(int agentId, bool isActive);
        Task<bool> DeleteAgentAsync(int agentId);
        Task<bool> ResetAgentPasswordAsync(int agentId, string newPassword);
    }
}
