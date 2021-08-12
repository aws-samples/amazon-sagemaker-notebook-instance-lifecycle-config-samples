## SageMaker Notebook Instance Lifecycle Config Samples

### Overview

A collection of sample scripts to customize [Amazon SageMaker Notebook Instances](https://docs.aws.amazon.com/sagemaker/latest/dg/nbi.html) using [Lifecycle Configurations](https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html)

Lifecycle Configurations provide a mechanism to customize Notebook Instances via shell scripts that are executed during the lifecycle of a Notebook Instance.

#### Sample Scripts

* [add-pypi-repository](scripts/add-pypi-repository) - This script adds a private PyPi repository in addition to or instead of pypi.org.
* [auto-stop-idle](scripts/auto-stop-idle) - This script stops a SageMaker notebook once it's idle for more than 1 hour. (default time)
* [connect-emr-cluster](scripts/connect-emr-cluster) - This script connects an EMR cluster to the Notebook Instance using SparkMagic.
* [disable-uninstall-ssm-agent](scripts/disable-uninstall-ssm-agent) - This script disables and uninstalls the SSM Agent at startup.
* [execute-notebook-on-startup](scripts/execute-notebook-on-startup) - This script executes a Notebook file on the instance during startup.
* [export-to-pdf-enable](scripts/export-to-pdf-enable) - This script enables Jupyter to export a notebook directly to PDF.
* [install-conda-package-all-environments](scripts/install-conda-package-all-environments) - This script installs a single conda package in all SageMaker conda environments, apart from the JupyterSystemEnv which is a system environment reserved for Jupyter.
* [install-conda-package-single-environment](scripts/install-conda-package-single-environment) - This script installs a single conda package in a single SageMaker conda environment.
* [install-lab-extension](scripts/install-lab-extension) - This script installs a jupyterlab extension package in SageMaker Notebook Instance.
* [install-nb-extension](scripts/install-nb-extension) - This script installs a single jupyter notebook extension package in SageMaker Notebook Instance.
* [install-pip-package-all-environments](scripts/install-pip-package-all-environments) - This script installs a single pip package in all SageMaker conda environments, apart from the JupyterSystemEnv which is a system environment reserved for Jupyter.
* [install-pip-package-single-environment](scripts/install-pip-package-single-environment) - This script installs a single pip package in a single SageMaker conda environments.
* [install-r-package](scripts/install-r-package) - This script installs a single R package in SageMaker R environment.
* [install-server-extension](scripts/install-server-extension) - This script installs a single jupyter notebook server extension package in SageMaker Notebook Instance.
* [migrate-ebs-data-backup](scripts/migrate-ebs-data-backup) - This script backs up content in `/home/ec2-user/SageMaker/` to a S3 bucket specified in a tag on the notebook instance.
* [migrate-ebs-data-sync](scripts/migrate-ebs-data-sync) - This script downloads a snapshot created by [migrate-ebs-data-backup](scripts/migrate-ebs-data-backup) to `/home/ec2-user/SageMaker/` in a new notebook instance. You specify the snapshop using tags on the notebook instance.
* [mount-efs-file-system](scripts/mount-efs-file-system) - This script mounts an EFS file system to the Notebook Instance at the ~/SageMaker/efs directory based off the DNS name.
* [mount-fsx-lustre-file-system](scripts/mount-fsx-lustre-file-system) - This script mounts an FSx for Lustre file system to the Notebook Instance at the /fsx directory based off the DNS and Mount name parameters.
* [notebook-history-s3](scripts/notebook-history-s3) - This script persists the underlying sqlite database of commands and cells executed for S3.
* [persistent-conda-ebs](scripts/persistent-conda-ebs) - This script installs a custom, persistent installation of conda on the Notebook Instance's EBS volume, and ensures that these custom environments are available as kernels in Jupyter.
* [proxy-for-jupyter](scripts/proxy-for-jupyter) - This script configures proxy settings for your Jupyter notebooks and the SageMaker Notebook Instance.
* [publish-instance-metrics](scripts/publish-instance-metrics) - This script publishes the system-level metrics from the Notebook Instance to CloudWatch.
* [set-codecommit-cross-account-access](scripts/set-codecommit-cross-account-access) - This script sets cross-account CodeCommit access, so you can work on repositories hosted in another account.
* [set-env-variable](scripts/set-env-variable) - This script gets a value from the Notebook Instance's tags and sets it as an environment variable for all processes including Jupyter.
* [set-git-config](scripts/set-git-config) - This script sets the username and email address in Git config.

### Development

For contributors looking to develop scripts, they can be developed directly on SageMaker Notebook Instances since that is the environment that they are run with. Lifecycle Configuration scripts run as `root`, the working directory is `/`.  To simulate the execution environment, you may use

```bash
sudo su
export PATH=/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
cd /
```

Edit the script in a file such as `my-script-on-start.sh` and execute it as

```bash
sh my-script-on-start.sh
```

The directory structure followed is:

```
scripts/
    my-script-name/
        on-start.sh
        on-create.sh
```

### Testing

To test the script end-to-end:

Create a [Lifecycle Configuration](https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateNotebookInstanceLifecycleConfig.html) with the script content and
a [Notebook Instance](https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateNotebookInstance.html) with the Lifecycle Configuration

```bash
# If the scripts are in a directory "scripts/my-script-name/*"
SCRIPT_NAME=my-script-name
ROLE_ARN=my-role-arn

RESOURCE_NAME="$SCRIPT_NAME-$RANDOM"

# Add any script specific options such as subnet-id
aws sagemaker create-notebook-instance-lifecycle-config \
    --notebook-instance-lifecycle-config-name "$RESOURCE_NAME" \
    --on-start Content=$((cat scripts/$SCRIPT_NAME/on-start.sh || echo "")| base64) \
    --on-create Content=$((cat scripts/$SCRIPT_NAME/on-create.sh || echo "")| base64)

aws sagemaker create-notebook-instance \
    --notebook-instance-name "$RESOURCE_NAME" \
    --instance-type ml.t2.medium \
    --role-arn "$ROLE_ARN" \
    --lifecycle-config-name "$RESOURCE_NAME"

aws sagemaker wait \
    notebook-instance-in-service \
    --notebook-instance-name "$RESOURCE_NAME"
```

* [Access](https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreatePresignedNotebookInstanceUrl.html) the Notebook Instance and perform any validation specific to the script.

```bash
aws sagemaker create-presigned-notebook-instance-url \
    --notebook-instance-name "$RESOURCE_NAME"
```

* [Stop](https://docs.aws.amazon.com/sagemaker/latest/dg/API_StopNotebookInstance.html) and [Start](https://docs.aws.amazon.com/sagemaker/latest/dg/API_StartNotebookInstance.html) the Notebook Instance

```bash
aws sagemaker stop-notebook-instance \
    --notebook-instance-name "$RESOURCE_NAME"

aws sagemaker wait \
    notebook-instance-stopped \
    --notebook-instance-name "$RESOURCE_NAME"

aws sagemaker start-notebook-instance \
    --notebook-instance-name "$RESOURCE_NAME"

aws sagemaker wait \
    notebook-instance-in-service \
    --notebook-instance-name "$RESOURCE_NAME"
```

* [Access](https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreatePresignedNotebookInstanceUrl.html) the Notebook Instance again and perform any validation specific to the script.

```bash
aws sagemaker create-presigned-notebook-instance-url \
    --notebook-instance-name "$RESOURCE_NAME"
```

File a Pull Request following the instructions in the [Contribution Guidelines](CONTRIBUTING.md).

## License Summary

This sample code is made available under the MIT-0 license. See the LICENSE file.
