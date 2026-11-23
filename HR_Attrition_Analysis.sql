-- ============================================================
--  HR ATTRITION ANALYSIS - SQL Server Project
--  Author  : Javariya Sohail
--  Tool    : SQL Server Management Studio (SSMS)
--  Dataset : HR Analytics - Employee Attrition (1,480 raw rows, 1,470 unique employees)
--  Purpose : Load -> clean -> normalise -> analyse -> BI views for Power BI
--  Setup   : CREATE DATABASE HR_ATTRITION; then import data/HR_Analytics.csv
--            as table dbo.HR_Analytics (SSMS > Tasks > Import Flat File).
-- ============================================================

USE HR_ATTRITION;
GO

SELECT TOP 20 * FROM HR_Analytics;

SELECT COUNT(*) AS TotalRows FROM HR_Analytics;

SELECT DISTINCT Attrition FROM HR_Analytics;
SELECT DISTINCT OverTime FROM HR_Analytics;

IF OBJECT_ID('dbo.EmployeeDetails', 'U') IS NOT NULL DROP TABLE EmployeeDetails;
IF OBJECT_ID('dbo.Employees',       'U') IS NOT NULL DROP TABLE Employees;
GO

CREATE TABLE Employees (
    EmployeeID              INT IDENTITY(1,1) PRIMARY KEY,
    EmpCode                 VARCHAR(20)     NOT NULL UNIQUE,
    Age                     TINYINT         NOT NULL,
    AgeGroup                VARCHAR(10)     NOT NULL,
    Gender                  VARCHAR(10)     NOT NULL,
    MaritalStatus           VARCHAR(15)     NOT NULL,
    Education               TINYINT         NOT NULL,
    EducationField          VARCHAR(50)     NOT NULL,
    Department              VARCHAR(50)     NOT NULL,
    JobRole                 VARCHAR(60)     NOT NULL,
    JobLevel                TINYINT         NOT NULL,
    EmployeeNumber          SMALLINT        NOT NULL
);
 
CREATE TABLE EmployeeDetails (
    DetailID                    INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID                  INT             NOT NULL,
    Attrition                   BIT             NOT NULL,
    BusinessTravel              VARCHAR(30)     NOT NULL,
    OverTime                    BIT             NOT NULL,
    DailyRate                   SMALLINT        NOT NULL,
    HourlyRate                  SMALLINT        NOT NULL,
    MonthlyIncome               INT             NOT NULL,
    MonthlyRate                 INT             NOT NULL,
    SalarySlab                  VARCHAR(15)     NOT NULL,
    PercentSalaryHike           TINYINT         NOT NULL,
    StockOptionLevel            TINYINT         NOT NULL,
    EnvironmentSatisfaction     TINYINT         NOT NULL,
    JobInvolvement              TINYINT         NOT NULL,
    JobSatisfaction             TINYINT         NOT NULL,
    RelationshipSatisfaction    TINYINT         NOT NULL,
    WorkLifeBalance             TINYINT         NOT NULL,
    PerformanceRating           TINYINT         NOT NULL,
    NumCompaniesWorked          TINYINT         NOT NULL,
    TotalWorkingYears           TINYINT         NOT NULL,
    TrainingTimesLastYear       TINYINT         NOT NULL,
    YearsAtCompany              TINYINT         NOT NULL,
    YearsInCurrentRole          TINYINT         NOT NULL,
    YearsSinceLastPromotion     TINYINT         NOT NULL,
    YearsWithCurrManager        TINYINT             NULL,
    DistanceFromHome            TINYINT         NOT NULL,
    CONSTRAINT FK_EmployeeDetails_Employees
        FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID)
);

INSERT INTO Employees (
    EmpCode, Age, AgeGroup, Gender, MaritalStatus,
    Education, EducationField, Department, JobRole, JobLevel, EmployeeNumber
)
SELECT DISTINCT
    EmpID,
    CAST(Age            AS TINYINT),
    AgeGroup,
    Gender,
    MaritalStatus,
    CAST(Education      AS TINYINT),
    EducationField,
    Department,
    JobRole,
    CAST(JobLevel       AS TINYINT),
    CAST(EmployeeNumber AS SMALLINT)
FROM HR_Analytics;
 
