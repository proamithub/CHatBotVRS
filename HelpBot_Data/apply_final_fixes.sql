USE [HelpBot_DB];
GO

SET NOCOUNT ON;

-- =======================================================
-- 1. Ensure columns exist on Bot_Sessions
-- =======================================================
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Bot_Sessions') AND name = 'FatherName')
BEGIN
    ALTER TABLE [dbo].[Bot_Sessions] ADD [FatherName] NVARCHAR(150) NULL;
    PRINT 'Added FatherName to Bot_Sessions';
END
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Bot_Sessions') AND name = 'RollNo')
BEGIN
    ALTER TABLE [dbo].[Bot_Sessions] ADD [RollNo] NVARCHAR(100) NULL;
    PRINT 'Added RollNo to Bot_Sessions';
END
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Bot_Sessions') AND name = 'ThemeColor')
BEGIN
    ALTER TABLE [dbo].[Bot_Sessions] ADD [ThemeColor] NVARCHAR(50) NULL;
END
GO

-- =======================================================
-- 2. Ensure columns exist on Chat_Messages
-- =======================================================
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Chat_Messages') AND name = 'ThemeColor')
BEGIN
    ALTER TABLE [dbo].[Chat_Messages] ADD [ThemeColor] NVARCHAR(50) NULL DEFAULT 'emerald';
    PRINT 'Added ThemeColor to Chat_Messages';
END
GO

-- =======================================================
-- 3. Reset All Agents to Offline (IsOnline = 0)
-- Default for IsOnline MUST be 0 (offline)
-- =======================================================
UPDATE [dbo].[Agents] 
SET [IsOnline] = 0;
PRINT 'Reset all agents to Offline (IsOnline = 0)';
GO

-- Drop existing default constraint on Agents.IsOnline if any
DECLARE @defConst NVARCHAR(250);
SELECT @defConst = dc.name
FROM sys.default_constraints dc
JOIN sys.columns c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
WHERE dc.parent_object_id = OBJECT_ID('dbo.Agents') AND c.name = 'IsOnline';

IF @defConst IS NOT NULL
BEGIN
    EXEC('ALTER TABLE dbo.Agents DROP CONSTRAINT [' + @defConst + ']');
    PRINT 'Dropped old default constraint on Agents.IsOnline';
END
GO

ALTER TABLE dbo.Agents ADD CONSTRAINT DF_Agents_IsOnline DEFAULT 0 FOR [IsOnline];
PRINT 'Set default constraint DF_Agents_IsOnline = 0 (Offline)';
GO

-- Ensure ThemeColor exists on Agents
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Agents') AND name = 'ThemeColor')
BEGIN
    ALTER TABLE [dbo].[Agents] ADD [ThemeColor] NVARCHAR(50) DEFAULT 'emerald';
    PRINT 'Added ThemeColor to Agents table';
END
GO

-- =======================================================
-- 4. SP: sp_SetAgentOnlineStatus
-- =======================================================
CREATE OR ALTER PROCEDURE dbo.sp_SetAgentOnlineStatus
    @AgentId  INT,
    @IsOnline BIT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Agents
    SET IsOnline = @IsOnline
    WHERE AgentId = @AgentId;

    SELECT AgentId, Name, Email, Role, IsOnline, IsActive, ISNULL(ThemeColor, 'emerald') AS ThemeColor
    FROM dbo.Agents
    WHERE AgentId = @AgentId;
END
GO

-- =======================================================
-- 5. SP: sp_AgentLogin
-- =======================================================
CREATE OR ALTER PROCEDURE dbo.sp_AgentLogin
    @Email VARCHAR(150),
    @Password NVARCHAR(255)
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
    WHERE Email = @Email 
      AND Password = @Password 
      AND IsActive = 1;
END
GO

-- =======================================================
-- 6. SP: sp_GetAgentById
-- =======================================================
CREATE OR ALTER PROCEDURE dbo.sp_GetAgentById
    @AgentId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT AgentId, Name, Email, Role, IsOnline, IsActive, ISNULL(ThemeColor, 'emerald') AS ThemeColor
    FROM dbo.Agents
    WHERE AgentId = @AgentId;
END
GO

-- =======================================================
-- 7. SP: sp_UpdateAgentTheme
-- =======================================================
CREATE OR ALTER PROCEDURE dbo.sp_UpdateAgentTheme
    @AgentId    INT,
    @ThemeColor NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Agents 
    SET ThemeColor = @ThemeColor 
    WHERE AgentId = @AgentId;

    SELECT AgentId, Name, Email, Role, IsOnline, IsActive, ISNULL(ThemeColor, 'emerald') AS ThemeColor
    FROM dbo.Agents 
    WHERE AgentId = @AgentId;
