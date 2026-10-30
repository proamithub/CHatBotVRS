USE [HelpBot_DB];
GO

-- =======================================================
-- 1. Table: Agents (Admin / Support Staff)
-- =======================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Agents')
BEGIN
    CREATE TABLE [dbo].[Agents] (
        [AgentId] INT IDENTITY(1,1) PRIMARY KEY,
        [Name] NVARCHAR(100) NOT NULL,
        [Email] VARCHAR(150) NOT NULL UNIQUE,
        [Password] NVARCHAR(255) NOT NULL,
        [Role] NVARCHAR(50) DEFAULT 'SupportAgent',
        [IsOnline] BIT DEFAULT 1,
        [IsActive] BIT DEFAULT 1,
        [CreatedDate] DATETIME DEFAULT GETDATE()
    );

    -- Seed 2 Initial Agents
    INSERT INTO [dbo].[Agents] ([Name], [Email], [Password], [Role], [IsOnline], [IsActive])
    VALUES 
    (N'Amit Sharma', 'amit@mvvu.ac.in', 'Admin@123', 'Senior Support Agent', 1, 1),
    (N'Priya Verma', 'priya@mvvu.ac.in', 'Agent@123', 'Support Executive', 1, 1);

    PRINT 'Agents table created and seeded.';
END
GO

-- =======================================================
-- 2. Alter Bot_Sessions for Live Agent Handoff
-- =======================================================
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Bot_Sessions') AND name = 'Status')
BEGIN
    ALTER TABLE [dbo].[Bot_Sessions] ADD 
        [UserName] NVARCHAR(150) NULL,
        [UserContact] VARCHAR(100) NULL,
        [Status] VARCHAR(50) DEFAULT 'Bot', -- 'Bot', 'WaitingAgent', 'Live', 'Closed'
        [AssignedAgentId] INT NULL,
        [AssignedAgentName] NVARCHAR(150) NULL,
        [LastActivityAt] DATETIME DEFAULT GETDATE();

    PRINT 'Bot_Sessions updated with live agent columns.';
END
GO

-- =======================================================
-- 3. Table: Chat_Messages (Live conversation between User & Agent/Bot)
-- =======================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Chat_Messages')
BEGIN
    CREATE TABLE [dbo].[Chat_Messages] (
        [MessageId] BIGINT IDENTITY(1,1) PRIMARY KEY,
        [SessionId] UNIQUEIDENTIFIER NOT NULL,
        [SenderType] VARCHAR(20) NOT NULL, -- 'User', 'Agent', 'Bot'
        [SenderName] NVARCHAR(100) NOT NULL,
        [MessageText] NVARCHAR(MAX) NOT NULL,
        [SentAt] DATETIME DEFAULT GETDATE(),
        [IsRead] BIT DEFAULT 0,
        CONSTRAINT FK_ChatMessages_Session FOREIGN KEY ([SessionId]) REFERENCES [dbo].[Bot_Sessions]([SessionId]) ON DELETE CASCADE
    );

    PRINT 'Chat_Messages table created.';
END
GO

-- =======================================================
-- 4. Stored Procedure: sp_AgentLogin
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
        IsActive
    FROM dbo.Agents
    WHERE Email = @Email 
      AND Password = @Password 
      AND IsActive = 1;
END
GO

-- =======================================================
-- 5. Stored Procedure: sp_GetLiveChatQueue
-- Description: Agent dashboard ke liye active chat sessions list karta hai
-- =======================================================
CREATE OR ALTER PROCEDURE dbo.sp_GetLiveChatQueue
    @AgentId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        s.SessionId,
        ISNULL(s.UserName, 'Student / Visitor') AS UserName,
        ISNULL(s.UserContact, '') AS UserContact,
        ISNULL(s.Status, 'Bot') AS Status,
        s.AssignedAgentId,
        s.AssignedAgentName,
        s.CreatedDate,
        s.LastActivityAt,
        (SELECT COUNT(1) FROM dbo.Chat_Messages m WHERE m.SessionId = s.SessionId) AS TotalMessages,
        (SELECT TOP 1 m.MessageText FROM dbo.Chat_Messages m WHERE m.SessionId = s.SessionId ORDER BY m.MessageId DESC) AS LastMessage
    FROM dbo.Bot_Sessions s
    WHERE s.IsCompleted = 0
    ORDER BY 
        CASE WHEN s.Status = 'WaitingAgent' THEN 1
             WHEN s.Status = 'Live' THEN 2
             ELSE 3 END ASC,
        s.LastActivityAt DESC;
END
GO

