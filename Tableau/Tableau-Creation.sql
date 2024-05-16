/*

Queries used for Tableau Project

*/
CREATE DATABASE portfolioproject;
USE portfolioproject;

-- 1. 

SELECT 
    SUM(new_cases) AS total_cases, 
    SUM(new_deaths) AS total_deaths, 
    SUM(new_deaths) / SUM(new_cases) * 100 AS DeathPercentage 
FROM CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 1, 2;

-- Just a double check based off the data provided
-- numbers are extremely close so we will keep them - The Second includes "International"  Location

-- 2. 

-- We take these out as they are not inluded in the above queries and want to stay consistent
-- European Union is part of Europe

SELECT 
    location, 
    SUM(cast(new_deaths as signed)) AS TotalDeathCount 
FROM 
    CovidDeaths 
WHERE 
    continent = ''
    AND location NOT IN ('World', 'European Union', 'International') 
GROUP BY 
    location 
ORDER BY 
    TotalDeathCount DESC;

-- 3.

SELECT 
    Location, 
    Population, 
    MAX(total_cases) AS HighestInfectionCount,  
    MAX((total_cases/population)) * 100 AS PercentPopulationInfected 
FROM 
    CovidDeaths 
GROUP BY 
    Location, Population 
ORDER BY 
    PercentPopulationInfected DESC
    LIMIT 0, 20000;

-- 4.

Select Location, Population,date, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From CovidDeaths
Group by Location, Population, date
order by PercentPopulationInfected desc
LIMIT 0, 20000;