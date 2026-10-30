USE [HelpBot_DB];
GO

SET NOCOUNT ON;

-- =======================================================
-- 1. Update Amit Sharma's role to 'Admin'
-- =======================================================
UPDATE [dbo].[Agents] 
SET [Role] = 'Admin' 
WHERE [Email] = 'amit@mvvu.ac.in';
PRINT 'Updated Amit Sharma role to Admin.';
GO

-- =======================================================
-- 2. Stored Procedure: sp_TransferChatSession
-- Transfers an active chat session to another agent
-- =======================================================
CREATE OR ALTER PROCEDURE dbo.sp_TransferChatSession
    @SessionId     UNIQUEIDENTIFIER,
    @FromAgentId   INT,
    @FromAgentName NVARCHAR(100),
    @ToAgentId     INT,
    @ToAgentName   NVARCHAR(100),
    @Reason        NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Update session owner
    UPDATE dbo.Bot_Sessions
    SET 
        AssignedAgentId   = @ToAgentId,
        AssignedAgentName = @ToAgentName,
        Status            = 'Live',
        LastActivityAt    = GETDATE()
    WHERE SessionId = @SessionId;

    -- Insert system transfer notification message into Chat_Messages
    DECLARE @Msg NVARCHAR(500);
    SET @Msg = N'[Transferred] Chat transferred from ' + @FromAgentName + N' to ' + @ToAgentName;
    IF @Reason IS NOT NULL AND LTRIM(RTRIM(@Reason)) <> ''
    BEGIN
        SET @Msg = @Msg + N' (Reason: ' + @Reason + N')';
    END

    INSERT INTO dbo.Chat_Messages (SessionId, SenderType, SenderName, MessageText, ThemeColor, SentAt)
    VALUES (@SessionId, 'Bot', 'System', @Msg, 'cyan', GETDATE());

    -- Return updated session
    SELECT 
        SessionId,
        UserName,
        Status,
        AssignedAgentId,
        AssignedAgentName,
        LastActivityAt
    FROM dbo.Bot_Sessions
    WHERE SessionId = @SessionId;
END
GO
PRINT 'Created sp_TransferChatSession.';
GO

-- =======================================================
-- 3. Stored Procedure: sp_GetAvailableAgents
-- Returns active agents for transfer selection
-- =======================================================
CREATE OR ALTER PROCEDURE dbo.sp_GetAvailableAgents
    @ExcludeAgentId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        AgentId, 
        Name, 
        Email, 
        Role, 
        IsOnline, 
        IsActive, 
        ISNULL(ThemeColor, 'emerald') AS ThemeColor
    FROM dbo.Agents
    WHERE IsActive = 1
      AND (@ExcludeAgentId IS NULL OR AgentId <> @ExcludeAgentId)
    ORDER BY IsOnline DESC, Name ASC;
END
GO
PRINT 'Created sp_GetAvailableAgents.';
GO

-- =======================================================
-- 4. Stored Procedure: sp_GetSessionDetails
-- Returns specific session status and online agent count
-- =======================================================
CREATE OR ALTER PROCEDURE dbo.sp_GetSessionDetails
    @SessionId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        s.SessionId,
        ISNULL(s.UserName, 'Student / Visitor') AS UserName,
        ISNULL(s.UserContact, '') AS UserContact,
        ISNULL(s.FatherName, '') AS FatherName,
        ISNULL(s.RollNo, '') AS RollNo,
        ISNULL(s.Status, 'Bot') AS Status,
        s.AssignedAgentId,
        s.AssignedAgentName,
        s.CreatedDate,
        s.LastActivityAt,
        (SELECT COUNT(1) FROM dbo.Chat_Messages m WHERE m.SessionId = s.SessionId) AS TotalMessages,
        (SELECT TOP 1 m.MessageText FROM dbo.Chat_Messages m WHERE m.SessionId = s.SessionId ORDER BY m.MessageId DESC) AS LastMessage,
        (SELECT COUNT(1) FROM dbo.Agents WHERE IsOnline = 1 AND IsActive = 1) AS OnlineAgentCount
    FROM dbo.Bot_Sessions s
    WHERE s.SessionId = @SessionId;
END
GO
PRINT 'Created sp_GetSessionDetails.';
GO

