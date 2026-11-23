# HR Attrition Analysis | SQL Server + Power BI

End-to-end people-analytics project: raw HR data is cleaned and normalised in **SQL Server**, exposed through reporting views, and visualised in a 3-page **Power BI** dashboard that shows who leaves, when, and why.

## Business questions

- What is the overall attrition rate, and which departments and job roles lose the most people?
- How do overtime, pay, tenure, age, travel and stock options relate to attrition?
- Do employees who leave report lower satisfaction and work-life balance?

## Key findings

Based on 1,470 unique employees, 237 of whom left (**16.1% attrition**).

| Driver | Higher-risk group | Attrition | Comparison group | Attrition |
| --- | --- | --- | --- | --- |
| Overtime | Works overtime | 30.5% | No overtime | 10.4% |
| Tenure | 0-2 years at company | 29.8% | 10+ years | 8.1% |
| Age | 18-25 | 35.8% | 36-45 | 9.2% |
| Salary slab | Up to 5k | 21.8% | 15k+ | 3.8% |
| Business travel | Travels frequently | 24.9% | Non-travel | 8.0% |
| Stock options | Level 0 | 24.4% | Level 2 | 7.6% |
| Marital status | Single | 25.5% | Divorced | 10.1% |
| Job role | Sales Representative | 39.8% | Research Director | 2.5% |
| Department | Sales | 20.6% | Research & Development | 13.8% |

- Employees who left earned on average about 30% less per month (4,787 vs 6,833) and scored lower on job satisfaction (2.47 vs 2.78 out of 4).
- The highest-risk profile is a young, single, low-paid employee in their first two years, working overtime in a sales role.

## Dashboard

The Power BI report (`powerbi/HR_AttritionAnalysis.pbix`) has three pages:

1. **Executive Attrition** - headline KPIs (total employees, attrition count, active employees, average income, average tenure), attrition by department, age group, job role, gender, tenure and overtime, with slicers.
2. **Workforce and Demographics** - attrition by gender, age, marital status, education field and job level, with breakdown tables.
3. **Drivers affecting Workforce** - overtime, distance from home, job satisfaction, work-life balance, travel and performance views.

A custom theme is included: `powerbi/HR_Attrition_Analytics_theme.json` (View > Themes > Browse for themes).

<!-- Add screenshots to /images and uncomment:
![Executive Attrition](images/page1_executive.png)
![Workforce and Demographics](images/page2_workforce.png)
![Drivers](images/page3_drivers.png)
-->

## Data model

The flat CSV is normalised into two related tables.

| Table | Grain | Key columns |
| --- | --- | --- |
| `Employees` | one row per employee | EmployeeID (PK), EmpCode, Age, AgeGroup, Gender, MaritalStatus, EducationField, Department, JobRole, JobLevel |
| `EmployeeDetails` | one row per employee | DetailID (PK), EmployeeID (FK), Attrition, OverTime, MonthlyIncome, SalarySlab, satisfaction scores, tenure and promotion fields |

## SQL layer

`sql/HR_Attrition_Analysis.sql` runs in this order: exploration, schema creation, data load, validation checks, analysis queries, reporting views.

- **Data cleaning:** `BusinessTravel` had an inconsistent label (`TravelRarely` vs `Travel_Rarely`) that is standardised during load; `Attrition` and `OverTime` are converted from Yes/No to `BIT`; blank `YearsWithCurrManager` values are loaded as `NULL` with `TRY_CAST`.
- **Duplicate handling:** the raw file contains 1,480 rows but only 1,470 unique employees (RM1461 to RM1470 appear twice). The load keeps one row per employee with `ROW_NUMBER()` so no KPI is inflated.
- **Validation:** row-count reconciliation and an orphan-row check (expected 0).
- **Reporting views (22):** `vw_EmployeeAttritionAnalysis` (the main flat view used by the report) plus one aggregated view per dimension, for example `vw_DepartmentAttrition`, `vw_JobroleAttrition`, `vw_OverTimeAttrition`, `vw_TenureAttrition`, `vw_SalarySlabAttrition` and `vw_SatisfactionAnalysis`.
- **SQL techniques:** joins, CTEs, window functions, conditional aggregation, `CASE` banding, `TRY_CAST`, views.

## How to run

1. Create a database: `CREATE DATABASE HR_ATTRITION;`
2. Import `data/HR_Analytics.csv` as table `dbo.HR_Analytics` (SSMS > Tasks > Import Flat File).
3. Run `sql/HR_Attrition_Analysis.sql`.
4. Open `powerbi/HR_AttritionAnalysis.pbix` in Power BI Desktop. If you want to point it at your own server, use Home > Transform data > Data source settings, then Refresh.

## Repository structure

```
HR-Attrition-Analysis/
|-- data/
|   `-- HR_Analytics.csv
|-- sql/
|   `-- HR_Attrition_Analysis.sql
|-- powerbi/
|   |-- HR_AttritionAnalysis.pbix
|   `-- HR_Attrition_Analytics_theme.json
|-- images/
`-- README.md
```

## Tech stack

SQL Server, SSMS, T-SQL, Power BI Desktop, DAX, Power Query.

## Author

**Javariya Sohail** - Associate Data Analyst
[LinkedIn](https://www.linkedin.com/in/javariya-sohail-0bb895253) | [GitHub](https://github.com/jiyasohail)
