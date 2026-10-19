"""Simple test DAG: two Python tasks and one Bash task, no external connections."""
from airflow.providers.standard.operators.bash import BashOperator
from airflow.sdk import dag, task
from pendulum import datetime


@dag(
    start_date=datetime(2026, 10, 1),
    schedule=None,          # manual trigger only
    catchup=False,
    tags=["test"],
)
def hello_test_dag():
    @task
    def say_hello():
        print("Hello from Airflow!")
        return "hello"

    @task
    def print_result(msg: str):
        print(f"Previous task returned: {msg}")

    bash_date = BashOperator(task_id="bash_date", bash_command="date && echo done")

    print_result(say_hello()) >> bash_date


hello_test_dag()