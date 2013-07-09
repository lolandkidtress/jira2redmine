/*
priorities into enumerations
*/

drop procedure bitnami_redmine.enumerations;

CREATE PROCEDURE bitnami_redmine.enumerations()
BEGIN   
    DECLARE p_pname varchar(255) default '';   
    DECLARE p_sequence INT DEFAULT 0;  
    DECLARE p_position_cnt INT DEFAULT 0;
		DECLARE done INT DEFAULT 0;
    DECLARE cnt INT DEFAULT 0;
    DECLARE p_possible_value varchar(255) DEFAULT '---';
    DECLARE P_TEMP varchar(255) default '' ;
    DECLARE cur1 CURSOR 
                FOR select sequence,pname 
								from jira.priority 
								where pname not in (
																		select name from bitnami_redmine.enumerations
																		where type='IssuePriority'
																		)
								order by sequence;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;  
		DECLARE exit handler for sqlexception
    begin
      rollback;
    end;
    
		start transaction;
		
		select count(*) into p_position_cnt 
		from bitnami_redmine.enumerations
		where type='IssuePriority';
		
		#select p_position_cnt;
		
    OPEN cur1;   
    loop1: LOOP   
    FETCH cur1 INTO p_sequence, p_pname;  
		
		IF done=1 THEN   
    LEAVE loop1;   
    END IF; 
				#select p_sequence,p_pname;
				
				insert into  bitnami_redmine.enumerations
				(name,position,is_default,type,active)
				values(p_pname,p_sequence+p_position_cnt,0,'IssuePriority',1);
				
				set cnt = row_count() + cnt;
		END LOOP loop1;
    CLOSE cur1;   
		select cnt,'effected';
		commit; 
END 
;

call bitnami_redmine.enumerations();
