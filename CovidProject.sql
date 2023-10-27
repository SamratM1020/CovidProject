

SELECT *
FROM CovidDeaths
ORDER BY 3, 4

--SELECT *
--FROM CovidVaccinations
--ORDER BY 3, 4

-- Select Data that we are going to be using 

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1, 2 -- want to base it off location (1) and date (2)


/* Lookining at Total Cases vs Total Deaths */
-- i.e. How many cases are there in this country and how many deaths do they have for their entire cases
-- say 1000 cases and 10 deaths, what's the percentage of people who died who had covid 

SELECT location, date, total_cases, total_deaths -- these are the columns we want to focus on
FROM CovidDeaths
ORDER BY 1, 2

-- want to know the percentage of people dying who have been infected by covid
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidDeaths
ORDER BY 1, 2

/* looking at it by location */
-- shows likelihood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1, 2 -- high percentage rates at the start (albeit smaller sample), got really bad around early May 2020
-- death percentage went down over time. over 20 million covid cases in the US by the end of 2020, 32 million by end of Apr 2021#

/* Looking at Total Cases vs Population */
-- shows what percentage of population got covid
SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
FROM CovidDeaths
-- WHERE location LIKE '%states%'
ORDER BY 1, 2
-- might use this one as a visualisation
-- think about the above query in terms of how we're going to visualise this in the future. Likely to be visualised in Power BI
-- using the US as our default example but going to compare it to the ROW


/* What countries have the highest infection rate compared to the population? */
SELECT
	location,
	population,
	MAX(total_cases) AS HighestInfectionCount,
	MAX((total_cases/population)*100) AS PercentPopulationInfected -- we can also do partition by with this one and add more columns in although it will take longer to run due to more rows 
FROM CovidDeaths
GROUP BY location, population -- aggregate functions in select statement so need to group by relevant columns (date is not a relevant column)
ORDER BY PercentPopulationInfected DESC
-- ^ Andorra has small population so highest infection rate
-- can also analyse this through looking at the most populated countries, see what their % is (ORDER BY population DESC)


/* Showing countries with the highest death count per population */

SELECT
		location,
		MAX(total_deaths) AS TotalDeathCount
FROM CovidDeaths
GROUP BY location
ORDER BY TotalDeathCount DESC 
-- ^ execute the above and we'll see an issue with the order of the TotalDeathCount
-- issue with the data type, go to columns and we'll see that total_deaths is in nvarchar(255), when it's an integer
-- what we need to do is to CAST it as an integer, CAST(expression AS datatype(length)) :
SELECT
		location,
		MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM CovidDeaths
GROUP BY location
ORDER BY TotalDeathCount DESC 
-- now much more accurate but have a slight issue with our data. In location section, we have some data that shouldn't be there
-- i.e. World, Europe, Africa etc. These are grouping entire continents 
-- look back at original full dataset:
SELECT *
FROM CovidDeaths
ORDER BY 3, 4
-- ^ we can see that there are result where the location is Asia but in other ones, the continent is Asia
SELECT *
FROM CovidDeaths
WHERE location IN ('World', 'Asia', 'Europe', 'North America', 'European Union', 'South America', 'Africa', 'Oceania', 'International')
ORDER BY 3, 4
-- ^ and we also notice that the continents column where the name of the continents are in the location column are NULL
-- therefore what we need to do is this:
SELECT *
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3, 4
-- gets rid of all the contineny names in location column


/* and now we can proceed to our query of showing the countries with highest death count per population */

SELECT
		location,
		MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC 
-- ^ Been breaking everything out by location


/* but let's break things down by continent this time (no null values in location): */
SELECT
		continent,
		MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM CovidDeaths
GROUP BY continent
ORDER BY TotalDeathCount DESC 
-- ^ get rid of the NULL value (as those have continent names + World + EU in location)

SELECT
		continent,
		MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC 
/* This is not perfect because there are some some small issues as North America appears to only be including
numbers from the United States (the country with the largest death count) but not Canada etc. 
Run the two queries below which confirms this. */

-- SELECT MAX(CAST(total_deaths AS int)) FROM CovidDeaths WHERE location = 'Canada'
-- SELECT MAX(CAST(total_deaths AS int)) FROM CovidDeaths WHERE location = 'United States'


/* correct way to do this.  */ 
SELECT 
	continent, 
	SUM(CAST(new_deaths AS int)) AS TotalDeathCount -- new_deaths is in nvarchar(255) so convert that to int in the query
FROM CovidDeaths
WHERE continent IS NOT NULL -- can alternatively use != ''
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- ^ total_deaths is a cumulative total of new_deaths which is recorded on a daily basis. In the wrong way, what made it
-- incorrect was that only the maximum value of the total_deaths was taken into consideration
-- when what we were actually supposed to do was to get the sum of new deaths as it totals up, and then group by continent

/* correct numbers can also be found by selecting location, grouping by location and filtering where continent is NULL */
SELECT 
	location, 
	SUM(CAST(new_deaths AS int)) AS TotalDeathCount -- or can use MAX(CAST(total_deaths AS int)) instead of SUM. I prefer SUM
FROM CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC
-- small tip: can filter out world, EU, international using the NOT IN operator for location



/*
for the purposes of heirarchy and that drill down effect in Power BI, we want to start including the continent
in our queries, so that we can drill down further into these things
*/

-- back to correct syntax for continent:
SELECT 
	continent,
	SUM(CAST(new_deaths AS int)) AS TotalDeathCount 
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC



/* showing the highest death count per population */

