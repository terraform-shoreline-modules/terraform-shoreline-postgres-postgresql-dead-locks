
### About Shoreline
The Shoreline platform provides real-time monitoring, alerting, and incident automation for cloud operations. Use Shoreline to detect, debug, and automate repairs across your entire fleet in seconds with just a few lines of code.

Shoreline Agents are efficient and non-intrusive processes running in the background of all your monitored hosts. Agents act as the secure link between Shoreline and your environment's Resources, providing real-time monitoring and metric collection across your fleet. Agents can execute actions on your behalf -- everything from simple Linux commands to full remediation playbooks -- running simultaneously across all the targeted Resources.

Since Agents are distributed throughout your fleet and monitor your Resources in real time, when an issue occurs Shoreline automatically alerts your team before your operators notice something is wrong. Plus, when you're ready for it, Shoreline can automatically resolve these issues using Alarms, Actions, Bots, and other Shoreline tools that you configure. These objects work in tandem to monitor your fleet and dispatch the appropriate response if something goes wrong -- you can even receive notifications via the fully-customizable Slack integration.

Shoreline Notebooks let you convert your static runbooks into interactive, annotated, sharable web-based documents. Through a combination of Markdown-based notes and Shoreline's expressive Op language, you have one-click access to real-time, per-second debug data and powerful, fleetwide repair commands.

### What are Shoreline Op Packs?
Shoreline Op Packs are open-source collections of Terraform configurations and supporting scripts that use the Shoreline Terraform Provider and the Shoreline Platform to create turnkey incident automations for common operational issues. Each Op Pack comes with smart defaults and works out of the box with minimal setup, while also providing you and your team with the flexibility to customize, automate, codify, and commit your own Op Pack configurations.

# Postgresql Deadlocks Incident
---

This incident type refers to the occurrence of deadlocks in a PostgreSQL database. A deadlock happens when two or more transactions are waiting for each other to release locks on resources, resulting in a situation where none of the transactions can proceed. This can cause significant disruption to the database and the applications that rely on it, as it prevents any further progress until the deadlock is resolved.

### Parameters
```shell
# Environment Variables

export HOSTNAME="PLACEHOLDER"

export USERNAME="PLACEHOLDER"

export DATABASE_PASSWORD="PLACEHOLDER"

export NEW_MAX_CONNECTIONS="PLACEHOLDER"

export DATABASE_NAME="PLACEHOLDER"

export DATABASE_USER="PLACEHOLDER"
```

## Debug

### Connect to the Postgresql instance
```shell
sudo -u postgres psql -h ${HOSTNAME} -d ${DATABASE_NAME} -U ${USERNAME}
```

### Show details of current locks
```shell
SELECT blocked_locks.pid AS blocked_pid, blocked_activity.usename AS blocked_user, blocking_locks.pid AS blocking_pid, blocking_activity.usename AS blocking_user, blocked_activity.query AS blocked_statement, blocking_activity.query AS blocking_statement FROM pg_catalog.pg_locks blocked_locks JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid JOIN pg_catalog.pg_locks blocking_locks ON blocking_locks.locktype = blocked_locks.locktype AND blocking_locks.DATABASE IS NOT DISTINCT FROM blocked_locks.DATABASE AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid AND blocking_locks.pid != blocked_locks.pid JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid WHERE NOT blocked_locks.GRANTED;
```

### Show queries currently running on the instance
```shell
SELECT pid,query,state FROM pg_stat_activit WHERE state = 'active';

```

### Show details of current transactions
```shell
SELECT * FROM pg_stat_activity WHERE backend_xid IN (SELECT transactionid FROM pg_locks WHERE locktype = 'transactionid');
```

### Dump the Postgresql logs
```shell
tail -n 100 /var/log/postgresql/postgresql-main.log
```

## Repair

### Stop the Postgresql service
```shell
sudo systemctl stop postgresql
```

### Wait for the service to stop
```shell
while sudo systemctl is-active --quiet postgresql; do sleep 1; done
```

### Start the Postgresql service
```shell
sudo systemctl start postgresql
```

### Wait for the service to start
```shell
while ! sudo systemctl is-active --quiet postgresql; do sleep 1; done
```

### Next Step
```shell
echo "Database server restarted successfully."
```

### Increase the number of connections allowed to the database to reduce contention.
```shell
bash

#!/bin/bash

# Set variables

DATABASE_USER=${DATABASE_USER}

DATABASE_NAME=${DATABASE_NAME}

DATABASE_PASSWORD=${DATABASE_PASSWORD}

NEW_MAX_CONNECTIONS=${NEW_MAX_CONNECTIONS}

# Increase the max connections

psql -U $DATABASE_USER -d $DATABASE_NAME -c "ALTER SYSTEM SET max_connections = $NEW_MAX_CONNECTIONS;"

psql -U $DATABASE_USER -d $DATABASE_NAME -c "SELECT pg_reload_conf();"


```
### Identify the deadlocked queries and kill.
```shell
#Identify the deadlocked queries

SELECT pid,query,state,locktype,mode,granted FROM pg_locks JOIN pg_stat_activity ON pg_locks.pid=pg_stat_activity.pid WHERE  pg_stat_activity.wait_event_type = 'deadlock';

#Terminate the query with the specified 

SELECT pg_terminate_backend(<pid>);

```