-- =======================================================
-- 5. Stored Procedure: sp_GetAdminDashboardStats
-- =======================================================
CREATE OR ALTER PROCEDURE dbo.sp_GetAdminDashboardStats
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TotalSessions INT = (SELECT COUNT(1) FROM dbo.Bot_Sessions);
    DECLARE @LiveSessions INT = (SELECT COUNT(1) FROM dbo.Bot_Sessions WHERE Status = 'Live' AND IsCompleted = 0);
    DECLARE @WaitingSessions INT = (SELECT COUNT(1) FROM dbo.Bot_Sessions WHERE Status = 'WaitingAgent' AND IsCompleted = 0);
    DECLARE @ClosedSessions INT = (SELECT COUNT(1) FROM dbo.Bot_Sessions WHERE Status = 'Closed' OR IsCompleted = 1);
    DECLARE @TotalAgents INT = (SELECT COUNT(1) FROM dbo.Agents WHERE IsActive = 1);
    DECLARE @OnlineAgents INT = (SELECT COUNT(1) FROM dbo.Agents WHERE IsOnline = 1 AND IsActive = 1);
    DECLARE @TotalMessages INT = (SELECT COUNT(1) FROM dbo.Chat_Messages);
    DECLARE @TotalTickets INT = (SELECT COUNT(1) FROM dbo.TblHelpDesk_AM);

    SELECT 
        @TotalSessions AS TotalSessions,
        @LiveSessions AS LiveSessions,
        @WaitingSessions AS WaitingSessions,
        @ClosedSessions AS ClosedSessions,
        @TotalAgents AS TotalAgents,
        @OnlineAgents AS OnlineAgents,
        @TotalMessages AS TotalMessages,
        @TotalTickets AS TotalTickets;
END
GO
PRINT 'Created sp_GetAdminDashboardStats.';
GO

-- =======================================================
-- 6. Stored Procedure: sp_GetChatHistory
-- =======================================================
CREATE OR ALTER PROCEDURE dbo.sp_GetChatHistory
    @AgentId INT = NULL,
    @Status VARCHAR(50) = NULL,
    @SearchTerm NVARCHAR(100) = NULL,
    @StartDate DATETIME = NULL,
    @EndDate DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        s.SessionId,
        ISNULL(s.UserName, 'Student / Visitor') AS UserName,
        ISNULL(s.UserContact, '') AS UserContact,
        ISNULL(s.FatherName, '') AS FatherName,
        ISNULL(s.RollNo, '') AS RollNo,
        ISNULL(s.Status, 'Bot') AS Status,
        s.AssignedAgentId,
        s.AssignedAgentName,
        s.CreatedDate,
        s.CompletedDate,
        ISNULL(s.LastActivityAt, s.CreatedDate) AS LastActivityAt,
        (SELECT COUNT(1) FROM dbo.Chat_Messages m WHERE m.SessionId = s.SessionId) AS TotalMessages,
        (SELECT TOP 1 m.MessageText FROM dbo.Chat_Messages m WHERE m.SessionId = s.SessionId ORDER BY m.MessageId ASC) AS FirstMessage,
        (SELECT TOP 1 m.MessageText FROM dbo.Chat_Messages m WHERE m.SessionId = s.SessionId ORDER BY m.MessageId DESC) AS LastMessage,
        DATEDIFF(MINUTE, s.CreatedDate, ISNULL(s.CompletedDate, s.LastActivityAt)) AS DurationMinutes
    FROM dbo.Bot_Sessions s
    WHERE 
        (@AgentId IS NULL OR s.AssignedAgentId = @AgentId)
        AND (@Status IS NULL OR @Status = '' OR @Status = 'ALL' OR s.Status = @Status)
        AND (@SearchTerm IS NULL OR @SearchTerm = '' OR 
             s.UserName LIKE '%' + @SearchTerm + '%' OR 
             s.UserContact LIKE '%' + @SearchTerm + '%' OR 
             s.RollNo LIKE '%' + @SearchTerm + '%' OR
             s.AssignedAgentName LIKE '%' + @SearchTerm + '%')
        AND (@StartDate IS NULL OR s.CreatedDate >= @StartDate)
        AND (@EndDate IS NULL OR s.CreatedDate <= @EndDate)
    ORDER BY s.CreatedDate DESC;
END
GO
PRINT 'Created sp_GetChatHistory.';
GO

