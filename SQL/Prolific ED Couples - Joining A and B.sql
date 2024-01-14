create database ed_couples;

select * from partner_a_demographics;

drop table partner_b_demographics;

select * from partner_a_demographics
order by random_id asc;

select * from partner_b_demographics;

alter table partner_a_demographics
add constraint
primary key (pro_id);
partner_a_demographicspartner_a_demographics
delete from partner_a_demographics
where Demographics_Filter = 0;

delete from partner_b_demographics
where Demographics_Filter = 0;

alter table partner_a_demographics
modify column pro_id varchar(50);

select * from partner_a_demographics
inner join partner_b_demographics
on partner_a_demographics.a_random_id = partner_b_demographics.b_pa_Rand_ID;

select * from partner_a_demographics
inner join partner_b_demographics
on partner_a_demographics.a_pro_id = partner_b_demographics.b_pa_Rand_ID;

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

create table a_men_b_women as 
select * from partner_a_men
inner join partner_b_women
on partner_a_men.a_random_id = partner_b_women.b_pa_Rand_ID;

create table b_men_a_women as
select * from partner_b_men
inner join partner_a_women
on partner_b_men.b_pa_Rand_ID = partner_a_women.a_random_id;

create table paired_couples as
select * from partner_a_demographics
inner join partner_b_demographics
on partner_a_demographics.a_random_id = partner_b_demographics.b_pa_Rand_ID;

select * from a_men_b_women;

select * from b_men_a_women;

select * from paired_couples;

commit;

rollback;

alter table a_men_b_women
rename column where column like "a%" to "m%";

alter table a_men_b_women
rename column A_Duration__in_seconds_ to m_duration_in_seconds;

alter table a_men_b_women
rename column a_finished to m_finished;

alter table a_men_b_women
rename column A_ResponseId to M_responseID;

alter table a_men_b_women
rename column A_Consent_Response to M_Consent_Response;

SET @tableName = 'a_men_b_women';

drop procedure RenameColumns;

DELIMITER //

CREATE PROCEDURE RenameColumns4()
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
        WHERE TABLE_NAME = 'b_men_a_women' AND COLUMN_NAME LIKE 'A%';

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN columnCursor;

    column_loop: LOOP
        FETCH columnCursor INTO oldColumnName, columnDataType, isNullable, columnDefault, extraInfo;

        IF done THEN
            LEAVE column_loop;
        END IF;

        SET newColumnName = CONCAT('W', SUBSTRING(oldColumnName, 2));

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
CALL RenameColumns4();

select * from a_men_b_women;

select * from b_men_a_women;

alter table b_men_a_women
drop column M_PA_Rand_ID;

alter table a_men_b_women
drop column W_PA_Rand_ID;

alter table a_men_b_women
modify column M_PRO_ID varchar(50) after W_Demographics_Filter;

alter table b_men_a_women
modify column W_PRO_ID varchar(50) after W_Demographics_Filter;

alter table b_men_a_women
rename column ï»¿A_Progress to W_Progress;

drop table all_couples;

create table all_couples as
select * from a_men_b_women
union
select * from b_men_a_women;

select * from all_couples;



