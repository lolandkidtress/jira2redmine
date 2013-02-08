/*covert jira's user　data into redmine
  1.defalult password is 12345678 
  2.convert firsname.lastname@mail.com into  firstname and lastname
  while either of them is null  
  
	
  step 1
  */
  

INSERT INTO bitnami_redmine.users
	(login, hashed_password, firstname, lastname, mail, 
	admin, status, language, 
	type, mail_notification, salt) 
SELECT user_name,'30a094f9885a231b550e85d2838efc1fe5c2de02',
			substr(email_address,instr(email_address,'.')+1,instr(email_address,'@')-instr(email_address,'.')-1)
			,substr(email_address,1,instr(email_address,'.')-1),email_address,
			'0',1,'ja','User','all','426eb179d3ecadafcbb995100ec2e379'
FROM jira.cwd_user
where id !='10000';

  /*fix user_preferences
  */

insert into bitnami_redmine.user_preferences
(user_id,others,hide_mail)
select id,
"---:comments_sorting: asc:warn_on_leaving_unsaved: '1':no_self_notified: false"
,0
from bitnami_redmine.users
where bitnami_redmine.users.id not in 
(select user_id from bitnami_redmine.user_preferences)
and bitnami_redmine.users.status != 0 


