using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using HelpBot_Data.Dapper;
using HelpBot_Model.DTO;
using HelpBot_Repo.IRepository;

namespace HelpBot_Repo.Repository
{
    public class AdminRepository : IAdminRepository
    {
        private readonly IDapperContext _dapperContext;

        public AdminRepository(IDapperContext dapperContext)
        {
            _dapperContext = dapperContext;
        }

        public async Task<AdminDashboardStatsDTO> GetDashboardStatsAsync()
        {
            var res = await _dapperContext.ProcedureHelper.QueryFirstOrDefaultAsync<AdminDashboardStatsDTO>(
                "dbo.sp_GetAdminDashboardStats"
            );
            return res ?? new AdminDashboardStatsDTO();
        }

        public async Task<IEnumerable<ChatHistoryItemDTO>> GetChatHistoryAsync(
            int? agentId = null, 
            string? status = null, 
            string? searchTerm = null, 
            DateTime? startDate = null, 
            DateTime? endDate = null)
        {
            var parameters = new
            {
                AgentId = agentId,
                Status = string.IsNullOrWhiteSpace(status) ? null : status,
                SearchTerm = string.IsNullOrWhiteSpace(searchTerm) ? null : searchTerm,
                StartDate = startDate,
                EndDate = endDate
            };
            return await _dapperContext.ProcedureHelper.QueryAsync<ChatHistoryItemDTO>(
                "dbo.sp_GetChatHistory",
                parameters
            );
        }

        public async Task<IEnumerable<AgentManageDTO>> GetAllAgentsAsync()
        {
            return await _dapperContext.ProcedureHelper.QueryAsync<AgentManageDTO>(
                "dbo.sp_GetAllAgents"
            );
        }

        public async Task<AgentManageDTO?> CreateAgentAsync(CreateAgentRequestDTO request)
        {
            var parameters = new
            {
                request.Name,
                request.Email,
                request.Password,
                request.Role
            };
            return await _dapperContext.ProcedureHelper.QueryFirstOrDefaultAsync<AgentManageDTO>(
                "dbo.sp_CreateAgent",
                parameters
            );
        }

        public async Task<AgentManageDTO?> UpdateAgentAsync(UpdateAgentRequestDTO request)
        {
            var parameters = new
            {
                request.AgentId,
                request.Name,
                request.Email,
                request.Password,
                request.Role,
                request.IsActive
            };
            return await _dapperContext.ProcedureHelper.QueryFirstOrDefaultAsync<AgentManageDTO>(
                "dbo.sp_UpdateAgent",
                parameters
            );
        }

        public async Task<bool> ToggleAgentActiveAsync(int agentId, bool isActive)
        {
            var parameters = new { AgentId = agentId, IsActive = isActive };
            var res = await _dapperContext.ProcedureHelper.QueryFirstOrDefaultAsync<dynamic>(
                "dbo.sp_ToggleAgentActive",
                parameters
            );
            return res != null;
        }

        public async Task<bool> DeleteAgentAsync(int agentId)
        {
            var parameters = new { AgentId = agentId };
            var res = await _dapperContext.ProcedureHelper.QueryFirstOrDefaultAsync<dynamic>(
                "dbo.sp_DeleteAgent",
                parameters
            );
            return res != null;
        }

        public async Task<bool> ResetAgentPasswordAsync(int agentId, string newPassword)
        {
            var parameters = new { AgentId = agentId, NewPassword = newPassword };
            var res = await _dapperContext.ProcedureHelper.QueryFirstOrDefaultAsync<dynamic>(
                "dbo.sp_ResetAgentPassword",
                parameters
            );
            return res != null;
        }
    }
}
