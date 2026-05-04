/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

Select *
From  coviddeaths
Where continent is not null 
order by 3,4 ;


-- Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
From coviddeaths
Where continent is not null 
order by 1,2 ; 


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From coviddeaths
Where location like '%states%'
and continent is not null 
order by 1,2; 


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From coviddeaths
-- Where location like '%states%'
order by 1,2 ;


-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From coviddeaths
-- Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc ;


-- Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as SIGNED)) as TotalDeathCount
From coviddeaths
-- Where location like '%states%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc ;



-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as SIGNED)) as TotalDeathCount
From coviddeaths
-- Where location like '%states%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc ;



-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as SIGNED)) as total_deaths, SUM(cast(new_deaths as SIGNED))/SUM(New_Cases)*100 as DeathPercentage
From coviddeaths
-- Where location like '%states%'
where continent is not null 
-- Group By date
order by 1,2 ;



-- Total Population vs Vaccinations


SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    
    SUM(CAST(vac.new_vaccinations AS SIGNED)) 
        OVER (PARTITION BY dea.location ORDER BY dea.date) 
        AS RollingPeopleVaccinated

FROM coviddeaths dea
JOIN covidvaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date

WHERE dea.continent IS NOT NULL 

ORDER BY dea.location, dea.date;

-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT *,
    (RollingPeopleVaccinated / population) * 100 AS VaccinationRate
FROM (
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,
        
        SUM(CAST(vac.new_vaccinations AS SIGNED)) 
            OVER (PARTITION BY dea.location ORDER BY dea.date) 
            AS RollingPeopleVaccinated

    FROM coviddeaths dea
    JOIN covidvaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date

    WHERE dea.continent IS NOT NULL
) 

ORDER BY location, date;
-- Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac (
    Continent, 
    Location, 
    Date, 
    Population, 
    New_Vaccinations, 
    RollingPeopleVaccinated
) AS
(
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,
        
        SUM(CAST(vac.new_vaccinations AS SIGNED)) 
            OVER (PARTITION BY dea.location ORDER BY dea.date) 
            AS RollingPeopleVaccinated

    FROM coviddeaths dea
    JOIN covidvaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date

    WHERE dea.continent IS NOT NULL
)

SELECT *, 
    (RollingPeopleVaccinated / Population) * 100 AS VaccinationRate
FROM PopvsVac;



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TEMPORARY TABLE IF EXISTS PercentPopulationVaccinated;

CREATE TEMPORARY TABLE PercentPopulationVaccinated (
    Continent VARCHAR(255),
    Location VARCHAR(255),
    Date DATETIME,
    Population BIGINT,
    New_vaccinations BIGINT,
    RollingPeopleVaccinated BIGINT
);

INSERT INTO PercentPopulationVaccinated
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    
    SUM(CAST(vac.new_vaccinations AS SIGNED)) 
        OVER (PARTITION BY dea.location ORDER BY dea.date) 
        AS RollingPeopleVaccinated

FROM coviddeaths dea
JOIN covidvaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date;

SELECT *, 
    (RollingPeopleVaccinated / Population) * 100 AS VaccinationRate
FROM PercentPopulationVaccinated
ORDER BY Location, Date;



-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    
    SUM(CAST(vac.new_vaccinations AS SIGNED)) 
        OVER (PARTITION BY dea.location ORDER BY dea.date) 
        AS RollingPeopleVaccinated

FROM `PortfolioProject`.CovidDeaths dea
JOIN `PortfolioProject`.CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date

WHERE dea.continent IS NOT NULL;