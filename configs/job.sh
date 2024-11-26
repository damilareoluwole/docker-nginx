#!/bin/bash

# Log the execution time
echo "[Laravel Scheduler] Task executed at $(date)" >> /var/www/html/storage/logs/laravel-scheduler.log

# Run the Laravel scheduler using absolute path
php /var/www/html/artisan schedule:run >> /var/www/html/storage/logs/laravel-scheduler.log 2>&1


