
/*
step 3 

step 3 status to issue_statuses 
状态 转换成 问题状态 
*/

#delete from bitnami_redmine.issue_statuses;

insert into bitnami_redmine.issue_statuses
(name,is_closed,is_default,position)
select pname,0,0,sequence from jira.issuestatus
where pname not in (select name from bitnami_redmine.issue_statuses)
;