END
GO

-- =======================================================
-- 8. SP: sp_RequestLiveAgent
-- Calculates OnlineAgentCount accurately
-- =======================================================
CREATE OR ALTER PROCEDURE dbo.sp_RequestLiveAgent
    @SessionId   UNIQUEIDENTIFIER,
    @UserName    NVARCHAR(100) = NULL,
    @UserContact VARCHAR(100)  = NULL,
    @FatherName  NVARCHAR(150) = NULL,
    @RollNo      NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.Bot_Sessions WHERE SessionId = @SessionId)
    BEGIN
        INSERT INTO dbo.Bot_Sessions 
            (SessionId, CurrentStep, IsCompleted, CreatedDate, Status, UserName, UserContact, FatherName, RollNo, LastActivityAt)
        VALUES 
            (@SessionId, 1, 0, GETDATE(), 'WaitingAgent',
             ISNULL(@UserName, 'Student / Visitor'),
             @UserContact, @FatherName, @RollNo, GETDATE());
    END
    ELSE
    BEGIN
        UPDATE dbo.Bot_Sessions
        SET 
            Status         = 'WaitingAgent',
            UserName       = ISNULL(@UserName, UserName),
            UserContact    = ISNULL(@UserContact, UserContact),
            FatherName     = ISNULL(@FatherName, FatherName),
            RollNo         = ISNULL(@RollNo, RollNo),
            LastActivityAt = GETDATE()
        WHERE SessionId = @SessionId;
    END

    -- Return session details along with current count of logged-in online agents
    SELECT 
        s.SessionId,
        ISNULL(s.UserName, 'Student / Visitor') AS UserName,
        ISNULL(s.UserContact, '') AS UserContact,
        ISNULL(s.FatherName, '') AS FatherName,
        ISNULL(s.RollNo, '') AS RollNo,
        s.Status,
        s.AssignedAgentId,
        s.AssignedAgentName,
        s.CreatedDate,
        s.LastActivityAt,
        (SELECT COUNT(1) FROM dbo.Agents WHERE IsOnline = 1 AND IsActive = 1) AS OnlineAgentCount
    FROM dbo.Bot_Sessions s
    WHERE s.SessionId = @SessionId;
END
GO

-- =======================================================
-- 9. SP: sp_GetLiveChatQueue
-- RULES:
-- a) 'WaitingAgent' sessions are visible to ALL agents
-- b) 'Live' sessions are visible ONLY to the AssignedAgentId
-- c) Other agents will NOT see another agent's Live session
-- =======================================================
CREATE OR ALTER PROCEDURE dbo.sp_GetLiveChatQueue
    @AgentId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        s.SessionId,
        ISNULL(s.UserName, 'Student / Visitor')  AS UserName,
        ISNULL(s.UserContact, '')                 AS UserContact,
        ISNULL(s.FatherName, '')                  AS FatherName,
        ISNULL(s.RollNo, '')                      AS RollNo,
        ISNULL(s.Status, 'Bot')                   AS Status,
        s.AssignedAgentId,
        s.AssignedAgentName,
        s.CreatedDate,
        ISNULL(s.LastActivityAt, s.CreatedDate)   AS LastActivityAt,
        (SELECT COUNT(1) FROM dbo.Chat_Messages m WHERE m.SessionId = s.SessionId) AS TotalMessages,
        (SELECT TOP 1 m.MessageText FROM dbo.Chat_Messages m WHERE m.SessionId = s.SessionId ORDER BY m.MessageId DESC) AS LastMessage,
        (SELECT COUNT(1) FROM dbo.Agents WHERE IsOnline = 1 AND IsActive = 1) AS OnlineAgentCount
    FROM dbo.Bot_Sessions s
    WHERE s.IsCompleted = 0
      AND (
          -- Unassigned students waiting for an agent -> All active agents can see
          s.Status = 'WaitingAgent'
          OR
          -- Already accepted / live -> ONLY the assigned agent sees this
          (s.Status = 'Live' AND (@AgentId IS NOT NULL AND s.AssignedAgentId = @AgentId))
      )
    ORDER BY 
        CASE WHEN s.Status = 'WaitingAgent' THEN 1
             WHEN s.Status = 'Live'         THEN 2
             ELSE 3 END ASC,
        s.LastActivityAt DESC;
END
GO

