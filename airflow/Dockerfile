FROM astrocrpublic.azurecr.io/runtime:3.3-9

# ---- Java 17 for PySpark (same major version as on Windows) ----
# The runtime's Debian only packages Java 21, so copy a Temurin 17 JRE in.
COPY --from=eclipse-temurin:17-jre /opt/java/openjdk /opt/java/openjdk
ENV JAVA_HOME=/opt/java/openjdk
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# ---- Separate Python 3.12 environment for the TriMark Spark code ----
# Airflow itself stays on Python 3.14; the Spark stages run with
# /opt/spark-venv/bin/python, pinned to the same versions as on Windows.
USER root
ENV UV_PYTHON_INSTALL_DIR=/opt/uv-python
RUN uv venv --python 3.12 /opt/spark-venv \
 && uv pip install --python /opt/spark-venv/bin/python \
      pyspark==4.2.0 py4j==0.10.9.9 pandas==3.0.3 pyarrow==24.0.0 \
      openpyxl==3.1.5 numpy==2.4.6 \
 && chmod -R a+rX /opt/uv-python /opt/spark-venv
USER astro

# Spark's Python workers (the mojibake UDF) must use the same 3.12 environment,
# not Airflow's Python 3.14.
ENV PYSPARK_PYTHON=/opt/spark-venv/bin/python
ENV PYSPARK_DRIVER_PYTHON=/opt/spark-venv/bin/python
