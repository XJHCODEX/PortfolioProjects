-- Queries --
-- CovidDeaths table
Select * From PortfolioProject..CovidDeaths order by 3,4
-- CovidVaccinations table
Select * From PortfolioProject..CovidVaccinations Order by 3,4
-- Select Data that we are going to be using
Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
order by 1,2
-- Looking at Total Cases vs Total Deaths
Select Location, date, total_cases, total_deaths, (cast(total_deaths as decimal)/total_cases)
From PortfolioProject..CovidDeaths
Where location like '%states%'
order by 1,2
-- Looking at DeathPercentage by states
Select Location, date, total_cases, (cast(total_deaths as decimal)/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where location like '%states%'
and continent is not null
order by 1,2
-- Shows what percentage of population by states got Covid 
Select Location, date, total_cases, total_deaths, (total_cases/population)*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Where location like '%states%'
order by 1,2
-- Looking at countries with Highest Infection Rate compared to Population by states
Select Location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc
-- Base selection on where continent is not null (Highest death count per population)
Select Location, MAX(cast(total_deaths as decimal)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null
Group by Location
order by TotalDeathCount desc
-- Base selection on where continent is null (Highest death count per population)
Select Location, MAX(cast(total_deaths as decimal)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is null
Group by Location
order by TotalDeathCount desc
-- Global numbers
Select SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths, (SUM(cast(new_deaths as int))/SUM(new_cases))*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where continent is not null
order by 1,2
-- Joins to combine CovidDeaths and CovidVaccination tables
Select *
From PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
-- Looking at total population Vs vaccinations
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
From PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3
-- Include RollingPeopleVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(cast(vac.new_vaccinations as decimal)) OVER (Partition by dea.Location Order by dea.location, dea.date)
as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3
-- use CTE
With PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(cast(vac.new_vaccinations as decimal)) OVER (Partition by dea.Location Order by dea.location, dea.date)
as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)
Select *, (RollingPeopleVaccinated/population)*100 as RollingPeopleVaccinatedPercentage
From PopvsVac
-- Drop table
Drop Table if exists #VaccinatedPopulation
-- Temp Table
CREATE TABLE #VaccinatedPopulation
(Continent nvarchar(255), Location nvarchar(255), Date datetime, Population numeric, New_vaccinations numeric, RollingPeopleVaccinated numeric)
INSERT INTO #VaccinatedPopulation
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(cast(vac.new_vaccinations as decimal)) OVER (Partition by dea.Location Order by dea.location, dea.date)
as RollingPeopleVacinated
From PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
Select *, (RollingPeopleVaccinated/population)*100 as RollingPeopleVaccinatedPercentage
From #VaccinatedPopulation
-- Drop View
Drop View if exists PercentPopulationVaccinated
-- Creating view to store data for later visualizations
CREATE VIEW VaccinatedPopulation as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(cast(vac.new_vaccinations as decimal)) OVER (Partition by dea.Location Order by dea.location, dea.date)
as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
-- View of VaccinatedPopulation
Select *
From VaccinatedPopulation