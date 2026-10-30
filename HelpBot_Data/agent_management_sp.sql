USE [HelpBot_DB];
GO

-- =======================================================
-- 1. Stored Procedure: dbo.sp_DeleteAgent
-- Safely removes or deactivates an agent
-- =======================================================
CREATE OR ALTER PROCEDURE dbo.sp_DeleteAgent
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
PRINT 'Created sp_DeleteAgent.';
GO

-- =======================================================
-- 2. Stored Procedure: dbo.sp_ResetAgentPassword
-- Admin resets an agent's password directly
-- =======================================================
CREATE OR ALTER PROCEDURE dbo.sp_ResetAgentPassword
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
PRINT 'Created sp_ResetAgentPassword.';
GO
