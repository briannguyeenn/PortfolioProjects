-- Alter the date column to just date and not datetime
ALTER TABLE CovidPortfolioProject..CovidDeaths
ALTER COLUMN date date

SELECT *
FROM CovidPortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 3,4

SELECT *
FROM CovidPortfolioProject..CovidVaccinations
ORDER BY 3,4


-- Select data that will be used

SELECT
	location, date, total_cases, new_cases, total_deaths, population
FROM
	CovidPortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY
	1, 2


-- Total Cases vs Total Deaths
-- Shows the possibility of death if you're infected with covid in your country
SELECT
	location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM
	CovidPortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY
	1, 2


-- Total Cases vs Population
-- Shows the percentage of the population that got covid
SELECT
	location, population, date, total_cases, (total_cases/population)*100 AS infected_percentage
FROM
	CovidPortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY
	1, 2


-- Countries total infected rate compared to population
-- 1. Visualization
SELECT
	location, population, date, MAX(total_cases) AS highest_total_infected, MAX(total_cases/population)*100 AS population_infected_percentage
FROM
	CovidPortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY
	location, population, date
ORDER BY
	population_infected_percentage DESC

SELECT
	location, population, MAX(total_cases) AS highest_total_infected, MAX(total_cases/population)*100 AS population_infected_percentage
FROM
	CovidPortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY
	location, population
ORDER BY
	population_infected_percentage DESC


-- Highest death count for each country
-- 2. Visualization 
SELECT
	location, MAX(CAST(total_deaths AS int)) AS total_death_count
FROM
	CovidPortfolioProject..CovidDeaths
WHERE
	continent is not null
GROUP BY
	location
ORDER BY
	total_death_count DESC


-- Total death count for each continent
-- 3. Visualization
SELECT
	location, MAX(CAST(total_deaths AS int)) AS total_death_count
FROM
	CovidPortfolioProject..CovidDeaths
WHERE
	continent is null 
	AND	location NOT IN ('World', 'European Union', 'International', 'Upper middle income', 'High income', 'Lower middle income', 'Low income')
GROUP BY
	location
ORDER BY
	total_death_count DESC


-- Highest death count per population by continent
SELECT
	continent, MAX(CAST(total_deaths AS int)) AS total_death_count
FROM
	CovidPortfolioProject..CovidDeaths
WHERE
	continent is not null
GROUP BY
	continent
ORDER BY
	total_death_count DESC


-- Global numbers
-- 4. Visualization
SELECT
	SUM(new_cases) as total_cases, SUM(CAST(new_deaths as int))as total_deaths, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 AS death_percentage
FROM
	CovidPortfolioProject..CovidDeaths
WHERE 
	continent is not null
--GROUP BY date
ORDER BY
	1, 2


-- Total Population vs Vaccinations
SELECT 
	death.continent, death.location, death.date, death.population, vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations as bigint)) OVER (PARTITION BY death.location ORDER BY death.location, 
	death.date) AS total_people_vaccinated
FROM 
	CovidPortfolioProject..CovidDeaths AS death
JOIN CovidPortfolioProject..CovidVaccinations AS vac
	ON death.location = vac.location
	AND death.date = vac.date
WHERE 
	death.continent is not null
ORDER BY
	2, 3

-- Using CTE
WITH PopvsVac (continent, location, date, population, new_vaccinations, total_people_vaccinated)
AS 
(
SELECT 
	death.continent, death.location, death.date, death.population, vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations as bigint)) OVER (PARTITION BY death.location ORDER BY death.location, 
	death.date) AS total_people_vaccinated
FROM 
	CovidPortfolioProject..CovidDeaths AS death
JOIN CovidPortfolioProject..CovidVaccinations AS vac
	ON death.location = vac.location
	AND death.date = vac.date
WHERE 
	death.continent is not null
--ORDER BY
	--2, 3
)
SELECT *, (total_people_vaccinated/population)*100 as vaccinated_percentage
FROM PopvsVac

ALTER TABLE CovidPortfolioProject..CovidVaccinations
ALTER COLUMN date date


-- Using Temp Table
DROP TABLE IF EXISTS #Percent_Population_Vaccinated
CREATE TABLE #Percent_Population_Vaccinated
(
continent nvarchar(255),
location nvarchar(255),
date date,
population bigint,
new_vaccinations bigint,
total_people_vaccinated bigint
)
INSERT INTO #Percent_Population_Vaccinated
SELECT 
	death.continent, death.location, death.date, death.population, vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations as bigint)) OVER (PARTITION BY death.location ORDER BY death.location, 
	death.date) AS total_people_vaccinated
FROM 
	CovidPortfolioProject..CovidDeaths AS death
JOIN CovidPortfolioProject..CovidVaccinations AS vac
	ON death.location = vac.location
	AND death.date = vac.date
WHERE 
	death.continent is not null
--ORDER BY
	--2, 3
SELECT *, (total_people_vaccinated/population)*100 as vaccinated_percentage
FROM #Percent_Population_Vaccinated


-- Creating View to store data for visualizations

USE CovidPortfolioProject
GO
CREATE VIEW PercentPopulationVaccinated as
SELECT 
	death.continent, death.location, death.date, death.population, vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations as bigint)) OVER (PARTITION BY death.location ORDER BY death.location, 
	death.date) AS total_people_vaccinated
FROM 
	CovidPortfolioProject..CovidDeaths AS death
JOIN CovidPortfolioProject..CovidVaccinations AS vac
	ON death.location = vac.location
	AND death.date = vac.date
WHERE 
	death.continent is not null

CREATE VIEW GlobalNumbers as
SELECT
	SUM(new_cases) as total_cases, SUM(CAST(new_deaths as int))as total_deaths, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 AS death_percentage
FROM
	CovidPortfolioProject..CovidDeaths
WHERE 
	continent is not null


CREATE VIEW TotalDeathsByContinent as
SELECT
	continent, MAX(CAST(total_deaths AS int)) AS total_death_counts
FROM
	CovidPortfolioProject..CovidDeaths
WHERE
	continent is not null
GROUP BY
	continent
ORDER BY
	total_death_counts DESC

