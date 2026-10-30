USE [HelpBot_DB];
GO

SET NOCOUNT ON;
GO

-- 1. Update sp_TransferChatSession without any corrupt emojis
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
PRINT 'Updated sp_TransferChatSession successfully.';
GO

-- 2. Update sp_RequestUserUpload without any corrupt emojis
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
PRINT 'Updated sp_RequestUserUpload successfully.';
GO

-- 3. Clean exact Unicode mojibake characters from Chat_Messages
DECLARE @Mojibake NVARCHAR(10);
SET @Mojibake = NCHAR(0x00F0) + NCHAR(0x0178) + NCHAR(0x201D) + NCHAR(0x201E) + N' ';

UPDATE dbo.Chat_Messages
SET MessageText = REPLACE(MessageText, @Mojibake, N'')
WHERE MessageText LIKE N'%' + NCHAR(0x00F0) + N'%';

-- Clean any remaining solitary ð characters
UPDATE dbo.Chat_Messages
SET MessageText = REPLACE(MessageText, NCHAR(0x00F0), N'')
WHERE MessageText LIKE N'%' + NCHAR(0x00F0) + N'%';

-- Clean up any extra spaces
UPDATE dbo.Chat_Messages
SET MessageText = REPLACE(MessageText, N'[Transferred]  Chat', N'[Transferred] Chat')
WHERE MessageText LIKE N'%[Transferred]%';
GO

-- Verify Chat_Messages
SELECT MessageId, SessionId, SenderType, MessageText, SentAt 
FROM dbo.Chat_Messages 
WHERE MessageText LIKE N'%Transferred%' OR MessageText LIKE N'%' + NCHAR(0x00F0) + N'%';
GO
