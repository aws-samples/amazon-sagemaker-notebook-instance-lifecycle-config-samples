## SageMaker Notebook Instance Lifecycle Config Samples

A collection of sample scripts to customize Amazon SageMaker Notebook Instances using Lifecycle Configurations

### Development

Scripts can be developed directly on SageMaker Notebook Instances since that is the environment that they are run with. Lifecycle Configuration scripts run as `root`, the working directory is `/`.  To simulate the execution environment, you may use

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

* [Create](https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateNotebookInstanceLifecycleConfig.html) a Lifecycle Configuration with the script content
* [Create](https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateNotebookInstance.html) a Notebook Instance with the Lifecycle Configuration
* Validate that the Notebook Instance creates successfully.
* [Access](https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreatePresignedNotebookInstanceUrl.html) the Notebook Instance and perform any validation specific to the script.
* [Stop](https://docs.aws.amazon.com/sagemaker/latest/dg/API_StopNotebookInstance.html) and [Start](https://docs.aws.amazon.com/sagemaker/latest/dg/API_StartNotebookInstance.html) the Notebook Instance
* Validate that the Notebook Instance creates successfully.
* [Access](https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreatePresignedNotebookInstanceUrl.html) the Notebook Instance again and perform any validation specific to the script.

File a Pull Request following the instructions in the [Contribution Guidelines](CONTRIBUTING.md).

## License Summary

This sample code is made available under the MIT-0 license. See the LICENSE file.
