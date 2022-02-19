ALTER TABLE [CovidDeaths] ALTER COLUMN total_deaths NUMERIC(22,5)
ALTER TABLE [CovidDeaths] ALTER COLUMN total_cases NUMERIC(22,5)

-- Select data for report
Select location, date, total_cases, new_cases, total_deaths, population 
From [Portfolio Project]..CovidDeaths
Order by 1,2

-- Looking at Total Cases vs Total Deaths
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage 
From [Portfolio Project]..CovidDeaths
Where location like '%states%'
Order by 1,2

-- Looking at Total Cases vs Population
-- Percentage of population with Covid
Select location, date, population, total_cases, (total_cases/population) * 100 as 'InfectionRate'
From [Portfolio Project]..CovidDeaths
where location like '%states%'
Order by 1,2 

-- Looking at Countries with Highest Infection Rate compared to Population
Select location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as InfectionRate
From [Portfolio Project]..CovidDeaths
Group by location, population
order by 4 desc



--- Showing countries with highest death count per population
 Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
 From [Portfolio Project]..CovidDeaths
 Where continent is not null
 Group by location
 Order by TotalDeathCount desc

 --GROUP BY CONTINENT
 Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
 From[Portfolio Project]..CovidDeaths
 Where continent is not null
 Group by continent
 Order by TotalDeathCount desc

 --GLOBAL NUMBERS
 Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
 From [Portfolio Project]..CovidDeaths
 Where continent is not null
 order by 1,2

 --Looking at total population vs vactinations

 Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(cast(vac.new_vaccinations as bigint)) 
        OVER (Partition by dea.Location Order by dea.location, 
        dea.date) as RollingPeopleVaccinated
 From [Portfolio Project]..CovidDeaths dea
 Join [Portfolio Project]..CovidVacctinations vac
	On dea.location = vac.location
	and dea.date = vac.date
 where dea.continent is not null
 order by 2,3

-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(numeric,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From [Portfolio Project]..CovidDeaths dea
Join [Portfolio Project]..CovidVacctinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (Convert(numeric(20), RollingPeopleVaccinated/Population))*100
From PopvsVac	

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(numeric,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From [Portfolio Project]..CovidDeaths dea
Join [Portfolio Project]..CovidVacctinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From [Portfolio Project]..CovidDeaths dea
Join [Portfolio Project]..CovidVacctinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
