# using the official docker image
FROM apache/airflow
# setting the airflow home directory
ENV AIRFLOW_HOME=/opt/airflow 

#changing user to root for installation of linux packages on the container
USER root

# installing git(for pulling the weather API python SDK) 
# build-essential and libpq-dev is for pyscopg2 binary
RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    libpq-dev

# create a working directory
WORKDIR /app
# copy the requirements.txt file that contains the python package into the working directory
COPY requirements.txt /app/requirements.txt



COPY d2b_analytics_project /app/d2b_analytics_project

# ENV DBT_PROFILES_DIR /app/profiles 

ENV DBT_PROFILES_DIR /app
COPY profiles.yml /app/profiles.yml
# COPY profiles.yml /root/.dbt/profiles.yml


# change the user back to airflow, before installation with pip
USER airflow

RUN pip install --no-cache-dir --user -r /app/requirements.txt

# USER dbt 

# RUN dbt debug 

# RUN dbt deps

EXPOSE 8080
