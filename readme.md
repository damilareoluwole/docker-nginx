// Change ownership and grant permission
sudo setfacl -R -m u:$USER:rwx storage
sudo setfacl -R -m g:www-data:rwx storage
sudo setfacl -R -d -m u:$USER:rwx storage
sudo setfacl -R -d -m g:www-data:rwx storage

sudo chown www-data:www-data -r storage/logs

