-- =======================================================
-- Database Setup Script for Local Server: VRS-AMITPC\SQLEXPRESS
-- Target Database: HelpBot_DB
-- Tables: Bot_Questions, Bot_Sessions, Bot_Responses
-- =======================================================

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'HelpBot_DB')
BEGIN
    CREATE DATABASE [HelpBot_DB];
    PRINT 'Database [HelpBot_DB] created successfully.';
END
ELSE
BEGIN
    PRINT 'Database [HelpBot_DB] already exists.';
END
GO

USE [HelpBot_DB];
GO

-- =======================================================
-- 1. Bot Questions Table
-- =======================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Bot_Questions')
BEGIN
    CREATE TABLE [dbo].[Bot_Questions] (
        [QuestionId] INT IDENTITY(1,1) PRIMARY KEY,
        [QuestionText] NVARCHAR(500) NOT NULL,
        [StepOrder] INT NOT NULL,
        [FieldKey] NVARCHAR(50) NOT NULL, -- e.g. 'FullName', 'MobileNo', 'Email', 'EnrollNo', 'ProblemDescription'
        [InputType] NVARCHAR(50) DEFAULT 'text', -- 'text', 'email', 'number', etc.
        [IsActive] BIT DEFAULT 1
    );

    -- Seed Initial Questions for the Help Bot
    INSERT INTO [dbo].[Bot_Questions] ([QuestionText], [StepOrder], [FieldKey], [InputType], [IsActive])
    VALUES 
    (N'Namaste! Welcome to Help Desk. Aapka poora naam kya hai?', 1, 'FullName', 'text', 1),
    (N'Aapka Mobile Number enter karein:', 2, 'MobileNo', 'number', 1),
    (N'Aapka Email Address kya hai?', 3, 'Email', 'email', 1),
    (N'Aapka Roll No ya Enrollment No kya hai? (Nahi hai toh NA likhein):', 4, 'EnrollNo', 'text', 1),
    (N'Aapko kya samasya ya help chahiye? Apni samasya detail me likhein:', 5, 'ProblemDescription', 'text', 1);
    
    PRINT 'Bot_Questions table created and seeded.';
END
GO

-- =======================================================
-- 2. Bot Sessions Table (Session tracking)
-- =======================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Bot_Sessions')
BEGIN
    CREATE TABLE [dbo].[Bot_Sessions] (
        [SessionId] UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        [CurrentStep] INT DEFAULT 1,
        [IsCompleted] BIT DEFAULT 0,
        [CreatedDate] DATETIME DEFAULT GETDATE(),
        [CompletedDate] DATETIME NULL
    );
    PRINT 'Bot_Sessions table created.';
END
GO

-- =======================================================
-- 3. Bot User Responses Table (User Answers)
-- =======================================================
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
    PRINT 'Bot_Responses table created.';
END
GO

PRINT 'Local HelpBot database setup complete.';
