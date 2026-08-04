FROM mcr.microsoft.com/azureml/promptflow/promptflow-runtime:latest

WORKDIR /var/azureml-app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5001

ENV PROMPTFLOW_RUN_MODE=serving
ENV PORT=5001

