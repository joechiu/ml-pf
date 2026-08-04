FROM mcr.microsoft.com/azureml/promptflow/promptflow-runtime:latest

WORKDIR /var/azureml-app

RUN apt-get update
RUN apt-get install vim wget -y

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8080

ENV PROMPTFLOW_RUN_MODE=serving
ENV PORT=8080

