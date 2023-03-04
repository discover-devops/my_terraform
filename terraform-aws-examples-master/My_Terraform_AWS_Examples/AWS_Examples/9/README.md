# Terraform Module 

It shows how to develop (not duplicating code) web server clusters in different environments using a module.

The environments are:

* Staging (stage)
* Production (prod)

This is the file layout:

```bash
global
    └── s3/
        ├── main.tf
        └── (etc)

modules
    └── services/
        └── webserver-cluster/
            ├── main.tf
            └── (etc)

stage
    ├── services/
    │   └── webserver-cluster/
    │       ├── main.tf
    │       └── (etc)
    └── data-stores/
        └── mysql/
            ├── main.tf
            └── (etc)

prod
    ├── services/
    │   └── webserver-cluster/
    │       ├── main.tf
    │       └── (etc)
    └── data-stores/
        └── mysql/
            ├── main.tf
            └── (etc)
```



## Using the code

* Configure your AWS access keys.

  **Important:** For security, it is strongly recommend that you use IAM users instead of the root account for AWS access.

  Setting your credentials for use by Terraform can be done in a number of ways, but here are the recommended approaches:

  * The default credentials file

    Set credentials in the AWS credentials profile file on your local system, located at:

    `~/.aws/credentials` on Linux, macOS, or Unix

    `C:\Users\USERNAME\.aws\credentials` on Windows

    This file should contain lines in the following format:

    ```bash
    [default]
    aws_access_key_id = <your_access_key_id>
    aws_secret_access_key = <your_secret_access_key>
    ```
    Substitute your own AWS credentials values for the values `<your_access_key_id>` and `<your_secret_access_key>`.

  * Environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`

    Set the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables.

    To set these variables on Linux, macOS, or Unix, use `export`:

    ```bash
    export AWS_ACCESS_KEY_ID=<your_access_key_id>
    export AWS_SECRET_ACCESS_KEY=<your_secret_access_key>
    ```

    To set these variables on Windows, use `set`:

    ```bash
    set AWS_ACCESS_KEY_ID=<your_access_key_id>
    set AWS_SECRET_ACCESS_KEY=<your_secret_access_key>
    ```

  
