#
# Regular cron jobs for the midenok-setup package
#
0 4	* * *	root	[ -x /usr/bin/midenok-setup_maintenance ] && /usr/bin/midenok-setup_maintenance
