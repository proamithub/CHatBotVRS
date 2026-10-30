USE [HelpBot_DB];
GO

SET NOCOUNT ON;

-- =======================================================
-- 1. Update Bot_Questions to English
-- =======================================================
UPDATE dbo.Bot_Questions
SET QuestionText = 'Welcome to the HelpDesk! What is your full name?'
WHERE QuestionId = 1;

UPDATE dbo.Bot_Questions
SET QuestionText = 'Please enter your Mobile Number:'
WHERE QuestionId = 2;

UPDATE dbo.Bot_Questions
SET QuestionText = 'Please enter your Email Address:'
WHERE QuestionId = 3;

UPDATE dbo.Bot_Questions
SET QuestionText = 'What is your Roll No or Enrollment No? (Enter ''NA'' if not applicable):'
WHERE QuestionId = 4;

UPDATE dbo.Bot_Questions
SET QuestionText = 'Please describe the issue or assistance you require in detail:'
WHERE QuestionId = 5;

PRINT 'Updated Bot_Questions to English.';
GO

-- =======================================================
-- 2. Update sp_AcceptChatSession to English
-- =======================================================
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

-- =======================================================
-- 3. Update sp_CloseChatSession to English
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

    DECLARE @CloseMsg NVARCHAR(500) = N'[Chat Closed] This chat session has been closed by ' + @ClosedBy + N'. Thank you!';

    INSERT INTO dbo.Chat_Messages (SessionId, SenderType, SenderName, MessageText, SentAt)
    VALUES (@SessionId, 'Bot', 'System', @CloseMsg, GETDATE());

    SELECT SessionId, Status, IsCompleted FROM dbo.Bot_Sessions WHERE SessionId = @SessionId;
END
GO

-- =======================================================
-- 4. Update sp_RequestLiveAgent to English
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

PRINT '=== All SQL procedures and questions converted to English successfully! ===';
