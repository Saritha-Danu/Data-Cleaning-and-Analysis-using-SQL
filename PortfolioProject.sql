SELECT * 
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

SELECT * 
FROM CovidVaccinations
ORDER BY 3,4

-- select the data that we are going to use

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
order by 1,2

-- looking at Total Cases vs Total Deaths

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM CovidDeaths
WHERE Location Like 'India' AND continent IS NOT NULL
order by 1,2


-- total_deaths, total_cases column where nvarchar dtype [hence, can't find %] , so change them to float

SELECT DATA_TYPE 
FROM INFORMATION_SCHEMA. COLUMNS 
WHERE TABLE_NAME = 'CovidDeaths' AND COLUMN_NAME = 'total_cases';

ALTER TABLE CovidDeaths 
ALTER COLUMN total_cases float 

ALTER TABLE CovidDeaths 
ALTER COLUMN total_deaths float 

-- shows likehood of dying if you  are covid +ve in your country

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM CovidDeaths
WHERE Location Like '%states%' AND continent IS NOT NULL
order by 1,2

-- Looking at Total cases vs Population
-- shows what percentage of population got covid

SELECT Location, date, population,total_cases, (total_cases/population)*100 as PercentPopulationInfected
FROM CovidDeaths
WHERE Location Like 'India' AND continent IS NOT NULL
order by 1,2


-- Countries with the highest infection rate compared to population

SELECT Location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population)*100) as PercentPopulationInfected
FROM CovidDeaths
--WHERE Location Like 'India'
GROUP BY Location, population
order by PercentPopulationInfected desc

-- showing countries with highest death count per population

SELECT Location, MAX(total_deaths) as DeathCount
FROM CovidDeaths
--WHERE Location Like 'India'
WHERE continent is NOT NULL
GROUP BY Location
order by DeathCount desc

-- LET'S BREAK THINGS DOWN BY CONTINENT
-- showing continents with highest death count

SELECT continent, MAX(total_deaths) as DeathCount
FROM CovidDeaths
--WHERE Location Like 'India'
WHERE continent is NOT NULL
GROUP BY continent
order by DeathCount desc

-- GLOBAL NUMBERS

SELECT date, 
       SUM(new_cases) AS total_cases, 
       SUM(new_deaths) AS total_deaths,
       CASE WHEN SUM(new_cases) > 0 THEN (SUM(new_deaths) / SUM(new_cases)) * 100 ELSE 0 END AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL  -- Use IS NOT NULL for strict comparison
GROUP BY date
ORDER BY 1, 2;

SELECT 
       SUM(new_cases) AS total_cases, 
       SUM(new_deaths) AS total_deaths,
       CASE WHEN SUM(new_cases) > 0 THEN (SUM(new_deaths) / SUM(new_cases)) * 100 ELSE 0 END AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL  -- Use IS NOT NULL for strict comparison
--GROUP BY date
ORDER BY 1, 2;

--3.6.34

select * 
from CovidVaccinations

-- looking at total people vs vaccinations

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(float, vac.new_vaccinations)) OVER (partition by dea.location order by dea.location,
dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population) * 100 : we can't use this column which was just created, hence use temp tables/ CTE's
from CovidDeaths dea
join CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- we want to find the total % of people vaccinated in a location, using RollingPeopleVaccinated, since it has the max_peopleVaccinated value at the end of each location
--CTE

with PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated) 
as
(select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(float, vac.new_vaccinations)) OVER (partition by dea.location order by dea.location,
dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population) * 100
from CovidDeaths dea
join CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
--order by 2,3
) 
select *, (RollingPeopleVaccinated/population) * 100
from PopvsVac


-- TEMP TABLE

drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(float, vac.new_vaccinations)) OVER (partition by dea.location order by dea.location,
dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population) * 100
from CovidDeaths dea
join CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date
--where dea.continent is not null
--order by 2,3
select *, (RollingPeopleVaccinated/population) * 100
from #PercentPopulationVaccinated

create view PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(float, vac.new_vaccinations)) OVER (partition by dea.location order by dea.location,
dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population) * 100
from CovidDeaths dea
join CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
--order by 2,3

