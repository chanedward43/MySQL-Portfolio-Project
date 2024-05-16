CREATE DATABASE `portfolioproject`;
USE `portfolioproject`;

-- Creating table of covid deaths
CREATE TABLE coviddeaths (
    iso_code VARCHAR(3),
    continent VARCHAR(15),
    location VARCHAR(50),
    date DATE,
    population INT,
    total_cases INT,
    new_cases INT,
    new_cases_smoothed DECIMAL(5,3),
    total_deaths INT,
    new_deaths INT,
    new_deaths_smoothed DECIMAL(5,3),
    total_cases_per_million DECIMAL(5,3),
    new_cases_per_million DECIMAL(5,3),
    new_cases_smoothed_per_million DECIMAL(5,3),
    total_deaths_per_million DECIMAL(5,3),
    new_deaths_per_million DECIMAL(5,3),
    new_deaths_smoothed_per_million DECIMAL(5,3),
    reproduction_rate DECIMAL(3,2),
    icu_patients INT,
    icu_patients_per_million DECIMAL(5,3),
    hosp_patients INT,
    hosp_patients_per_million DECIMAL(5,3),
    weekly_icu_admissions INT,
    weekly_icu_admissions_per_million DECIMAL(5,3),
    weekly_hosp_admissions INT,
    weekly_hosp_admissions_per_million DECIMAL(5,3)
);

LOAD DATA INFILE 'CovidDeaths.csv'
INTO TABLE coviddeaths
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    iso_code, continent, location, @var_date, population, total_cases, new_cases, new_cases_smoothed, 
    total_deaths, new_deaths, new_deaths_smoothed, total_cases_per_million, new_cases_per_million, 
    new_cases_smoothed_per_million, total_deaths_per_million, new_deaths_per_million, 
    new_deaths_smoothed_per_million, reproduction_rate, icu_patients, icu_patients_per_million, 
    hosp_patients, hosp_patients_per_million, weekly_icu_admissions, weekly_icu_admissions_per_million, 
    weekly_hosp_admissions, weekly_hosp_admissions_per_million
)
SET date = STR_TO_DATE(@var_date, '%Y-%m-%d');

-- Creating table of covid vaccinations
CREATE TABLE covidvaccinations (
    iso_code VARCHAR(3),
    continent VARCHAR(15),
    location VARCHAR(50),
    date DATE,
    new_tests INT,
    total_tests INT,
    total_tests_per_thousand DECIMAL(10, 3),
    new_tests_per_thousand DECIMAL(10, 3),
    new_tests_smoothed DECIMAL(10, 3),
    new_tests_smoothed_per_thousand DECIMAL(10, 3),
    positive_rate DECIMAL(5, 3),
    tests_per_case DECIMAL(5, 3),
    tests_units VARCHAR(50),
    total_vaccinations INT,
    people_vaccinated INT,
    people_fully_vaccinated INT,
    new_vaccinations INT,
    new_vaccinations_smoothed INT,
    total_vaccinations_per_hundred DECIMAL(5, 3),
    people_vaccinated_per_hundred DECIMAL(5, 3),
    people_fully_vaccinated_per_hundred DECIMAL(5, 3),
    new_vaccinations_smoothed_per_million DECIMAL(10, 3),
    stringency_index DECIMAL(5, 2),
    population_density DECIMAL(10, 3),
    median_age DECIMAL(5, 2),
    aged_65_older DECIMAL(5, 3),
    aged_70_older DECIMAL(5, 3),
    gdp_per_capita DECIMAL(10, 3),
    extreme_poverty DECIMAL(5, 2),
    cardiovasc_death_rate DECIMAL(10, 3),
    diabetes_prevalence DECIMAL(5, 2),
    female_smokers DECIMAL(5, 2),
    male_smokers DECIMAL(5, 2),
    handwashing_facilities DECIMAL(10, 3),
    hospital_beds_per_thousand DECIMAL(5, 2),
    life_expectancy DECIMAL(5, 2),
    human_development_index DECIMAL(5, 3)
);

