## Objective

To compare the performances of major cloud services when used as backup storages for [Duplicacy](https://github.com/gilbertchen/duplicacy). 

## Disclaimer
As an independent developer, I am not affliated with any companies behind these cloud storage services.  Nor do I receive any financial support/incenstive from any of them for publishing this report or building Duplicacy.

## Storages

The table below lists the storages to be tested and compares their pricings.  The only storage supported by Duplicacy but not included in the comparison is Hubic.  That is because Hubic is considerably slower than others, likely caused by their https servers not allowing connection reuse so there is too much overhead for re-estabilishing https connections with each file transfer.

| Type         |   Storage (monthly)    |   Upload           |    Download    |    API Charge   |
|:------------:|:-------------:|:------------------:|:--------------:|:-----------:|
| Amazon S3    | $0.023/GB | free | $0.09/GB | [yes](https://aws.amazon.com/s3/pricing/) |
| Wasabi       | $3.99 first 1TB <br> $0.039/GB additional | free | $.04/GB | no |
| DigitalOcean Spaces| $5 first 250GB <br> $0.02/GB additional | free | first 1TB free <br> $0.01/GB additional| no |
| Backblaze B2 | $0.005/GB | free | $0.02 | [yes](https://www.backblaze.com/b2/b2-transactions-price.html) |
| Google Cloud Storage| $0.026/GB | free |$ 0.12/GB | [yes](https://cloud.google.com/storage/pricing) |
| Google Drive | 15GB free <br> $1.99/100GB <br> $9.99/TB | free | free | no |
| Microsoft Azure | $0.0184/GB | free | free | [yes](https://azure.microsoft.com/en-us/pricing/details/storage/blobs/) |
| Microsoft OneDrive | 5GB free <br> $1.99/50GB <br> $5.83/TB | free | free | no |
| Dropbox | 2GB free <br> $8.25/TB | free | free | no |

## Setup

All tests were performed on a Ubuntu 16.04.1 LTS virtual machine running on a dedicated ESXi server with an Intel Xeon D-1520 CPU (4 cores at 2.2 GHz) and 32G memory.  The server is located at the east coast, so the results may be biased against those services who have their servers on the west coast.  The network bandwidth is 200Mbps.

The 2 datasets in https://github.com/gilbertchen/benchmarking are used to test backup and restore speeds.  It should be noted that this is not a simple file upload and download test.  Before uploading a chunk to the storage, Duplicacy always checks first if the chunk already exists on the storage, in order to take advantage of [cross-computer deduplication](https://github.com/gilbertchen/duplicacy/blob/master/DESIGN.md) if two computers have identical or similar files.  This existence check means that one extra API call is needed for each chunk to be uploaded. 

An SFTP storage is also included in the test to compare cloud storages with a local storage.  The SFTP server is a different virtual machine running on the same ESXi host.

## Dataset 1: the Linux code base

The first dataset is the [Linux code base](https://github.com/torvalds/linux) with a total size of 1.76 GB and about 58K files, so it is a relatively small repository consisting of small files, but it represents a popular use case where a backup tool runs alongside a version control program such as git to frequently save changes made between checkins.

To test incremental backup, a random commit on July 2016 was selected, and the entire code base is rolled back to that commit. After the initial backup was finished, other commits were chosen such that they were about one month apart.  The code base is then moved forward to these commits one by one to emulate incremental changes.  Details can be found in linux-backup-cloud.sh.

Restore was tested the same way.  The first store is a full restore of the first backup on an empty repository, and each subsequent restore is an increment one that only patches files changed by each commit.  The following table lists the elapsed real times (in seconds) of the restore operations:

Here are the elapsed real times (in seconds) of the backup and restore operations as reported by the `time` command:


| Storage              | initial backup | 2nd | 3rd | 4th | 5th | 6th | initial restore | 2nd | 3rd | 4th | 5th | 6th |
|:--------------------:|:------:|:----:|:-----:|:----:|:-----:|:----:|:-----:|:----:|:----:|:----:|:----:|:----:|
| SFTP                 |  31.5  | 6.6  | 20.6  | 4.3  | 27.0  | 7.4  | 22.5  | 7.8  | 18.4 | 3.6  | 18.7 | 8.7  | 
| Amazon S3            |  41.1  | 5.9  | 21.9  | 4.1  | 23.1  | 7.6  | 27.7  | 7.6  | 23.5 | 3.5  | 23.7 | 7.2  | 
| Wasabi               |  38.7  | 5.7  | 31.7  | 3.9  | 21.5  | 6.8  | 25.7  | 6.5  | 23.2 | 3.3  | 22.4 | 7.6  | 
| DigitalOcean Spaces  |  51.6  | 7.1  | 31.7  | 3.8  | 24.7  | 7.5  | 29.3  | 6.4  | 27.6 | 2.7  | 24.7 | 6.2  | 
| Backblaze B2         |  106.7 | 24.0 | 88.2  | 13.5 | 46.3  | 14.8 | 67.9  | 14.4 | 39.1 | 6.2  | 38.0 | 11.2 | 
| Google Cloud Storage |  76.9  | 11.9 | 33.1  | 6.7  | 32.1  | 12.7 | 39.5  | 9.9  | 26.2 | 4.8  | 25.5 | 10.4 | 
| Google Drive         |  139.3 | 14.7 | 45.2  | 9.8  | 60.5  | 19.8 | 129.4 | 17.8 | 54.4 | 8.4  | 67.3 | 17.4 | 
| Microsoft Azure      |  35.0  | 5.4  | 20.4  | 3.9  | 22.1  | 6.1  | 30.7  | 7.1  | 21.5 | 3.6  | 21.6 | 9.2  | 
| Microsoft OneDrive   |  250.0 | 31.6 | 80.2  | 16.9 | 82.7  | 36.4 | 333.4 | 26.2 | 82.0 | 12.9 | 71.1 | 24.4 |  
| Dropbox              |  267.2 | 35.8 | 113.7 | 19.5 | 109.0 | 38.3 | 164.0 | 31.6 | 80.3 | 14.3 | 73.4 | 22.9 | 

These results indicate that the performances of cloud storages vary a lot.  While S3-compatiable ones (Amazon, Wasabi, and DigitalOcean) and Azure can back up and restore at speeds close to those of the SFTP storage, others are much slower.  However, one of the advantage of cloud storages is that most of them support simultaneous connections, so we can keep increasing the number of threads until the local processing or the network becomes the bottleneck.

The following table shows new results with 4 threads:

| Storage              | initial backup | 2nd | 3rd | 4th | 5th | 6th | initial restore | 2nd | 3rd | 4th | 5th | 6th |
|:--------------------:|:------:|:----:|:----:|:----:|:----:|:----:|:----:|:----:|:----:|:----:|:----:|:----:|
| SFTP                 |  45.0  | 7.7  | 25.4 | 3.5  | 24.7 | 5.3  | 20.5 | 8.7  | 19.8 | 3.8  | 21.1 | 8.5  | 
| Amazon S3            |  30.2  | 5.4  | 17.6 | 4.1  | 21.3 | 6.8  | 17.1 | 7.7  | 17.3 | 3.6  | 19.5 | 6.7  | 
| Wasabi               |  30.7  | 5.4  | 18.3 | 3.8  | 19.5 | 7.4  | 16.8 | 7.1  | 17.3 | 3.5  | 16.4 | 6.2  | 
| DigitalOcean Spaces  |  30.9  | 6.7  | 18.1 | 3.6  | 20.9 | 6.9  | 15.9 | 6.6  | 17.9 | 2.6  | 15.7 | 6.0  | 
| Backblaze B2         |  44.1  | 11.9 | 30.0 | 9.8  | 31.5 | 15.3 | 52.6 | 12.4 | 30.0 | 8.3  | 32.6 | 11.5 | 
| Google Cloud Storage |  36.8  | 6.9  | 19.3 | 5.3  | 23.8 | 7.3  | 17.3 | 6.7  | 20.0 | 4.5  | 17.6 | 6.1  | 
| Google Drive         |  121.6 | 11.6 | 43.3 | 8.1  | 34.9 | 13.4 | 42.5 | 15.5 | 24.6 | 7.9  | 29.5 | 8.1  | 
| Microsoft Azure      |  31.1  | 5.0  | 21.2 | 4.0  | 21.0 | 6.2  | 22.2 | 6.6  | 19.3 | 4.0  | 17.3 | 6.2  | 
| Microsoft OneDrive   |  137.2 | 14.4 | 35.0 | 13.2 | 42.0 | 17.9 | 64.4 | 19.4 | 34.9 | 13.8 | 30.2 | 11.0 | 


Dropbox doesn't seem to support simultaneous writes, so it was missing from the table.  Moreover, Google Drive was the only cloud storage that did't benefit from multiple threads, possibly due to strict per-user rate limiting.  Amazon, Wasabi, DigitalOcean, Azure, Google Cloud Storage, and Azure all achieved comparable or even slightly superior performances than the SFTP storage. 

## Dataset 2: a VirtualBox virtual machine

The second test was targeted at the other end of the spectrum - datasets with fewer but much larger files.  Virtual machine files typically fall into this category.  The particular dataset for this test is a VirtualBox virtual machine file.  The base disk image is 64 bit CentOS 7, downloaded from http://www.osboxes.org/centos/.  Its size is about 4 GB, still small compared to virtual machines that are actually being used everyday, but it is enough to quantify performance differences between these 4 backup tools.

The first backup was performed right after the virtual machine had been set up without installing new software.  The second backup was performed after installing common developer tools using the command `yum groupinstall 'Development Tools'`.  The third backup was performed after a power-on immediately followed by a power-off.  The first restore is a full restore of the first backup on an empty directory, while the second and third are incremental.

The following table lists the elapsed real times (in seconds) of the backup and restore operations:

| Storage              | Initial backup | 2nd backup | 3rd backup | Initial restore | 2nd restore | 3rd restore |
|:--------------------:|:-------------:|:-------------:|:-------------:|:-------------:|:-------------:|:-------------:|
| SFTP                 |  143.5  |  89.6  |  65.5  |  129.6  |  119.8  |  80.5  |  
| Amazon S3            |  248.7  |  127.2 |  64.2  |  203.0  |  141.8  |  99.0  |  
| Wasabi               |  176.5  |  98.2  |  66.5  |  153.6  |  127.2  |  86.3  |  
| DigitalOcean Spaces  |  275.9  |  120.4 |  67.4  |  419.1  |  160.8  |  92.0  |  
| Backblaze B2         |  1510.0 |  740.3 |  138.9 |  767.7  |  295.2  |  113.6 |  
| Google Cloud Storage |  479.7  |  180.9 |  72.6  |  299.2  |  147.3  |  88.2  |  
| Google Drive         |  700.4  |  275.9 |  84.5  |  819.4  |  337.6  |  118.8 |  
| Microsoft Azure      |  188.9  |  96.7  |  64.6  |  202.4  |  171.1  |  103.4 |  
| Microsoft OneDrive   |  1267.2 |  449.3 |  104.7 |  895.5  |  564.9  |  147.6 |  
| Dropbox              |  1655.6 |  612.6 |  127.7 |  1034.5 |  386.3  |  135.6 |  

Similar performance improvements can be observed with 4 threads:

| Storage              | Initial backup | 2nd backup | 3rd backup | Initial restore | 2nd restore | 3rd restore |
|:--------------------:|:-------------:|:-------------:|:-------------:|:-------------:|:-------------:|:-------------:|
| SFTP                 |  143.5  |  96.5  |  69.3  |  136.3  |  121.5  |  87.5  |  
| Amazon S3            |  125.3  |  80.3  |  70.2  |  123.5  |  125.5  |  83.1  |  
| Wasabi               |  114.4  |  80.0  |  64.0  |  173.7  |  158.4  |  87.5  |  
| DigitalOcean Spaces  |  115.6  |  89.7  |  63.2  |  105.0  |  95.7   |  77.9  |  
| Backblaze B2         |  222.3  |  124.7 |  69.6  |  263.8  |  190.2  |  101.1 |  
| Google Cloud Storage |  149.6  |  87.6  |  62.3  |  95.5   |  109.0  |  85.2  |  
| Google Drive         |  292.9  |  120.9 |  80.3  |  422.4  |  232.4  |  118.4 |  
| Microsoft Azure      |  120.2  |  88.8  |  72.2  |  143.7  |  112.6  |  138.1 |  
| Microsoft OneDrive   |  483.7  |  152.9 |  80.5  |  394.7  |  237.3  |  128.7 |  

## Conclusion

As far as I know, this is perhaps the first head-to-head performance comparisons of popular cloud backup storages.  Although results presented here are neither comprehensive nor conclusive, I do hope that they will at least provide some assistance when users of Duplicacy or other cloud backup tools are deciding which cloud service to choose.

These results also suggest that storages designed to be mainly accessed via an API are generally faster than storages that are primarily provided in the form of cloud drives, since the latter are perhpaps more optimized for their own clients with the API access merely being an addon.

The more imporant message, however, is that cloud backup can be faster than local backup, with only modest network bandwidth, if you can use multiple threads.  So it may worth a try to add cloud components to your existing backup strategies.
