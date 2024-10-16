#!/bin/bash
echo "[ cronjob task ] executed at `date`" > /proc/1/fd/2
php artisan schedule:work
