# GeneticRiskIndex

This repository contains reproducible infrastructure and application scripts for
calculating extinction risk index based on spatial separation of species,
dispersal capacity, and landscape resistance processed with
[Circuitscape.jl](https://github.com/Circuitscape/Circuitscape.jl). It is
written primarily for species in Victoria, Australia using the ALA occurrence
datasets.

Terraform is used to build the required Amazon Web Services (AWS) Batch
infrastructure to process hundreds/thousands of species. AWS containers are
provisioned with R and Julia using
[Docker](https://www.docker.com/resources/what-container).


# Installation

Software needed to run these scripts locally:
- [terraform](https://www.terraform.io/)
- [docker](https://docs.docker.com/get-docker/)
- [aws cli](https://aws.amazon.com/cli/)

On linux and mac these can be installed with most package managers (e.g. brew,
apt, pacman) and run from the command line. It is recommended these scripts are
run from linux, either in a local machine, a virtual machine or on a server.

Once terraform and aws-cli are installed, clone or download this repository to
get started.

# Use

## Overview

The process is broken into a number of steps:

1. Set up all AWS infrastructure for the project.

2. Run prefiltering, circuitscape and postprocessing iteratively until all tasks
are working and outputs make sense.

3. Back up all data to an S3 bucket. This can also happen during step 2.

4. Destroy all AWS infrastructure, besides the S3 bucket.


## Set AWS credentials

`aws cli` handles storing your aws credentials in your system.
Terraform will use these to create instances in your account, and we 
will use `aws cli` from the command line.

Run:

```
aws configure
```

and follow the prompt.


## Set up infrastructure

To simulate setting up infrastructure, from the command line run:

```
cd terraform/setup
terraform plan
```

To actually run them, run:

```
terraform apply
```

And answer 'yes'. This should build all the required infrastructure.



## Prefiltering

We first need to upload the required `habitat.tif` and `fire_severity.tif` layers:

```
aws s3 cp sbv.tif s3://genetic-risk-index-bucket/habitat.tif
aws s3 cp fire_severity.tif s3://genetic-risk-index-bucket/fire_severity.tif
```

These only need to be uploaded once, unless you need to change them. Then we
can upload the csv containing the taxa we want to process in this batch:

```
aws s3 cp batch_taxa.csv s3://genetic-risk-index-bucket/batch_taxa.csv
```

This will likely be repeatedly uploaded to run lists of taxa, as it is unlikely
the whole list will run successfully immediately.

Then, trigger the R prefilter job. We can get the ids of our jobs and job queue from
terraform, so we don't have to track any of that manually:

```
aws submit-job --job-name prefilter --job-queue '$(terraform output queue)` --job-definition $(terraform output prefilter)
```

The name can be anything you like. To back-up data from the run to the amazon s3 bucket:

```
aws datasync start-task-execution --task-arn '$(terraform output efs-data-backup-arn)`
```

We can check that it worked:

```
aws s3 ls s3://genetic-risk-index-bucket/data
```

Or visit the s3 console page in a web browser:

https://s3.console.aws.amazon.com/s3/buckets/genetic-risk-index-bucket

Then we can run the Circuitscape batch jobs returned by the prefilter task


## Run Circuitscape jobs

Get the job list:

```
aws s3 cp s3://genetic-risk-index-bucket/job_list.txt job_list.txt
```

The file will be a list of taxa to run in circuitscape, you can check it to see if it makes sense.

```
less job_list.txt
```

**⚠  WARNING aws-cli commands can start thousands of containers** 

Be careful to check the contents of your job_list.txt file are what you expect them to be.

You can also set the job list, as long as you only include taxa that have been
output by the R job previously:

```
aws s3 cp job_list.txt s3://genetic-risk-index-bucket/job_list.txt 
```

Now run the first taxon in the list only, or a list of length 1:

```
aws submit-job --job-name circuitscape --job-queue '$(terraform output queue)` --job-definition $(terraform output circuitscape)
```

For an array of taxa (must be 2 or more jobs, thats just how AWS Batch arrays work)

```
aws submit-job --array-properties size=$(wc -l job_list.txt) --job-name circuitscape --job-queue '$(terraform output queue)` --job-definition $(terraform output circuitscape)
```

Backup again:

```
aws datasync start-task-execution --task-arn '$(terraform output efs-data-backup-arn)`
```

## Run post-processing

```
aws submit-job --job-name postprocessing --job-queue '$(terraform output queue)` --job-definition $(terraform output postprocessing)
```

You can check the batch tasks in the console:
https://ap-southeast-2.console.aws.amazon.com/batch/v2/home

Make sure also to check the s3 bucket in the web interface to be sure the data
is available before you destroy any infrastructure.


## Destroy infastructure

To finally destroy all infrastructure, besides the pre-existing s3 bucket, run:

```
terraform destroy
```
