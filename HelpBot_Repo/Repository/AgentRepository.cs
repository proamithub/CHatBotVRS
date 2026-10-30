using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using HelpBot_Data.Dapper;
using HelpBot_Model.DTO;
using HelpBot_Repo.IRepository;

namespace HelpBot_Repo.Repository
{
    public class AgentRepository : IAgentRepository
    {
        private readonly IDapperContext _dapperContext;

        public AgentRepository(IDapperContext dapperContext)
        {
            _dapperContext = dapperContext;
        }

        public async Task<AgentDTO?> LoginAgentAsync(string email, string password)
        {
            var parameters = new { Email = email, Password = password };
            return await _dapperContext.ProcedureHelper.QueryFirstOrDefaultAsync<AgentDTO>(
                "dbo.sp_AgentLogin", 
                parameters
            );
        }

        public async Task<IEnumerable<LiveSessionDTO>> GetLiveChatQueueAsync(int? agentId = null)
        {
            var parameters = new { AgentId = agentId };
            return await _dapperContext.ProcedureHelper.QueryAsync<LiveSessionDTO>(
                "dbo.sp_GetLiveChatQueue", 
                parameters
            );
        }

        public async Task<LiveSessionDTO?> AcceptChatSessionAsync(Guid sessionId, int agentId, string agentName)
        {
            var parameters = new 
            { 
                SessionId = sessionId, 
                AgentId = agentId, 
                AgentName = agentName 
            };
            return await _dapperContext.ProcedureHelper.QueryFirstOrDefaultAsync<LiveSessionDTO>(
                "dbo.sp_AcceptChatSession", 
                parameters
            );
        }

        public async Task<ChatMessageDTO?> SendChatMessageAsync(SendChatMessageRequestDTO request)
        {
            var parameters = new
            {
                request.SessionId,
                request.SenderType,
                request.SenderName,
                request.MessageText,
                request.ThemeColor
            };
            return await _dapperContext.ProcedureHelper.QueryFirstOrDefaultAsync<ChatMessageDTO>(
                "dbo.sp_SendChatMessage", 
                parameters
            );
        }

        public async Task<IEnumerable<ChatMessageDTO>> GetChatMessagesAsync(Guid sessionId, long lastMessageId = 0)
        {
            var parameters = new { SessionId = sessionId, LastMessageId = lastMessageId };
            return await _dapperContext.ProcedureHelper.QueryAsync<ChatMessageDTO>(
                "dbo.sp_GetChatMessages", 
                parameters
            );
        }

        public async Task<LiveSessionDTO?> RequestLiveAgentAsync(Guid sessionId, string? userName, string? userContact = null, string? fatherName = null, string? rollNo = null)
        {
            var parameters = new 
            { 
                SessionId = sessionId, 
                UserName = userName,
                UserContact = userContact,
                FatherName = fatherName,
                RollNo = rollNo
            };
            return await _dapperContext.ProcedureHelper.QueryFirstOrDefaultAsync<LiveSessionDTO>(
                "dbo.sp_RequestLiveAgent", 
                parameters
            );
        }

        public async Task<bool> CloseChatSessionAsync(Guid sessionId, string closedBy)
        {
            var parameters = new { SessionId = sessionId, ClosedBy = closedBy };
            var res = await _dapperContext.ProcedureHelper.QueryFirstOrDefaultAsync<dynamic>(
                "dbo.sp_CloseChatSession", 
                parameters
            );
            return res != null;
        }

        public async Task<AgentDTO?> UpdateAgentThemeAsync(int agentId, string themeColor)
        {
            var parameters = new { AgentId = agentId, ThemeColor = themeColor };
            return await _dapperContext.ProcedureHelper.QueryFirstOrDefaultAsync<AgentDTO>(
                "dbo.sp_UpdateAgentTheme", 
                parameters
            );
        }

        public async Task<bool> SetAgentOnlineStatusAsync(int agentId, bool isOnline)
        {
            var parameters = new { AgentId = agentId, IsOnline = isOnline };
            var res = await _dapperContext.ProcedureHelper.QueryFirstOrDefaultAsync<dynamic>(
                "dbo.sp_SetAgentOnlineStatus",
                parameters
            );
            return res != null;
        }

        public async Task<AgentDTO?> GetAgentByIdAsync(int agentId)
        {
            var parameters = new { AgentId = agentId };
            return await _dapperContext.ProcedureHelper.QueryFirstOrDefaultAsync<AgentDTO>(
                "dbo.sp_GetAgentById", 
                parameters
            );
        }

        public async Task<bool> TransferChatSessionAsync(TransferChatRequestDTO request)
        {
            var parameters = new
            {
                request.SessionId,
                request.FromAgentId,
                request.FromAgentName,
                request.ToAgentId,
                request.ToAgentName,
                request.Reason
            };
            var res = await _dapperContext.ProcedureHelper.QueryFirstOrDefaultAsync<dynamic>(
                "dbo.sp_TransferChatSession",
                parameters
            );
            return res != null;
        }

        public async Task<IEnumerable<AgentDTO>> GetAvailableAgentsAsync(int? excludeAgentId = null)
        {
            var parameters = new { ExcludeAgentId = excludeAgentId };
            return await _dapperContext.ProcedureHelper.QueryAsync<AgentDTO>(
                "dbo.sp_GetAvailableAgents",
                parameters
            );
        }

        public async Task<LiveSessionDTO?> GetSessionDetailsAsync(Guid sessionId)
        {
            var parameters = new { SessionId = sessionId };
            return await _dapperContext.ProcedureHelper.QueryFirstOrDefaultAsync<LiveSessionDTO>(
                "dbo.sp_GetSessionDetails",
                parameters
            );
        }

        public async Task<bool> RequestUserUploadAsync(Guid sessionId, string agentName, string? prompt = null)
        {
            var parameters = new
            {
                SessionId = sessionId,
                AgentName = agentName,
                Prompt = prompt
            };
            var res = await _dapperContext.ProcedureHelper.QueryFirstOrDefaultAsync<dynamic>(
                "dbo.sp_RequestUserUpload",
                parameters
            );
            return res != null;
        }

        public async Task<ChatMessageDTO?> SaveUploadedFileMessageAsync(SaveUploadedFileDTO request)
        {
            var parameters = new
            {
                request.SessionId,
                request.SenderType,
                request.SenderName,
                request.MessageText,
                request.AttachmentUrl,
                request.AttachmentType,
                request.AttachmentName
            };
            return await _dapperContext.ProcedureHelper.QueryFirstOrDefaultAsync<ChatMessageDTO>(
                "dbo.sp_SaveUploadedFileMessage",
                parameters
            );
        }
    }
}
