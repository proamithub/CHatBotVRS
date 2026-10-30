USE [HelpBot_DB];
GO

SET NOCOUNT ON;

-- =======================================================
-- 1. Clean existing mojibake in Chat_Messages table
-- =======================================================
UPDATE dbo.Chat_Messages
SET MessageText = REPLACE(REPLACE(MessageText, N'ðŸ‘¨â€ ðŸ’¼', N''), N'ðŸ”’', N'')
WHERE MessageText LIKE N'%ð%';

UPDATE dbo.Chat_Messages
SET MessageText = REPLACE(MessageText, N'  ', N' ')
WHERE MessageText LIKE N'%  %';

PRINT 'Cleaned mojibake from existing Chat_Messages records.';
GO

-- =======================================================
-- 2. Update sp_AcceptChatSession without raw unicode emojis
-- Clean plain text that never corrupts across encodings
-- =======================================================
CREATE OR ALTER PROCEDURE dbo.sp_AcceptChatSession
    @SessionId  UNIQUEIDENTIFIER,
    @AgentId    INT,
    @AgentName  NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    -- Only allow accept if session is currently 'WaitingAgent' OR already assigned to this agent
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
            DECLARE @JoinMsg NVARCHAR(500) = N'[Agent Connected] Agent ' + @AgentName + N' ne live chat join kar liya! Ab aap seedha baat kar sakte hain.';
            
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
-- 3. Update sp_CloseChatSession without raw unicode emojis
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

    DECLARE @CloseMsg NVARCHAR(500) = N'[Chat Closed] Chat session ko ' + @ClosedBy + N' dwara close kar diya gaya hai. Thank you!';

    INSERT INTO dbo.Chat_Messages (SessionId, SenderType, SenderName, MessageText, SentAt)
    VALUES (@SessionId, 'Bot', 'System', @CloseMsg, GETDATE());

    SELECT SessionId, Status, IsCompleted FROM dbo.Bot_Sessions WHERE SessionId = @SessionId;
END
GO

PRINT '=== Cleaned SPs and existing messages successfully! ===';