-- we want to start looking at this from the viewpoint of "how am I going to visualise this?"
-- do this by looking at global numbers. Can do as many as we want, in the group by, replace location with continent.
-- Gives us that drill-down effect, click on North America and then bring it out, it shows all the countries in NA etc.
-- SELECT continent, location + GROUP BY continent, location? 


-- We want to caluclate everything across the entire world. GLOBAL numbers. Not including any location/country, any continent
-- we want to know how many new cases and deaths there were in each day
SELECT
	date,
	SUM(new_cases) AS total_cases,
	SUM(CAST(new_deaths AS int)) AS total_deaths,
	(SUM(CAST(new_deaths AS int))/SUM(new_cases))*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1
-- new_cases is in float but new_deaths is in nvarchar(255) so need to convert new_deaths to int


/*
to get the total cases and total deaths across the entire world over the entire 16 month period,
remove the date column and remove the 'GROUP BY date' clause.
Don't really need ORDER BY for this one either
*/
SELECT
	SUM(new_cases) AS total_cases,
	SUM(CAST(new_deaths AS int)) AS total_deaths,
	(SUM(CAST(new_deaths AS int))/SUM(new_cases))*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
-- 2.11% death percentage across the world



/* looking at CovidVaccinations table */

SELECT *
FROM CovidVaccinations

-- columns we'll be looking at will be tests, vaccinations

-- joining the two tables together. On two things. Location and date

SELECT *
FROM CovidDeaths AS dea
INNER JOIN CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date

/* looking at total populations vs vaccination */

SELECT
	dea.continent,
	dea.location,
	dea.date, -- note: if we just say date, SQL will return an error as we did not specify which table we pulled the date from
	dea.population,
	vac.new_vaccinations
FROM CovidDeaths AS dea
INNER JOIN CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3
-- Canada started vaccinations very early (15/12/20) and went on to perform hundreds and thousands of vaccinations per day

/*
We won't be using total_vaccinations, we'll use new_vaccinations per day. Want to know or do a rolling count 
of vaccinations. Cumulative increase of vaccinations so want to add it all up.

We'll be using the likes of partition by, windows function, etc. 
*/

SELECT
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location) -- need to partition it by location because we're breaking it up and if we do it by continent, the numbers will be completely off. (and also partly the date). 
FROM CovidDeaths AS dea
INNER JOIN CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- instead of using CAST, we can also use the CONVERT function
-- syntax: CONVERT(data_type, expression), in this case it's CONVERT(int, vac.new_vaccination)
SELECT
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location) -- need to partition it by location because we're breaking it up and if we do it by continent, the numbers will be completely off. (and also partly the date). 
FROM CovidDeaths AS dea
INNER JOIN CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- ^ Because we only partitioned on just location, it did the sum of all the new vaccinations by that location (look at Albania as example)
-- So what we need to do is to order by both the location and, more importantly, the date
-- the date is what is going to separate it out and show the rolling total count of vaccinations in that country following each day
SELECT
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths AS dea
INNER JOIN CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3
-- looking at Albania again, it adds up every single consecutive one. It's a rolling count.

-- We want to look at the Total population vs Vaccinations, and we want to use the max number of RollingPeopleVaccinated
-- and then divide it by the population to get a percentage of how many people in that country are vaccinated:
SELECT
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated,
	(RollingPeopleVaccinated/dea.population)*100
FROM CovidDeaths AS dea
INNER JOIN CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3
-- ^ returns a syntax error as you can't use a column you've created to then use it in the next one (due to order of execution)
-- so ignore the last query typed out and highlight/C&P the one before


/* Therefore, what we need to do is to create either a CTE or a temp table. Can do one or both. */

-- USE CTE
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) -- bracketed column is optional to change name of columns
AS
(
SELECT
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths AS dea
INNER JOIN CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT 
	*,
	(RollingPeopleVaccinated/Population)*100 AS PercentPopulationVaccinated
FROM PopvsVac
ORDER BY 2,3
-- remember to highlight the whole thing, from the CTE right down to our SELECT statement at the bottom
-- i.e. run the query WITH the CTE
-- note: the ORDER BY clause CANNOT be used inside a CTE 
-- results show that as of 30th April 2021, 12% of Albania is vaccinated (row 862)

-- can also look at the max value of % people vaccinated but make sure you don't select date as that will throw the whole thing off


/* using a TEMP TABLE. Remember, need to specify data type in temp table. Since it's a table after all! */

CREATE TABLE #PercentPopulationVaccinated
(Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric)

INSERT INTO #PercentPopulationVaccinated
SELECT
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths AS dea
INNER JOIN CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated/Population)*100 AS PercentPopulationVaccinated
FROM #PercentPopulationVaccinated
ORDER BY 2,3

/* note: say we change our mind and we do not want to use the filter WHERE dea.continent IS NOT NULL. Instead of 
commenting out that filter and then running the creation of the temp table again (which would return an error),
what we need to do is use the following command below:
		DROP TABLE IF EXISTS #PercentPopulationVaccinated
*/



/* 
Creating a VIEW to store data for later visualisations.
Say if we want to look at the global numbers, just toss it in a view.
Or even continents with highest death count per population, just toss it in a view

Syntax to create a view is "CREATE VIEW (expression) AS"

*/

CREATE VIEW PercentPopulationVaccinated AS
SELECT
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths AS dea
INNER JOIN CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--^ note: ORDER BY clause is invalid in views, just like it is in CTEs

SELECT *
FROM PercentPopulationVaccinated
ORDER BY 2,3

-- Views are permanent, they are stored in the database, unlike a temp table which is gone once the window closes and have to run it again

