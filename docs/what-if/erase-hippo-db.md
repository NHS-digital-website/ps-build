

```
sudo -s
grep -E "(username|password)=" /home/hippo_authoring/tomcat/conf/context.xml

mysqldump -u ${hippo_user} -p${hippo_password} --no-data -h hippo-authoring.mysql.db.int hippocms \
  | grep "DROP TABLE" \
  | mysql -u ${hippo_user} -p${hippo_password} -h hippo-authoring.mysql.db.int hippocms

unset hippo_user
unset hippo_password
```