-- The raw file holds 10 employees (RM1461-RM1470) twice. Keep one row per EmpID,
-- otherwise the join below loads 1,480 detail rows and inflates every KPI.
;WITH Deduped AS (
    SELECT r.*,
           ROW_NUMBER() OVER (
               PARTITION BY r.EmpID
               ORDER BY TRY_CAST(r.YearsWithCurrManager AS INT) DESC
           ) AS rn
    FROM HR_Analytics r
)
INSERT INTO EmployeeDetails (
    EmployeeID, Attrition, BusinessTravel, OverTime,
    DailyRate, HourlyRate, MonthlyIncome, MonthlyRate, SalarySlab,
    PercentSalaryHike, StockOptionLevel,
    EnvironmentSatisfaction, JobInvolvement, JobSatisfaction,
    RelationshipSatisfaction, WorkLifeBalance, PerformanceRating,
    NumCompaniesWorked, TotalWorkingYears, TrainingTimesLastYear,
    YearsAtCompany, YearsInCurrentRole, YearsSinceLastPromotion,
    YearsWithCurrManager, DistanceFromHome
)
SELECT
    e.EmployeeID,
    CAST(r.Attrition AS BIT),
    CASE
        WHEN REPLACE(r.BusinessTravel, '_', '') = 'TravelRarely'     THEN 'Travel_Rarely'
        WHEN REPLACE(r.BusinessTravel, '_', '') = 'TravelFrequently' THEN 'Travel_Frequently'
        ELSE r.BusinessTravel
    END,
    CAST(r.OverTime AS BIT),
    CAST(r.DailyRate                AS SMALLINT),
    CAST(r.HourlyRate               AS SMALLINT),
    CAST(r.MonthlyIncome            AS INT),
    CAST(r.MonthlyRate              AS INT),
    r.SalarySlab,
    CAST(r.PercentSalaryHike        AS TINYINT),
    CAST(r.StockOptionLevel         AS TINYINT),
    CAST(r.EnvironmentSatisfaction  AS TINYINT),
    CAST(r.JobInvolvement           AS TINYINT),
    CAST(r.JobSatisfaction          AS TINYINT),
    CAST(r.RelationshipSatisfaction AS TINYINT),
    CAST(r.WorkLifeBalance          AS TINYINT),
    CAST(r.PerformanceRating        AS TINYINT),
    CAST(r.NumCompaniesWorked       AS TINYINT),
    CAST(r.TotalWorkingYears        AS TINYINT),
    CAST(r.TrainingTimesLastYear    AS TINYINT),
    CAST(r.YearsAtCompany           AS TINYINT),
    CAST(r.YearsInCurrentRole       AS TINYINT),
    CAST(r.YearsSinceLastPromotion  AS TINYINT),
    TRY_CAST(r.YearsWithCurrManager AS TINYINT),
    CAST(r.DistanceFromHome         AS TINYINT)
FROM Deduped r
JOIN Employees e ON e.EmpCode = r.EmpID
WHERE r.rn = 1;
GO

SELECT COUNT(*) AS EmployeesLoaded FROM Employees;
SELECT COUNT(*) AS Employee_Details FROM EmployeeDetails;

SELECT DISTINCT BusinessTravel FROM EmployeeDetails ORDER BY BusinessTravel

SELECT COUNT(*) AS NullMngYrs FROM EmployeeDetails WHERE YearsWithCurrManager is null;

SELECT Attrition, COUNT(*) AS EMployeeCount FROM EmployeeDetails GROUP BY Attrition

-- Orphan check: detail rows with no matching employee (expect 0)
SELECT COUNT(*) AS OrphanRows
FROM EmployeeDetails ed
LEFT JOIN Employees e ON e.EmployeeID = ed.EmployeeID
WHERE e.EmployeeID IS NULL;

--attrition
SELECT COUNT(*) AS TotalEmp, SUM(CAST(Attrition AS INT)) AS attritionCount,
COUNT(*)-SUM(CAST(Attrition AS INT)) AS ActiveEmp,
ROUND(SUM(CAST(Attrition AS INT)) * 100.0 / COUNT(*), 2) AS AttritionRate_pct 
FROM EmployeeDetails

