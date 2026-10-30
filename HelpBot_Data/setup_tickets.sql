USE [HelpBot_DB];
GO

-- =======================================================
-- 1. PriorityType_AM Table & Data
-- =======================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PriorityType_AM')
BEGIN
    CREATE TABLE [dbo].[PriorityType_AM] (
        [FID] INT IDENTITY(1,1) PRIMARY KEY,
        [FlagType] VARCHAR(100) NULL,
        [IsActive] INT NOT NULL DEFAULT 1,
        [Color] VARCHAR(50) NULL,
        [Sequence] INT NOT NULL DEFAULT 0
    );

    SET IDENTITY_INSERT [dbo].[PriorityType_AM] ON;
    INSERT INTO [dbo].[PriorityType_AM] ([FID], [FlagType], [IsActive], [Color], [Sequence]) VALUES
    (1, 'Normal', 1, '', 4),
    (2, 'High', 1, 'red', 1),
    (3, 'Medium', 1, 'orange', 2),
    (4, 'Low', 1, '', 3);
    SET IDENTITY_INSERT [dbo].[PriorityType_AM] OFF;

    PRINT 'PriorityType_AM created and seeded.';
END
GO

-- =======================================================
-- 2. TblHelpDeskComplaintType_AM Table & Data
-- =======================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TblHelpDeskComplaintType_AM')
BEGIN
    CREATE TABLE [dbo].[TblHelpDeskComplaintType_AM] (
        [CTypeID] INT PRIMARY KEY,
        [TypeName] VARCHAR(100) NOT NULL,
        [Details] NVARCHAR(150) NULL,
        [IsActive] BIT DEFAULT 1,
        [Sequence] INT NOT NULL DEFAULT 0,
        [AlertMsg] NVARCHAR(500) NULL
    );

    INSERT INTO [dbo].[TblHelpDeskComplaintType_AM] ([CTypeID], [TypeName], [IsActive], [Sequence]) VALUES
    (0, 'Other', 1, 99),
    (1, 'IGRS', 1, 1),
    (2, 'Enrollment', 1, 2),
    (3, 'Verification', 1, 3),
    (4, 'Provisional Certificate', 1, 4),
    (5, 'Migration Certificate', 1, 5),
    (6, 'Transcript', 1, 6),
    (7, 'Duplicate Marksheet', 1, 7),
    (8, 'Degree', 1, 8),
    (11, 'Online Result Correction', 1, 9),
    (12, 'Online Examination Form Filling', 1, 10),
    (13, 'Online Admission Form Filling', 1, 11),
    (14, 'TN-No', 1, 12);

    PRINT 'TblHelpDeskComplaintType_AM created and seeded.';
END
GO

-- =======================================================
-- 3. TblHelpDesk_AM (Main Tickets Table)
-- =======================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TblHelpDesk_AM')
BEGIN
    CREATE TABLE [dbo].[TblHelpDesk_AM] (
        [EntryID] BIGINT IDENTITY(1,1) PRIMARY KEY,
        [HelpID] NVARCHAR(50) NULL,
        [TicketID] NVARCHAR(50) NOT NULL,
        [Subject] NVARCHAR(500) NOT NULL,
        [Email] VARCHAR(150) NULL,
        [Name] NVARCHAR(150) NULL,
        [Mobile] VARCHAR(50) NULL,
        [CreatedDate] DATETIME NOT NULL DEFAULT GETDATE(),
        [IsActive] BIT NOT NULL DEFAULT 1,
        [Status] VARCHAR(50) DEFAULT 'Open',
        [Enroll_Roll] VARCHAR(50) NOT NULL,
        [CTypeID] INT NOT NULL DEFAULT 0,
        [FlagTypeID] INT NOT NULL DEFAULT 1,
        [ForwardCTypeID] INT NOT NULL DEFAULT 0,
        [ForwardBy] INT NOT NULL DEFAULT 0,
        [ForwardDateTime] DATETIME NULL,
        [IpAddress] VARCHAR(100) NULL,
        [ProfilePic] VARCHAR(500) NULL,
        [Roll] VARCHAR(15) NULL,
        [Remark] VARCHAR(50) NULL
    );

    PRINT 'TblHelpDesk_AM created.';
