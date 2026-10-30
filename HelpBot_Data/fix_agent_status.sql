USE [HelpBot_DB];
GO

-- =======================================================
-- FIX: Agent Default IsOnline = 0 (Offline by default)
-- Agent tabhi Online hoga jab login karega
-- =======================================================

-- Existing agents ko offline kar do (reset)
UPDATE [dbo].[Agents] SET [IsOnline] = 0 WHERE [IsActive] = 1;
PRINT 'All agents set to offline (IsOnline = 0)';
GO

-- Default constraint bhi fix karo
IF EXISTS (
    SELECT 1 FROM sys.default_constraints 
    WHERE parent_object_id = OBJECT_ID('Agents') 
    AND COL_NAME(parent_object_id, parent_column_id) = 'IsOnline'
)
BEGIN
    DECLARE @ConstraintName NVARCHAR(200);
    SELECT @ConstraintName = name 
    FROM sys.default_constraints 
    WHERE parent_object_id = OBJECT_ID('Agents') 
      AND COL_NAME(parent_object_id, parent_column_id) = 'IsOnline';
    
    EXEC('ALTER TABLE [dbo].[Agents] DROP CONSTRAINT [' + @ConstraintName + ']');
    PRINT 'Old IsOnline default constraint dropped';
END
GO

ALTER TABLE [dbo].[Agents] ADD DEFAULT 0 FOR [IsOnline];
PRINT 'IsOnline default set to 0 (Offline)';
GO

-- =======================================================
-- FIX: sp_GetLiveChatQueue
-- "Live" sessions sirf us agent ko dikhein jo uska assigned agent hai
-- "WaitingAgent" sessions sab agents dekh sakte hain
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
        (SELECT COUNT(1) FROM dbo.Chat_Messages m 
         WHERE m.SessionId = s.SessionId) AS TotalMessages,
        (SELECT TOP 1 m.MessageText FROM dbo.Chat_Messages m 
         WHERE m.SessionId = s.SessionId ORDER BY m.MessageId DESC) AS LastMessage,
        (SELECT COUNT(1) FROM dbo.Agents 
         WHERE IsOnline = 1 AND IsActive = 1) AS OnlineAgentCount
    FROM dbo.Bot_Sessions s
    WHERE s.IsCompleted = 0
      AND s.Status IN ('WaitingAgent', 'Live', 'Bot')
      AND (
          -- WaitingAgent: sabhi active agents dekh sakte hain
          s.Status = 'WaitingAgent'
          OR
          -- Live: sirf assigned agent dekh sakta hai
          (s.Status = 'Live' AND (@AgentId IS NULL OR s.AssignedAgentId = @AgentId))
          OR
          -- Bot sessions: ignore (show karo lekin accept nahi)
          s.Status = 'Bot'
      )
    ORDER BY 
        CASE WHEN s.Status = 'WaitingAgent' THEN 1
             WHEN s.Status = 'Live'         THEN 2
             ELSE 3 END ASC,
        s.LastActivityAt DESC;
END
GO

PRINT '=== Agent Status Fixes Applied Successfully! ===';
