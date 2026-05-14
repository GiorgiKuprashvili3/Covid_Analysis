-- ============================================================
-- COVID-19 Impact & Vaccination Effectiveness Analysis
-- Dataset : Our World in Data (OWID) daily COVID dataset
-- Scope   : 405,726 rows | 243 countries | 2020-01-05 to 2024-08-14
-- Tools   : SQL Server (T-SQL) + Excel
-- ============================================================


-- ============================================================
-- PHASE 0 — Data Import & Exploration
-- ============================================================
-- Quick structure & sample check
SELECT TOP 100 * FROM dbo.OwidCovid;

-- Row counts and date span
SELECT
    COUNT(*)                 AS TotalRows,
    COUNT(DISTINCT location) AS Countries,
    MIN(date)                AS FirstDate,
    MAX(date)                AS LastDate
FROM dbo.OwidCovid;
-- 405,726 rows | 243 locations | 2020-01-05 to 2024-08-14

-- Coverage check by continent
SELECT continent, COUNT(DISTINCT location) AS Countries
FROM dbo.OwidCovid
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY Countries DESC;


-- ============================================================
-- PHASE 1 — Analytical Panel (Country_Summary view)
-- One unified row per country: latest cumulative totals + derived rates
-- ============================================================
IF OBJECT_ID('dbo.Country_Summary', 'V') IS NOT NULL
    DROP VIEW dbo.Country_Summary;
GO

CREATE VIEW dbo.Country_Summary
AS
WITH LatestPerCountry AS (
    SELECT
        location,
        continent,
        MAX(date) AS LatestDate
    FROM dbo.OwidCovid
    WHERE continent IS NOT NULL
    GROUP BY location, continent
)
SELECT
    o.location                            AS Country,
    o.continent                           AS Continent,
    o.population                          AS Population,
    o.total_cases                         AS TotalCases,
    o.total_deaths                        AS TotalDeaths,
    o.people_fully_vaccinated             AS PeopleVaccinated,
    o.gdp_per_capita                      AS GdpPerCapita,

    /* Derived rates */
    CAST(o.total_cases AS FLOAT)
        / NULLIF(o.population, 0)         AS InfectionRate,
    CAST(o.total_deaths AS FLOAT)
        / NULLIF(o.total_cases, 0)        AS DeathRate,
    CAST(o.people_fully_vaccinated AS FLOAT)
        / NULLIF(o.population, 0)         AS VaccinationRate
FROM dbo.OwidCovid AS o
INNER JOIN LatestPerCountry AS lpc
       ON o.location = lpc.location
      AND o.date     = lpc.LatestDate;
GO


-- ============================================================
-- PHASE 2 — Data Quality Checks
-- NULLs, impossible values, duplicates.
-- Flagged region rows (continent IS NULL) for exclusion.
-- ============================================================

-- 2.1 Missing values per critical column
SELECT
    SUM(CASE WHEN total_cases    IS NULL THEN 1 ELSE 0 END) AS MissingCases,
    SUM(CASE WHEN total_deaths   IS NULL THEN 1 ELSE 0 END) AS MissingDeaths,
    SUM(CASE WHEN population     IS NULL THEN 1 ELSE 0 END) AS MissingPopulation,
    SUM(CASE WHEN gdp_per_capita IS NULL THEN 1 ELSE 0 END) AS MissingGdp
FROM dbo.OwidCovid;

-- 2.2 Region aggregates masquerading as countries
SELECT DISTINCT location
FROM dbo.OwidCovid
WHERE continent IS NULL;
-- 'World', 'European Union', 'High income', etc. — excluded from per-country analysis

-- 2.3 Impossible values (negative new cases / deaths from data revisions)
SELECT COUNT(*) AS NegativeNewCases
FROM dbo.OwidCovid
WHERE new_cases < 0;

-- 2.4 Duplicate (location, date) check
SELECT location, date, COUNT(*) AS rows
FROM dbo.OwidCovid
GROUP BY location, date
HAVING COUNT(*) > 1;
-- No duplicates found


-- ============================================================
-- PHASE 3 — Trend & Seasonality
-- Monthly global aggregates and 7-day rolling daily series for top countries.
-- ============================================================

-- 3.1 Global monthly trend (56 months)
SELECT
    FORMAT(date, 'yyyy-MM') AS Month,
    SUM(new_cases)          AS NewCases,
    SUM(new_deaths)         AS NewDeaths,
    CAST(SUM(new_deaths) AS FLOAT)
      / NULLIF(SUM(new_cases), 0) AS MonthlyCfr
FROM dbo.OwidCovid
WHERE continent IS NOT NULL
GROUP BY FORMAT(date, 'yyyy-MM')
ORDER BY Month;

