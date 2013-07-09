/*
select * from projects;
select * from projects_trackers; 
select * from enabled_modules; 模块
issue_categories 问题类别
*/


insert into bitnami_redmine.projects
(name,homepage,is_public,identifier,status,created_on)
select pname,url,'0',pkey,'1',sysdate() from jira.project
where pname not in (select name from bitnami_redmine.projects);


/*
no parent project in jira
simply set lft & rgt
*/


drop PROCEDURE bitnami_redmine.pj_lft_rgt;

CREATE PROCEDURE bitnami_redmine.pj_lft_rgt()
BEGIN   
    DECLARE p_id varchar(255) default '';   
    DECLARE p_lft INT DEFAULT 0;  
    DECLARE p_rgt INT DEFAULT 0;
	DECLARE	max_lft INT DEFAULT 0;  
	DECLARE max_rgt INT DEFAULT 0;
	DECLARE	min_lft INT DEFAULT 0;  
	DECLARE min_rgt INT DEFAULT 0;
		
	DECLARE done INT DEFAULT 0;
    DECLARE cnt INT DEFAULT 0;
	DECLARE rescnt INT DEFAULT 0;
		
    DECLARE cur1 CURSOR 
                FOR select id from bitnami_redmine.projects
										where (lft is null or rgt is null)
										order by id;
    DECLARE CONTINUE HANDLER FOR NOT FOUND 
    begin
			SET done=1; 
			#select max_lft,min_rgt,max_rgt,p_id;
    end; 
		
		DECLARE exit handler for sqlexception
    begin
      rollback;
			select 'sqlexception';
    end;
   
		start transaction;
		
		select count(*) into rescnt from bitnami_redmine.projects
										where (lft is null or rgt is null)
										order by id;
		
		select rescnt,'should be updated';		
		select count(*)*2 into max_rgt from bitnami_redmine.projects;
		select max(rgt) into min_rgt from bitnami_redmine.projects;
		
		
    OPEN cur1;   
    loop1: LOOP   
    FETCH cur1 INTO p_id;  
		
		IF done=1 THEN   
    LEAVE loop1;   
    END IF; 
				
				set max_lft=min_rgt+1;
				set min_rgt=min_rgt+2;
				select max_lft,min_rgt,max_rgt,p_id;
				
				
				update bitnami_redmine.projects 
				set lft=max_lft,rgt=min_rgt
				where id=p_id;
				
				set cnt = row_count() + cnt;
				
		END LOOP loop1;
    CLOSE cur1; 
		
		if max_rgt <> min_rgt || rescnt <> cnt 
		then 
		select 'error : max_rgt <> min_rgt OR rescnt <> cnt';
		rollback;
		else
		select cnt,'effected';
		#select 'finished';
		commit;
		end if;
END 
;

call bitnami_redmine.pj_lft_rgt();

/*
projects_trackers; 
*/

insert into bitnami_redmine.projects_trackers
select pj.id,tracker.id from bitnami_redmine.trackers tracker,bitnami_redmine.projects pj
where pj.id not in (select project_id from bitnami_redmine.projects_trackers )
group by pj.id,tracker.id
order by pj.id,tracker.id;

/*
enabled_modules
*/

insert into bitnami_redmine.enabled_modules
(project_id,name)
select pj.id,module.name from bitnami_redmine.enabled_modules module,bitnami_redmine.projects pj
where pj.id not in (select distinct(project_id) from bitnami_redmine.enabled_modules)
group by pj.id,module.name
order by  pj.id,module.name;



/*
wikis
*/


insert into bitnami_redmine.wikis
(project_id,start_page,status)
select id,identifier,1 from bitnami_redmine.projects pj
where id not in (select project_id from bitnami_redmine.wikis);



/*
user & group
*/

select pid as pj_id,projectroleid,roletype,roletypeparameter 
from jira.projectroleactor;





/*
custom_filed
*/

