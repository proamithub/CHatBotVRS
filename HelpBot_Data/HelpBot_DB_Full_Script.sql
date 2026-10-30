-- ===============================================================
-- Complete Database Script for HelpBot_DB
-- Generated: 2026-10-30 18:11:02
-- Server: VRS-AMITPC\SQLEXPRESS
-- ===============================================================

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'HelpBot_DB')
BEGIN
    CREATE DATABASE [HelpBot_DB];
END
GO

USE [HelpBot_DB];
GO

-- ===============================================================
-- 1. TABLES CREATION
-- ===============================================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Agents')
BEGIN
    CREATE TABLE [dbo].[Agents] (
        [AgentId] INT IDENTITY(1,1) PRIMARY KEY,
        [Name] NVARCHAR(100) NOT NULL,
        [Email] VARCHAR(150) NOT NULL UNIQUE,
        [Password] NVARCHAR(255) NOT NULL,
        [Role] NVARCHAR(50) DEFAULT 'SupportAgent',
        [IsOnline] BIT DEFAULT 0,
        [IsActive] BIT DEFAULT 1,
        [CreatedDate] DATETIME DEFAULT GETDATE(),
        [ThemeColor] NVARCHAR(50) NOT NULL DEFAULT 'emerald'
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Bot_Questions')
BEGIN
    CREATE TABLE [dbo].[Bot_Questions] (
        [QuestionId] INT IDENTITY(1,1) PRIMARY KEY,
        [QuestionText] NVARCHAR(500) NOT NULL,
        [StepOrder] INT NOT NULL,
        [FieldKey] NVARCHAR(50) NOT NULL,
        [InputType] NVARCHAR(50) DEFAULT 'text',
        [IsActive] BIT DEFAULT 1
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Bot_Sessions')
BEGIN
    CREATE TABLE [dbo].[Bot_Sessions] (
        [SessionId] UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        [CurrentStep] INT DEFAULT 1,
        [IsCompleted] BIT DEFAULT 0,
        [CreatedDate] DATETIME DEFAULT GETDATE(),
        [CompletedDate] DATETIME NULL,
        [UserName] NVARCHAR(150) NULL,
        [UserContact] VARCHAR(50) NULL,
        [Status] VARCHAR(50) DEFAULT 'Bot',
        [AssignedAgentId] INT NULL,
        [AssignedAgentName] NVARCHAR(150) NULL,
        [LastActivityAt] DATETIME DEFAULT GETDATE(),
        [FatherName] NVARCHAR(150) NULL,
        [RollNo] NVARCHAR(50) NULL,
        [AgentTheme] NVARCHAR(50) NULL,
        [ConnectedDate] DATETIME NULL,
        [ThemeColor] NVARCHAR(50) NULL,
        [IsUploadAllowed] BIT DEFAULT 0
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Bot_Responses')
BEGIN
    CREATE TABLE [dbo].[Bot_Responses] (
        [ResponseId] BIGINT IDENTITY(1,1) PRIMARY KEY,
        [SessionId] UNIQUEIDENTIFIER NOT NULL,
        [QuestionId] INT NOT NULL,
        [AnswerText] NVARCHAR(MAX) NOT NULL,
        [SubmittedAt] DATETIME DEFAULT GETDATE(),
        CONSTRAINT FK_BotResponses_Session FOREIGN KEY ([SessionId]) REFERENCES [Bot_Sessions]([SessionId]) ON DELETE CASCADE,
        CONSTRAINT FK_BotResponses_Question FOREIGN KEY ([QuestionId]) REFERENCES [Bot_Questions]([QuestionId])
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Chat_Messages')
BEGIN
    CREATE TABLE [dbo].[Chat_Messages] (
        [MessageId] BIGINT IDENTITY(1,1) PRIMARY KEY,
        [SessionId] UNIQUEIDENTIFIER NOT NULL,
        [SenderType] VARCHAR(20) NOT NULL,
        [SenderName] NVARCHAR(100) NOT NULL,
        [MessageText] NVARCHAR(MAX) NOT NULL,
        [SentAt] DATETIME DEFAULT GETDATE(),
        [IsRead] BIT DEFAULT 0,
        [ThemeColor] NVARCHAR(50) NULL,
        [AttachmentUrl] NVARCHAR(500) NULL,
        [AttachmentType] VARCHAR(50) NULL,
        [AttachmentName] NVARCHAR(255) NULL,
        CONSTRAINT FK_ChatMessages_Session FOREIGN KEY ([SessionId]) REFERENCES [Bot_Sessions]([SessionId]) ON DELETE CASCADE
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PriorityType_AM')
BEGIN
    CREATE TABLE [dbo].[PriorityType_AM] (
        [FID] INT IDENTITY(1,1) PRIMARY KEY,
        [FlagType] VARCHAR(100) NULL,
        [IsActive] INT NOT NULL DEFAULT 1,
        [Color] VARCHAR(50) NULL,
        [Sequence] INT NOT NULL DEFAULT 0
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TblHelpDeskComplaintType_AM')
BEGIN
    CREATE TABLE [dbo].[TblHelpDeskComplaintType_AM] (
        [CTypeID] INT PRIMARY KEY,
        [TypeName] VARCHAR(100) NOT NULL,
        [Details] NVARCHAR(500) NULL,
        [IsActive] BIT DEFAULT 1,
        [Sequence] INT DEFAULT 0,
        [AlertMsg] NVARCHAR(500) NULL
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TblHelpDesk_AM')
BEGIN
    CREATE TABLE [dbo].[TblHelpDesk_AM] (
        [EntryID] BIGINT IDENTITY(1,1) PRIMARY KEY,
        [HelpID] NVARCHAR(50) NULL,
        [TicketID] NVARCHAR(50) NOT NULL,
        [Subject] NVARCHAR(500) NOT NULL,
        [Email] VARCHAR(150) NULL,
        [Name] NVARCHAR(150) NULL,
        [Mobile] VARCHAR(20) NULL,
        [CreatedDate] DATETIME NOT NULL DEFAULT GETDATE(),
        [IsActive] BIT NOT NULL DEFAULT 1,
        [Status] VARCHAR(50) DEFAULT 'Open',
        [Enroll_Roll] VARCHAR(50) NOT NULL,
        [CTypeID] INT NOT NULL DEFAULT 0,
        [FlagTypeID] INT NOT NULL DEFAULT 1,
        [ForwardCTypeID] INT NOT NULL DEFAULT 0,
        [ForwardBy] INT NOT NULL DEFAULT 0,
        [ForwardDateTime] DATETIME NULL,
        [IpAddress] VARCHAR(50) NULL,
        [ProfilePic] VARCHAR(255) NULL,
        [Roll] VARCHAR(50) NULL,
        [Remark] NVARCHAR(MAX) NULL
    );
END
GO
-- ===============================================================
-- 2. SEED DATA
-- ===============================================================

-- Seed Bot Questions
IF NOT EXISTS (SELECT 1 FROM [dbo].[Bot_Questions])
BEGIN
    SET IDENTITY_INSERT [dbo].[Bot_Questions] ON;
    INSERT INTO [dbo].[Bot_Questions] ([QuestionId], [QuestionText], [StepOrder], [FieldKey], [InputType], [IsActive]) VALUES
    (1, N'Namaste! Welcome to Help Desk. Aapka poora naam kya hai?', 1, 'FullName', 'text', 1),
    (2, N'Aapka Mobile Number enter karein:', 2, 'MobileNo', 'number', 1),
    (3, N'Aapka Email Address kya hai?', 3, 'Email', 'email', 1),
    (4, N'Aapka Roll No ya Enrollment No kya hai? (Nahi hai toh NA likhein):', 4, 'EnrollNo', 'text', 1),
    (5, N'Aapko kya samasya ya help chahiye? Apni samasya detail me likhein:', 5, 'ProblemDescription', 'text', 1);
    SET IDENTITY_INSERT [dbo].[Bot_Questions] OFF;
END
GO

-- Seed Priority Types
IF NOT EXISTS (SELECT 1 FROM [dbo].[PriorityType_AM])
BEGIN
    SET IDENTITY_INSERT [dbo].[PriorityType_AM] ON;
    INSERT INTO [dbo].[PriorityType_AM] ([FID], [FlagType], [IsActive], [Color], [Sequence]) VALUES
    (1, 'Normal', 1, NULL, 4),
    (2, 'High', 1, 'red', 1),
    (3, 'Medium', 1, 'orange', 2),
    (4, 'Low', 1, NULL, 3);
    SET IDENTITY_INSERT [dbo].[PriorityType_AM] OFF;
END
GO

-- Seed Complaint Types
IF NOT EXISTS (SELECT 1 FROM [dbo].[TblHelpDeskComplaintType_AM])
BEGIN
    INSERT INTO [dbo].[TblHelpDeskComplaintType_AM] ([CTypeID], [TypeName], [IsActive]) VALUES
    (0, 'Other', 1),
    (1, 'IGRS', 1),
    (2, 'Enrollment', 1),
    (3, 'Verification', 1),
    (4, 'Provisional Certificate', 1),
    (5, 'Migration Certificate', 1),
    (6, 'Transcript', 1),
    (7, 'Duplicate Marksheet', 1),
    (8, 'Degree', 1),
    (11, 'Online Result Correction', 1),
    (12, 'Online Examination Form Filling', 1),
    (13, 'Online Admission Form Filling', 1),
    (14, 'TN-No', 1);
END
GO

-- Seed Default Agents (including SuperAdmin Amit)
IF NOT EXISTS (SELECT 1 FROM [dbo].[Agents] WHERE Email = 'amit@mvvu.ac.in')
BEGIN
    INSERT INTO [dbo].[Agents] ([Name], [Email], [Password], [Role], [IsOnline], [IsActive], [ThemeColor])
    VALUES (N'Amit Sharma', 'amit@mvvu.ac.in', 'Admin@123', 'Admin', 0, 1, 'amber');
END
IF NOT EXISTS (SELECT 1 FROM [dbo].[Agents] WHERE Email = 'priya@mvvu.ac.in')
BEGIN
    INSERT INTO [dbo].[Agents] ([Name], [Email], [Password], [Role], [IsOnline], [IsActive], [ThemeColor])
    VALUES (N'Priya Verma', 'priya@mvvu.ac.in', 'Agent@123', 'Senior Support Agent', 0, 1, 'cyan');
END
IF NOT EXISTS (SELECT 1 FROM [dbo].[Agents] WHERE Email = 'rahul@mvvu.ac.in')
BEGIN
    INSERT INTO [dbo].[Agents] ([Name], [Email], [Password], [Role], [IsOnline], [IsActive], [ThemeColor])
    VALUES (N'Rahul Singh', 'rahul@mvvu.ac.in', 'Agent@123', 'SupportAgent', 0, 1, 'cyan');
END
IF NOT EXISTS (SELECT 1 FROM [dbo].[Agents] WHERE Email = 'neha@mvvu.ac.in')
BEGIN
    INSERT INTO [dbo].[Agents] ([Name], [Email], [Password], [Role], [IsOnline], [IsActive], [ThemeColor])
    VALUES (N'Neha Gupta', 'neha@mvvu.ac.in', 'Agent@123', 'SupportAgent', 0, 1, 'amber');
END
GO
-- ===============================================================
-- 3. STORED PROCEDURES (28 Stored Procedures)
-- ===============================================================

-- ---------------------------------------------------------------
-- Procedure: sp_AcceptChatSession
-- ---------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.sp_AcceptChatSession
    @SessionId  UNIQUEIDENTIFIER,
    @AgentId    INT,
    @AgentName  NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

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

        IF NOT EXISTS (
            SELECT 1 FROM dbo.Chat_Messages 
            WHERE SessionId = @SessionId AND MessageText LIKE '[Agent Connected]%'
        )
        BEGIN
            DECLARE @JoinMsg NVARCHAR(500) = N'[Agent Connected] Agent ' + @AgentName + N' has joined the live chat. You can now chat directly.';
            
            INSERT INTO dbo.Chat_Messages (SessionId, SenderType, SenderName, MessageText, ThemeColor, SentAt)
            VALUES (@SessionId, 'Bot', 'System', @JoinMsg, 'emerald', GETDATE());
        END
    END

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

-- ---------------------------------------------------------------
-- Procedure: sp_AgentLogin
-- ---------------------------------------------------------------
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

-- ---------------------------------------------------------------
-- Procedure: sp_CloseChatSession
-- ---------------------------------------------------------------
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

    DECLARE @CloseMsg NVARCHAR(500) = N'[Chat Closed] This chat session has been closed by ' + @ClosedBy + N'. Thank you!';

    INSERT INTO dbo.Chat_Messages (SessionId, SenderType, SenderName, MessageText, SentAt)
    VALUES (@SessionId, 'Bot', 'System', @CloseMsg, GETDATE());

    SELECT SessionId, Status, IsCompleted FROM dbo.Bot_Sessions WHERE SessionId = @SessionId;
END

GO

-- ---------------------------------------------------------------
-- Procedure: sp_CreateAgent
-- ---------------------------------------------------------------
CREATE OR ALTER Procedure: dbo.sp_CreateAgent
-- =======================================================
CREATE   PROCEDURE dbo.sp_CreateAgent
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

-- ---------------------------------------------------------------
-- Procedure: sp_CreateTicket
-- ---------------------------------------------------------------
CREATE OR ALTER Procedure: sp_CreateTicket
-- Description: Chatbot ke collected answers se Ticket create karta hai
-- =======================================================
CREATE   PROCEDURE dbo.sp_CreateTicket
    @Name NVARCHAR(150),
    @Mobile VARCHAR(50),
    @Email VARCHAR(150),
    @Enroll_Roll VARCHAR(50),
    @CTypeID INT,
    @Subject NVARCHAR(500),
    @FlagTypeID INT = 1
AS
BEGIN
    SET NOCOUNT ON;

    -- Generate Next Ticket ID (e.g. MVVU-2600111)
    DECLARE @NextNumber INT;
    SELECT @NextNumber = ISNULL(MAX(TRY_CAST(RIGHT(TicketID, 7) AS INT)), 2600110) + 1
    FROM dbo.TblHelpDesk_AM
    WHERE TicketID LIKE 'MVVU-[0-9]%';

    DECLARE @NewTicketID NVARCHAR(50) = 'MVVU-' + CAST(@NextNumber AS NVARCHAR(20));

    -- Insert into Main Ticket Table
    INSERT INTO dbo.TblHelpDesk_AM (
        TicketID, 
        Name, 
        Mobile, 
        Email, 
        Enroll_Roll, 
        CTypeID, 
        FlagTypeID, 
        Status, 
        Subject, 
        CreatedDate, 
        IsActive, 
        ForwardCTypeID, 
        ForwardBy
    )
    VALUES (
        @NewTicketID, 
        @Name, 
        @Mobile, 
        @Email, 
        @Enroll_Roll, 
        @CTypeID, 
        @FlagTypeID, 
        'Open', 
        @Subject, 
        GETDATE(), 
        1, 
        0, 
        0
    );

    -- Return created ticket details
    SELECT 
        h.EntryID,
        h.TicketID,
        h.Name,
        h.Mobile,
        h.Email,
        h.Enroll_Roll,
        ISNULL(c.TypeName, 'Other') AS Category,
        ISNULL(p.FlagType, 'Normal') AS Priority,
        h.Status,
        h.Subject,
        h.CreatedDate
    FROM dbo.TblHelpDesk_AM h
    LEFT JOIN dbo.TblHelpDeskComplaintType_AM c ON h.CTypeID = c.CTypeID
    LEFT JOIN dbo.PriorityType_AM p ON h.FlagTypeID = p.FID
    WHERE h.TicketID = @NewTicketID;
END

GO

-- ---------------------------------------------------------------
-- Procedure: sp_DeleteAgent
-- ---------------------------------------------------------------
CREATE OR ALTER Procedure: dbo.sp_DeleteAgent
-- Safely removes or deactivates an agent
-- =======================================================
CREATE   PROCEDURE dbo.sp_DeleteAgent
    @AgentId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Check if agent has chat history
    IF EXISTS (SELECT 1 FROM dbo.Bot_Sessions WHERE AssignedAgentId = @AgentId)
    BEGIN
        -- Has history: soft-delete so chat logs remain intact
        UPDATE dbo.Agents
        SET 
            IsActive = 0,
            IsOnline = 0
        WHERE AgentId = @AgentId;
    END
    ELSE
    BEGIN
        -- No history: safe to permanently remove
        DELETE FROM dbo.Agents WHERE AgentId = @AgentId;
    END

    SELECT 1 AS Success;
END

GO

-- ---------------------------------------------------------------
-- Procedure: sp_GetAdminDashboardStats
-- ---------------------------------------------------------------
CREATE OR ALTER Procedure: sp_GetAdminDashboardStats
-- =======================================================
CREATE   PROCEDURE dbo.sp_GetAdminDashboardStats
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

-- ---------------------------------------------------------------
-- Procedure: sp_GetAgentById
-- ---------------------------------------------------------------
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

-- ---------------------------------------------------------------
-- Procedure: sp_GetAllAgents
-- ---------------------------------------------------------------
CREATE OR ALTER Procedure: dbo.sp_GetAllAgents
-- =======================================================
CREATE   PROCEDURE dbo.sp_GetAllAgents
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

-- ---------------------------------------------------------------
-- Procedure: sp_GetAvailableAgents
-- ---------------------------------------------------------------
CREATE OR ALTER Procedure: sp_GetAvailableAgents
-- Returns active agents for transfer selection
-- =======================================================
CREATE   PROCEDURE dbo.sp_GetAvailableAgents
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

-- ---------------------------------------------------------------
-- Procedure: sp_GetBotQuestions
-- ---------------------------------------------------------------
CREATE OR ALTER Procedure: sp_GetBotQuestions
-- Description: Chatbot ke active questions step order me return karta hai
-- =======================================================
CREATE   PROCEDURE dbo.sp_GetBotQuestions
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        QuestionId, 
        QuestionText, 
        StepOrder, 
        FieldKey, 
        InputType, 
        IsActive
    FROM dbo.Bot_Questions
    WHERE IsActive = 1
    ORDER BY StepOrder ASC;
END

GO

-- ---------------------------------------------------------------
-- Procedure: sp_GetChatHistory
-- ---------------------------------------------------------------
CREATE OR ALTER Procedure: sp_GetChatHistory
-- =======================================================
CREATE   PROCEDURE dbo.sp_GetChatHistory
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

-- ---------------------------------------------------------------
-- Procedure: sp_GetChatMessages
-- ---------------------------------------------------------------
CREATE OR ALTER Procedure: dbo.sp_GetChatMessages
-- =======================================================
CREATE   PROCEDURE dbo.sp_GetChatMessages
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
        AttachmentUrl,
        AttachmentType,
        AttachmentName,
        ISNULL(ThemeColor, 'emerald') AS ThemeColor,
        SentAt
    FROM dbo.Chat_Messages
    WHERE SessionId = @SessionId
      AND MessageId > @LastMessageId
    ORDER BY MessageId ASC;
END

GO

-- ---------------------------------------------------------------
-- Procedure: sp_GetComplaintTypes
-- ---------------------------------------------------------------
CREATE OR ALTER Procedure: sp_GetComplaintTypes
-- Description: Available complaint categories list return karta hai
-- =======================================================
CREATE   PROCEDURE dbo.sp_GetComplaintTypes
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        CTypeID, 
        TypeName, 
        IsActive, 
        Sequence
    FROM dbo.TblHelpDeskComplaintType_AM
    WHERE IsActive = 1
    ORDER BY Sequence ASC;
END

GO

-- ---------------------------------------------------------------
-- Procedure: sp_GetLiveChatQueue
-- ---------------------------------------------------------------
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

-- ---------------------------------------------------------------
-- Procedure: sp_GetSessionDetails
-- ---------------------------------------------------------------
CREATE OR ALTER Procedure: dbo.sp_GetSessionDetails
-- =======================================================
CREATE   PROCEDURE dbo.sp_GetSessionDetails
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
        ISNULL(s.IsUploadAllowed, 0) AS IsUploadAllowed,
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

-- ---------------------------------------------------------------
-- Procedure: sp_GetTicketStatus
-- ---------------------------------------------------------------
CREATE OR ALTER Procedure: sp_GetTicketStatus
-- Description: TicketID ya Enroll_Roll se ticket live status check karta hai
-- =======================================================
CREATE   PROCEDURE dbo.sp_GetTicketStatus
    @SearchTerm VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        h.EntryID,
        h.TicketID,
        h.Name,
        h.Mobile,
        h.Email,
        h.Enroll_Roll,
        ISNULL(c.TypeName, 'Other') AS Category,
        ISNULL(p.FlagType, 'Normal') AS Priority,
        h.Status,
        h.Subject,
        h.CreatedDate
    FROM dbo.TblHelpDesk_AM h
    LEFT JOIN dbo.TblHelpDeskComplaintType_AM c ON h.CTypeID = c.CTypeID
    LEFT JOIN dbo.PriorityType_AM p ON h.FlagTypeID = p.FID
    WHERE h.TicketID = @SearchTerm OR h.Enroll_Roll = @SearchTerm
    ORDER BY h.EntryID DESC;
END

GO

-- ---------------------------------------------------------------
-- Procedure: sp_RequestLiveAgent
-- ---------------------------------------------------------------
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

-- ---------------------------------------------------------------
-- Procedure: sp_RequestUserUpload
-- ---------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.sp_RequestUserUpload
    @SessionId UNIQUEIDENTIFIER,
    @AgentName NVARCHAR(100),
    @Prompt    NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Bot_Sessions
    SET 
        IsUploadAllowed = 1,
        LastActivityAt  = GETDATE()
    WHERE SessionId = @SessionId;

    DECLARE @MsgText NVARCHAR(500);
    SET @MsgText = N'[Upload Requested] Agent ' + @AgentName + N' requested document/image: ' + ISNULL(NULLIF(@Prompt, ''), N'Please upload the required file or photo.') + N' [Upload button is now active below].';

    INSERT INTO dbo.Chat_Messages (SessionId, SenderType, SenderName, MessageText, ThemeColor, SentAt)
    VALUES (@SessionId, 'Bot', 'System', @MsgText, 'cyan', GETDATE());

    SELECT SessionId, IsUploadAllowed FROM dbo.Bot_Sessions WHERE SessionId = @SessionId;
END

GO

-- ---------------------------------------------------------------
-- Procedure: sp_ResetAgentPassword
-- ---------------------------------------------------------------
CREATE OR ALTER Procedure: dbo.sp_ResetAgentPassword
-- Admin resets an agent's password directly
-- =======================================================
CREATE   PROCEDURE dbo.sp_ResetAgentPassword
    @AgentId     INT,
    @NewPassword NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Agents
    SET Password = @NewPassword
    WHERE AgentId = @AgentId;

    SELECT AgentId, Name, Email, Role, IsActive
    FROM dbo.Agents
    WHERE AgentId = @AgentId;
END

GO

-- ---------------------------------------------------------------
-- Procedure: sp_SaveBotResponse
-- ---------------------------------------------------------------
CREATE OR ALTER Procedure: sp_SaveBotResponse
-- Description: Step-by-step user response store karta hai
-- =======================================================
CREATE   PROCEDURE dbo.sp_SaveBotResponse
    @SessionId UNIQUEIDENTIFIER,
    @QuestionId INT,
    @AnswerText NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    -- Ensure Session exists
    IF NOT EXISTS (SELECT 1 FROM dbo.Bot_Sessions WHERE SessionId = @SessionId)
    BEGIN
        INSERT INTO dbo.Bot_Sessions (SessionId, CurrentStep, IsCompleted, CreatedDate)
        VALUES (@SessionId, 1, 0, GETDATE());
    END

    -- Insert Answer
    INSERT INTO dbo.Bot_Responses (SessionId, QuestionId, AnswerText, SubmittedAt)
    VALUES (@SessionId, @QuestionId, @AnswerText, GETDATE());

    -- Update Session CurrentStep
    UPDATE dbo.Bot_Sessions
    SET CurrentStep = CurrentStep + 1
    WHERE SessionId = @SessionId;

    SELECT CurrentStep, IsCompleted FROM dbo.Bot_Sessions WHERE SessionId = @SessionId;
END

GO

-- ---------------------------------------------------------------
-- Procedure: sp_SaveUploadedFileMessage
-- ---------------------------------------------------------------
CREATE OR ALTER Procedure: dbo.sp_SaveUploadedFileMessage
-- Saves the uploaded file message and immediately locks/deactivates upload
-- =======================================================
CREATE   PROCEDURE dbo.sp_SaveUploadedFileMessage
    @SessionId      UNIQUEIDENTIFIER,
    @SenderType     VARCHAR(20),
    @SenderName     NVARCHAR(100),
    @MessageText    NVARCHAR(MAX),
    @AttachmentUrl  NVARCHAR(500),
    @AttachmentType VARCHAR(50),
    @AttachmentName NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    -- Immediately disable upload permission
    UPDATE dbo.Bot_Sessions
    SET 
        IsUploadAllowed = 0,
        LastActivityAt  = GETDATE()
    WHERE SessionId = @SessionId;

    -- Insert message
    INSERT INTO dbo.Chat_Messages 
        (SessionId, SenderType, SenderName, MessageText, AttachmentUrl, AttachmentType, AttachmentName, ThemeColor, SentAt)
    VALUES 
        (@SessionId, @SenderType, @SenderName, @MessageText, @AttachmentUrl, @AttachmentType, @AttachmentName, 'emerald', GETDATE());

    SELECT TOP 1
        MessageId,
        SessionId,
        SenderType,
        SenderName,
        MessageText,
        AttachmentUrl,
        AttachmentType,
        AttachmentName,
        ISNULL(ThemeColor, 'emerald') AS ThemeColor,
        SentAt
    FROM dbo.Chat_Messages
    WHERE SessionId = @SessionId
    ORDER BY MessageId DESC;
END

GO

-- ---------------------------------------------------------------
-- Procedure: sp_SendChatMessage
-- ---------------------------------------------------------------
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

-- ---------------------------------------------------------------
-- Procedure: sp_SetAgentOnlineStatus
-- ---------------------------------------------------------------
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

-- ---------------------------------------------------------------
-- Procedure: sp_ToggleAgentActive
-- ---------------------------------------------------------------
CREATE OR ALTER Procedure: dbo.sp_ToggleAgentActive
-- =======================================================
CREATE   PROCEDURE dbo.sp_ToggleAgentActive
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

-- ---------------------------------------------------------------
-- Procedure: sp_TransferChatSession
-- ---------------------------------------------------------------
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

    -- Clean system transfer notification message without emoji
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

-- ---------------------------------------------------------------
-- Procedure: sp_UpdateAgent
-- ---------------------------------------------------------------
CREATE OR ALTER Procedure: dbo.sp_UpdateAgent
-- =======================================================
CREATE   PROCEDURE dbo.sp_UpdateAgent
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

-- ---------------------------------------------------------------
-- Procedure: sp_UpdateAgentTheme
-- ---------------------------------------------------------------
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

