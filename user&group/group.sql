/*
exclude exclude jira-users,jira-developers,jira-administrators
*/
insert into users
(lastname,admin,status,type)
select group_name,'0','1','Group' from jira.cwd_group
where id not in ('10000','10002','10001')


/*
map users to groups
exclude jira-users,jira-developers,jira-administrators
*/
insert into  groups_users
(group_id,user_id)
select groupid,userid from 
(select 
	(select redmine.id  from users redmine
		where redmine.type ='Group'
		and redmine.lastname = parent_name
		)as groupid,
	(select distinct(redmine.id) from users redmine
		where redmine.type ='User'
		and redmine.login = child_name 
		) as userid  
from jira.cwd_membership
where parent_id not in ('10000','10002','10001')

)result
where userid is not null
order by  groupid,userid