SELECT e.Department,COUNT(*) AS TotalEmp, SUM(Cast(ed.Attrition AS INT))
AS AttritionCount, ROUND(SUM(CAST(ed.Attrition AS INT)) * 100.0 / COUNT(*), 2) AS AttritionRatepct
FROM Employees e
JOIN EmployeeDetails ed ON e.EmployeeID = ed.EmployeeID
GROUP BY e.Department ORDER BY AttritionRatepct DESC;

SELECT CASE WHEN ed.Attrition = 1 THEN 'Left' ELSE 'Stayed' END AS Status,
COUNT(*) AS HeadCount, 
AVG(ed.MonthlyIncome) AS avgMonthlyIncome,
MIN(ed.MonthlyIncome) AS MinIncome,
MAX(ed.MonthlyIncome) AS MaxIncome
FROM EmployeeDetails ed
GROUP BY ed.Attrition ORDER BY ed.Attrition DESC;

SELECT 
    ed.SalarySlab, 
    COUNT(*) AS TotalEmployees, 
    SUM(CAST(ed.Attrition AS INT)) AS AttritionCount,
    ROUND(SUM(CAST(ed.Attrition AS INT)) * 100.0 / COUNT(*), 2) AS AttritionRatepct,
    AVG(ed.MonthlyIncome) AS AvgIncome
FROM 
    EmployeeDetails ed
GROUP BY 
    ed.SalarySlab 
ORDER BY
    CASE ed.SalarySlab
        WHEN 'Upto 5k' THEN 1
        WHEN '5k-10k' THEN 2      
        WHEN '10k-15k' THEN 3   
        WHEN '15k+' THEN 4
    END;

SELECT e.JobRole, COUNT(*) AS TotalEmployees,
SUM(CAST(ed.Attrition AS INT)) AS AttritionCount,
ROUND(SUM(CAST(ed.Attrition AS INT)) * 100.0 / COUNT(*), 2) AS AttritionRatepct,
AVG(ed.MonthlyIncome) AS AvgIncome,
ROUND(AVG(CAST(ed.JobSatisfaction AS FLOAT)), 2) AS avgJobSatisfaction
FROM Employees e
JOIN EmployeeDetails ed ON e.EmployeeID = ed.EmployeeID
GROUP BY e.JobRole
ORDER BY AttritionRatepct desc;

SELECT CASE WHEN ed.Overtime = 1 THEN 'Yes' ELSE 'No' END AS DoesOverTime,
COUNT(*) AS TotalEmployees, SUM (CAST(ed.Attrition AS INT)) AS AttritionCount,
ROUND(SUM(CAST(ed.Attrition AS INT)) * 100.0 / COUNT(*), 2) AS AttritionRate_pct,
AVG(ed.MonthlyIncome) AS avgIncome
FROM EmployeeDetails ed GROUP BY ed.OverTime ORDER BY ed.Overtime DESC;

SELECT e.Department, ROUND(AVG(CASE WHEN ed.Overtime = 0 THEN CAST (ed.Attrition AS FLOAT) END) * 100,1)
AS AttritionPct_NoOT,
ROUND(AVG(CASE WHEN ed.Overtime = 1 THEN CAST (ed.Attrition AS FLOAT) END) * 100,1)
AS AttritionPct_WithOT
FROM Employees e JOIN EmployeeDetails ed ON e.EmployeeID = ed.EmployeeID
GROUP BY e.Department ORDER BY AttritionPct_WithOT desc;

SELECT e.AgeGroup, COUNT(*) AS totalEmployees,
SUM(CAST(ed.Attrition AS INT)) AS AttritionCount,
ROUND(SUM(CAST(ed.Attrition AS INT)) * 100.0 / COUNT(*),2) AS AttritionRatePct,
AVG(ed.MonthlyIncome) AS AvgIncome
FROM Employees e JOIN EmployeeDetails ed ON e.EmployeeID = ed.EmployeeID
GROUP BY e.AgeGroup ORDER BY
CASE e.AgeGroup 
WHEN '18-25' THEN 1
WHEN '26-35' THEN 2
WHEN '36-45' THEN 3
WHEN '46-55' THEN 4
ELSE 5
END;

SELECT e.Gender, COUNT(*) AS totalEmployees,
SUM(CAST(ed.Attrition AS INT)) AS AttritionCount,
ROUND(SUM(CAST(ed.Attrition AS INT)) * 100.0 / COUNT(*),2) AS AttritionRatePct,
AVG(ed.MonthlyIncome) AS AvgIncome
FROM Employees e JOIN EmployeeDetails ed ON e.EmployeeID = ed.EmployeeID
GROUP BY e.Gender ORDER BY AttritionRatePct desc;

