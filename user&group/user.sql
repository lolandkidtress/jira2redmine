/*covert jira's user　data into redmine
  1.defalult password is 12345678 

  2.convert firsname.lastname@mail.com into  firstname and lastname  
  
	
  step 1
  */
  

INSERT INTO bitnami_redmine.users
	(login, hashed_password, firstname, lastname, mail, 
	admin, status, language, 
	type, mail_notification, salt) 
SELECT user_name as login,'74b5bfa3f80cebada32d3268bd67c60c557f50a7' as hashed_password,
			substr(email_address,instr(email_address,'.')+1,instr(email_address,'@')-instr(email_address,'.')-1) as firstname
			,substr(email_address,1,instr(email_address,'.')-1) as lastname,email_address ,
			'0' as  admin,1 as status,'ja' as language,'User' as type,'all' as mail_notification,
			'8b2e8e5b36b958d0b03a2754bb8aed6d' as salt
FROM jira.cwd_user
where id not in ('10000','10002','10001') /*exclude jira-users,jira-developers,jira-administrators */


  /*user_preferences
  */

insert into bitnami_redmine.user_preferences
(user_id,others,hide_mail)
select id,
"---
:comments_sorting: asc
:warn_on_leaving_unsaved: '1'
:no_self_notified: false
:gantt_zoom: 2
:gantt_months: 6" 
,0
from bitnami_redmine.users
where bitnami_redmine.users.id not in 
(select user_id from bitnami_redmine.user_preferences)
and bitnami_redmine.users.status != 0 
