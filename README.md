## Objective

To compare the performances of major cloud services when used as backup storages for Duplicacy. 

## Disclaimer
As an independent developer, I am not affliated with any companies behind these cloud storage services.  Nor do I receive any financial support/incenstive in publishing this report or building Duplicacy.

## Storages

|              |   Storage     |   Upload           |    Download    |    API Charge   |
|:------------:|:-------------:|:------------------:|:--------------:|:-----------:|
| S3           | $0.023/GB | free | $0.09/GB | [yes](https://aws.amazon.com/s3/pricing/) |
| Wasabi       | $3.99 first 1TB <br> $0.039/GB additional | free | $.04/GB | no |
| DigitalOcean | $5 first 250GB <br> $0.02/GB additional | free | first 1TB free <br> $0.01/GB additional| no |
| Backblaze B2 | $0.005/GB | free | $0.02 | [yes](https://www.backblaze.com/b2/b2-transactions-price.html) |
| Google Cloud Storage| $0.026/GB | free |$ 0.12/GB | [yes](https://cloud.google.com/storage/pricing) |
| Microsoft Azure | $0.0184/GB | free | free | [yes](https://azure.microsoft.com/en-us/pricing/details/storage/blobs/) |
| Google Drive | 15GB free, $1.99/100GB, $9.99/TB | free | free | no |
| Microsoft OneDrive | 5GB free, $1.99/50GB, $5.83/TB | free | free | no |

## Setup

All tests were performed on a Ubuntu 16.04.1 LTS virtual machine running on a dedicated ESXi server with an Intel Xeon D-1520 CPU (4 cores at 2.2 GHz) and 32G memory.  The server is located at the east coast, so the results may be biased against those services who have their servers on the east coast.

The 2 datasets in https://github.com/gilbertchen/benchmarking are used to test backup and restore speeds.  Note that this is not a simple file upload and download test.  Before uploading a chunk to the storage, Duplicacy always checks first if the chunk already exists on the storage, in order to take advantage of [cross-computer deduplication](https://github.com/gilbertchen/duplicacy/blob/master/DESIGN.md) if two computers have identical or similar files.  This existence check means one or more extra API call for each chunk to be uploaded. 

## Dataset 1: the Linux code base

The first dataset is the [Linux code base](https://github.com/torvalds/linux) with a total size of 1.76 GB and about 58K files, so it is a relatively small repository consisting of small files, but it represents a popular use case where a backup tool runs alongside a version control program such as git to frequently save changes made between checkins.

To test incremental backup, a random commit on July 2016 was selected, and the entire code base is rolled back to that commit. After the initial backup was finished, other commits were chosen such that they were about one month apart.  The code base is then moved forward to these commits one by one to emulate incremental changes.  Details can be found in linux-backup-cloud.sh.

Here are the elapsed real times (in seconds) as reported by the `time` command:



## Dataset 2: a VirtualBox virtual machine

The second test was targeted at the other end of the spectrum - datasets with fewer but much larger files.  Virtual machine files typically fall into this category.  The particular dataset for this test is a VirtualBox virtual machine file.  The base disk image is 64 bit CentOS 7, downloaded from http://www.osboxes.org/centos/.  Its size is about 4 GB, still small compared to virtual machines that are actually being used everyday, but it is enough to quantify performance differences between these 4 backup tools.

The first backup was performed right after the virtual machine had been set up without installing new software.  The second backup was performed after installing common developer tools using the command `yum groupinstall 'Development Tools'`.  The third backup was performed after a power-on immediately followed by a power-off.



## Conclusion


