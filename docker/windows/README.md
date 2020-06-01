# Windows Agent Docker Image

This image is based on the [official documentation](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/docker?view=azure-devops#windows).

> Note: You can update the [Dockerfile](Dockerfile) to add any software that your require into the Azure DevOps agent, if you don't want to have to download the bits during all pipelines executions.

## Build it

```bash
docker built -t YOUR_IMAGE_NAME:YOUR_IMAGE_TAG .
```

## Push it

```bash
docker push YOUR_IMAGE_NAME:YOUR_IMAGE_TAG
```
