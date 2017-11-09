## Objective

To compare the performances of major cloud services when used as backup storages for [Duplicacy](https://github.com/gilbertchen/duplicacy). 

## Disclaimer
As an independent developer, I am not affliated with any companies behind these cloud storage services.  Nor do I receive any financial support/incenstive from any of them for publishing this report or building Duplicacy.

## Storages

The table below lists the storages to be compared in this report and their costs.  The only storage supported by Duplicacy but not included in the comparison is Hubic.  That is because Hubic is considerably slower than others, mostly due to the fact that their https servers do not support connection reuse and there is too much overhead with each chunk transfer.


| Type         |   Storage (monthly)    |   Upload           |    Download    |    API Charge   |
|:------------:|:-------------:|:------------------:|:--------------:|:-----------:|
| S3           | $0.023/GB | free | $0.09/GB | [yes](https://aws.amazon.com/s3/pricing/) |
| Wasabi       | $3.99 first 1TB <br> $0.039/GB additional | free | $.04/GB | no |
| DigitalOcean Spaces| $5 first 250GB <br> $0.02/GB additional | free | first 1TB free <br> $0.01/GB additional| no |
| Backblaze B2 | $0.005/GB | free | $0.02 | [yes](https://www.backblaze.com/b2/b2-transactions-price.html) |
| Google Cloud Storage| $0.026/GB | free |$ 0.12/GB | [yes](https://cloud.google.com/storage/pricing) |
| Microsoft Azure | $0.0184/GB | free | free | [yes](https://azure.microsoft.com/en-us/pricing/details/storage/blobs/) |
| Google Drive | 15GB free <br> $1.99/100GB <br> $9.99/TB | free | free | no |
| Microsoft OneDrive | 5GB free <br> $1.99/50GB <br> $5.83/TB | free | free | no |
| Dropbox | 2GB free <br> $8.25/TB | free | free | no |

## Setup

All tests were performed on a Ubuntu 16.04.1 LTS virtual machine running on a dedicated ESXi server with an Intel Xeon D-1520 CPU (4 cores at 2.2 GHz) and 32G memory.  The server is located at the east coast, so the results may be biased against those services who have their servers on the west coast.

The 2 datasets in https://github.com/gilbertchen/benchmarking are used to test backup and restore speeds.  Note that this is not a simple file upload and download test.  Before uploading a chunk to the storage, Duplicacy always checks first if the chunk already exists on the storage, in order to take advantage of [cross-computer deduplication](https://github.com/gilbertchen/duplicacy/blob/master/DESIGN.md) if two computers have identical or similar files.  This existence check means one or more extra API call for each chunk to be uploaded. 

## Dataset 1: the Linux code base

The first dataset is the [Linux code base](https://github.com/torvalds/linux) with a total size of 1.76 GB and about 58K files, so it is a relatively small repository consisting of small files, but it represents a popular use case where a backup tool runs alongside a version control program such as git to frequently save changes made between checkins.

To test incremental backup, a random commit on July 2016 was selected, and the entire code base is rolled back to that commit. After the initial backup was finished, other commits were chosen such that they were about one month apart.  The code base is then moved forward to these commits one by one to emulate incremental changes.  Details can be found in linux-backup-cloud.sh.

Here are the elapsed real times (in seconds) as reported by the `time` command:

| Storage         | Initial Backup | 2nd | 3rd | 4th | 5th | 6th |
|:------------:|:-------------:|:-------------:|:-------------:|:-------------:|:-------------:|:-------------:|
| SFTP |  31.5  |  6.6  |  20.6  |  4.3  |  27.0  |  7.4  |
| S3 |  41.1  |  5.9  |  21.9  |  4.1  |  23.1  |  7.6  |  
| Wasabi |  38.7  |  5.7  |  31.7  |  3.9  |  21.5  |  6.8  | 
| DigitalOcean Spaces|  51.6  |  7.1  |  31.7  |  3.8  |  24.7  |  7.5  |  
| Backblaze B2 |  106.7  |  24.0  |  88.2  |  13.5  |  46.3  |  14.8  |  
| Google Cloud Storage |  76.9  |  11.9  |  33.1  |  6.7  |  32.1  |  12.7  | 
| Microsoft Azure |  35.0  |  5.4  |  20.4  |  3.9  |  22.1  |  6.1  | 
| Google Drive |  139.3  |  14.7  |  45.2  |  9.8  |  60.5  |  19.8  | 
| Microsoft OneDrive |  250.0  |  31.6  |  80.2  |  16.9  |  82.7  |  36.4  |
| Dropbox |  267.2  |  35.8  |  113.7  |  19.5  |  109.0  |  38.3  |  




## Dataset 2: a VirtualBox virtual machine

The second test was targeted at the other end of the spectrum - datasets with fewer but much larger files.  Virtual machine files typically fall into this category.  The particular dataset for this test is a VirtualBox virtual machine file.  The base disk image is 64 bit CentOS 7, downloaded from http://www.osboxes.org/centos/.  Its size is about 4 GB, still small compared to virtual machines that are actually being used everyday, but it is enough to quantify performance differences between these 4 backup tools.

The first backup was performed right after the virtual machine had been set up without installing new software.  The second backup was performed after installing common developer tools using the command `yum groupinstall 'Development Tools'`.  The third backup was performed after a power-on immediately followed by a power-off.



## Conclusion


