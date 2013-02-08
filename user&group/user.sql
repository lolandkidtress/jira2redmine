/*covert jira's user　data into redmine
  1.defalult password is 123456 
  2.convert firsname.lastname@mail.com into  firstname and lastname
  while either of them is null  
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

