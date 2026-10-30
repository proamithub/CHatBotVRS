using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using HelpBot_Model.DTO;

namespace HelpBot_Repo.IRepository
{
    public interface IAgentRepository
    {
        Task<AgentDTO?> LoginAgentAsync(string email, string password);
        Task<IEnumerable<LiveSessionDTO>> GetLiveChatQueueAsync(int? agentId = null);
        Task<LiveSessionDTO?> AcceptChatSessionAsync(Guid sessionId, int agentId, string agentName);
        Task<ChatMessageDTO?> SendChatMessageAsync(SendChatMessageRequestDTO request);
        Task<IEnumerable<ChatMessageDTO>> GetChatMessagesAsync(Guid sessionId, long lastMessageId = 0);
        Task<LiveSessionDTO?> RequestLiveAgentAsync(Guid sessionId, string? userName, string? userContact = null, string? fatherName = null, string? rollNo = null);
        Task<bool> CloseChatSessionAsync(Guid sessionId, string closedBy);
        Task<AgentDTO?> UpdateAgentThemeAsync(int agentId, string themeColor);
        Task<bool> SetAgentOnlineStatusAsync(int agentId, bool isOnline);
        Task<AgentDTO?> GetAgentByIdAsync(int agentId);
        Task<bool> TransferChatSessionAsync(TransferChatRequestDTO request);
        Task<IEnumerable<AgentDTO>> GetAvailableAgentsAsync(int? excludeAgentId = null);
        Task<LiveSessionDTO?> GetSessionDetailsAsync(Guid sessionId);
        Task<bool> RequestUserUploadAsync(Guid sessionId, string agentName, string? prompt = null);
        Task<ChatMessageDTO?> SaveUploadedFileMessageAsync(SaveUploadedFileDTO request);
    }
}
