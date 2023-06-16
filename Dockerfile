FROM apache/airflow
# COPY requirements.txt requirements.txt
# # RUN pip install --user --upgrade pip
# RUN pip install --no-cache-dir --user -r requirements.txt
ENV AIRFLOW_HOME=/opt/airflow 

USER root
# RUN apt-get update && apt-get install -y git
RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    libpq-dev

WORKDIR /app
COPY requirements.txt /app/requirements.txt
USER airflow
# COPY requirements.txt requirements.txt
# RUN pip install --user --upgrade pip
# RUN pip cache purge
RUN pip install --no-cache-dir --user -r /app/requirements.txt
# USER airflow
# RUN pip install --no-cache-dir -user git+https://github.com/weatherapicom/python
# RUN pip install --no-cache-dir -user sqlalchemy
# RUN pip install --no-cache-dir -user psycopg2
EXPOSE 8090
