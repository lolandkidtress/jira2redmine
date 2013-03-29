drop PROCEDURE bitnami_redmine.issue_mig;

CREATE PROCEDURE bitnami_redmine.issue_mig()
BEGIN   
  DECLARE p_id int ;  
	DECLARE p_tracker_id int;
	DECLARE p_project_id int;
	DECLARE p_subject varchar(255) default '';
	DECLARE p_due_date date ;
	DECLARE p_status_id int;
	DECLARE p_assigned_to_id int;
	DECLARE p_priority_id int;
	DECLARE p_author_id int ;
	DECLARE p_lock_version int ;
	DECLARE p_created_on datetime ;
	DECLARE p_updated_on datetime ;
	DECLARE p_start_date date; 
	DECLARE p_done_ratio int;
	DECLARE p_estimated_hours float ;
	DECLARE p_parent_id int;
	DECLARE p_root_id int;
	DECLARE p_is_private boolean;
		
	DECLARE done INT DEFAULT 0;
    DECLARE cnt INT DEFAULT 0;
	DECLARE rescnt INT DEFAULT 0;
		
    DECLARE cur1 CURSOR 
                FOR select 
										(select re.id from jira.issuetype ji,bitnami_redmine.trackers re 
										where ji.pname=re.name and ji.id = jirai.issuetype) as issuetype ,
									  (select re.id 
										from bitnami_redmine.projects re,jira.jiraissue ji,jira.project pj  
										where ji.PROJECT=pj.ID
										and re.name=pj.pname
										and ji.PROJECT =jirai.PROJECT
										order by re.id limit 1
										) as PROJECT,
										jirai.SUMMARY,jirai.DUEDATE,	
										(select re.id  from jira.issuestatus ji,bitnami_redmine.issue_statuses  re 
										where ji.id = jirai.issuestatus
										and ji.pname=re.name) as issuestatus,
										(select id from bitnami_redmine.users re where re.login= jirai.ASSIGNEE) as ASSIGNEE,
										(select re.id from bitnami_redmine.enumerations re,jira.PRIORITY ji 
										where re.name = ji.pname and ji.id=jirai.PRIORITY ) as priority,
										(select re.id
										from bitnami_redmine.users re where re.login= jirai.REPORTER) as auth_id,
										0 as lock_version,jirai.created, jirai.UPDATED,null as start_date,0 as done_ratio,
										null as estimated_hours,'' as parent_id,'' as root_id,0 as is_private
										from jira.jiraissue jirai
										##where jirai.pkey like 'HHT-149'
										order by jirai.id;
										
    DECLARE CONTINUE HANDLER FOR NOT FOUND 
    begin
			SET done=1; 
    end; 
		
		DECLARE exit handler for sqlexception
    begin
      rollback;
			select 'sqlexception';
    end;
   
		start transaction;
		
		select count(*) into rescnt from jira.jiraissue;
		
		select rescnt,'should be updated';		
		
		/*select count(*)*2 into max_rgt from bitnami_redmine.projects;
		slect max(rgt) into min_rgt from bitnami_redmine.projects;
		*/
		
    OPEN cur1;   
    loop1: LOOP   
    FETCH cur1 INTO 
		p_tracker_id,
		p_project_id,
		p_subject,
		p_due_date,
		p_status_id,
		p_assigned_to_id,
		p_priority_id,
		p_author_id ,
		p_lock_version,
		p_created_on,
		p_updated_on ,
		p_start_date ,
		p_done_ratio ,
		p_estimated_hours ,
		p_parent_id ,
		p_root_id ,
		p_is_private;
		
		IF done=1 THEN   
    LEAVE loop1;   
    END IF; 
				
				/*p_parent_id,priority_id,author_id*/
				if p_author_id is null
				then set p_author_id =3; 
				end if;
				
				if p_priority_id is null
				then set p_priority_id = 1;
				end if;
				
				if p_parent_id = ''
				then set p_parent_id = null;
				end if;
				
				INSERT INTO bitnami_redmine.issues
				(tracker_id, project_id, subject, due_date, 
				status_id, assigned_to_id, priority_id, author_id,
				lock_version, created_on, updated_on, start_date, done_ratio, estimated_hours, 
				parent_id, root_id,is_private,lft,rgt) 
				VALUES (
				p_tracker_id,p_project_id,p_subject,p_due_date,
				p_status_id,p_assigned_to_id,p_priority_id,p_author_id,
				p_lock_version,p_created_on,p_updated_on ,
				p_start_date ,p_done_ratio ,p_estimated_hours ,
				p_parent_id ,p_root_id ,p_is_private,1,2);
				
				##update root_id
				select id into p_id from bitnami_redmine.issues
				where tracker_id = p_tracker_id 
					and project_id = p_project_id
					and subject = p_subject;
				
				
				update bitnami_redmine.issues		
				set root_id=p_id
				where tracker_id = p_tracker_id
					and project_id = p_project_id
					and subject = p_subject;
				
				set cnt = row_count() + cnt;
				
				
				
		END LOOP loop1;
    CLOSE cur1; 
		
		
		if rescnt <> cnt 
		then 
		select 'error : rescnt <> cnt';
		rollback;
		else
		select cnt,'effected';
		#select 'finished';
		commit;
		end if;
		
END 
;

call bitnami_redmine.issue_mig();