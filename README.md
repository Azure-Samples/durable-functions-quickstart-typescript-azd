<!--
---
name: Durable Functions TypeScript Fan-Out/Fan-In quickstart (Azure Durable Task Scheduler)
description: A Durable Functions quickstart written in TypeScript demonstrating the fan-out/fan-in pattern, using the Azure Durable Task Scheduler (DTS) backend. It's deployed to Azure Functions Flex Consumption plan using the Azure Developer CLI (azd). The sample uses managed identity and optionally a virtual network for secure-by-default deployment.
page_type: sample
products:
- azure-functions
- azure
- entra-id
urlFragment: starter-durable-fan-out-fan-in-typescript
languages:
- typescript
- javascript
- bicep
- azdeveloper
---
-->

# Durable Functions Fan-Out/Fan-In quickstart - TypeScript (Durable Task Scheduler)

This template repository contains a Durable Functions sample demonstrating the fan-out/fan-in pattern in TypeScript (using the Azure Functions Node.js v4 programming model). The sample can be easily deployed to Azure using the Azure Developer CLI (`azd`). It uses managed identity for all service-to-service authentication and optionally a virtual network to make sure deployment is secure by default. You can opt out of a VNet being used in the sample by setting `VNET_ENABLED` to `false` in the parameters.

[Durable Functions](https://learn.microsoft.com/azure/azure-functions/durable/durable-functions-overview) is part of the Azure Functions offering. It helps orchestrate stateful logic that's long-running or multi-step by providing *durable execution*. An execution is durable when it can continue in another process or machine from the point of failure in the face of interruptions or infrastructure failures. Durable Functions handles automatic retries and state persistence as your orchestrations run to ensure durable execution.

## Backend: Azure Durable Task Scheduler (DTS)

State for this sample is managed by **[Azure Durable Task Scheduler (DTS)](https://learn.microsoft.com/azure/azure-functions/durable/durable-task-scheduler/durable-task-scheduler)**, a fully managed backend provider for Durable Functions. Compared with the classic Azure Storage backend, DTS delivers:

+ Higher and more predictable orchestration throughput
+ A dedicated dashboard for viewing and debugging orchestrations
+ A purpose-built data store — no Storage queues/tables required
+ Managed-identity-based auth from your Function App to the scheduler

> DTS is currently in **preview**. This sample uses the preview extension bundle (`Microsoft.Azure.Functions.ExtensionBundle.Preview`) and the `Microsoft.DurableTask/schedulers@2025-04-01-preview` resource provider.

## Prerequisites

+ [Node.js 20+](https://nodejs.org/)
+ [Azure Functions Core Tools v4](https://learn.microsoft.com/azure/azure-functions/functions-run-local)
+ [Azure Developer CLI (`azd`)](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd)
+ [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli?view=azure-cli-latest)
+ [Docker](https://www.docker.com/products/docker-desktop/) — required to run the local DTS emulator
+ To use Visual Studio Code to run and debug locally:
  + [Visual Studio Code](https://code.visualstudio.com/)
  + [Azure Functions extension](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azurefunctions)

## Initialize the local project

You can initialize a project from this `azd` template in one of these ways:

+ Use this `azd init` command from an empty local (root) folder:

    ```shell
    azd init --template durable-functions-quickstart-typescript-azd
    ```

    Supply an environment name, such as `dfquickstart` when prompted. In `azd`, the environment is used to maintain a unique deployment context for your app.

+ Clone the GitHub template repository locally using the `git clone` command:

    ```shell
    git clone https://github.com/Azure-Samples/durable-functions-quickstart-typescript-azd.git
    cd durable-functions-quickstart-typescript-azd
    ```

    You can also clone the repository from your own fork in GitHub.

## Run locally against the DTS emulator

DTS provides a Docker-based emulator so you can develop and test without provisioning Azure resources.

1. Start the DTS emulator (includes the dashboard on port 8082):

    ```shell
    docker run --name dts-emulator -d -p 8080:8080 -p 8082:8082 mcr.microsoft.com/dts/dts-emulator:latest
    ```

2. Create `src/local.settings.json` from the sample:

    ```shell
    cp src/local.settings.json.sample src/local.settings.json
    ```

    The sample file contains the emulator connection string and task hub:

    ```json
    {
      "IsEncrypted": false,
      "Values": {
        "AzureWebJobsStorage": "UseDevelopmentStorage=true",
        "FUNCTIONS_WORKER_RUNTIME": "node",
        "DURABLE_TASK_SCHEDULER_CONNECTION_STRING": "Endpoint=http://localhost:8080;Authentication=None",
        "TASKHUB_NAME": "default"
      }
    }
    ```

3. Install dependencies and start the function host:

    ```shell
    cd src
    npm install
    npm start
    ```

4. Trigger the orchestration:

    ```shell
    curl -i http://localhost:7071/api/orchestrators/fetchOrchestration
    ```

5. View the run in the emulator dashboard at <http://localhost:8082>.

## Deploy to Azure

1. Sign in and provision + deploy everything in one step:

    ```shell
    azd auth login
    azd up
    ```

2. Pick an environment name, subscription, and region. The allowed region list is defined in `infra/main.bicep` and defaults to `northcentralus`.

3. Once the deployment finishes, `azd` prints the HTTP trigger URL. You can also run:

    ```shell
    azd show
    ```

    to retrieve the function app name and the DTS endpoint.

4. Invoke the orchestration in Azure:

    ```shell
    curl -i https://<your-function-app>.azurewebsites.net/api/orchestrators/fetchOrchestration
    ```

### What `azd up` provisions

+ A user-assigned managed identity (UAMI) used by the Function App
+ An Azure Storage account (blob only — for deployment package and `AzureWebJobsStorage`)
+ An Azure Functions Flex Consumption plan + Function App (Node 20)
+ Log Analytics workspace + Application Insights
+ An **Azure Durable Task Scheduler** (`Microsoft.DurableTask/schedulers`) and a **task hub**
+ RBAC:
    + `Storage Blob Data Owner` on the storage account for the UAMI
    + `Monitoring Metrics Publisher` on Application Insights for the UAMI
    + `Durable Task Data Contributor` on the DTS scheduler for the UAMI (and for the deployer, so you can open the dashboard)

The Function App is configured with these DTS-specific app settings:

| Setting | Value |
|---|---|
| `DURABLE_TASK_SCHEDULER_CONNECTION_STRING` | `Endpoint=<dts-url>;Authentication=ManagedIdentity;ClientID=<uami-client-id>` |
| `TASKHUB_NAME` | The name of the provisioned task hub |

## Monitor orchestrations

DTS ships a portal-integrated dashboard for browsing orchestrations, inspecting history, and viewing status in near real-time.

+ **Local (emulator):** <http://localhost:8082>
+ **Azure (deployed):** open the DTS scheduler resource in the [Azure portal](https://portal.azure.com) and click **Dashboard**, or navigate directly to <https://dashboard.durabletask.io> and sign in to your task hub.

You can also query Application Insights for traces emitted by the `DurableTask.AzureManagedBackend` category, which is enabled in `src/host.json`.

## Clean up

```shell
azd down --purge
docker rm -f dts-emulator
```

## Project structure

```
.
├── azure.yaml                 # azd service descriptor (service: api -> ./src)
├── infra/
│   ├── main.bicep             # subscription-scope entry; provisions everything
│   ├── main.parameters.json
│   ├── abbreviations.json
│   └── app/
│       ├── api.bicep          # Flex Consumption function app + DTS app settings
│       ├── dts.bicep          # Microsoft.DurableTask/schedulers + taskHubs
│       ├── dts-Access.bicep   # Durable Task Data Contributor role assignments
│       ├── rbac.bicep         # storage + app-insights role assignments
│       ├── vnet.bicep
│       └── storage-PrivateEndpoint.bicep
└── src/
    ├── host.json              # storageProvider.type = azureManaged; preview bundle
    ├── local.settings.json.sample
    ├── package.json           # durable-functions ^3.1.0, @azure/functions ^4.7.0
    ├── tsconfig.json
    └── fetchOrchestration.ts  # HTTP trigger + orchestrator + activity
```

## Baseline

The commit immediately before this sample was migrated to DTS is preserved as the git tag `pre-dts-azure-storage` on the maintainer's fork, for historical reference.

## Resources

+ [Azure Durable Task Scheduler documentation](https://learn.microsoft.com/azure/azure-functions/durable/durable-task-scheduler/durable-task-scheduler)
+ [Durable Functions overview](https://learn.microsoft.com/azure/azure-functions/durable/durable-functions-overview)
+ [Azure Functions Flex Consumption plan](https://learn.microsoft.com/azure/azure-functions/flex-consumption-plan)
+ [Azure Developer CLI (`azd`)](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
