/*
	migration jira.priority,jira.resolution into redmine.enumerations
	migration jira.customfieldoption,jira.customfield;


select * from jira.customfieldoption;
select * from jira.customfield;
select * from jira.customfieldvalue;

select * from custom_fields;
select * from custom_fields_trackers;
*/

/*
custom_fields
*/

INSERT INTO bitnami_redmine.custom_fields
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
 ,'0' as is_required,'0' as is_for_all,  /*is_required and is_visible will be fixed later*/
'0' is_filter, '1' as searchable, 
'' as default_value, '1' as editable, 
'1' as visible,'0' multiple
from jira.customfield;

/*
fields_trackers
*/



/*
custom_fields's possible_values
*/
drop PROCEDURE bitnami_redmine.fieldoption;

CREATE PROCEDURE bitnami_redmine.fieldoption()
BEGIN   
    DECLARE p_cfname varchar(255) default '';   
        DECLARE p_customvalue varchar(255);  
    DECLARE done INT DEFAULT 0;
        DECLARE cnt INT DEFAULT 0;
        DECLARE p_possible_value varchar(255) DEFAULT '---';
        DECLARE P_TEMP varchar(255) default '' ;
    DECLARE cur1 CURSOR 
                FOR select fieldt.cfname,optiont.customvalue from jira.customfieldoption optiont,jira.customfield fieldt
                     where optiont.CUSTOMFIELD = fieldt.ID
                     order by optiont.CUSTOMFIELDCONFIG,optiont.sequence;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;   
    OPEN cur1;   
    loop1: LOOP   
    FETCH cur1 INTO p_cfname, p_customvalue;   

        #select P_TEMP,p_cfname,p_possible_value, p_customvalue;  
        if P_TEMP = '' then
            set P_TEMP = p_cfname;
            set p_possible_value =concat(p_possible_value,'\r\n- ',p_customvalue) ;
        else
        
            if P_TEMP != p_cfname then
                    #select '<>';
                
                    if  p_possible_value != '---' then      
                    select 'update',P_TEMP,p_possible_value;
                
                    update bitnami_redmine.custom_fields set possible_values=p_possible_value
                    where name = P_TEMP;
                    
                    set cnt = row_count();
                        if cnt <> 0 then
                            select cnt,'effected';
                        else
                            select 'alert:something wrong!';
                            LEAVE loop1;
                        end if;
                    #select 'reset';
                    set P_TEMP = p_cfname;
                    set p_possible_value =concat('---','\r\n- ',p_customvalue) ;
                
                    end if;
                set P_TEMP = p_cfname;
                
            
            else
                #select '==';
                set p_possible_value = concat(p_possible_value,'\r\n- ',p_customvalue) ;
                #select 'possible_value=',p_possible_value;
            
            end if;
        end if;
        
        IF done=1 THEN   
    LEAVE loop1;   
    END IF;   
    END LOOP loop1;   
    CLOSE cur1;   
END 
;

call fieldoption()


/*
custom_fields_trackers
*/

insert into bitnami_redmine.custom_fields_trackers 
(custom_field_id,tracker_id)
select fields.id,trackers.id from
(select distinct(id) from custom_fields 
 where custom_fields.id not in 
    (select distinct(custom_field_id) from custom_fields_trackers)) fields,
(select distinct(id) from trackers) trackers;



/* 
is_required.
in jira, you can set whether the field is(not) required among the different field config schemas.
but you can't do this in redmine.
So I will set the field to be required if it is once required in jira.
字段配置中决定是否是必填项


*/

#select * from bitnami_redmine.custom_fields
update bitnami_redmine.custom_fields set is_required = '1'
where name in (
select cfname from jira.customfield
where id in (
select distinct(substr(FIELDIDENTIFIER,instr(FIELDIDENTIFIER,'_')+1,length(FIELDIDENTIFIER)))
FROM jira.fieldlayoutitem 
where ISREQUIRED = 'true'
and FIELDIDENTIFIER like 'customfield%'
    )
)


/* 
is_for_all
用于所有项目 需要等项目导入后才修改
*/


select sc.name,sctab.NAME,fielditem.FIELDIDENTIFIER
from fieldscreen sc,fieldscreentab sctab,
fieldscreenlayoutitem fielditem 
where sctab.FIELDSCREEN = sc.id
and fielditem.FIELDSCREENTAB = sctab.ID
order by sc.NAME,sctab.SEQUENCE,fielditem.SEQUENCE;





