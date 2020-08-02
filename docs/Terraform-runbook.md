# Terraform

GCP services can be used to launch environment.

## Prepare S3 backend

- Go to the [terraform/storage](../terraform/storage) directory (`cd terraform/storage`)
- Copy `terraform.tfvars.example` to `terraform.tfvars`
  - You must set `project` variable to your project ID in GCP
  - You must set unique bucket name for `terraform_backend_bucket_name` variable
- Run terraform

        terraform init
        terraform apply

## Launch environment

To launch kubernetes cluster in GCP do the following:

- Go to the [terraform](../terraform) directory (`cd terraform`)
- Copy `backend.tf.example` to `backend.tf`
  - Edit [terraform/backend.tf](../terraform/backend.tf):
      set `terraform_backend_bucket_name` value to bucket parameter
- Copy `terraform.tfvars.example` to `terraform.tfvars`
  - You must set `project` variable to your project ID in GCP
- Run terraform

        terraform init
        terraform apply

## Stop environment

To delete kubernetes cluster in GCP do the following:

- Go to the [terraform](../terraform) directory (`cd terraform`)
- Run `terraform destroy`
