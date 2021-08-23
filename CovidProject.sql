/*
COVID 19 DATA EXPLORATION 
-------------------------
Skills used: JOINs, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

--SELECT *
--FROM PortifolioProject.dbo.CovidDeaths
--ORDER BY 3,4

--SELECT *
--FROM PortifolioProject.dbo.CovidVaccinations
--ORDER BY 3,4

--SELECT Data to be used
SELECT 
	location, date, total_cases, total_deaths,new_cases,population
FROM PortifolioProject.dbo.CovidDeaths
ORDER BY 1,2

--SELECT TABLE_CATALOG,TABLE_SCHEMA,TABLE_NAME, COLUMN_NAME, DATA_TYPE 
SELECT COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'CovidDeaths'

--Total cases vs Total Deaths
SELECT 
	location, date, total_cases, total_deaths, 
	(CAST(Total_deaths AS float)/CAST(total_cases AS float))*100 AS 'DeathPercent'
FROM PortifolioProject.dbo.CovidDeaths
ORDER BY 1,2

-- Countries with Highest Infection Rate compared to Population
SELECT
	location, population,
	MAX(CAST(Total_deaths AS float)) AS HighestInfectionCount,
	ROUND(MAX((CAST(Total_deaths AS float)/population))*100,4) AS PercentPopulationInfected
FROM PortifolioProject.dbo.CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

-- Countries with Highest Death Count per Population
SELECT 
	location, 
	MAX(CAST(Total_deaths AS float)) AS TotalDeathCount
FROM PortifolioProject.dbo.CovidDeaths
--WHERE location like '%states%'
WHERE continent is not null 
GROUP BY location
ORDER BY TotalDeathCount DESC


-- BREAKING THINGS DOWN BY CONTINENT
	-- Showing contintents with the highest death count per population
SELECT 
	continent, 
	MAX(CAST(Total_deaths AS float)) AS TotalDeathCount
FROM PortifolioProject.dbo.CovidDeaths
--WHERE location like '%states%'
WHERE continent is not null 
GROUP BY continent
ORDER BY TotalDeathCount DESC



-- GLOBAL NUMBERS

SELECT
	SUM(CAST(new_cases AS float)) AS total_cases,
	SUM(CAST(new_deaths AS float)) AS total_deaths,
	SUM(CAST(new_deaths AS float))/SUM(CAST(new_cases AS float))*100 AS DeathPercentage
FROM PortifolioProject.dbo.CovidDeaths
--WHERE location like '%states%'
WHERE continent is not null 
--GROUP BY date
ORDER BY 1,2

SELECT * FROM PortifolioProject.dbo.CovidVaccinations


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
SELECT 
	dea.continent, 
	dea.location, 
	dea.date,
	dea.population, 
	vac.new_vaccinations,
	SUM(CONVERT(float,vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortifolioProject.dbo.CovidDeaths dea
JOIN PortifolioProject.dbo.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null 
ORDER BY 2,3


-- Using CTE to perform Calculation on Partition By in previous query
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, vac.new_vaccinations,
	SUM(CONVERT(float,vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM PortifolioProject.dbo.CovidDeaths dea
JOIN PortifolioProject.dbo.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null 
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100 AS 'PercentPeopleVaccinated'
FROM PopvsVac
WHERE location = 'italy'


-- Using Temp Table to perform Calculation on Partition By in previous query
DROP Table if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	New_vaccinations numeric,
	RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
	SUM(CONVERT(float,vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM PortifolioProject.dbo.CovidDeaths dea
JOIN PortifolioProject.dbo.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--WHERE dea.continent is not null 
--ORDER BY 2,3


-- Creating View to store data for later visualizations
Create View PercentPopulationVaccinated AS
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
	SUM(CONVERT(float,vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM PortifolioProject.dbo.CovidDeaths dea
JOIN PortifolioProject.dbo.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null 

--Query from view table 
SELECT *, (RollingPeopleVaccinated/Population)*100 AS 'PercentPeopleVaccinated'
FROM PercentPopulationVaccinated