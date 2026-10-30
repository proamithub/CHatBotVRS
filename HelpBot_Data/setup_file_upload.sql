USE [HelpBot_DB];
GO

-- =======================================================
-- 1. Alter Bot_Sessions for IsUploadAllowed
-- =======================================================
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Bot_Sessions') AND name = 'IsUploadAllowed')
BEGIN
    ALTER TABLE [dbo].[Bot_Sessions] ADD [IsUploadAllowed] BIT DEFAULT 0;
    PRINT 'Added IsUploadAllowed to Bot_Sessions';
END
GO

-- =======================================================
-- 2. Alter Chat_Messages for Attachment details
-- =======================================================
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Chat_Messages') AND name = 'AttachmentUrl')
BEGIN
    ALTER TABLE [dbo].[Chat_Messages] ADD 
        [AttachmentUrl] NVARCHAR(500) NULL,
        [AttachmentType] VARCHAR(50) NULL,
        [AttachmentName] NVARCHAR(255) NULL;
    PRINT 'Added Attachment columns to Chat_Messages';
END
GO

-- =======================================================
-- 3. Stored Procedure: dbo.sp_RequestUserUpload
-- Agent activates the file upload permission for the student
-- =======================================================
CREATE OR ALTER PROCEDURE dbo.sp_RequestUserUpload
    @SessionId UNIQUEIDENTIFIER,
    @AgentName NVARCHAR(100),
    @Prompt    NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Enable upload permission for session
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
PRINT 'Created sp_RequestUserUpload.';
GO

-- =======================================================
-- 4. Stored Procedure: dbo.sp_SaveUploadedFileMessage
-- Saves the uploaded file message and immediately locks/deactivates upload
-- =======================================================
CREATE OR ALTER PROCEDURE dbo.sp_SaveUploadedFileMessage
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
PRINT 'Created sp_SaveUploadedFileMessage.';
GO

-- =======================================================
-- 5. Stored Procedure: dbo.sp_GetChatMessages
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
PRINT 'Updated sp_GetChatMessages.';
GO

-- =======================================================
-- 6. Stored Procedure: dbo.sp_GetSessionDetails
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
PRINT 'Updated sp_GetSessionDetails.';
GO
