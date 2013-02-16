/*
	migration jira.priority,jira.resolution into redmine.enumerations
	migration jira.customfieldoption,jira.customfield,jira.customfieldvalue;
*/

select * from jira.customfieldoption;
select * from jira.customfield;
select * from jira.customfieldvalue;

select * from custom_fields;
select * from custom_fields_trackers;


INSERT INTO custom_fields
(type, name, field_format, possible_values, `regexp`, min_length, max_length, is_required, is_for_all, is_filter, searchable, default_value, editable, visible, multiple) 
select 
'IssueCustomField' as type,cfname as name,
case
when customfieldtypekey = 'com.atlassian.jira.plugin.system.customfieldtypes:textfield' 
then 'string'
when customfieldtypekey = 'com.atlassian.jira.plugin.system.customfieldtypes:select'
then 'list'
when customfieldtypekey = 'com.atlassian.jira.plugin.system.customfieldtypes:datepicker'
then 'date'
when customfieldtypekey = 'com.atlassian.jira.plugin.system.customfieldtypes:datetime'
then 'date'
when customfieldtypekey = 'com.atlassian.jira.plugin.system.customfieldtypes:textarea'
then 'text'
else 'text' 
end filed_format
,null as possible_values,'' as 'regexp',
0 as min_length, 
case 
 when customfieldtypekey = 'com.atlassian.jira.plugin.system.customfieldtypes:textfield'  
 then 255
 when customfieldtypekey = 'com.atlassian.jira.plugin.system.customfieldtypes:textarea'
 then 255
 else '0' 
 end max_length
 ,'0' as is_required,'0' as is_for_all, 
'0' is_filter, '1' as searchable, 
'' as default_value, '1' as editable, 
'1' as visible,'0' multiple
from jira.customfield;



    /*CREATE PROCEDURE cursor_example()   
    READS SQL DATA   
    */
BEGIN   
    DECLARE l_employee_id INT;   
    DECLARE l_salary NUMERIC(8,2);   
    DECLARE l_department_id INT;   
    DECLARE done INT DEFAULT 0;   
    DECLARE cur1 CURSOR FOR SELECT employee_id, salary, department_id FROM employees;   
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;   
    OPEN cur1;   
    emp_loop: LOOP   
    FETCH cur1 INTO l_employee_id, l_salary, l_department_id;   
    IF done=1 THEN   
    LEAVE emp_loop;   
    END IF;   
    END LOOP emp_loop;   
    CLOSE cur1;   
END 