SELECT e.MaritalStatus, COUNT(*) AS totalEmployees,
SUM(CAST(ed.Attrition AS INT)) AS AttritionCount,
ROUND(SUM(CAST(ed.Attrition AS INT)) * 100.0 / COUNT(*),2) AS AttritionRatePct,
AVG(ed.MonthlyIncome) AS AvgIncome
FROM Employees e JOIN EmployeeDetails ed ON e.EmployeeID = ed.EmployeeID
GROUP BY e.MaritalStatus ORDER BY AttritionRatePct desc;

SELECT CASE WHEN ed.YearsAtCompany <=2 THEN '0-2 yrs (new)'
WHEN ed.YearsAtCompany <=5 THEN '3-5 yrs (Developing)'
WHEN ed.YearsAtCompany <=10 THEN '6-10 yrs(Established)'
ELSE '10+ yrs'
END AS TenureBand,
COUNT(*) AS TotalEmployees,
SUM(CAST(ed.Attrition AS INT)) AS AttritionCount,
ROUND(SUM(CAST(ed.Attrition AS INT)) * 100.0 / COUNT(*),2) AS AttritionRatePct,
AVG(ed.MonthlyIncome) AS AvgIncome,
AVG(ed.YearsSinceLastPromotion) AS AvgYrsSinceLastP FROM EmployeeDetails ed
GROUP BY
CASE WHEN ed.YearsAtCompany <=2 THEN '0-2 yrs (new)'
WHEN ed.YearsAtCompany <=5 THEN '3-5 yrs (Developing)'
WHEN ed.YearsAtCompany <=10 THEN '6-10 yrs(Established)'
ELSE '10+ yrs'
END
ORDER BY MIN(ed.YearsAtCompany);

SELECT ed.YearsSinceLastPromotion, COUNT(*) AS TotalEmployees,
SUM(CAST(ed.Attrition AS INT)) AS AttritionCount,
ROUND(SUM(CAST(ed.Attrition AS INT)) * 100.0 / COUNT(*), 2) AS AttritionRatePct
FROM EmployeeDetails ed 
GROUP BY ed.YearsSinceLastPromotion ORDER BY ed.YearsSinceLastPromotion

SELECT e.EducationField, COUNT(*) AS TotalEmployees, 
SUM(CAST(ed.Attrition AS INT)) AS AttritionCount,
ROUND(SUM(CAST(ed.Attrition AS int)) * 100.0/ COUNT(*),2) AS AttritionRatePct
FROM Employees e 
JOIN EmployeeDetails ed ON e.EmployeeID = ed.EmployeeID
GROUP BY e.EducationField ORDER BY AttritionRatePct DESC;

SELECT ed.BusinessTravel, COUNT(*) AS TotalEmployees,
SUM(CAST(ed.Attrition AS INT)) AS AttritionCount,
ROUND(SUM(CAST(ed.Attrition AS int)) * 100.0/ COUNT(*),2) AS AttritionRatePct,
AVG(ed.MonthlyIncome) AS AvgIncome
FROM EmployeeDetails ed GROUP BY ed.BusinessTravel
ORDER BY AttritionRatePct DESC;

SELECT ed.StockOptionLevel,COUNT(*) AS TotalEmployees,
SUM(CAST(ed.Attrition AS INT)) AS AttritionCount,
ROUND(SUM(CAST(ed.Attrition AS int)) * 100.0/ COUNT(*),2) AS AttritionRatePct,
AVG(ed.MonthlyIncome) AS AvgIncome
FROM EmployeeDetails ed 
GROUP BY ed.StockOptionLevel
ORDER BY AttritionRatePct DESC;

SELECT 
CASE    
    WHEN ed.DistanceFromHome <= 5 THEN 'Near (1-5)'
    WHEN ed.DistanceFromHome <= 15 THEN 'Medium (6-15)'
    ELSE 'Far(16+)'
    END AS DistanceBand,
    COUNT(*) AS TotalEmployees,