-- =======================================================
-- 10. SP: sp_AcceptChatSession
-- First-come first-served lock:
-- Can ONLY be accepted if Status is 'WaitingAgent' or already assigned to this agent
-- =======================================================
CREATE OR ALTER PROCEDURE dbo.sp_AcceptChatSession
    @SessionId  UNIQUEIDENTIFIER,
    @AgentId    INT,
    @AgentName  NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    -- Only update if it is still 'WaitingAgent' OR already owned by this agent
    IF EXISTS (
        SELECT 1 FROM dbo.Bot_Sessions 
        WHERE SessionId = @SessionId 
          AND (Status = 'WaitingAgent' OR (Status = 'Live' AND AssignedAgentId = @AgentId))
    )
    BEGIN
        UPDATE dbo.Bot_Sessions
        SET 
            AssignedAgentId   = @AgentId,
            AssignedAgentName = @AgentName,
            Status            = 'Live',
            LastActivityAt    = GETDATE()
        WHERE SessionId = @SessionId;

        -- Insert notification message for student with [Agent Connected]
        IF NOT EXISTS (
            SELECT 1 FROM dbo.Chat_Messages 
            WHERE SessionId = @SessionId AND MessageText LIKE '[Agent Connected]%'
        )
        BEGIN
            DECLARE @JoinMsg NVARCHAR(500) = N'[Agent Connected] 👨‍💼 ' + @AgentName + N' ne live chat join kar liya! Ab aap seedha baat kar sakte hain.';
            
            INSERT INTO dbo.Chat_Messages (SessionId, SenderType, SenderName, MessageText, ThemeColor, SentAt)
            VALUES (@SessionId, 'Bot', 'System', @JoinMsg, 'emerald', GETDATE());
        END
    END

    -- Return the current state of session
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

-- =======================================================
-- 11. SP: sp_SendChatMessage
-- =======================================================
CREATE OR ALTER PROCEDURE dbo.sp_SendChatMessage
    @SessionId   UNIQUEIDENTIFIER,
    @SenderType  VARCHAR(20),
    @SenderName  NVARCHAR(100),
    @MessageText NVARCHAR(MAX),
    @ThemeColor  NVARCHAR(50) = 'emerald'
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.Bot_Sessions WHERE SessionId = @SessionId)
    BEGIN
        INSERT INTO dbo.Bot_Sessions (SessionId, CurrentStep, IsCompleted, CreatedDate, Status, UserName, LastActivityAt)
        VALUES (@SessionId, 1, 0, GETDATE(), 'Bot', @SenderName, GETDATE());
    END

    UPDATE dbo.Bot_Sessions
    SET LastActivityAt = GETDATE()
    WHERE SessionId = @SessionId;

    INSERT INTO dbo.Chat_Messages (SessionId, SenderType, SenderName, MessageText, ThemeColor, SentAt)
    VALUES (@SessionId, @SenderType, @SenderName, @MessageText, @ThemeColor, GETDATE());

    SELECT TOP 1
        MessageId,
        SessionId,
        SenderType,
        SenderName,
        MessageText,
        ThemeColor,
        SentAt
    FROM dbo.Chat_Messages
    WHERE SessionId = @SessionId
    ORDER BY MessageId DESC;
END
GO

-- =======================================================
-- 12. SP: sp_GetChatMessages
-- =======================================================
CREATE OR ALTER PROCEDURE dbo.sp_GetChatMessages
    @SessionId     UNIQUEIDENTIFIER,
    @LastMessageId BIGINT = 0
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        MessageId,
        SessionId,
        SenderType,
        SenderName,
        MessageText,
        ISNULL(ThemeColor, 'emerald') AS ThemeColor,
        SentAt
    FROM dbo.Chat_Messages
    WHERE SessionId = @SessionId
      AND MessageId > @LastMessageId
    ORDER BY MessageId ASC;
END
GO

-- =======================================================
-- 13. SP: sp_CloseChatSession
-- =======================================================
CREATE OR ALTER PROCEDURE dbo.sp_CloseChatSession
    @SessionId UNIQUEIDENTIFIER,
    @ClosedBy NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Bot_Sessions
    SET 
        Status = 'Closed',
        IsCompleted = 1,
        CompletedDate = GETDATE()
    WHERE SessionId = @SessionId;

    INSERT INTO dbo.Chat_Messages (SessionId, SenderType, SenderName, MessageText, SentAt)
    VALUES (@SessionId, 'Bot', 'System', N'[Chat Closed] 🔒 Chat session ko ' + @ClosedBy + N' dwara close kar diya gaya hai. Thank you!', GETDATE());

    SELECT SessionId, Status, IsCompleted FROM dbo.Bot_Sessions WHERE SessionId = @SessionId;
END
GO

PRINT '=== All Procedures and Schema Fixes Successfully Installed! ===';