END
GO

-- =======================================================
-- 4. Insert 10 Sample Tickets
-- =======================================================
DELETE FROM [dbo].[TblHelpDesk_AM];

INSERT INTO [dbo].[TblHelpDesk_AM] 
([TicketID], [Name], [Mobile], [Email], [Enroll_Roll], [CTypeID], [FlagTypeID], [Status], [Subject], [CreatedDate], [IsActive], [ForwardCTypeID], [ForwardBy])
VALUES
('MVVU-2600101', N'Aman Sharma', '9876543210', 'aman.sharma@gmail.com', 'MVVU/24/10452', 12, 1, 'Open', N'Examination form submit nahi ho raha hai, server error aa raha hai.', DATEADD(day, -5, GETDATE()), 1, 0, 0),
('MVVU-2600102', N'Pooja Verma', '9812345678', 'pooja.verma99@gmail.com', 'MVVU/23/08912', 11, 2, 'Pending', N'3rd Semester mark sheet me Father ka naam galat print hua hai.', DATEADD(day, -4, GETDATE()), 1, 0, 0),
('MVVU-2600103', N'Rohan Gupta', '9723456789', 'rohan.gupta@yahoo.com', '241008129034', 5, 1, 'In-Progress', N'Migration certificate ke liye apply kiya tha, status pending dikha raha hai.', DATEADD(day, -4, GETDATE()), 1, 0, 0),
('MVVU-2600104', N'Sneha Singh', '9934567890', 'sneha.singh21@gmail.com', 'MVVU/22/05431', 4, 1, 'Resolved', N'Job interview ke liye urgent Provisional Certificate chahiye.', DATEADD(day, -3, GETDATE()), 1, 0, 0),
('MVVU-2600105', N'Vikram Patel', '9645678901', 'vikram.patel@outlook.com', '231005671029', 8, 3, 'Pending', N'Degree certificate dispatch hua ya nahi? Tracking number provide karein.', DATEADD(day, -3, GETDATE()), 1, 0, 0),
('MVVU-2600106', N'Ananya Mishra', '9556789012', 'ananya.mishra@gmail.com', 'MVVU/25/12098', 2, 2, 'Open', N'Enrollment number abhi tak generate nahi hua, admission confirm ho chuka hai.', DATEADD(day, -2, GETDATE()), 1, 0, 0),
('MVVU-2600107', N'Deepak Yadav', '9467890123', 'deepak.yadav92@gmail.com', '221004561088', 7, 1, 'Open', N'Final year original mark sheet kho gayi hai, Duplicate Marksheet ki process batayein.', DATEADD(day, -2, GETDATE()), 1, 0, 0),
('MVVU-2600108', N'Kavita Devi', '9378901234', 'kavita.devi@rediffmail.com', 'MVVU/24/33210', 1, 2, 'In-Progress', N'IGRS portal par complaint darj ki thi, reply ka intezar hai.', DATEADD(day, -1, GETDATE()), 1, 0, 0),
('MVVU-2600109', N'Rahul Kumar', '9289012345', 'rahul.kumar01@gmail.com', '251009871145', 12, 1, 'Resolved', N'Admit card download link par error 404 aa raha tha.', DATEADD(hour, -12, GETDATE()), 1, 0, 0),
('MVVU-2600110', N'Priya Soni', '9190123456', 'priya.soni2026@gmail.com', 'MVVU/25/44120', 0, 1, 'Open', N'Student portal login password reset email nahi aa raha hai.', GETDATE(), 1, 0, 0);

PRINT '10 Sample tickets inserted successfully into TblHelpDesk_AM.';
GO
