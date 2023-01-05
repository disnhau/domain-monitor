# setup
- subfinder
- in the first file, read carefully then update some information
    + dir_root
    + telegram information
- chmod +x domain-monitor.sh

# running
- help
> ./domain-monitor.sh -h for help

- add new domain to monitor
> ./domain-monitor.sh -d domain.com

- run check for new sub domains
> ./domain-monitor.sh -a cron

# crontab on linux system

- open crontab editor
> crontab -e

- add this line (monitor every hour)
> 0 * * * * /path/to/domain-monitor.sh -a cron
