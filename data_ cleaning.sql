-- SQL Project - Data Cleaning

-- https://www.kaggle.com/datasets/swaptr/layoffs-2022

-- first thing i want to do is create a staging table. This is the one i will work in and clean the data. I want a table with the raw data in case something happens

create layoffs_staging
select * from layoffs;

select * from 
layoffs_staging;

select count(*) as total_rows_1
from layoffs_staging;


#  checking  for duplicates 
SELECT *,count(*)
FROM layoffs_staging
GROUP BY company, location,industry,total_laid_off,percentage_laid_off, `date`,stage,country,
funds_raised_millions
HAVING COUNT(*) > 1;


#  remove the  duplicates 
create table layoffs_staging2
select *
from(
select *, 
ROW_NUMBER()over(partition by company, location,industry,total_laid_off,percentage_laid_off, `date`,stage,country,
funds_raised_millions)as row_num
from layoffs_staging
)t;

DELETE from layoffs_staging2
where row_num>1; 

# verify the removal
select * from layoffs_staging2
where row_num>1;

--  Standardize Data
# look at the column of company, there are space at the begining in some rows
select company, trim(company)
from layoffs_staging2;

update layoffs_staging2
set company=trim(company);

-- look at the column of industry,I  noticed the Crypto has multiple different variations. i need to standardize that - let's say all to Crypto
SELECT DISTINCT industry
FROM world_layoffs.layoffs_staging2
ORDER BY industry;

update layoffs_staging2
set industry='crypto'
where industry like 'crypto%';

SELECT DISTINCT industry
FROM world_layoffs.layoffs_staging2
ORDER BY industry;

-- look at the column of location, it seems good
select distinct location
from layoffs_staging2
order by 1;

-- look at the country column, everything looks good except apparently i have some "United States" and some "United States." with a period at the end. Let's standardize this.
SELECT DISTINCT country
FROM world_layoffs.layoffs_staging2
ORDER BY country;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
where country like 'united states%';

-- now if i run this again it is fixed
SELECT DISTINCT country
FROM world_layoffs.layoffs_staging2
ORDER BY country;


-- Let's also fix the date columns:
SELECT *
FROM world_layoffs.layoffs_staging2;

-- i can use str to date to update this field
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- now i can convert the data type properly
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- Look at null values and see what can be populated
SELECT DISTINCT industry
FROM world_layoffs.layoffs_staging2
ORDER BY industry;

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE industry IS NULL 
OR industry = ''
ORDER BY industry;

-- let's take a look at these
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE company LIKE 'Bally%';

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE company LIKE 'airbnb%';

-- it looks like airbnb is a travel, but this one just isn't populated.
-- I'm sure it's the same for the others. What i can do is
-- write a query that if there is another row with the same company name, it will update it to the non-null industry values
-- makes it easy so if there were thousands i wouldn't have to manually check them all
-- i should set the blanks to nulls since those are typically easier to work with
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- now if i check those are all null

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE industry IS NULL 
OR industry = ''
ORDER BY industry;

-- now i need to populate those nulls if possible

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;
-- lets look at Airbnb to see if it worked
select * from layoffs_staging2
where company='Airbnb';
-- and if i check it looks like Bally's was the only one without a populated row to populate this null values
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE industry IS NULL 
OR industry = ''
ORDER BY industry;

-- remove any columns and rows that are not necessary - few ways

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Delete Useless data i can't really use
DELETE FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT * 
FROM world_layoffs.layoffs_staging2;

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;


SELECT * 
FROM world_layoffs.layoffs_staging2;

