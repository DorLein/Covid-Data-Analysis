Select * 
from dbo.CovidDeath
where continent is not null
order by 3,4

--Select * 
--from dbo.CovidVaccinations
--order by 3,4

Select Location,date,total_cases,total_deaths,new_cases,population
from dbo.CovidDeath
order by 1,2

-- Total cases vs Total Deaths
-- (This shows the likelihook of dying if you contract covid in your country )
Select Location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 as DeathPercentage
from dbo.CovidDeath
Where location like '%morocco'
order by 1,2

-- Total cases vs Population 
--(This shows what percentage of population got Covid )
Select Location,date,total_cases,Population,(total_cases/Population)*100 as PercentPopulationInfected
from dbo.CovidDeath
Where location like '%morocco'
order by 1,2

-- Countries with highest infection rate compared to Population 
Select Location ,Population , max(total_cases) as HighestInfectionCount,max(total_cases/population)*100 as Percentage 
from dbo.CovidDeath
Group by Location , Population 
order by Percentage desc

-- Countries with the highest death count per Population
Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From dbo.CovidDeath
where continent is not null
Group by Location
order by TotalDeathCount desc

-- Continent with the highest death count per population 
Select continent , Max(cast(total_deaths as int)) as TotalDeathCount
from dbo.CovidDeath
Where continent is not null
Group by continent 
order by TotalDeathCount desc

--Global numbers 
Select sum(new_cases) as total_cases, sum(cast(new_deaths as int))as total_deaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
from dbo.CovidDeath
where continent is not null
order by 1,2

-- Shows Percentage of Population that has received at least one covid vaccination 
Select dea.continent, dea.location,dea.date,dea.population,vac.new_vaccinations,sum(convert(int,vac.new_vaccinations))over(Partition by dea.Location order by dea.location,dea.date)as RollingPeopleVaccinated
from dbo.CovidDeath dea
join dbo.CovidVaccinations vac 
on dea.location = vac.location 
and dea.date = vac.date 
where dea.continent is not null 
order by 2,3

-- Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,
        SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
    FROM 
        dbo.CovidDeath dea
    JOIN 
        dbo.CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
    WHERE 
        dea.continent IS NOT NULL
)
-- Perform the division here
SELECT 
    *,
    (RollingPeopleVaccinated / population) * 100 AS VaccinationPercentage
FROM 
    PopvsVac;



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
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From dbo.CovidDeath dea
Join dbo.CovidVaccinations vac
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
From dbo.CovidDeath  dea
Join dbo.CovidVaccinations  vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
