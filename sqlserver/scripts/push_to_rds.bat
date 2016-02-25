@echo Please make sure the target RDS database has been truncated and its schema match with the source database...
@echo If not please CTRL-C here and prep the target database, then restart this script again.
@pause

@echo Delete any previously generated export/transfer script
@del export_and_transfer_to_rds.bat

@echo Generating a new export_and_transfer_to_rds.bat script
@sqlcmd -d Merlin -i generate_export_import_queries.sql -b -k1 | findstr "bcp echo" > export_and_transfer_to_rds.bat

@echo "Executing the new export_and_transfer_to_rds.bat script"
@call export_and_transfer_to_rds.bat
@IF ERRORLEVEL 1 goto ErrorLabel

@echo Delete any previously generated statistics update script
@del update_rds_statistics.sql

@echo Generating a new update_rds_statistics.sql script
@sqlcmd -d Merlin -i generate_update_statistics_queries.sql -b -k1 | findstr "update statistics" > update_rds_statistics.sql

@echo Updating statistics on target table
@sqlcmd -d Merlin -i update_rds_statistics.sql -b -k1 -S sau-merlin-1.ck24jacu2hmg.us-west-2.rds.amazonaws.com -U sau_merlin -P P4tF7KuQz4

@echo "Export from source database and transfer to target RDS database completed successfully."
@echo $(date)
@goto End

:ErrorLabel
@echo.
@echo #####
@echo ERROR(S) encountered executing the newly generated export_and_transfer_to_rds.bat script...
@echo #####
@pause
@goto End

:End