LOAD DATA INFILE 'covidvaccinations.csv'
INTO TABLE covidvaccinations
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    iso_code, continent, location, @var_date, new_tests, total_tests, total_tests_per_thousand, new_tests_per_thousand, 
    new_tests_smoothed, new_tests_smoothed_per_thousand, positive_rate, tests_per_case, tests_units, 
    total_vaccinations, people_vaccinated, people_fully_vaccinated, new_vaccinations, new_vaccinations_smoothed, 
    total_vaccinations_per_hundred, people_vaccinated_per_hundred, people_fully_vaccinated_per_hundred, 
    new_vaccinations_smoothed_per_million, stringency_index, population_density, median_age, aged_65_older, 
    aged_70_older, gdp_per_capita, extreme_poverty, cardiovasc_death_rate, diabetes_prevalence, female_smokers, 
    male_smokers, handwashing_facilities, hospital_beds_per_thousand, life_expectancy, human_development_index
)
SET date = STR_TO_DATE(@var_date, '%Y-%m-%d');


SELECT * FROM coviddeaths
order by 3,4;

SELECT * FROM covidvaccinations
order by 3,4;

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM coviddeaths
order by 1,2;

-- Looking at Total cases vs total deaths
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM coviddeaths
WHERE location like '%new zealand%'
order by 1,2;

-- Looking at Total cases vs population
-- Shows the percentage that got covid
SELECT Location, date, Population, total_cases, (total_cases/Population)*100 as PopulationPercentage
FROM coviddeaths
WHERE location like '%new zealand%'
order by 1,2;

-- Looking at Countries with Highest Infection Rate Compared to Population
SELECT Location, Population, MAX(total_cases) as HighestInfectionCount, MAX(total_cases/Population)*100 as PercentagePopulationInfected
FROM coviddeaths
-- WHERE location like '%new zealand%'
GROUP BY Location, Population
order by PercentagePopulationInfected desc;

-- Showing countries with the highest death count per population
SELECT Location, MAX(CAST(Total_deaths AS SIGNED)) AS TotalDeathCount
FROM coviddeaths
WHERE continent <> ''
GROUP BY Location
ORDER BY TotalDeathCount DESC;

-- SHowing continent with the highest death count per population
SELECT continent, MAX(CAST(Total_deaths AS SIGNED)) AS TotalDeathCount
FROM coviddeaths 
WHERE continent <>  '' -- Would use null, but using text
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- Global numbers
SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as SIGNED)) as total_deaths, SUM(cast(new_deaths as signed))/
	SUM(new_cases)*100 as DeathPercentage
FROM CovidDeaths
WHERE continent <>  ''
GROUP BY date
ORDER BY 1,2;

-- Looking at Total Population vs vaccination (doesn't work cause the dates are order by first value)
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as signed)) OVER (Partition by dea.location ORDER BY dea.location,
	dea.Date) as RollingPeopleVaccinated
FROM CovidDeaths dea
join covidvaccinations vac
	on dea.location = vac.location
    and dea.date = vac.date
WHERE dea.continent <>  ''
order by 2,3;

-- USE CTE
WITH PopvsVac(Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as signed)) OVER (Partition by dea.location ORDER BY dea.location,
	dea.Date) as RollingPeopleVaccinated
FROM CovidDeaths dea
join covidvaccinations vac
	on dea.location = vac.location
    and dea.date = vac.date
WHERE dea.continent <>  ''
)

Select *, (RollingPeopleVaccinated/Population) * 100
FROM PopvsVac;

-- Creating View to store data for later visualisation
CREATE VIEW ContinentTotalDeathCount as
SELECT continent, MAX(CAST(Total_deaths AS SIGNED)) AS TotalDeathCount
FROM coviddeaths 
WHERE continent <>  '' -- Would use null, but using text
GROUP BY continent;