SUM(CAST(ed.Attrition AS INT)) AS AttritionCount,
ROUND(SUM(CAST(ed.Attrition AS int)) * 100.0/ COUNT(*),2) AS AttritionRatePct
FROM EmployeeDetails ed
GROUP BY 
CASE 
    WHEN ed.DistanceFromHome <= 5 THEN 'Near (1-5)'
    WHEN ed.DistanceFromHome <= 15 THEN 'Medium (6-15)'
    ELSE 'Far(16+)'
    END
order by AttritionRatePct DESC;

SELECT ed.NumCompaniesWorked, COUNT(*) AS TotalEmployees,
SUM(CAST(ed.Attrition AS INT)) AS AttritionCount,
ROUND(SUM(CAST(ed.Attrition AS int)) * 100.0/ COUNT(*),2) AS AttritionRatePct
FROM EmployeeDetails ed
GROUP BY ed.NumCompaniesWorked
ORDER BY AttritionRatePct DESC;

-- VIEWS FOR POWER BI
CREATE OR ALTER VIEW 
vw_OverallAttrition 
AS 
SELECT 
    COUNT(*) as TotalEmployees,
    SUM(CAST(Attrition AS int)) AS AttritionCount,
    COUNT(*) - SUM(CAST(Attrition AS INT)) AS ActiveEmployees,
    ROUND(SUM(CAST(Attrition AS int)) * 100.0/ COUNT(*),2) AS AttritionRatePct
    FROM EmployeeDetails
GO

CREATE OR ALTER VIEW
vw_DepartmentAttrition AS
SELECT
    e.Department, COUNT(*) AS TotalEmployees,
    SUM(CAST(Attrition AS int)) AS AttritionCount,
    ROUND(SUM(CAST(Attrition AS int)) * 100.0/ COUNT(*),2) AS AttritionRatePct,
    ROUND(AVG(ed.MonthlyIncome), 2) AS AvgIncome
    FROM Employees e
    JOIN EmployeeDetails ed
    ON e.EmployeeID = ed.EmployeeID
    GROUP BY e.Department
GO

CREATE OR ALTER VIEW
vw_EducationFieldAttrition AS
SELECT
    e.EducationField, COUNT(*) AS TotalEmployees,
    SUM(CAST(Attrition AS int)) AS AttritionCount,
    ROUND(SUM(CAST(Attrition AS int)) * 100.0/ COUNT(*),2) AS AttritionRatePct,
    ROUND(AVG(ed.MonthlyIncome), 2) AS AvgIncome
    FROM Employees e
    JOIN EmployeeDetails ed
    ON e.EmployeeID = ed.EmployeeID
    GROUP BY e.EducationField
GO

CREATE OR ALTER VIEW
vw_BusinesstravelAttrition AS
SELECT
    ed.BusinessTravel, COUNT(*) AS TotalEmployees,
    SUM(CAST(Attrition AS int)) AS AttritionCount,
    ROUND(SUM(CAST(Attrition AS int)) * 100.0/ COUNT(*),2) AS AttritionRatePct,
    ROUND(AVG(ed.MonthlyIncome), 2) AS AvgIncome
    FROM Employees e
    JOIN EmployeeDetails ed
    ON e.EmployeeID = ed.EmployeeID
    GROUP BY ed.BusinessTravel
GO

CREATE OR ALTER VIEW
vw_JobroleAttrition AS
SELECT
    e.JobRole, COUNT(*) AS TotalEmployees,
    SUM(CAST(ed.Attrition AS int)) AS AttritionCount,
    ROUND(SUM(CAST(Attrition AS int)) * 100.0/ COUNT(*),2) AS AttritionRatePct,
    ROUND(AVG(ed.MonthlyIncome), 2) AS AvgIncome,
    ROUND(AVG(CAST(ED.JobSatisfaction AS FLOAT)),2) AS AvgJobSatisfaction
    FROM Employees e
    JOIN EmployeeDetails ed
    ON e.EmployeeID = ed.EmployeeID
    GROUP BY e.JobRole
GO

CREATE OR ALTER VIEW
vw_SalarySlabAttrition AS
SELECT
    ed.SalarySlab, COUNT(*) AS TotalEmployees,
    SUM(CAST(Attrition AS int)) AS AttritionCount,
    ROUND(SUM(CAST(Attrition AS int)) * 100.0/ COUNT(*),2) AS AttritionRatePct,
    ROUND(AVG(ed.MonthlyIncome), 2) AS AvgIncome
    FROM Employees e
    JOIN EmployeeDetails ed
    ON e.EmployeeID = ed.EmployeeID
    GROUP BY ed.SalarySlab
