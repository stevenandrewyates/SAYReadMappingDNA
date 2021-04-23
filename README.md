# SAYReadMappingDNA
This GitHub repository contains everything you need to start mapping reads to a genome.


# Description

This guide and scripts will walk you through mapping DNA to a genome using the Euler computing system at ETH Zurich (http://scicomp.ethz.ch/wiki/Euler).

# Downloading a genome reference

Before read mapping we first need to get the a genome. By this I mean online. First off we will download (`wget`) the genome to your current directory and then make a directory (`mkdir`) called GENOME to store it in:

```
wget ftp://ftp.ensemblgenomes.org/pub/plants/release-50/fasta/manihot_esculenta/dna/Manihot_esculenta.Manihot_esculenta_v6.dna.toplevel.fa.gz
mkdir genome
```

Next we will move (`mv`) the file to the genome folder then unzip (`gunzip`) it

```
mv Manihot_esculenta.Manihot_esculenta_v6.dna.toplevel.fa.gz GENOME/
gunzip GENOME/ Manihot_esculenta.Manihot_esculenta_v6.dna.toplevel.fa.gz
```

Next, we will format the genome. Normally this isn't needed but for those annoying rare occasions it is best to format before hand. For formatting, we will use `seqret` from the *EMBOSS* [package here](http://emboss.bioinformatics.nl/cgi-bin/emboss/help/seqret). All this does is make the strings of nucleotides the same length, per line. As you will see below the formatted genome is in the file GENOME/genome.fasta.

```
module load gcc/4.8.2 gdc emboss/6.5.7
seqret -sequence GENOME/ Manihot_esculenta.Manihot_esculenta_v6.dna.toplevel.fa --outseq GENOME/genome.fasta
```

Now we can start to build a genome reference for read aligning. This will be done using *bowtie2* using the `bowtie2-build` command.

```
module load bowtie2
bowtie2-build GENOME/genome.fasta GENOME/genome
```

Voila, genome reference ready.


## Example
This can all be done using the script below, where `-f x` is the link to your genome.

```
module load git
git clone https://github.com/stevenandrewyates/SAYReadMappingDNA
sh SAYReadMappingDNA/01_DownloadGenome.sh -f ftp://ftp.ensemblgenomes.org/pub/plants/release-50/fasta/manihot_esculenta/dna/Manihot_esculenta.Manihot_esculenta_v6.dna.toplevel.fa.gz
```

Perhaps, you've got a big one (a large genome of course)? If the above doesn't work then you might want to submit the `bowtie2-build` as a batch submission job (`bsub`). The advantage being you can increase the RAM and length of time for building. In this script you need to state the `-N` number of cores, `-R` RAM per core (in GB) and  `-M` the duration in hours:

```
sh SAYReadMappingDNA/02_DownloadGenome.sh -N 3 -R 2 -M 2 -f ftp://ftp.ensemblgenomes.org/pub/plants/release-50/fasta/manihot_esculenta/dna/Manihot_esculenta.Manihot_esculenta_v6.dna.toplevel.fa.gz
```
# Read mapping

In  the following stretch we are going to align short reads to the genome reference (*GENOME/genome*) we prepared earlier. This must be run in steps, which means no skipping! What happens is we first align the data making *SAM* files, then we must convert them into *BAM* files, and finally sort the *BAM* files. So it's a three stage process.

Let's assume all your fastq data is in a folder called FASTQ like in the the [download scripts](https://github.com/stevenandrewyates/SAYEulerDataManagement/). We can use a loop to find all the files and systematically align each one (no typing each file one-by-one). So we will use some pattern matching (`grep`) to find the files. Then make a unique list (`sed`) and store it in the file *FASTQlist*:

```
ls $FASTQ | grep "1.fastq" | sed 's/1.fastq//g' > FASTQlist.txt
```

Next some house keeping. We will load `bowtie2` and then prepare two directories to store the output. The directory SAM will contain the data from the alignments. While the MapAlign folder will contain the alignment reports. These are very useful to assess the quality of your data.

```
module load bowtie2
mkdir SAM
mkdir MapAlign
```

Once these are prepared we  can begin read aligning `for` all the files in the *FASTQlist.txt* by con`cat`enating the files to the loop. Next we will use `bsub` and specify the length of time `-W` in minutes, with the amount of RAM (`-R`) and number of cores (`-n`). We will use `bowtie2`and exclude the unaligned reads from the *SAM* file (`--no-unal`).

```
for x in $(cat FASTQlist.txt);  do echo "bsub -W 60 -n 2 -R \"rusage[mem=1024]\" -e MapAlign/$x.txt bowtie2 --no-unal -p $COR -x  $GEN/$GENOME  -1 $FASTQ/${x}1.fastq -2 $FASTQ/${x}2.fastq -S SAM/$x.sam ";done | sh
```
This can all be handled using the script:

```
bash SAYReadMappingDNA/03_ReadMapBsub.sh -N 3 -R 2 -M 2 -F FASTQ -G GENOME
```

Where `-N` is the number of processors, `-R` is RAM in GB, `-M` is the time in hours, `-F` is the *FASTQ* folder with your data and -G is the directory with your genome 

# Making *BAM* files

Once all data is mapped we will convert the *SAM* files to *BAM* files. As before we will make a driectory (`mkdir`) for the output. Also we need to load *samtools*.

```
mkdir BAM
module load samtools
```

Then use a `for` loop to iterate through the *SAM* files. In the example below we use `sed` to chop off the *sam* bit of the file and replace it with *bam*. The *bsub* requests are the same as before:

```
ls $SAM| grep "sam" > SAMlist.txt
for x in $(cat SAMlist.txt | sed 's/.sam//g');  do echo "bsub -W 60 -n 2 -R \"rusage[mem=1024]\" samtools view -bt GENOME/$GEN -o BAM/$x.bam SAM/$x.sam";done | sh;
```

Again this can all be done by a script in the following way:

```
bash  SAYReadMappingDNA/04_ReadMapBsubBAM.sh -N 1 -R 1 -M 1 -S SAM -G genome.fasta
```

The only changes are `-S` is the input directory of *SAM* files and `-G` is the link to the (formatted) genome fasta file, in the folder GENOME. 


# Sorting *BAM* files

More of the same here. Make and output directory (`mkdir`) and load *samtools* (another version is needed due to a bug) and get a list of the *BAM* files.

```
ls $BAM| grep "bam" > BAMlist.txt
module load gdc
module load samtools/1.7
mkdir BAMsorted
```

Then we can `for` loop through the files using the following:

```
for x in $(cat BAMlist.txt | sed 's/.bam//g');  do echo "bsub -W 60 -n 2 -R \"rusage[mem=1024]\" samtools sort -o BAMsorted/$x.bamsort BAM/$x.bam";done | sh;
```

As before this can all be done with a script:

```
bash SAYReadMappingDNA/05_ReadMapBsubBAMsorted.sh -N 1 -R 1 -M 1 -S BAM -G genome.fasta
```

In this case `-S` is now the *BAM* directory.


Please remember this is a three stage process, you must wait until each step is complete! I'm afraid that I can't give you nice script that does everything. The reason being if you run everything at once Euler will begin converting *SAM* files to *BAM* files before they are made, and *BAM* files to sorted *BAM* files before they are made. So here it is again in an easy format:


```
bash SAYReadMappingDNA/03_ReadMapBsub.sh -N 3 -R 2 -M 2 -F FASTQ -G GENOME
bash SAYReadMappingDNA/04_ReadMapBsubBAM.sh -N 1 -R 1 -M 1 -S SAM -G genome.fasta
bash SAYReadMappingDNA/05_ReadMapBsubBAMsorted.sh -N 1 -R 1 -M 1 -S BAM -G genome.fasta
```

At each step you can use `bjobs` to check how your jobs are running, once they are clear complete use `ls -l SAM` or `ls -l BAM` or `ls -l BAMsorted` to check that the files are made and that they contain data. Also you may want to run `rm -rf SAM` to remove the *SAM* files after you have made the *BAM* files: to clear space. Likewise you can run `rm -rf BAM` once you have the sorted *BAM* files.

The problem with this workflow is that it only works with small input files. If you have tens of millions of reads then you will need to adjust the run time for *bsub*. This can be estimated but you will either ask for too much (wasting resources) or too little and get no output. I have  asolution to this and will add it later :)