-- 3.2 7-day rolling average for top 12 countries by population
WITH TopCountries AS (
    SELECT TOP 12 location
    FROM dbo.OwidCovid
    WHERE continent IS NOT NULL
    GROUP BY location
    ORDER BY MAX(population) DESC
)
SELECT
    o.location,
    o.date,
    o.new_cases,
    AVG(CAST(o.new_cases AS FLOAT)) OVER (
        PARTITION BY o.location
        ORDER BY o.date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS Rolling7DayCases
FROM dbo.OwidCovid AS o
INNER JOIN TopCountries AS tc ON o.location = tc.location
ORDER BY o.location, o.date;


-- ============================================================
-- PHASE 4 — Vaccination Effectiveness  ← KEY ANALYSIS
-- Bucketed countries by vaccination rate, compared mean death rate per band.
-- Verdict: 0-20% band → 1.40% death rate | 80%+ band → 0.57%
-- ============================================================

-- 4.1 Country-level: vax band vs death rate
WITH Banded AS (
    SELECT
        Country,
        VaccinationRate,
        DeathRate,
        GdpPerCapita,
        CASE
            WHEN VaccinationRate <  0.20 THEN '1. 0-20%'
            WHEN VaccinationRate <  0.40 THEN '2. 20-40%'
            WHEN VaccinationRate <  0.60 THEN '3. 40-60%'
            WHEN VaccinationRate <  0.80 THEN '4. 60-80%'
            ELSE                              '5. 80%+'
        END AS VaxBand
    FROM dbo.Country_Summary
    WHERE VaccinationRate IS NOT NULL
      AND DeathRate       IS NOT NULL
)
SELECT
    VaxBand,
    COUNT(*)        AS Countries,
    AVG(DeathRate)  AS AvgDeathRate,
    MIN(DeathRate)  AS MinDeathRate,
    MAX(DeathRate)  AS MaxDeathRate
FROM Banded
GROUP BY VaxBand
ORDER BY VaxBand;
-- Verdict: 0-20% band: 1.40%   |   80%+ band: 0.57%  (2.5x difference)


-- ============================================================
-- PHASE 5 — Confounders: GDP Per Capita & Continent
-- GDP per capita separates outcomes more cleanly than continent.
-- A 5.5x death-rate gap between poorest and richest bands.
-- ============================================================

-- 5.1 Death rate by GDP per capita band
WITH GdpBanded AS (
    SELECT
        Country,
        DeathRate,
        InfectionRate,
        VaccinationRate,
        CASE
            WHEN GdpPerCapita <  5000  THEN '1. <$5k'
            WHEN GdpPerCapita < 15000  THEN '2. $5k-$15k'
            WHEN GdpPerCapita < 30000  THEN '3. $15k-$30k'
            WHEN GdpPerCapita < 50000  THEN '4. $30k-$50k'
            ELSE                              '5. $50k+'
        END AS GdpBand
    FROM dbo.Country_Summary
    WHERE GdpPerCapita IS NOT NULL
)
SELECT
    GdpBand,
    COUNT(*)              AS Countries,
    AVG(DeathRate)        AS AvgDeathRate,
    AVG(InfectionRate)    AS AvgInfectionRate,
    AVG(VaccinationRate)  AS AvgVaxRate
FROM GdpBanded
GROUP BY GdpBand
ORDER BY GdpBand;

-- 5.2 Continent rollup
SELECT
    Continent,
    COUNT(*)         AS Countries,
    SUM(Population)  AS Population,
    SUM(TotalCases)  AS TotalCases,
    SUM(TotalDeaths) AS TotalDeaths,
    CAST(SUM(TotalDeaths) AS FLOAT) * 1000000.0
        / NULLIF(SUM(Population), 0) AS DeathsPerMillion
FROM dbo.Country_Summary
GROUP BY Continent
ORDER BY DeathsPerMillion DESC;
-- South America: 3,104 | Europe: 2,581 | Africa: 182 (likely undercounted)


-- ============================================================
-- SUPPLEMENTARY — Top Country Rankings
-- ============================================================

-- Top 10 countries by total deaths
SELECT TOP 10
    Country,
    TotalDeaths,
    CAST(DeathRate * 100 AS DECIMAL(5,2)) AS DeathRatePct
FROM dbo.Country_Summary
WHERE TotalDeaths IS NOT NULL
ORDER BY TotalDeaths DESC;

-- Top 10 countries by vaccination rate
SELECT TOP 10
    Country,
    CAST(VaccinationRate * 100 AS DECIMAL(5,1)) AS VaxRatePct,
    CAST(DeathRate * 100 AS DECIMAL(5,2)) AS DeathRatePct
FROM dbo.Country_Summary
WHERE VaccinationRate IS NOT NULL
ORDER BY VaccinationRate DESC;
