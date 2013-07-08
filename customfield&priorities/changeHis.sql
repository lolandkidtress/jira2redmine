/*
field value's change history

select isu.SUMMARY,itm.groupid,itm.field,
grp.issueid,grp.author,grp.created,
itm.oldvalue,itm.oldstring,itm.newvalue,itm.newstring
from jira.changeitem itm left join jira.changegroup grp on itm.groupid = grp.ID ,
jira.jiraissue isu
where isu.ID=grp.issueid
order by issueid,groupid;


select jnl.journalized_id,jnl.user_id,jnl.notes,jnl.created_on,jnl.private_notes, 
jnldt.prop_key,jnldt.old_value,jnldt.value
from bitnami_redmine.journals jnl left join bitnami_redmine.journal_details jnldt 
on jnldt.journal_id=jnl.id
order by jnl.created_on;

*/
drop procedure bitnami_redmine.changeHis_mig;

CREATE PROCEDURE bitnami_redmine.changeHis_mig()
BEGIN   
    
    DECLARE p_isssubject varchar(255) default '';
    DECLARE p_notes varchar(255) default '';
    DECLARE p_journalized_id INT default 0;
    DECLARE p_journalized_type varchar(255) default '';
    DECLARE p_id INT default 0;
        
    DECLARE p_groupid INT;
    DECLARE p_journal_id INT;
    DECLARE p_user_id INT default 0 ;

    DECLARE p_field varchar(255) default '';
    DECLARE p_property varchar(255) default '';
    DECLARE p_prop_key varchar(255) default '';

    DECLARE p_author varchar(255);
    DECLARE p_created_on date;
    DECLARE p_oldvalue varchar(255);
    DECLARE p_newvalue varchar(255);
    DECLARE p_oldstring varchar(255);
    DECLARE p_newstring varchar(255);

    DECLARE done INT DEFAULT 0;
    DECLARE cnt INT DEFAULT 0;
    DECLARE rescnt INT DEFAULT 0;

    DECLARE P_TEMP varchar(255) default '' ;
    
    DECLARE detail CURSOR 
                FOR select itm.field,
                            concat(ifnull(itm.oldvalue,''),ifnull(itm.oldstring,'')) as oldvalue,
                            concat(ifnull(itm.newvalue,''),ifnull(itm.newstring,'')) as newvalue
                            from jira.changeitem itm left join jira.changegroup grp 
                            on itm.groupid = grp.ID
                            where grp.ID = p_groupid 
                            order by groupid,issueid; 
 
    DECLARE head CURSOR 
                FOR select distinct(itm.groupid) as groupid
                            from jira.changeitem itm left join jira.changegroup grp 
                            on itm.groupid = grp.ID 
                            where itm.groupid = 10000
                            order by groupid,issueid;

                                            
    DECLARE CONTINUE HANDLER FOR NOT FOUND  
        begin
            set done = 1;
            #select 'NOT FOUND';
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
        
        select count(*) into rescnt
                            from jira.changeitem itm left join jira.changegroup grp 
                            on itm.groupid = grp.ID 
                            where itm.groupid = 10000;
        
        select 'total ',rescnt,' to be migrated';

        begin start transaction;


OPEN head;
    head_loop:LOOP
    fetch head into p_groupid;
    
        select max(id) + 1 into p_id from bitnami_redmine.journals;
        
    select (
        select bitnami_redmine.issues.id from jira.jiraissue,bitnami_redmine.issues
        where summary = bitnami_redmine.issues.subject
        and jira.jiraissue.id = issueid) into p_journalized_id
    from jira.changegroup
    where id =p_groupid; 

    select 
    created into p_created_on
    from jira.changegroup
    where id =p_groupid;
        
    select 
    (select id from bitnami_redmine.users where login = author) into p_user_id
    from jira.changegroup
    where id =p_groupid;
        
            IF p_journalized_id = 0 
                then 
                select 'journalized_id not found in redmine';
                leave head_loop;
            end if;

    insert into bitnami_redmine.journals
        (id,journalized_id,journalized_type,user_id,created_on,private_notes)
        values
        (p_id,p_journalized_id,'Issue',p_user_id,p_created_on,'0' );
    
    #select 'insert into ',p_id,p_journal_id,p_journalized_id,p_journalized_type,p_user_id,p_created_on;

    blockdetail:begin

    DECLARE CONTINUE HANDLER FOR NOT FOUND  
        begin
           close detail;
           leave detail_loop;
        end;

    OPEN detail;   
        detail_loop: LOOP   
        FETCH detail INTO p_field,p_oldvalue,p_newvalue ;
/*
        select distinct(itm.field)
                            from jira.changeitem itm
                            where not exists 
                            (select 1 from bitnami_redmine.custom_fields where name = field)
                            order by FIELD;
*/
            if p_field not in custom_fields then
                set p_property = 'attr';
            

                if p_field = 'assignee' then
                    set p_prop_key = 'assigned_to_id';

                end if;

                if p_field = 'Attachment' then
                /*
                    bitnami_redmine.attachments;
                */
                    set p_property = 'attachment';

                    insert into bitnami_redmine.attachments

                    select id into p_prop_key from bitnami_redmine.attachments


                end if;

                if p_field = 'Comment' then
                /*
                    原jira的备注在转换时单独做成一个自定义字段

                */
                    set p_property = 'cf'；
                    select id into p_prop_key from bitnami_redmine.custom_fields
                    where name = 'jira remark'; 
                    
                end if;

                if p_field = 'Link' then
                    set p_prop_key = '';
                end if;

                if p_field = 'resolution' then
                    set p_prop_key = '';
                end if;

                if p_field = 'status' then
                    set p_prop_key = 'status_id';
                    select * from bitnami_redmine.issue_statuses;
                end if;

                if p_field = 'summary' then
                    set p_prop_key = '';
                end if;

        else 
            set p_property = 'cf';
            set p_prop_key = field_id

        end if;

        if p_prop_key is '' then 
                    select p_field,' convert error';
                    leave detail_loop; 
                end if;




            insert into bitnami_redmine.journal_details
                (journal_id,property,prop_key,old_value,value);
                values
                (p_id,p_property,p_prop_key,p_oldvalue,p_newvalue);
                
            set cnt = row_count() + cnt;

        END LOOP detail_loop;  
        CLOSE detail; 
        
    END blockdetail;

    #备注 select actionbody into p_notes from jira.jiraaction where issueid=p_issid;

IF done=1 THEN   
    LEAVE head_loop; 
    END IF;

END LOOP head_loop;   
        CLOSE head;
        
        if rescnt <> cnt then
            rollback;
            select '<>';
        else
            commit;  
            select cnt,'commit';
        end if;


END ;
END
;

call bitnami_redmine.changeHis_mig();

                