GO

CREATE OR ALTER VIEW 
vw_OverTimeAttrition
AS 
SELECT
    CASE 
        WHEN ed.Overtime = 1 THEN 'Yes'
        ELSE 'No'
        END AS DoesOvertime,
        COUNT(*) AS totalEmployees,
        SUM(CAST(ed.Attrition AS INT)) AS AttritionCount,
        ROUND(SUM(CAST(Attrition AS int)) * 100.0/ COUNT(*),2) AS AttritionRatePct,
        ROUND(AVG(ed.MonthlyIncome), 2) AS AvgIncome
        FROM EmployeeDetails ed
GROUP BY ed.OverTime;
GO

CREATE OR ALTER VIEW
vw_DepartmentOvertimeAttrition
AS 
SELECT
    e.Department,
    ROUND(
        AVG(
            CASE
                WHEN ed.Overtime= 0 THEN 
                CAST(ed.Attrition AS FLOAT)
                END
                )* 100, 2) AS AttritionPct_NoOt,
                ROUND(AVG(
                        CASE
                            WHEN ed.Overtime = 1
                            THEN 
                            CAST(ed.Attrition AS FLOAT) 
                            END
                            )*100,
                            2) AS AttritioPct_WithOt
                            FROM Employees e 
                            JOIN EmployeeDetails ed
                            ON e.EmployeeID =ed.EmployeeID 
        GROUP BY e.Department
GO

CREATE OR ALTER VIEW
vw_ageGroupAttrition AS
SELECT
    e.AgeGroup, COUNT(*) AS TotalEmployees,
    SUM(CAST(Attrition AS int)) AS AttritionCount,
    ROUND(SUM(CAST(Attrition AS int)) * 100.0/ COUNT(*),2) AS AttritionRatePct,
    ROUND(AVG(ed.MonthlyIncome), 2) AS AvgIncome
    FROM Employees e
    JOIN EmployeeDetails ed
    ON e.EmployeeID = ed.EmployeeID
    GROUP BY e.AgeGroup
GO

CREATE OR ALTER VIEW
vw_GenderviewAttrition AS
SELECT
    e.Gender, COUNT(*) AS TotalEmployees,
    SUM(CAST(Attrition AS int)) AS AttritionCount,
    ROUND(SUM(CAST(Attrition AS int)) * 100.0/ COUNT(*),2) AS AttritionRatePct,
    ROUND(AVG(ed.MonthlyIncome), 2) AS AvgIncome
    FROM Employees e
    JOIN EmployeeDetails ed
    ON e.EmployeeID = ed.EmployeeID
    GROUP BY e.Gender
GO

CREATE OR ALTER VIEW
vw_MaritalstatusAttrition AS
SELECT
    e.MaritalStatus, COUNT(*) AS TotalEmployees,
    SUM(CAST(Attrition AS int)) AS AttritionCount,
    ROUND(SUM(CAST(Attrition AS int)) * 100.0/ COUNT(*),2) AS AttritionRatePct,
    ROUND(AVG(ed.MonthlyIncome), 2) AS AvgIncome
    FROM Employees e
    JOIN EmployeeDetails ed
    ON e.EmployeeID = ed.EmployeeID
    GROUP BY e.MaritalStatus
GO


CREATE OR ALTER VIEW
vw_TenureAttrition
AS 
SELECT
    CASE 
        WHEN ed.YearsAtCompany <=2 THEN '0-2 yrs (new)'
        WHEN ed.YearsAtCompany <=5 THEN '3-5 yrs (Developing)'
        WHEN ed.YearsAtCompany <=10 THEN '6-10 yrs(Established)'
        ELSE '10+ yrs'
    END AS TenureBand,
    COUNT(*) AS TotalEmployees,
    SUM(CAST(ed.Attrition AS INT)) AS AttritionCount,
    ROUND(SUM(CAST(ed.Attrition AS INT)) * 100.0 / COUNT(*),2) AS AttritionRatePct,
    AVG(ed.MonthlyIncome) AS AvgIncome,
    AVG(ed.YearsSinceLastPromotion) AS AvgYrsSinceLastP FROM EmployeeDetails ed
    GROUP BY
    CASE 
        WHEN ed.YearsAtCompany <=2 THEN '0-2 yrs (new)'
        WHEN ed.YearsAtCompany <=5 THEN '3-5 yrs (Developing)'
        WHEN ed.YearsAtCompany <=10 THEN '6-10 yrs(Established)'
    ELSE '10+ yrs'
