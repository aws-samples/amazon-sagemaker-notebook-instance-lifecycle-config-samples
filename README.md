## SageMaker Notebook Instance Lifecycle Config Samples

### Overview

A collection of sample scripts to customize [Amazon SageMaker Notebook Instances](https://docs.aws.amazon.com/sagemaker/latest/dg/nbi.html) using [Lifecycle Configurations](https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html)

Lifecycle Configurations provide a mechanism to customize Notebook Instances via shell scripts that are executed during the lifecycle of a Notebook Instance.

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
