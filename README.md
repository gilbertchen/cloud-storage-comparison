## Objective

To benchmark the performances of major cloud services when used as backup storages for Duplicacy. 

## Disclaimer
As an independent developer, I am not affliated with any companies behind these cloud storage services.  Nor do I receive any financial support/incenstive in publishing this report or building Duplicacy.

## Setup

All tests were performed on a virtual machine running on a dedicated ESXi server located at 

## Dataset 1: the Linux code base

The first dataset is the [Linux code base](https://github.com/torvalds/linux) mostly because it is the largest github repository that we could find and it has frequent commits (good for testing incremental backups).  Its size is 1.76 GB with about 58K files, so it is a relatively small repository consisting of small files, but it represents a popular use case where a backup tool runs alongside a version control program such as git to frequently save changes made between checkins.

To test incremental backup, a random commit on July 2016 was selected, and the entire code base is rolled back to that commit. After the initial backup was finished, other commits were chosen such that they were about one month apart.  The code base is then moved forward to these commits one by one to emulate incremental changes.  Details can be found in linux-backup-test.sh.


Here are the elapsed real times (in seconds) as reported by the `time` command, with the user CPU times and system CPU times in the parentheses:



## Dataset 2: a VirtualBox virtual machine

The second test was targeted at the other end of the spectrum - a dataset with fewer but much larger files.  Virtual machine files typically fall into this category.  The particular dataset for this test is a VirtualBox virtual machine file.  The base disk image is 64 bit CentOS 7, downloaded from http://www.osboxes.org/centos/.  Its size is about 4 GB, still small compared to virtual machines that are actually being used everyday, but it is enough to quantify performance differences between these 4 backup tools.

The first backup was performed right after the virtual machine had been set up without installing any software.  The second backup was performed after installing common developer tools using the command `yum groupinstall 'Development Tools'`.  The third backup was performed after a power on immediately followed by a power off.



## Conclusion