END;
GO

CREATE OR ALTER VIEW
vw_PromotionAttrition AS
SELECT
    ed.YearsSinceLastPromotion, COUNT(*) AS TotalEmployees,
    SUM(CAST(Attrition AS int)) AS AttritionCount,
    ROUND(SUM(CAST(Attrition AS int)) * 100.0/ COUNT(*),2) AS AttritionRatePct,
    ROUND(AVG(ed.MonthlyIncome), 2) AS AvgIncome
    FROM Employees e
    JOIN EmployeeDetails ed
    ON e.EmployeeID = ed.EmployeeID
    GROUP BY ed.YearsSinceLastPromotion
GO

CREATE OR ALTER VIEW
vw_StockOptionAttrition AS
SELECT
    ed.StockOptionLevel, COUNT(*) AS TotalEmployees,
    SUM(CAST(Attrition AS int)) AS AttritionCount,
    ROUND(SUM(CAST(Attrition AS int)) * 100.0/ COUNT(*),2) AS AttritionRatePct,
    ROUND(AVG(ed.MonthlyIncome), 2) AS AvgIncome
    FROM Employees e
    JOIN EmployeeDetails ed
    ON e.EmployeeID = ed.EmployeeID
    GROUP BY ed.StockOptionLevel
GO

CREATE OR ALTER VIEW
vw_CompaniesWorkedAtAttrition AS
SELECT
    ed.NumCompaniesWorked, COUNT(*) AS TotalEmployees,
    SUM(CAST(Attrition AS int)) AS AttritionCount,
    ROUND(SUM(CAST(Attrition AS int)) * 100.0/ COUNT(*),2) AS AttritionRatePct,
    ROUND(AVG(ed.MonthlyIncome), 2) AS AvgIncome
    FROM Employees e
    JOIN EmployeeDetails ed
    ON e.EmployeeID = ed.EmployeeID
    GROUP BY ed.NumCompaniesWorked
GO

CREATE OR ALTER VIEW
vw_PerformanceRatingAttrition AS
SELECT
    ed.PerformanceRating, COUNT(*) AS TotalEmployees,
    SUM(CAST(Attrition AS int)) AS AttritionCount,
    ROUND(SUM(CAST(Attrition AS int)) * 100.0/ COUNT(*),2) AS AttritionRatePct,
    ROUND(AVG(ed.MonthlyIncome), 2) AS AvgIncome
    FROM Employees e
    JOIN EmployeeDetails ed
    ON e.EmployeeID = ed.EmployeeID
    GROUP BY ed.PerformanceRating
GO

CREATE OR ALTER VIEW
vw_JobInvolvmentAttrition AS
SELECT
    ed.JobInvolvement, COUNT(*) AS TotalEmployees,
    SUM(CAST(Attrition AS int)) AS AttritionCount,
    ROUND(SUM(CAST(Attrition AS int)) * 100.0/ COUNT(*),2) AS AttritionRatePct,
    ROUND(AVG(ed.MonthlyIncome), 2) AS AvgIncome
    FROM Employees e
    JOIN EmployeeDetails ed
    ON e.EmployeeID = ed.EmployeeID
    GROUP BY ed.JobInvolvement
GO

CREATE OR ALTER VIEW
vw_TrainingAttrition AS
SELECT
    ed.TrainingTimesLastYear, COUNT(*) AS TotalEmployees,
    SUM(CAST(Attrition AS int)) AS AttritionCount,
    ROUND(SUM(CAST(Attrition AS int)) * 100.0/ COUNT(*),2) AS AttritionRatePct,
    ROUND(AVG(ed.MonthlyIncome), 2) AS AvgIncome
    FROM Employees e
    JOIN EmployeeDetails ed
    ON e.EmployeeID = ed.EmployeeID
    GROUP BY ed.TrainingTimesLastYear
GO


