## Overview

This repository contains the third assignment for the Scientific Programming course MSB1015 in 2019. This assignment is supposed to cover the aspects of parallel processing and the workflow framework "Nextflow". During this assignment, we will create a small pipeline to parse the smiles and calculate the JPLogP descriptor for all chemical compounds available on Wikidata. Next, we will benchmark the performance of the pipeline using different settings for the CPU cores used and report the execution time.



## Installation

The assignment is implemented using Domain-Specific Language (DSL) that eases the writing of data-intensive computational pipelines and runs using Nextflow workflow framework.

#### Benchmarking Platform

The workflow was tested on Linux Ubuntu 18.04 virtual machine with allocated hardware (4 cores and 3GB RAM).

The virtual machine is installed on a personal laptop (Processor: Intel Core i5, RAM: 8GB)

#### Software versions

Nextflow version 19.07.0.5106

RStudio 1.1.456 

R (64bit) 3.5.2

#### Nextflow requirements

Nextflow can be used on any POSIX compatible system (Linux, OS X, etc). It requires Bash 3.2 (or later) and [Java 8 (or later, up to 11)](http://www.oracle.com/technetwork/java/javase/downloads/index.html) to be installed.

#### Nextflow Installation

1. Download the executable package by copying and pasting the following command in your terminal window: `wget -qO- https://get.nextflow.io | bash`. 

   It will create the `nextflow` main executable file in the current directory.

2. Optionally, move the `nextflow` file to your user home directory so the nextflow command can be called using : ~/nextflow

   As an alternative, you can make sure the nextflow file is in a directory accessible by your `$PATH` variable so the nextflow command can be called using : ./nextflow

#### Running the assignment

1. Download the repository from the releases tab.

2. Unzip the zipped source file.

3. Go to the repository folder with "cd" command.

4. The SMILEs data already provided in the "data" folder. If you want to test the R script file that fetches the SMILEs data from Wikidata, then run "scripts/SmilesFetcher.R" using RStudio.

5. Check that you have the "time" command by typing it in the terminal. If not install it using:

   `apt-get install time` 

6. Run the following commands (one by one):

   ```bash
   time -v ./nextflow main.nf -profile cpu_1
   
   time -v ./nextflow main.nf -profile cpu_2
   
   time -v ./nextflow main.nf -profile cpu_4
   ```

   **Note:**  the previous commands use the -profile parameter to use a specific set of configurations defined through the file "nextflow.config". The naming of that file is important because Nextflow looks specifically for "nextflow.config" file next to the executed workflow file.

   

## Workflow Description

This is a simple workflow composed of one step. First, input channel is defined (molecules_ch) to read the SMILEs data from the TSV file and parse it line by line.

Next, a process is defined to process a line (or more) from the TSV which is feed through the input channel. It calculates the JPlogP descriptor and prints it to the console.

The main aim from this workflow is to examine the performance and the execution time of the pipeline using different settings of the number of CPUs and the way the input data is chuncked.



## Results

There are two important directives to be used inside the workflow process that have an effect on how resources are utilized in terms of CPU.

- **cpus**: this directive allows you to define the number of (logical) CPU required by the process' task. This means it will reserve the defined number of CPUs when a pipeline process is executed.
- **maxForks**: this directive allows you to define the maximum number of process instances that can be executed in parallel. By default this value is equals to the number of CPU cores available minus 1.  This means, if you have 10 lines in your CSV for example and you want to run each one of them in process then by using (maxForks: 1), only one instance of the process can be run at a time and hence 10 instances will be run sequentially.

**Important**: After many tests and going through the documentation, I can say that it is important to notice that setting (cpus) alone does not limit the number of process instances that can be run in parallel but will make sure that each instance will not consume more than certain number of CPUs. At the same time using (maxForks) alone will not limit the number of CPUs used if the code inside the process is multi-threaded but will make sure that no more than a defined number of instances of that process will be executed at the same time.

Even though, we know from our code that calculating and printing the JPlogP descriptor is not a multi-threaded function, maxForks here will play the important role of controlling how to parallelize the instances of the process for each smile or list of smiles. 

It is better to use combination of the two directives to fully control our pipeline, and that is by setting the "cpus" always to 1 and using different values for "maxForks" (1,2,4).

**Very Important:** Close all running programs on your PC before testing the pipeline if you want to monitor the behavior of the cores because other programs running on your computer will also use the CPU and tamper your observation.



#### Setting the input channel behavior 

Normally, when you use Channel.fromPath() with the splitCsv() function, it will parse the provided CSV/TSV file line by line and feed each row to an instance of each process that use that channel.

So, if we have a file with 10000 lines then 10000 instances of our process will be created and executed.

There is a parameter can be added to the splitCsv() function calld "by" and used like "by:1000". This parameter determines how many rows should be read as a chunk before channeling them to the process instance. So, for example, if we have a file with 10000 lines and we used "by:1000" then only 10 instances of our process will be created and executed and it is our job to loop through the 1000 item in each chunk inside the process code and process them.



#### Workflow benchmark without using data chunks (the impementation available in commit [57c805e](https://github.com/a-ammar/MSB1015-Assignment3/commit/57c805e8cf626847cbd92504b0d076f5a2c9d78a))

In our "wikidata_smiles.tsv" file, there are 158767 compound. So, using the default splitCSV() command in the channel, each row (compound) will be processed in an independent instance of the process (i.e. 158767 instances).

Using three profiles defined in "nextflow.config" to use 1,2 and 4 cores, these were the reported execution times:

| 1 CPU            | 2 CPU            | 4 CPU             |
| ---------------- | ---------------- | ----------------- |
| 22 min 17 second | 15 min 37 second | 11 min 04 seconds |

And the CPU behavior for 1 CPUs and 4 CPUs is shown below:

**1 CPU**

![](https://user-images.githubusercontent.com/43293732/67582493-baf11a80-f6fe-11e9-8477-ffa0aeb18ceb.png)

We can see that one core is more occupied than the others. Since the OS is responsible of allocating the CPUs to the processes, we see that the color switched because another CPU is allocated to the workflow.  There is no guarantee that the exact same core (physically) will process the whole workflow.

**4 CPUs**

![](https://user-images.githubusercontent.com/43293732/67582578-e4aa4180-f6fe-11e9-873c-8f4c7b77fa72.png)

We can see here that the 4 cores are consumed together and since the instance of the process is calculating the descriptor for only one SMILE at a time, we can see that the core is not fully consumed and the average of the CPUs consumption is about 50% where the process is too fast and a new instance will take the core and start all over again. We will see next with data chunks how it is different.



#### Workflow benchmark  using data chunks (1000 rows)

In our "wikidata_smiles.tsv" file, there are 158767 compound. So, using the splitCSV() command in the channel with the parameter "by:1000", it will push every 1000 parsed lines into one instance of the process and that will lead to 159 chunks and 159 instances. The config profiles will take care of parallelizing each instance with specific number of CPUs.  

Using three profiles defined in "nextflow.config" to use 1,2 and 4 cores, these were the reported execution times:

| 1 CPU          | 2 CPU           | 4 CPU           |
| -------------- | --------------- | --------------- |
| 4 min 7 second | 2 min 58 second | 2 min 1 seconds |

And the CPU behavior for 1 CPUs and 4 CPUs is shown below:

**1 CPU**

![](https://user-images.githubusercontent.com/43293732/67583391-58991980-f700-11e9-9abf-3caf0dfe667d.png)

We see here that there is more work done by the process instance because it has to deal with 1000 smile so the 1 core is fully consumed and lasts longer. Also the overall time for the workflow is shorter because the process is faster dealing with list of smiles than creating a new instance for each SMILE.

**4 CPUs**

![](https://user-images.githubusercontent.com/43293732/67583399-5c2ca080-f700-11e9-86cc-4bfb6dc97944.png)

Here all the cores are fully consumed and this the fastest combination of settings to perform the workflow.



## The SPARQL query

The query retrieves all the compounds available in Wikidata with their corresponding SMILEs and isoSMILEs if available. 

```SPARQL
SELECT DISTINCT ?compound ?smiles ?isoSmiles WHERE {
            ?compound wdt:P233 | wdt:P2017 [] .
            OPTIONAL { ?compound wdt:P233 ?smiles }
            OPTIONAL { ?compound wdt:P2017 ?isoSmiles }
          }
```

Predicate P233 : canonical SMILES

Predicate P2017 :  isomeric SMILES



## Licenses

1. The *Nextflow* framework is released under the Apache 2.0 license.
2. WikidataQueryServiceR  R package license is [MIT](https://cran.r-project.org/web/licenses/MIT) + file [LICENSE](https://cran.r-project.org/web/packages/WikidataQueryServiceR/LICENSE).
3. CDK is licensed under [GNU Lesser General Public License](https://www.gnu.org/licenses/old-licenses/lgpl-2.1.en.html), version 2.1 (or later). 



## Citations

P. Di Tommaso, et al. Nextflow enables reproducible computational workflows. Nature Biotechnology 35, 316–319 (2017) doi:[10.1038/nbt.3820](http://www.nature.com/nbt/journal/v35/n4/full/nbt.3820.html)

Christoph Steinbeck, et al. The Chemistry Development Kit (CDK): An Open-Source Java Library for Chemo-and Bioinformatics. J. Chem. Inf. Comput. Sci ,43, 2493-500 (2003) doi: https://doi.org/10.1021/ci025584y



## Github pages

You can access the assignment HTML page through Github pages on the following URL:

https://a-ammar.github.io/MSB1015-Assignment3/

## 

## Authors

Ammar Ammar

Supervised By: Prof. Egon Willighagen
