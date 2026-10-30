using System;

namespace HelpBot_Model.DTO
{
    public class AgentDTO
    {
        public int AgentId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Role { get; set; } = string.Empty;
        public string ThemeColor { get; set; } = "emerald";
        public bool IsOnline { get; set; }
        public bool IsActive { get; set; }
    }

    public class AgentLoginRequestDTO
    {
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
    }

    public class LiveSessionDTO
    {
        public Guid SessionId { get; set; }
        public string UserName { get; set; } = string.Empty;
        public string UserContact { get; set; } = string.Empty;
        public string? FatherName { get; set; }
        public string? RollNo { get; set; }
        public string Status { get; set; } = "Bot";
        public bool IsUploadAllowed { get; set; }
        public int? AssignedAgentId { get; set; }
        public string? AssignedAgentName { get; set; }
        public DateTime CreatedDate { get; set; }
        public DateTime? ConnectedDate { get; set; }
        public DateTime LastActivityAt { get; set; }
        public int TotalMessages { get; set; }
        public string? LastMessage { get; set; }
        public int OnlineAgentCount { get; set; }
    }

    public class ChatMessageDTO
    {
        public long MessageId { get; set; }
        public Guid SessionId { get; set; }
        public string SenderType { get; set; } = string.Empty; // 'User', 'Agent', 'Bot'
        public string SenderName { get; set; } = string.Empty;
        public string MessageText { get; set; } = string.Empty;
        public string? AttachmentUrl { get; set; }
        public string? AttachmentType { get; set; } // 'image', 'document'
        public string? AttachmentName { get; set; }
        public string? ThemeColor { get; set; }
        public DateTime SentAt { get; set; }
    }

    public class SendChatMessageRequestDTO
    {
        public Guid SessionId { get; set; }
        public string SenderType { get; set; } = "User"; // 'User' or 'Agent'
        public string SenderName { get; set; } = string.Empty;
        public string MessageText { get; set; } = string.Empty;
        public string? AttachmentUrl { get; set; }
        public string? AttachmentType { get; set; }
        public string? AttachmentName { get; set; }
        public string? ThemeColor { get; set; }
    }

    public class AcceptChatRequestDTO
    {
        public Guid SessionId { get; set; }
        public int AgentId { get; set; }
        public string AgentName { get; set; } = string.Empty;
    }

    public class CloseChatRequestDTO
    {
        public Guid SessionId { get; set; }
        public string ClosedBy { get; set; } = string.Empty;
    }

    public class UpdateThemeRequestDTO
    {
        public int AgentId { get; set; }
        public string ThemeColor { get; set; } = "emerald";
    }

    public class TransferChatRequestDTO
    {
        public Guid SessionId { get; set; }
        public int FromAgentId { get; set; }
        public string FromAgentName { get; set; } = string.Empty;
        public int ToAgentId { get; set; }
        public string ToAgentName { get; set; } = string.Empty;
        public string? Reason { get; set; }
    }

    public class RequestUploadDTO
    {
        public Guid SessionId { get; set; }
        public string? Prompt { get; set; }
    }

    public class SaveUploadedFileDTO
    {
        public Guid SessionId { get; set; }
        public string SenderType { get; set; } = "User";
        public string SenderName { get; set; } = "Student";
        public string MessageText { get; set; } = string.Empty;
        public string AttachmentUrl { get; set; } = string.Empty;
        public string AttachmentType { get; set; } = "document";
        public string AttachmentName { get; set; } = string.Empty;
    }

    public class AdminDashboardStatsDTO
    {
        public int TotalSessions { get; set; }
        public int LiveSessions { get; set; }
        public int WaitingSessions { get; set; }
        public int ClosedSessions { get; set; }
        public int TotalAgents { get; set; }
        public int OnlineAgents { get; set; }
        public int TotalMessages { get; set; }
        public int TotalTickets { get; set; }
    }

    public class ChatHistoryItemDTO
    {
        public Guid SessionId { get; set; }
        public string UserName { get; set; } = string.Empty;
        public string UserContact { get; set; } = string.Empty;
        public string? FatherName { get; set; }
        public string? RollNo { get; set; }
        public string Status { get; set; } = string.Empty;
        public int? AssignedAgentId { get; set; }
        public string? AssignedAgentName { get; set; }
        public DateTime CreatedDate { get; set; }
        public DateTime? CompletedDate { get; set; }
        public DateTime LastActivityAt { get; set; }
        public int TotalMessages { get; set; }
        public string? FirstMessage { get; set; }
        public string? LastMessage { get; set; }
        public int? DurationMinutes { get; set; }
    }

    public class AgentManageDTO
    {
        public int AgentId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Role { get; set; } = string.Empty;
        public string ThemeColor { get; set; } = "emerald";
        public bool IsOnline { get; set; }
        public bool IsActive { get; set; }
        public DateTime CreatedDate { get; set; }
        public int TotalChatsHandled { get; set; }
        public int ActiveChats { get; set; }
    }

    public class CreateAgentRequestDTO
    {
        public string Name { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public string Role { get; set; } = "SupportAgent";
    }

    public class UpdateAgentRequestDTO
    {
        public int AgentId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string? Password { get; set; }
        public string Role { get; set; } = "SupportAgent";
        public bool IsActive { get; set; } = true;
    }
}
