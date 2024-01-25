select * 
from covid_vaccinations
order by total_vaccinations, people_vaccinated desc;

select * from covid_deaths
order by population, total_cases desc; 


-- Select data to be used
select location, date, total_cases, new_cases, total_deaths, population
from covid_deaths
order by 1,2;

-- Looking at total cases vs total deaths
-- Shows the probability of dying due to covid in a particular country
select location, date, total_cases, total_deaths, (cast(total_deaths as float)/total_cases)*100 as fatality_rate
from covid_deaths where location like 'India'
order by 1,2;


-- Looking at total cases vs population
-- Shows the probability of getting covid in a particular country
select location, date, total_cases, population, (cast(total_cases as float)/population)*100 as infection_rate
from covid_deaths where location like 'India'
order by 1,2;


-- Looking at countries having highest infection rate as compared to population
select location, max(total_cases) as Highest_Infection_Count, population, 
max((cast(total_cases as float)/population))*100 as maximum_infection_rate
from covid_deaths
group by location, population
order by 4 desc;

-- Looking at countries having highest death rate as compared to population
select location, MAX(total_deaths)as Highest_Fatality_count
from covid_deaths
where location not in ('World','Asia','Africa','Europe','North America','South America','Lower middle income','Upper middle income','High income','Low income','European Union')
group by location, population
order by 2 desc;

-- Looking at the data by continent for highest death counts
select location, MAX(total_deaths)as Highest_Fatality_count
from covid_deaths
where continent is null and location not in ('High income','Upper middle income', 'Lower middle income','Low income')
group by location
order by Highest_Fatality_count desc;


-- Showing the continents with highest infection rate
select location, MAX(total_cases) as Highest_Infection_Count
from covid_deaths
where continent is null and location not in ('High income','Upper middle income', 'Lower middle income','Low income')
group by location
order by Highest_Infection_Count desc;

-- Looking at the global data
select date, SUM(new_cases) as weekly_new_cases_globally, sum(new_deaths) as weekly_new_deaths_globally,
SUM(cast(new_deaths as float))/SUM(new_cases)*100 as weekly_global_fatality_rate
from covid_deaths 
where continent is not null and new_cases is not null
group by date
order by 1;

-- Total fatality rate worldwide
select SUM(new_cases) as total_cases_globally, sum(new_deaths) as total_deaths_globally,
SUM(cast(new_deaths as float))/SUM(new_cases)*100 as total_global_fatality_rate
from covid_deaths 
where continent is not null and new_cases is not null;

-- Looking at the vaccinations table and the deaths table
select * from covid_deaths as death
join covid_vaccinations as vacc
on death.location=vacc.location and death.date=vacc.date;

-- Looking at total Population vs vaccinations for each country
select death.continent,death.location, vacc.date, death.population, vacc.new_vaccinations
from covid_deaths as death
join covid_vaccinations as vacc on
death.location=vacc.location
where death.continent is not null and vacc.location like 'India'
order by death.date desc;

-- Rolling count of daily vaccinations for each country
select death.continent,death.location, death.date, death.population, vacc.new_vaccinations,
SUM(vacc.new_vaccinations) over (partition by death.location order by death.location, death.date)
from covid_deaths death
join covid_vaccinations vacc on
death.location=vacc.location
where death.continent is not null
order by 2,3;


-- Using a CTE
with population_vs_vaccination(Continent, Location, Date, Population,new_vaccinations, PeopleVaccinated)
as(
select death.continent,death.location, death.date, death.population, vacc.new_vaccinations,
SUM(cast(vacc.new_vaccinations as bigint)) over (partition by death.location order by death.location, death.date) as PeopleVaccinated
from covid_deaths death
join covid_vaccinations vacc on
death.location=vacc.location
where death.continent is not null
)
select * from population_vs_vaccination;

-- Temp table
Drop table if exists #percentpopulationvaccinated
create table #percentpopulationvaccinated
(	
	Continent varchar(50), 
	Location varchar(50), 
	Date datetime, 
	Population numeric,
	new_vaccinations numeric, 
	PeopleVaccinated numeric
)
insert into #percentpopulationvaccinated
select death.continent,death.location, death.date, death.population, vacc.new_vaccinations,
SUM(cast(vacc.new_vaccinations as bigint)) over (partition by death.location order by death.location, death.date) as PeopleVaccinated
from covid_deaths death
join covid_vaccinations vacc on
death.location=vacc.location
where death.continent is not null

select * from #percentpopulationvaccinated;

-- Creating view for upcoming data visulaizations
create view india_data as
select location, date, total_cases, total_deaths, (cast(total_deaths as float)/total_cases)*100 as fatality_rate
from covid_deaths where location like 'India'

select * from india_data;


-- Diving deeper into the data

-- Percentage of population vaccinated in each country
-- CTE
with percentage_vaccinated (location, population, doses_administered)
as
(
select dth.location, dth.population, max(vac.total_vaccinations) as doses_adminstered
from covid_deaths as dth
join covid_vaccinations as vac
on dth.location=vac.location
group by dth.location,dth.population
)
select location, population, (cast(doses_administered as float)/2)/population *100 as percentage_vaccinated_two_doses
from percentage_vaccinated
where (cast(doses_administered as float)/2)/population *100 <100
order by 2 desc;


-- Total people hospitalised in each country
select dth.location, max(cast(dth.total_cases as bigint))as total_cases, 
sum(cast(dth.hosp_patients as bigint)) as total_hospitalised
from covid_deaths as dth
group by dth.location
order by 3 desc; 

-- Percentage of people hostpitalised in each country
with percentage_hospitalised(location, total_cases, total_hospitalised)
as
(
select dth.location, max(cast(dth.total_cases as bigint))as total_cases, 
sum(cast(dth.hosp_patients as bigint)) as total_hospitalised
from covid_deaths as dth
group by dth.location
)
select location, total_cases, total_hospitalised, 
cast(total_hospitalised as float)/total_cases * 100 as percentage_hospitalised
from percentage_hospitalised
order by 4 desc;

-- By continent, number of people vaccinated
select dth.continent, max(vac.people_fully_vaccinated) as people_vaccinated
from covid_deaths as dth
join covid_vaccinations as vac
on dth.continent=vac.continent
where dth.continent is not null
group by dth.continent
order by 2 desc;