-- =======================================================
-- 6. Stored Procedure: sp_AcceptChatSession
-- Description: Agent chat accept karta hai aur handoff karta hai
-- =======================================================
CREATE OR ALTER PROCEDURE dbo.sp_AcceptChatSession
    @SessionId UNIQUEIDENTIFIER,
    @AgentId INT,
    @AgentName NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    -- Update session state
    UPDATE dbo.Bot_Sessions
    SET 
        AssignedAgentId = @AgentId,
        AssignedAgentName = @AgentName,
        Status = 'Live',
        LastActivityAt = GETDATE()
    WHERE SessionId = @SessionId;

    -- Insert system join message
    DECLARE @JoinMsg NVARCHAR(500) = N'👨‍💼 Agent ' + @AgentName + N' has joined the live chat. Aap direct baatchit kar sakte hain!';
    
    INSERT INTO dbo.Chat_Messages (SessionId, SenderType, SenderName, MessageText, SentAt)
    VALUES (@SessionId, 'Bot', 'System', @JoinMsg, GETDATE());

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
-- 7. Stored Procedure: sp_SendChatMessage
-- Description: User ya Agent ka message save karta hai
-- =======================================================
CREATE OR ALTER PROCEDURE dbo.sp_SendChatMessage
    @SessionId UNIQUEIDENTIFIER,
    @SenderType VARCHAR(20),
    @SenderName NVARCHAR(100),
    @MessageText NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    -- Ensure session exists
    IF NOT EXISTS (SELECT 1 FROM dbo.Bot_Sessions WHERE SessionId = @SessionId)
    BEGIN
        INSERT INTO dbo.Bot_Sessions (SessionId, CurrentStep, IsCompleted, CreatedDate, Status, UserName)
        VALUES (@SessionId, 1, 0, GETDATE(), 'Bot', @SenderName);
    END

    -- If sender is User and provides name for first time
    IF @SenderType = 'User'
    BEGIN
        UPDATE dbo.Bot_Sessions
        SET LastActivityAt = GETDATE()
        WHERE SessionId = @SessionId;
    END
    ELSE
    BEGIN
        UPDATE dbo.Bot_Sessions
        SET LastActivityAt = GETDATE()
        WHERE SessionId = @SessionId;
    END

    -- Insert Message
    INSERT INTO dbo.Chat_Messages (SessionId, SenderType, SenderName, MessageText, SentAt)
    VALUES (@SessionId, @SenderType, @SenderName, @MessageText, GETDATE());

    -- Return inserted message
    SELECT TOP 1
        MessageId,
        SessionId,
        SenderType,
        SenderName,
        MessageText,
        SentAt
    FROM dbo.Chat_Messages
    WHERE SessionId = @SessionId
    ORDER BY MessageId DESC;
END
GO

-- =======================================================
-- 8. Stored Procedure: sp_GetChatMessages
-- Description: Session ke messages laata hai (supports incremental polling with @LastMessageId)
-- =======================================================
CREATE OR ALTER PROCEDURE dbo.sp_GetChatMessages
    @SessionId UNIQUEIDENTIFIER,
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
        SentAt
    FROM dbo.Chat_Messages
    WHERE SessionId = @SessionId
      AND MessageId > @LastMessageId
    ORDER BY MessageId ASC;
END
GO

-- =======================================================
-- 9. Stored Procedure: sp_RequestLiveAgent
-- Description: User jab live human agent se baat karna chahe
-- =======================================================
CREATE OR ALTER PROCEDURE dbo.sp_RequestLiveAgent
    @SessionId UNIQUEIDENTIFIER,
    @UserName NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.Bot_Sessions WHERE SessionId = @SessionId)
    BEGIN
        INSERT INTO dbo.Bot_Sessions (SessionId, CurrentStep, IsCompleted, CreatedDate, Status, UserName)
        VALUES (@SessionId, 1, 0, GETDATE(), 'WaitingAgent', ISNULL(@UserName, 'Student / Visitor'));
    END
    ELSE
    BEGIN
        UPDATE dbo.Bot_Sessions
        SET 
            Status = 'WaitingAgent',
            UserName = ISNULL(@UserName, UserName),
            LastActivityAt = GETDATE()
        WHERE SessionId = @SessionId;
    END

    -- Insert waiting notification message
    INSERT INTO dbo.Chat_Messages (SessionId, SenderType, SenderName, MessageText, SentAt)
    VALUES (
        @SessionId, 
        'Bot', 
        'HelpDesk Bot', 
        N'🔄 Aapka request submit ho gaya hai. Support Agent se connect kiya ja raha hai, kripya line par bane rahein...', 
        GETDATE()
    );

    SELECT SessionId, Status, AssignedAgentName, LastActivityAt 
    FROM dbo.Bot_Sessions 
    WHERE SessionId = @SessionId;
END
GO

-- =======================================================
-- 10. Stored Procedure: sp_CloseChatSession
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
    VALUES (@SessionId, 'Bot', 'System', N'🔒 Chat session ko ' + @ClosedBy + N' dwara close kar diya gaya hai. Thank you!', GETDATE());

    SELECT SessionId, Status, IsCompleted FROM dbo.Bot_Sessions WHERE SessionId = @SessionId;
END
GO

PRINT 'Live Agent Tables and Stored Procedures setup completed successfully.';
