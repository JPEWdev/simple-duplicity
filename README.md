# simple-duplicity
Simple backup scripts for duplicity.

This script is designed to be a simple and easy to understand script 
for running duplicity backup commands. The script is primarily targeted
at allowing a user to schedule a cron job to backup their home directory,
rather than a whole system backup.

To use it, copy [simple-duplicity.conf.example](simple-duplicity.conf.exmaple)
to ~/.simple-duplicity.conf. The example has comments that describe what
options are available. If you want multiple backup configurations, you can
have multiple config files and specify which one you would like with the
--profile option.

SInce this script is designe to be pretty simple, it requires knowledge
of how duplicity works. There are probably better options if you are
unfamiliar with dupicity, or want more features.
