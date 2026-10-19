"""
## Redshift insert test

Connectivity test: Airflow -> Redshift Data API -> mdm-sbx-01 / northstar_lake_sbx.

1. `insert_test_row` -- inserts vendor_id 4 into staging.demo_vendor (skipped if it already exists,
   so re-runs don't duplicate it; Redshift doesn't enforce the primary key).
2. `read_back` -- selects the table so the new row shows in the task log / XCom.

Cleanup: `delete from staging.demo_vendor where vendor_id = 4`
"""

from airflow.providers.amazon.aws.operators.redshift_data import RedshiftDataOperator
from airflow.sdk import dag
from pendulum import datetime

REDSHIFT = {"workgroup_name": "mdm-sbx-01", "database": "northstar_lake_sbx", "aws_conn_id": "aws_default"}


@dag(
    start_date=datetime(2026, 10, 1),
    schedule=None,
    catchup=False,
    doc_md=__doc__,
    default_args={"owner": "triamark", "retries": 0},
    tags=["triamark", "test"],
)
def triamark_redshift_insert_test():
    insert_test_row = RedshiftDataOperator(
        task_id="insert_test_row",
        sql="""
            insert into staging.demo_vendor (vendor_id, vendor_name, city, is_active)
            select 4, 'Airflow Test Vendor', 'Airflow', true
            where not exists (select 1 from staging.demo_vendor where vendor_id = 4)
        """,
        **REDSHIFT,
    )

    read_back = RedshiftDataOperator(
        task_id="read_back",
        sql="select vendor_id, vendor_name, city, is_active from staging.demo_vendor order by vendor_id",
        return_sql_result=True,
        **REDSHIFT,
    )

    insert_test_row >> read_back


triamark_redshift_insert_test()