-- =======================================================
-- 7. Stored Procedure: dbo.sp_GetAllAgents
-- =======================================================
CREATE OR ALTER PROCEDURE dbo.sp_GetAllAgents
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        a.AgentId,
        a.Name,
        a.Email,
        a.Role,
        ISNULL(a.ThemeColor, 'emerald') AS ThemeColor,
        a.IsOnline,
        a.IsActive,
        a.CreatedDate,
        (SELECT COUNT(1) FROM dbo.Bot_Sessions s WHERE s.AssignedAgentId = a.AgentId) AS TotalChatsHandled,
        (SELECT COUNT(1) FROM dbo.Bot_Sessions s WHERE s.AssignedAgentId = a.AgentId AND s.Status = 'Live' AND s.IsCompleted = 0) AS ActiveChats
    FROM dbo.Agents a
    ORDER BY 
        CASE WHEN a.Role = 'Admin' THEN 1 ELSE 2 END ASC,
        a.IsOnline DESC,
        a.Name ASC;
END
GO
PRINT 'Created sp_GetAllAgents.';
GO

-- =======================================================
-- 8. Stored Procedure: dbo.sp_CreateAgent
-- =======================================================
CREATE OR ALTER PROCEDURE dbo.sp_CreateAgent
    @Name     NVARCHAR(100),
    @Email    VARCHAR(150),
    @Password NVARCHAR(255),
    @Role     NVARCHAR(50) = 'SupportAgent'
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM dbo.Agents WHERE Email = @Email)
    BEGIN
        RAISERROR(N'An agent with this email already exists!', 16, 1);
        RETURN;
    END

    INSERT INTO dbo.Agents (Name, Email, Password, Role, IsOnline, IsActive, ThemeColor, CreatedDate)
    VALUES (@Name, @Email, @Password, @Role, 0, 1, 'emerald', GETDATE());

    SELECT 
        AgentId, Name, Email, Role, ThemeColor, IsOnline, IsActive, CreatedDate,
        0 AS TotalChatsHandled, 0 AS ActiveChats
    FROM dbo.Agents
    WHERE AgentId = SCOPE_IDENTITY();
END
GO
PRINT 'Created sp_CreateAgent.';
GO

-- =======================================================
-- 9. Stored Procedure: dbo.sp_UpdateAgent
-- =======================================================
CREATE OR ALTER PROCEDURE dbo.sp_UpdateAgent
    @AgentId  INT,
    @Name     NVARCHAR(100),
    @Email    VARCHAR(150),
    @Password NVARCHAR(255) = NULL,
    @Role     NVARCHAR(50) = 'SupportAgent',
    @IsActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM dbo.Agents WHERE Email = @Email AND AgentId <> @AgentId)
    BEGIN
        RAISERROR(N'This email is already in use by another agent!', 16, 1);
        RETURN;
    END

    IF @Password IS NOT NULL AND LTRIM(RTRIM(@Password)) <> ''
    BEGIN
        UPDATE dbo.Agents
        SET 
            Name = @Name,
            Email = @Email,
            Password = @Password,
            Role = @Role,
            IsActive = @IsActive
        WHERE AgentId = @AgentId;
    END
    ELSE
    BEGIN
        UPDATE dbo.Agents
        SET 
            Name = @Name,
            Email = @Email,
            Role = @Role,
            IsActive = @IsActive
        WHERE AgentId = @AgentId;
    END

    SELECT 
        AgentId, Name, Email, Role, ThemeColor, IsOnline, IsActive, CreatedDate,
        (SELECT COUNT(1) FROM dbo.Bot_Sessions s WHERE s.AssignedAgentId = a.AgentId) AS TotalChatsHandled,
        (SELECT COUNT(1) FROM dbo.Bot_Sessions s WHERE s.AssignedAgentId = a.AgentId AND s.Status = 'Live' AND s.IsCompleted = 0) AS ActiveChats
    FROM dbo.Agents a
    WHERE a.AgentId = @AgentId;
END
GO
PRINT 'Created sp_UpdateAgent.';
GO

-- =======================================================
-- 10. Stored Procedure: dbo.sp_ToggleAgentActive
-- =======================================================
CREATE OR ALTER PROCEDURE dbo.sp_ToggleAgentActive
    @AgentId  INT,
    @IsActive BIT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Agents
    SET 
        IsActive = @IsActive,
        IsOnline = CASE WHEN @IsActive = 0 THEN 0 ELSE IsOnline END
    WHERE AgentId = @AgentId;

    SELECT AgentId, Name, Email, Role, IsOnline, IsActive
    FROM dbo.Agents
    WHERE AgentId = @AgentId;
END
GO
PRINT 'Created sp_ToggleAgentActive.';
GO

PRINT '=======================================================';
PRINT 'All Admin & Agent Transfer procedures created successfully!';
PRINT '=======================================================';
