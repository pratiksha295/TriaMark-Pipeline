"""Read-only test: Airflow -> Redshift Data API -> mdm-sbx-01 / northstar_lake_sbx."""
from airflow.providers.amazon.aws.operators.redshift_data import RedshiftDataOperator
from airflow.sdk import dag
from pendulum import datetime

REDSHIFT = {
    "workgroup_name": "mdm-sbx-01",       # Redshift Serverless workgroup
    "database": "northstar_lake_sbx",
    "aws_conn_id": "aws_default",
}


@dag(start_date=datetime(2026, 10, 1), schedule=None, catchup=False, tags=["test", "redshift"])
def redshift_data_api_test():
    whoami = RedshiftDataOperator(
        task_id="whoami",
        sql="select current_user, current_database(), getdate()",
        return_sql_result=True,
        **REDSHIFT,
    )

    list_staging_tables = RedshiftDataOperator(
        task_id="list_staging_tables",
        sql="select table_name from information_schema.tables where table_schema = 'staging' order by 1",
        return_sql_result=True,
        **REDSHIFT,
    )

    whoami >> list_staging_tables


redshift_data_api_test()