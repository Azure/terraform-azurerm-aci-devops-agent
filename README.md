# Run Azure Pipelines in Azure Container Instances

This repository contains a Terraform module that helps you to deploy [Azure DevOps self-hosted agents](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/agents?view=azure-devops&tabs=browser#install) running on Azure Container Instance.

You can choose to deploy Linux or Windows agents, provide custom Docker images for the agents to include the tools you really need. It also give you the option to deploy the agents into a private virtual network, if the agents needs to access internal resources.

[![Build Status](https://dev.azure.com/juliencorioland/Azure%20DevOps%20Agents%20ACI/_apis/build/status/terraform-azure-devops-agent-aci-e2e?branchName=master)](https://dev.azure.com/juliencorioland/Azure%20DevOps%20Agents%20ACI/_build/latest?definitionId=1&branchName=master)

## How-to

### Build the Docker images

This module requires that you build your own Linux and/or Windows Docker images, to run the Azure DevOps agents. The [docker](docker/README.md) contains Dockerfile and instructions for both. 

### Use the Terraform Module

For usage, please refer to the [examples](examples//README.md).

## Test

### Configurations

- [Configure Terraform for Azure](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/terraform-install-configure)

We provide 2 ways to build, run, and test the module on a local development machine.  [Native (Mac/Linux)](#native-maclinux) or [Docker](#docker).

### Native (Mac/Linux)

#### Prerequisites

- [Ruby **(~> 2.3)**](https://www.ruby-lang.org/en/downloads/)
- [Bundler **(~> 1.15)**](https://bundler.io/)
- [Terraform **(~> 0.11.7)**](https://www.terraform.io/downloads.html)
- [Golang **(~> 1.12.3)**](https://golang.org/dl/)

#### Environment setup

We provide simple script to quickly set up module development environment:

```sh
$ curl -sSL https://raw.githubusercontent.com/Azure/terramodtest/master/tool/env_setup.sh | sudo bash
```

#### Run test

Then simply run it in local shell:

```sh
$ bundle install
$ rake build
$ rake full
```

### Docker

We provide a Dockerfile to build a new image based `FROM` the `microsoft/terraform-test` Docker hub image which adds additional tools / packages specific for this module (see Custom Image section).  Alternatively use only the `microsoft/terraform-test` Docker hub image [by using these instructions](https://github.com/Azure/terraform-test).

#### Prerequisites

- [Docker](https://www.docker.com/community-edition#/download)

#### Custom Image

This builds the custom image:

```sh
$ docker build --build-arg BUILD_ARM_SUBSCRIPTION_ID=$ARM_SUBSCRIPTION_ID --build-arg BUILD_ARM_CLIENT_ID=$ARM_CLIENT_ID --build-arg BUILD_ARM_CLIENT_SECRET=$ARM_CLIENT_SECRET --build-arg BUILD_ARM_TENANT_ID=$ARM_TENANT_ID -t azure-devops-agent-aci-test .
```

This runs the build and unit tests:

```sh
$ docker run --rm \
    -e TF_VAR_azure_devops_org_name=$AZDO_ORG_NAME \
    -e TF_VAR_azure_devops_personal_access_token=$AZDO_PAT \
    -e TF_VAR_azure_devops_pool_name=$AZDO_POOL_NAME \
    azure-devops-agent-aci-test /bin/bash -c "bundle install && rake build"
```

This runs the end to end tests:

```sh
$ docker run --rm \
    -e TF_VAR_azure_devops_org_name=$AZDO_ORG_NAME \
    -e TF_VAR_azure_devops_personal_access_token=$AZDO_PAT \
    -e TF_VAR_azure_devops_pool_name=$AZDO_POOL_NAME \
    azure-devops-agent-aci-test /bin/bash -c "bundle install && rake e2e"
```

This runs the full tests:

```sh
$ docker run --rm \
    -e TF_VAR_azure_devops_org_name=$AZDO_ORG_NAME \
    -e TF_VAR_azure_devops_personal_access_token=$AZDO_PAT \
    -e TF_VAR_azure_devops_pool_name=$AZDO_POOL_NAME \
    azure-devops-agent-aci-test /bin/bash -c "bundle install && rake full"
```

With:

- `AZDO_ORG_NAME` being the name of the Azure DevOps organization
- `AZDO_PAT` being the personnal access token to connect to Azure DevOps
- `AZDO_POOL_NAME` being the name of the Azure DevOps agent pool

## Authors

Originally created by [Julien Corioland](http://github.com/jcorioland)

## License

[MIT](LICENSE)

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
