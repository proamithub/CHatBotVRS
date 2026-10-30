USE [HelpBot_DB];
GO

-- =======================================================
-- FIX 1: Add missing columns to Bot_Sessions if not exist
-- =======================================================
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Bot_Sessions') AND name = 'FatherName')
BEGIN
    ALTER TABLE [dbo].[Bot_Sessions] ADD [FatherName] NVARCHAR(150) NULL;
    PRINT 'Added FatherName column to Bot_Sessions';
END
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Bot_Sessions') AND name = 'RollNo')
BEGIN
    ALTER TABLE [dbo].[Bot_Sessions] ADD [RollNo] NVARCHAR(100) NULL;
    PRINT 'Added RollNo column to Bot_Sessions';
END
GO

-- =======================================================
-- FIX 2: Add ThemeColor to Chat_Messages if not exist
-- =======================================================
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Chat_Messages') AND name = 'ThemeColor')
BEGIN
    ALTER TABLE [dbo].[Chat_Messages] ADD [ThemeColor] NVARCHAR(50) NULL DEFAULT 'emerald';
    PRINT 'Added ThemeColor column to Chat_Messages';
END
GO

-- =======================================================
-- FIX 3: sp_RequestLiveAgent — FatherName & RollNo support + OnlineAgentCount
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
            Status      = 'WaitingAgent',
            UserName    = ISNULL(@UserName, UserName),
            UserContact = ISNULL(@UserContact, UserContact),
            FatherName  = ISNULL(@FatherName, FatherName),
            RollNo      = ISNULL(@RollNo, RollNo),
            LastActivityAt = GETDATE()
        WHERE SessionId = @SessionId;
    END

    -- Insert waiting notification message
    IF NOT EXISTS (
        SELECT 1 FROM dbo.Chat_Messages
        WHERE SessionId = @SessionId AND SenderType = 'Bot'
          AND MessageText LIKE N'%request submit%'
    )
    BEGIN
        INSERT INTO dbo.Chat_Messages (SessionId, SenderType, SenderName, MessageText, SentAt)
        VALUES (
            @SessionId, 'Bot', 'HelpDesk Bot',
            N'🔄 Aapka request submit ho gaya hai. Support Agent se connect kiya ja raha hai, kripya line par bane rahein...',
            GETDATE()
        );
    END

    -- Return session + online agent count
    SELECT 
        s.SessionId, s.Status, s.AssignedAgentName, s.LastActivityAt,
        s.UserContact, s.FatherName, s.RollNo,
        (SELECT COUNT(1) FROM dbo.Agents WHERE IsOnline = 1 AND IsActive = 1) AS OnlineAgentCount
    FROM dbo.Bot_Sessions s
    WHERE s.SessionId = @SessionId;
END
GO

-- =======================================================
-- FIX 4: sp_GetLiveChatQueue — FatherName & RollNo include
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
        (SELECT TOP 1 m.MessageText FROM dbo.Chat_Messages m 
         WHERE m.SessionId = s.SessionId ORDER BY m.MessageId DESC) AS LastMessage,
        (SELECT COUNT(1) FROM dbo.Agents WHERE IsOnline = 1 AND IsActive = 1) AS OnlineAgentCount
    FROM dbo.Bot_Sessions s
    WHERE s.IsCompleted = 0
      AND s.Status IN ('WaitingAgent', 'Live', 'Bot')
    ORDER BY 
        CASE WHEN s.Status = 'WaitingAgent' THEN 1
             WHEN s.Status = 'Live'         THEN 2
             ELSE 3 END ASC,
        s.LastActivityAt DESC;
END
GO

-- =======================================================
-- FIX 5: sp_SendChatMessage — ThemeColor support
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

    -- Ensure session exists
    IF NOT EXISTS (SELECT 1 FROM dbo.Bot_Sessions WHERE SessionId = @SessionId)
    BEGIN
        INSERT INTO dbo.Bot_Sessions (SessionId, CurrentStep, IsCompleted, CreatedDate, Status, UserName, LastActivityAt)
        VALUES (@SessionId, 1, 0, GETDATE(), 'Bot', @SenderName, GETDATE());
    END

    -- Update last activity
    UPDATE dbo.Bot_Sessions
    SET LastActivityAt = GETDATE()
    WHERE SessionId = @SessionId;

    -- Insert Message with ThemeColor
    INSERT INTO dbo.Chat_Messages (SessionId, SenderType, SenderName, MessageText, ThemeColor, SentAt)
    VALUES (@SessionId, @SenderType, @SenderName, @MessageText, @ThemeColor, GETDATE());

    -- Return inserted message
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
-- FIX 6: sp_GetChatMessages — ThemeColor include
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
-- FIX 7: sp_AcceptChatSession — [Agent Connected] tag add in message
-- =======================================================
CREATE OR ALTER PROCEDURE dbo.sp_AcceptChatSession
    @SessionId  UNIQUEIDENTIFIER,
    @AgentId    INT,
    @AgentName  NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    -- Update session state
    UPDATE dbo.Bot_Sessions
    SET 
        AssignedAgentId   = @AgentId,
        AssignedAgentName = @AgentName,
        Status            = 'Live',
        LastActivityAt    = GETDATE()
    WHERE SessionId = @SessionId;

    -- Insert system join message WITH [Agent Connected] marker so user side detects it
    DECLARE @JoinMsg NVARCHAR(500) = N'[Agent Connected] 👨‍💼 ' + @AgentName + N' ne live chat join kar liya! Ab aap seedha baat kar sakte hain.';
    
    INSERT INTO dbo.Chat_Messages (SessionId, SenderType, SenderName, MessageText, ThemeColor, SentAt)
    VALUES (@SessionId, 'Bot', 'System', @JoinMsg, 'emerald', GETDATE());

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
-- FIX 8: sp_SetAgentOnlineStatus — ensure exists
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
    SELECT AgentId, IsOnline FROM dbo.Agents WHERE AgentId = @AgentId;
END
GO

-- =======================================================
-- FIX 9: sp_GetAgentById — ensure ThemeColor column exists & returned
-- =======================================================
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Agents') AND name = 'ThemeColor')
BEGIN
    ALTER TABLE [dbo].[Agents] ADD [ThemeColor] NVARCHAR(50) DEFAULT 'emerald';
    PRINT 'Added ThemeColor to Agents table';
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetAgentById
    @AgentId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT AgentId, Name, Email, Role, IsOnline, IsActive,
           ISNULL(ThemeColor, 'emerald') AS ThemeColor
    FROM dbo.Agents
    WHERE AgentId = @AgentId;
END
GO

-- =======================================================
-- FIX 10: sp_UpdateAgentTheme — ensure it saves ThemeColor
-- =======================================================
CREATE OR ALTER PROCEDURE dbo.sp_UpdateAgentTheme
    @AgentId    INT,
    @ThemeColor NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.Agents SET ThemeColor = @ThemeColor WHERE AgentId = @AgentId;
    SELECT AgentId, Name, Email, Role, IsOnline, IsActive,
           ISNULL(ThemeColor, 'emerald') AS ThemeColor
    FROM dbo.Agents WHERE AgentId = @AgentId;
END
GO

PRINT '=== All SP fixes applied successfully! ===';
