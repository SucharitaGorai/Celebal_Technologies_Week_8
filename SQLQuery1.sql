CREATE DATABASE DateDimensionDB;
GO

USE DateDimensionDB;
GO

CREATE TABLE DateDimension (
    Date DATE PRIMARY KEY,                 -- Primary Key
    SKDate INT,                            -- e.g., 20200714
    KeyDate DATE,                          -- Same as Date
    CalendarDay INT,                       -- Day of month (1–31)
    CalendarMonth INT,                     -- Month (1–12)
    CalendarQuarter INT,                   -- Quarter (1–4)
    CalendarYear INT,                      -- e.g., 2020
    DayName VARCHAR(20),                   -- e.g., Tuesday
    DayNameShort VARCHAR(10),              -- e.g., Tue
    DayNumberOfWeek INT,                   -- Sunday = 1 (default in SQL Server)
    DayNumberOfYear INT,                   -- Day number in year (1–365/366)
    DaySuffix VARCHAR(5),                  -- e.g., 14th
    FiscalWeek INT,                        -- Assumed same as calendar week
    FiscalPeriod INT,                      -- Assumed same as month
    FiscalQuarter INT,                     -- Assumed same as calendar quarter
    FiscalYear INT,                        -- Assumed same as calendar year
    FiscalYearPeriod VARCHAR(10)           -- e.g., 202007
);
GO

CREATE PROCEDURE PopulateDateDimension
    @InputDate DATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartDate DATE = DATEFROMPARTS(YEAR(@InputDate), 1, 1);
    DECLARE @EndDate DATE = DATEFROMPARTS(YEAR(@InputDate), 12, 31);

    ;WITH DateSequence AS (
        SELECT @StartDate AS DateValue
        UNION ALL
        SELECT DATEADD(DAY, 1, DateValue)
        FROM DateSequence
        WHERE DateValue < @EndDate
    )
    INSERT INTO DateDimension (
        SKDate,
        KeyDate,
        Date,
        CalendarDay,
        CalendarMonth,
        CalendarQuarter,
        CalendarYear,
        DayName,
        DayNameShort,
        DayNumberOfWeek,
        DayNumberOfYear,
        DaySuffix,
        FiscalWeek,
        FiscalPeriod,
        FiscalQuarter,
        FiscalYear,
        FiscalYearPeriod
    )
    SELECT 
        CONVERT(INT, CONVERT(VARCHAR(8), DateValue, 112)) AS SKDate,
        DateValue AS KeyDate,
        DateValue AS Date,
        DAY(DateValue) AS CalendarDay,
        MONTH(DateValue) AS CalendarMonth,
        DATEPART(QUARTER, DateValue) AS CalendarQuarter,
        YEAR(DateValue) AS CalendarYear,
        DATENAME(WEEKDAY, DateValue) AS DayName,
        LEFT(DATENAME(WEEKDAY, DateValue), 3) AS DayNameShort,
        DATEPART(WEEKDAY, DateValue) AS DayNumberOfWeek,
        DATEPART(DAYOFYEAR, DateValue) AS DayNumberOfYear,
        CAST(DAY(DateValue) AS VARCHAR) + 
            CASE 
                WHEN DAY(DateValue) IN (11,12,13) THEN 'th'
                WHEN RIGHT(CAST(DAY(DateValue) AS VARCHAR),1) = '1' THEN 'st'
                WHEN RIGHT(CAST(DAY(DateValue) AS VARCHAR),1) = '2' THEN 'nd'
                WHEN RIGHT(CAST(DAY(DateValue) AS VARCHAR),1) = '3' THEN 'rd'
                ELSE 'th'
            END AS DaySuffix,
        DATEPART(WEEK, DateValue) AS FiscalWeek, 
        MONTH(DateValue) AS FiscalPeriod,        
        DATEPART(QUARTER, DateValue) AS FiscalQuarter,
        YEAR(DateValue) AS FiscalYear,
        CAST(YEAR(DateValue) AS VARCHAR) + RIGHT('0' + CAST(MONTH(DateValue) AS VARCHAR), 2) AS FiscalYearPeriod
    FROM DateSequence
    OPTION (MAXRECURSION 366); -- To restrict recursion within a year
END;
GO

EXEC PopulateDateDimension '2020-07-14';
GO

SELECT * FROM DateDimension ORDER BY Date;
GO




