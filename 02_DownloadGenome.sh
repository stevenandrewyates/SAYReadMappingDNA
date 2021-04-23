##################################################
######            Details                   ######
##################################################

# author:   Steven Yates
# contact:  steven.yates@usys.ethz.ch
# Year:     2021
# Citation: TBA

##################################################
######            Description               ######
##################################################

# A script to download a genome and install a 
# bowtie2 reference using the Euler computing system.
# This will launch a batch submission job (bsub).
# this is suitable for large genomes, because you 
# can specify the RAM and time limits.

##################################################
######              Usage                   ######
##################################################

# this requires one input, a link to the genome 
# as shown below for cassava:
# -f is the genome to download and install
# -R is the RAM, in GB
# -N is the number of cores
# -M is the time in hours.

# bash $SCRATCH/02_DownloadGenome.sh -N 3 -R 2 -M 2 -f ftp://ftp.ensemblgenomes.org/pub/plants/release-50/fasta/manihot_esculenta/dna/Manihot_esculenta.Manihot_esculenta_v6.dna.toplevel.fa.gz

##################################################
######              Script                  ######
##################################################

while getopts f:R:N:M: flag
do
    case "${flag}" in
        f) IN=${OPTARG};;
 	R) RAM=${OPTARG};;
        N) COR=${OPTARG};;
	M) TIME=${OPTARG};;M
    esac
done


echo $COR;


echo "Sequence to download is:";
echo $IN; 
echo "number of cores is:";
echo $COR;
echo "and requesting $RAM per core";
RAMMB=$(($RAM*1024));
TotalRam=$(($COR*$RAM));
echo "RAM in MB per core:";
echo $RAMMB;
echo "Total RAM requested:";
echo $TotalRam;

MINUTES=$(($TIME*60));
echo "For $MINUTES minutes:"; 



# download the genome
echo "Downloading the genome";
wget $IN
# make a directory called GENOME
echo "making directory called GENOME";
mkdir GENOME

# unzip the data
GZ=$(echo $IN | sed 's/.*\///g')


# move the data to the GENOME folder
echo "moving data to GENOME directory";
mv $GZ GENOME/

echo "unzipping the data $GZ"
gunzip GENOME/$GZ
FA=$(echo $GZ | sed 's/.gz*//g')
echo "made file GENOME/$FA"

# load EMBOSS
echo "loading EMBOSS"
module load gcc/4.8.2 gdc emboss/6.5.7

# next we will convert the data to a nice format
echo "formatting the data and writing to the file: GENOME/genome.fasta"
seqret -sequence GENOME/$FA --outseq GENOME/genome.fasta

# load bowtie2
echo "loading bowtie2 module"
module load bowtie2

# build bowtie reference
echo "building reference genome called 'genome'" 
echo "making a bsub job that looks like this:"
echo "bsub -W $MINUTES -n $COR -R \"rusage[mem=$RAMMB]\" bowtie2-build GENOME/genome.fasta GENOME/genome"


echo "bsub -W $MINUTES -n $COR -R \"rusage[mem=$RAMMB]\" bowtie2-build GENOME/genome.fasta GENOME/genome" | sh
echo "Done :)";
