# Integrating Data from Separate Tables

We have a sample of men and women collected via Prolific, who completed a survey on Qualtrics. The initial sample of participants were recruited via Prolific (“Partner As”). At the end of this survey, participants were asked to enter the email address of their current romantic partner. If “Partner A” opted to enter a valid email address, the survey link was then sent to their romantic partner (“Partner B”). 

These data offer the unique opportunity to compare survey responses between both members of a romantic couple. For example, we could compare men’s self-reported experience with erectile dysfunction with their female partner’s perceptions of the male partner’s experience with erectile dysfunction. In other words, these data afford us the opportunity to determine whether both members of a romantic couple generally agree with each other regarding various relationship experiences. However, before we can analyze the data in this way, we’ll need to do some reorganization so that each male partner is paired up with his female counterpart (i.e., each male participant should be in the same row as his female partner). Luckily, all “Partner A” participants were given a 5-digit random ID, which they were asked to provide to their romantic partner (Partner B). Partner B was then asked to provide this 5-digit ID when taking their survey so that their responses could be linked with their partner’s. This 5-digit ID will serve as our “primary key” when joining the responses of men and women into a single table.

When we download the data from Qualtrics, the first thing we notice is that the data are separated into two CSV files: “Partner A Data” and “Partner B Data”, representing those participants who were recruited directly via Prolific (Partner As) and those participants who were recruited by their romantic partner (Partner Bs). Each CSV file contains data from both men and women. 

The first thing we want to do after we’ve imported both CSV files into our SQL database is separate each file into two tables by sex (for a total of 4 tables). 

```sql
create table partner_a_men as
select * from partner_a_demographics
where a_sex_self = 1; 

create table partner_a_women as
select * from partner_a_demographics
where a_sex_self = 2; 

create table partner_b_men as
select * from partner_b_demographics
where b_sex_self = 1; 

create table partner_b_women as
select * from partner_b_demographics
where b_sex_self = 2;
```

We can now join the “Partner A” men with their counterparts in the “partner_b_women” table, and the “Partner B” men with their counterparts in the “partner_a_women” table. We’ll use inner joins so that all columns from each table are preserved when we create our new, combined tables. We’ll also make sure to keep all men on the “left” side of each combined table. This will make it easier to combine all participants into a single table later on.


```sql
create table a_men_b_women as 
select * from partner_a_men
inner join partner_b_women
on partner_a_men.a_random_id = partner_b_women.b_pa_Rand_ID;

create table b_men_a_women as
select * from partner_b_men
inner join partner_a_women
on partner_b_men.b_pa_Rand_ID = partner_a_women.a_random_id;
```
Finally, we need to integrate both tables so that all paired couples are in a single table. But first, we need to rename the columns in both tables so that each column for men’s variables (regardless of whether they were originally partner A or partner B) are the same across tables. And of course, we will repeat this process for women’s variables as well. 

I used chatgpt to help me write a couple stored procedures that will automatically rename the columns. For the table in which all men are “partner A” and all women are “partner B”, we want to rename the columns so that the “A” preceding each variable name is replaced with “M” (for men) and each “B” is replaced with “W” for women. Below is an example of just one of the stored procedures which will change all “A”s to “M”s, but we only need to change a few bits of code to make all of the necessary changes.

```sql
DELIMITER //

CREATE PROCEDURE RenameColumns()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE oldColumnName VARCHAR(255);
    DECLARE newColumnName VARCHAR(255);
    DECLARE columnDataType VARCHAR(255);
    DECLARE isNullable VARCHAR(3);
    DECLARE columnDefault VARCHAR(255);
    DECLARE extraInfo VARCHAR(255);

    DECLARE columnCursor CURSOR FOR
        SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, COLUMN_DEFAULT, EXTRA
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_NAME = 'a_men_b_women' AND COLUMN_NAME LIKE 'A%';

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN columnCursor;

    column_loop: LOOP
        FETCH columnCursor INTO oldColumnName, columnDataType, isNullable, columnDefault, extraInfo;

        IF done THEN
            LEAVE column_loop;
        END IF;

        SET newColumnName = CONCAT('M', SUBSTRING(oldColumnName, 2));

        SET @sql = CONCAT('ALTER TABLE b_men_a_women CHANGE COLUMN ', oldColumnName, ' ', newColumnName, ' ', columnDataType,
                          IF(isNullable = 'NO', ' NOT NULL', ''),
                          IF(columnDefault IS NOT NULL, CONCAT(' DEFAULT ', QUOTE(columnDefault)), ''),
                          IF(extraInfo IS NOT NULL, CONCAT(' ', extraInfo), ''));

        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END LOOP;

    CLOSE columnCursor;
END //

DELIMITER ;

-- Call the stored procedure
CALL RenameColumns();
```
Now, we can use the “UNION” operator to vertically stack/concatenate the two tables

```sql
create table all_couples as
select * from a_men_b_women
union
select * from b_men_a_women;
```

