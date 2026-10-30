USE [HelpBot_DB];
GO

-- =======================================================
-- 1. Stored Procedure: sp_GetBotQuestions
-- Description: Chatbot ke active questions step order me return karta hai
-- =======================================================
CREATE OR ALTER PROCEDURE dbo.sp_GetBotQuestions
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

-- =======================================================
-- 2. Stored Procedure: sp_GetComplaintTypes
-- Description: Available complaint categories list return karta hai
-- =======================================================
CREATE OR ALTER PROCEDURE dbo.sp_GetComplaintTypes
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

-- =======================================================
-- 3. Stored Procedure: sp_CreateTicket
-- Description: Chatbot ke collected answers se Ticket create karta hai
-- =======================================================
CREATE OR ALTER PROCEDURE dbo.sp_CreateTicket
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

    -- Generate Next Ticket ID (e.g. S-2600111)
    DECLARE @NextNumber INT;
    SELECT @NextNumber = ISNULL(MAX(TRY_CAST(RIGHT(TicketID, 7) AS INT)), 2600110) + 1
    FROM dbo.TblHelpDesk_AM
    WHERE TicketID LIKE 'S-[0-9]%';

    DECLARE @NewTicketID NVARCHAR(50) = 'S-' + CAST(@NextNumber AS NVARCHAR(20));

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

-- =======================================================
-- 4. Stored Procedure: sp_GetTicketStatus
-- Description: TicketID ya Enroll_Roll se ticket live status check karta hai
-- =======================================================
CREATE OR ALTER PROCEDURE dbo.sp_GetTicketStatus
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

-- =======================================================
-- 5. Stored Procedure: sp_SaveBotResponse
-- Description: Step-by-step user response store karta hai
-- =======================================================
CREATE OR ALTER PROCEDURE dbo.sp_SaveBotResponse
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

PRINT 'All HelpBot Stored Procedures created successfully.';
