## Objective

To compare the performances of major cloud services when used as backup storages for [Duplicacy](https://github.com/gilbertchen/duplicacy). 

## Disclaimer
As an independent developer, I am not affiliated with any companies behind these cloud storage services.  Nor do I receive any financial support/incentive from any of them for publishing this report or building Duplicacy.

## Storages

The table below lists the storages to be tested and compares their pricing.  The only storage supported by Duplicacy but not included in the comparison is Hubic.  That is because Hubic is considerably slower than others, likely caused by their https servers not allowing connections to be reused so there is too much overhead for re-establishing https connections with each file transfer.

| Type         |   Storage (monthly)    |   Upload           |    Download    |    API Charge   |
|:------------:|:-------------:|:------------------:|:--------------:|:-----------:|
| Amazon S3    | $0.023/GB | free | $0.09/GB | [yes](https://aws.amazon.com/s3/pricing/) |
| Wasabi       | $3.99 first 1TB <br> $0.0039/GB additional | free | $.04/GB | no |
| DigitalOcean Spaces| $5 first 250GB <br> $0.02/GB additional | free | first 1TB free <br> $0.01/GB additional| no |
| Backblaze B2 | $0.005/GB | free | $0.02/GB | [yes](https://www.backblaze.com/b2/b2-transactions-price.html) |
| Google Cloud Storage| $0.026/GB | free |$ 0.12/GB | [yes](https://cloud.google.com/storage/pricing) |
| Google Drive | 15GB free <br> $1.99/100GB <br> $9.99/TB | free | free | no |
| Microsoft Azure | $0.0184/GB | free | free | [yes](https://azure.microsoft.com/en-us/pricing/details/storage/blobs/) |
| Microsoft OneDrive | 5GB free <br> $1.99/50GB <br> $5.83/TB | free | free | no |
| Dropbox | 2GB free <br> $8.25/TB | free | free | no |

## Setup

All tests were performed on a Ubuntu 16.04.1 LTS virtual machine running on a dedicated ESXi server with an Intel Xeon D-1520 CPU (4 cores at 2.2 GHz) and 32G memory.  The server is located at the east coast, so the results may be biased against those services who have their servers on the west coast.  The network bandwidth is 200Mbps.

The same 2 datasets in https://github.com/gilbertchen/benchmarking are used to test backup and restore speeds.  It should be noted that this is not a simple file upload and download test.  Before uploading a chunk to the storage, Duplicacy always checks first if the chunk already exists on the storage, in order to take advantage of [cross-computer deduplication](https://github.com/gilbertchen/duplicacy/blob/master/DESIGN.md) if two computers happen to have identical or similar files.  This existence check means that at least one extra API call is needed for each chunk to be uploaded. 

A local SFTP storage is also included in the test to provide a base line for the comparisons.  The SFTP server runs on a different virtual machine on the same ESXi host.

All scripts to run the tests are available in this repo so you can run your own tests.

## Dataset 1: the Linux code base

The first dataset is the [Linux code base](https://github.com/torvalds/linux) with a total size of 1.76 GB and about 58K files, so it is a relatively small repository consisting of small files, but it represents a popular use case where a backup tool runs alongside a version control program such as git to frequently save changes made between checkins.

To test incremental backup, a random commit on July 2016 was selected, and the entire code base is rolled back to that commit. After the initial backup was finished, other commits were chosen such that they were about one month apart.  The code base is then moved forward to these commits one by one to emulate incremental changes.  Details can be found in linux-backup-cloud.sh.

Restore was tested the same way.  The first restore is a full restore of the first backup on an empty repository, and each subsequent restore is an incremental one that only patches files changed by each commit.

All running times of the backup and restore operations were measured by the `time` command as the real elapsed times:

![cloud_comparison_linux_1](https://github.com/gilbertchen/cloud-storage-comparison/blob/master/images/cloud_comparison_linux_1.png)

These results indicate that the performances of cloud storages vary a lot.  While S3-compatible ones (Amazon, Wasabi, and DigitalOcean) and Azure can back up and restore at speeds close to those of the local SFTP storage, others are much slower.  However, one of the advantages of cloud storages is that most of them support simultaneous connections, so we can keep increasing the number of threads until the local processing or the network becomes the bottleneck.

The following charts shows new results with 4 threads:

![cloud_comparison_linux_4](https://github.com/gilbertchen/cloud-storage-comparison/blob/master/images/cloud_comparison_linux_4.png)

Dropbox doesn't seem to support simultaneous writes, so it was missing from the table.  Moreover, Google Drive was the only cloud storage that didn't benefit from the use of multiple threads, possibly due to strict per-user rate limiting.  Amazon S3, Wasabi, DigitalOcean, and Azure all achieved comparable or even slightly superior performances than the SFTP storage. 

## Dataset 2: a VirtualBox virtual machine

The second test was targeted at the other end of the spectrum - datasets with fewer but much larger files.  Virtual machine files typically fall into this category.  The particular dataset for this test is a VirtualBox virtual machine file.  The base disk image is 64 bit CentOS 7, downloaded from http://www.osboxes.org/centos/.  Its size is about 4 GB, still small compared to virtual machines that are actually being used everyday, but it is enough to quantify performance differences.

The first backup was performed right after the virtual machine had been set up without installing new software.  The second backup was performed after installing common developer tools using the command `yum groupinstall 'Development Tools'`.  The third backup was performed after a power-on immediately followed by a power-off.  The first restore is a full restore of the first backup on an empty directory, while the second and third are incremental.

The following chart compares real times (in seconds) of the backup and restore operations:

![cloud_comparison_vm_1](https://github.com/gilbertchen/cloud-storage-comparison/blob/master/images/cloud_comparison_vm_1.png)

Similar performance improvements can be observed with 4 threads:

![cloud_comparison_vm_4](https://github.com/gilbertchen/cloud-storage-comparison/blob/master/images/cloud_comparison_vm_4.png)


## Conclusion

As far as I know, this is perhaps the first head-to-head performance comparisons of popular cloud backup storages.  Although results presented here are neither comprehensive nor conclusive, I do hope that they will at least provide some guidance for users of Duplicacy or other cloud backup tools when deciding which cloud service to choose.

These results also suggest that storages designed to be primarily accessed via an API are generally faster than storages that are offered as cloud drives, since the latter are perhaps more optimized for their own clients with the API access merely being an addon.

The more important message, however, is that cloud backup can be as fast as local backup, with only modest network bandwidth, especially if you can use multiple threads.  It may be worth a try to add cloud components to your backup strategies if you haven't already done so.
