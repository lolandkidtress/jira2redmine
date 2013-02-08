/*
  migration jira.issue type 
  into redmine.trackers

  step 2
*/

delete from bitnami_redmine.trackers;

insert into bitnami_redmine.trackers
( name,is_in_chlog,position,is_in_roadmap
)
select pname,0,sequence,11 from jira.issuetype;

