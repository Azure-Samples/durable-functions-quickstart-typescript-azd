cat <<EOF > ./src/local.settings.json
{
    "IsEncrypted": false,
    "Values": {
        "AzureWebJobsStorage": "UseDevelopmentStorage=true",
        "FUNCTIONS_WORKER_RUNTIME": "node",
        "DURABLE_TASK_SCHEDULER_CONNECTION_STRING": "Endpoint=${DTS_ENDPOINT};Authentication=DefaultAzure",
        "TASKHUB_NAME": "${TASKHUB_NAME}"
    }
}
EOF
