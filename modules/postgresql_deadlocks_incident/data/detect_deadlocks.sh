#Identify the deadlocked queries

SELECT pid,query,state,locktype,mode,granted FROM pg_locks JOIN pg_stat_activity ON pg_locks.pid=pg_stat_activity.pid WHERE  pg_stat_activity.wait_event_type = 'deadlock';

#Terminate the query with the specified 

SELECT pg_terminate_backend(<pid>);