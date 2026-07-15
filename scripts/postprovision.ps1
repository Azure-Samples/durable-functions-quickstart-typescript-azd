$settings = @{
    IsEncrypted = $false
    Values = @{
        AzureWebJobsStorage = "UseDevelopmentStorage=true"
        FUNCTIONS_WORKER_RUNTIME = "node"
        DURABLE_TASK_SCHEDULER_CONNECTION_STRING = "Endpoint=$($env:DTS_ENDPOINT);Authentication=DefaultAzure"
        TASKHUB_NAME = $env:TASKHUB_NAME
    }
}
$settings | ConvertTo-Json -Depth 10 | Set-Content -Path "./src/local.settings.json"
