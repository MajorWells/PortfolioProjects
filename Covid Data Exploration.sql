

select *
FROM [Portfolio Project]..['Covid Vaccinations$']
order by 3,4

--select location, date, total_cases, new_cases, total_deaths, population
--FROM [Portfolio Project]..['Covid Deaths$']
--order by 1,2 ASC

--LOOKING AT TOTAL CASES VS DEATHS

--Roughly calculates likelihood of death by Covid-19 in United States
select location, date, total_cases, total_deaths,
(total_deaths/total_cases) *100 AS Death_Percentage
FROM [Portfolio Project]..['Covid Deaths$']
WHERE location like '%States%'
order by date desc


--Looking at total cases against population
--Shows % of population that has died from COVID-19
select location, date, population, total_deaths,
(total_deaths/population) *100 AS Death_Percentage
FROM [Portfolio Project]..['Covid Deaths$']
WHERE location like '%States%'
order by date desc

--Looking at total cases against population
--Shows % of population that has contracted COVID-19
select location, date, population, total_cases,
(total_cases/population) *100 AS Case_Percentage
FROM [Portfolio Project]..['Covid Deaths$']
--WHERE location like '%States%'
order by date

--Looking at countries with highest infection rates

select location, population, MAX(total_cases) as HighestInfectionCount, 
MAX((total_cases/population)) *100 AS Case_Percentage
FROM [Portfolio Project]..['Covid Deaths$']
where continent is not null
group by population, location
order by Case_Percentage desc

--Looking at countries with highest death rates
select location, population, MAX(cast(total_deaths as int)) as Total_Death_Count, 
MAX((total_deaths/population)) *100 AS Death_Percentage
FROM [Portfolio Project]..['Covid Deaths$']
where continent is not null
group by population, location
order by Total_Death_Count desc



--Slicing by continent
select location, MAX(cast(total_deaths as int)) as Total_Death_Count, 
MAX((total_deaths/population)) *100 AS Death_Percentage
FROM [Portfolio Project]..['Covid Deaths$']
where continent is null
group by location
order by Total_Death_Count desc

--Showing continents with highest death count per population

--select date, MAX(cast(total_deaths as int)) as Total_Death_Count, 
--MAX((total_deaths/population)) *100 AS Death_Percentage
--FROM [Portfolio Project]..['Covid Deaths$']
--where continent is not null
--group by date
--order by Total_Death_Count desc

--summing total new cases per day, globally. Filtering out the Continent grouping to avoid double counting countries
select date, SUM(new_cases) AS global_new_cases, SUM(cast(new_deaths as int)) as global_new_deaths
FROM [Portfolio Project]..['Covid Deaths$']
where continent is not null
group by date
order by date desc

--summing total new cases per day, globally. Filtering out the Continent grouping to avoid double counting countries
select 
date, 
SUM(new_cases) AS global_new_cases, 
SUM(cast(new_deaths as int)) as global_new_deaths,
SUM(cast(new_deaths as int))/(SUM(new_cases)) as global_death_rate
FROM [Portfolio Project]..['Covid Deaths$']
where continent is not null
group by date
order by date desc



--Looking at total pop. vs vaxxed, Uses CTE
with popvsvac (continent, location, date, population, new_vaccinations, rolling_vaxxed_population)
as

(SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS INT))
OVER (Partition by dea.location order by dea.location, dea.date) as rolling_vaxxed_population

FROM [Portfolio Project]..['Covid Deaths$'] DEA
JOIN [Portfolio Project]..['Covid Vaccinations$'] VAC
	ON dea.date = vac.date
	and dea.location = vac.location
WHERE dea.continent is not null
--order by 1,2
)

Select *, (rolling_vaxxed_population/population) *100 AS vaxxed_percentage
from popvsvac



--Looking at total pop. vs vaxxed, Uses temp table
DROP table if exists #percentpopulationvaxxed
Create table #percentpopulationvaxxed
(
continent nvarchar(255),
location nvarchar(255), 
date datetime, 
population numeric,
new_vaccinations numeric,
rolling_vaxxed_population numeric
)

Insert into #percentpopulationvaxxed
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS INT))
OVER (Partition by dea.location order by dea.location, dea.date) as rolling_vaxxed_population

FROM [Portfolio Project]..['Covid Deaths$'] DEA
JOIN [Portfolio Project]..['Covid Vaccinations$'] VAC
	ON dea.date = vac.date
	and dea.location = vac.location
WHERE dea.continent is not null
--order by 1,2

Select *, (rolling_vaxxed_population/population) *100 AS vaxxed_percentage
from #percentpopulationvaxxed

--Creating View to store data for later visualization

create view percentpopulationvaxxed as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS INT))
OVER (Partition by dea.location order by dea.location, dea.date) as rolling_vaxxed_population

FROM [Portfolio Project]..['Covid Deaths$'] DEA
JOIN [Portfolio Project]..['Covid Vaccinations$'] VAC
	ON dea.date = vac.date
	and dea.location = vac.location
WHERE dea.continent is not null
--order by 2, 3