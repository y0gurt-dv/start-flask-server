rm -r test_project
rm /etc/nginx/sites-available/test
rm /etc/nginx/sites-enabled/test


rm /etc/systemd/system/test_app.service
systemctl stop test_app
systemctl daemon-reload

systemctl restart nginx