CREATE OR ALTER VIEW
vw_JobLevelAttrition AS
SELECT
    e.JobLevel, COUNT(*) AS TotalEmployees,
    SUM(CAST(Attrition AS int)) AS AttritionCount,
    ROUND(SUM(CAST(Attrition AS int)) * 100.0/ COUNT(*),2) AS AttritionRatePct,
    ROUND(AVG(ed.MonthlyIncome), 2) AS AvgIncome
    FROM Employees e
    JOIN EmployeeDetails ed
    ON e.EmployeeID = ed.EmployeeID
    GROUP BY e.JobLevel
GO


CREATE OR ALTER VIEW vw_SatisfactionAnalysis 
AS 
SELECT 
    ROUND(
        AVG(
            CASE 
                WHEN ed.Attrition = 1 THEN CAST(ed.JobSatisfaction AS FLOAT) 
            END
        ), 2
    ) AS AvgJobSatisfaction_Left,

    ROUND(
        AVG(
            CASE 
                WHEN ed.Attrition = 0 THEN CAST(ed.JobSatisfaction AS FLOAT) 
            END
        ), 2
    ) AS AvgJobSatisfaction_Stayed,

    ROUND(
        AVG(
            CASE 
                WHEN ed.Attrition = 1 THEN CAST(ed.WorkLifeBalance AS FLOAT) 
            END
        ), 2
    ) AS AvgWorkLifeBalance_Left,

    ROUND(
        AVG(
            CASE 
                WHEN ed.Attrition = 0 THEN CAST(ed.WorkLifeBalance AS FLOAT) 
            END
        ), 2
    ) AS AvgWorkLifeBalance_Stayed,

    ROUND(
        AVG(
            CASE 
                WHEN ed.Attrition = 1 THEN CAST(ed.EnvironmentSatisfaction AS FLOAT) 
            END
        ), 2
    ) AS AvgEnvironmentSatisfaction_Left,

    ROUND(
        AVG(
            CASE 
                WHEN ed.Attrition = 0 THEN CAST(ed.EnvironmentSatisfaction AS FLOAT) 
            END
        ), 2
    ) AS AvgEnvironmentSatisfaction_Stayed
FROM EmployeeDetails ed;
GO

CREATE OR ALTER VIEW
vw_AttritionStatusIncome
AS 
SELECT
    CASE
        WHEN ed.Attrition = 1 THEN 
        'Left'
        ELSE 'Stayed'
    END AS EmployeeStatus,

    COUNT(*) AS HeadCount,

    ROUND(AVG(ed.MonthlyIncome), 2)
AS AvgMonthlyIncome,

MIN(ed.MonthlyIncome) AS MinIncome,
MAX(ed.MonthlyIncome) AS MaxIncome

FROM EmployeeDetails ed
GROUP BY ed.Attrition;
GO

CREATE OR ALTER VIEW vw_EmployeeAttritionAnalysis
AS
SELECT
    e.EmployeeID,
    e.EmpCode,
    e.Age,
    e.AgeGroup,
    e.Gender,
    e.MaritalStatus,
    e.Education,
    e.EducationField,
    e.Department,
    e.JobRole,
    e.JobLevel,

    ed.Attrition,
    
    CASE
        WHEN ed.Attrition = 1 THEN 'Left'
        ELSE 'Stayed'
    END AS AttritionStatus,

    ed.BusinessTravel,

    CASE
        WHEN ed.OverTime = 1 THEN 'Yes'
        ELSE 'No'
    END AS OverTimeStatus,

    ed.MonthlyIncome,
    ed.SalarySlab,
    ed.PercentSalaryHike,
    ed.StockOptionLevel,

    ed.EnvironmentSatisfaction,
    ed.JobInvolvement,
    ed.JobSatisfaction,
    ed.RelationshipSatisfaction,
    ed.WorkLifeBalance,
    ed.PerformanceRating,

    ed.NumCompaniesWorked,
    ed.TotalWorkingYears,
    ed.TrainingTimesLastYear,
    ed.YearsAtCompany,
    ed.YearsInCurrentRole,
    ed.YearsSinceLastPromotion,
    ed.YearsWithCurrManager,
    ed.DistanceFromHome

FROM Employees e
JOIN EmployeeDetails ed
    ON e.EmployeeID = ed.EmployeeID;
GO

SELECT * FROM vw_EmployeeAttritionAnalysis
