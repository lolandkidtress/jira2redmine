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
 ,'0' as is_required,'0' as is_for_all,  /*is_required and visible will be fixed later*/
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
        DECLARE rescnt INT DEFAULT 0;
    DECLARE p_possible_value varchar(255) DEFAULT '---';
    DECLARE P_TEMP varchar(255) default '' ;
    DECLARE cur1 CURSOR 
                FOR select fieldt.cfname,optiont.customvalue from jira.customfieldoption optiont,jira.customfield fieldt
                     where optiont.CUSTOMFIELD = fieldt.ID
                     order by optiont.CUSTOMFIELDCONFIG,optiont.sequence;
    DECLARE CONTINUE HANDLER FOR NOT FOUND  
    /*
     Error :   1329: No data - zero rows fetched, selected, or processed  
     #http://bugs.mysql.com/bug.php?id=42834      
    */
        begin
            set done = 1;
            #select 'NOT FOUND';
            update bitnami_redmine.custom_fields set possible_values=p_possible_value
      where name = P_TEMP;
                            set cnt = row_count() + cnt;
                        if cnt <> 0 then
                            select cnt,'effected';
                        else
                            select 'alert:something wrong!';
                        end if;
        end; 
    declare exit handler for sqlexception
        
    begin
        #LEAVE loop1;
      select 'sqlexception ERROR';
      rollback;
    end;  
        
        select count(*) into rescnt from (
        select optiont.CUSTOMFIELD from jira.customfieldoption optiont
        group by optiont.CUSTOMFIELD) res;
        
        select 'total',rescnt;
        
    start transaction;

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
                    
                    set cnt = row_count() + cnt;
                        if row_count() <> 0 then
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

                select 'last update',P_TEMP,p_possible_value;
        
                if rescnt <> cnt then
            rollback;
                        select '<>';
        else
            commit;  
            select cnt,'commit';
        end if;
                
END 
;

call bitnami_redmine.fieldoption();



/*
custom_fields_trackers
*/
insert into bitnami_redmine.custom_fields_trackers 
(custom_field_id,tracker_id)
select fields.id,trackers.id from
(select distinct(id) from bitnami_redmine.custom_fields 
 where custom_fields.id not in 
    (select distinct(custom_field_id) from bitnami_redmine.custom_fields_trackers)) fields,
(select distinct(id) from bitnami_redmine.trackers) trackers;


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
是否 用于所有项目



select sc.name,sctab.NAME,fielditem.FIELDIDENTIFIER
from fieldscreen sc,fieldscreentab sctab,
fieldscreenlayoutitem fielditem 
where sctab.FIELDSCREEN = sc.id
and fielditem.FIELDSCREENTAB = sctab.ID
order by sc.NAME,sctab.SEQUENCE,fielditem.SEQUENCE;
*/

/*
custom_field_value

select fld.id,fld.cfname,
fldv.issue,
(select iss.summary from jira.jiraissue iss where iss.ID = fldv.ISSUE) as issuesubject,
fldv.CUSTOMFIELD,
concat(ifnull(fldv.STRINGVALUE,''),ifnull(fldv.NUMBERVALUE,''),ifnull(fldv.TEXTVALUE,''),ifnull(fldv.DATEVALUE,''))
from jira.customfieldvalue fldv, jira.customfield fld
where fld.id = fldv.CUSTOMFIELD;

用于所有项目 需要等项目和自定义字段导入后才修改
*/

drop PROCEDURE bitnami_redmine.custfidval_mig;

CREATE PROCEDURE bitnami_redmine.custfidval_mig()
BEGIN   
    DECLARE p_cfname varchar(255) default ''; 
    DECLARE p_isssubject varchar(255) default '';
    DECLARE p_customvalue varchar(255); 
        
    DECLARE p_fldid varchar(255);
    DECLARE p_issid varchar(255);
        
    DECLARE done INT DEFAULT 0;
    DECLARE cnt INT DEFAULT 0;
    DECLARE rescnt INT DEFAULT 0;
    DECLARE p_possible_value varchar(255) DEFAULT '---';
    DECLARE P_TEMP varchar(255) default '' ;
        
    DECLARE cur1 CURSOR 
                FOR select fld.cfname,
                                        (select iss.summary from jira.jiraissue iss where iss.ID = fldv.ISSUE) as issuesubject,
                                        concat(ifnull(fldv.STRINGVALUE,''),ifnull(fldv.NUMBERVALUE,''),ifnull(fldv.TEXTVALUE,''),ifnull(fldv.DATEVALUE,'')) as value
                                        from jira.customfieldvalue fldv, jira.customfield fld
                                        where fld.id = fldv.CUSTOMFIELD
                                        order by issuesubject,cfname;

                                            
    DECLARE CONTINUE HANDLER FOR NOT FOUND  

        begin
            set done = 1;
            select 'NEXT NOT FOUND';
                        set cnt = row_count() + cnt;
                        if cnt <> 0 then
                            select cnt,'effected';
                                                        #LEAVE loop1;
                        else
                            select 'NOT FOUND:cnt =0!';
                        end if;
        end; 
                
                
    declare exit handler for sqlexception
        
    begin
        #LEAVE loop1;
      select 'sqlexception ERROR';
      rollback;
    end;  
        
        select count(*) into rescnt from  jira.customfieldvalue ;
        
        select 'total',rescnt;
                
    start transaction;

    OPEN cur1;   
    REPEAT 
    FETCH cur1 INTO p_cfname,p_isssubject ,p_customvalue;   
    /*
        IF done=1 THEN   
    #LEAVE loop1;   
    END REPEAT;
        END IF;
     */           
                select id into p_fldid from bitnami_redmine.custom_fields
                where name = p_cfname;
                
                select id into p_issid from bitnami_redmine.issues
                where subject = p_isssubject;
            
                insert into bitnami_redmine.custom_values
                (customized_type,customized_id,custom_field_id,value)
                values
                ('Issue',p_issid,p_fldid,p_customvalue);
                                
                                set cnt = row_count() + cnt;
                                
                select p_issid,p_fldid,p_customvalue,'value';
                                
                if row_count() = 0 then
                                                        select cnt,'effected';
                            select 'row_count=0 error';
                            #LEAVE loop1;
                                                        set done = 1;
                end if;
        
    #END LOOP loop1;   
    UNTIL DONE END REPEAT;
        CLOSE cur1;
        select rescnt,cnt ;
        if rescnt <> cnt then
            rollback;
            select '<>';
        else
            commit;  
            select cnt,'commit';
        end if;
                
END ;

call bitnami_redmine.custfidval_mig();



/*
field refer to project
*/

insert into bitnami_redmine.custom_fields_projects
select a.id,b.id from bitnami_redmine.custom_fields a,bitnami_redmine.projects b



