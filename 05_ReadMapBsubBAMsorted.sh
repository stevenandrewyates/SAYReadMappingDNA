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

# A script to use bowtie2 to align reads to a genome.
# This will launch a batch submission job (bsub).
# This is suitable for large genomes, because you 
# can specify the RAM and time limits.
# The output data will be in the folder SAM.

##################################################
######              Usage                   ######
##################################################

# This requires the following inputs
 
# -S is the directory with the SAM data
# -G name of the genome fasta file, in the directory GENOME
# -R is the RAM, in GB
# -N is the number of cores
# -M is the time in hours.

# bash $SCRATCH/05_ReadMapBsubBAMsorted.sh -N 1 -R 1 -M 1 -S BAM -G genome.fasta



##################################################
######              Script                  ######
##################################################

while getopts G:S:R:N:M: flag
do
    case "${flag}" in
        S) BAM=${OPTARG};;
        G) GEN=${OPTARG};;
 	R) RAM=${OPTARG};;
        N) COR=${OPTARG};;
	M) TIME=${OPTARG};;
    esac
done

echo "number of cores is:";
echo $COR;
echo "and requesting ${RAM}GB per core";
RAMMB=$(($RAM*1024));
TotalRam=$(($COR*$RAM));
echo "RAM in MB per core:";
echo $RAMMB;
echo "Total RAM requested:";
echo $TotalRam;

MINUTES=$(($TIME*60));
echo "For $MINUTES minutes:"; 



# find the fastq files and writethem to a file
echo "looking in directory $BAM for fastq files";  
ls $BAM| grep "bam" > BAMlist.txt

# load bowtie2
echo "loading samtools module"
module load gdc
module load samtools/1.7


# make a directory called BAM to output the data
echo "make a directory called BAMsorted to output the data"
mkdir BAMsorted

echo "executing these bsub jobs";
for x in $(cat BAMlist.txt | sed 's/.bam//g');  do echo "bsub -W $MINUTES -n $COR -R \"rusage[mem=$RAMMB]\" samtools sort -o BAMsorted/$x.bamsort BAM/$x.bam";done;


for x in $(cat BAMlist.txt | sed 's/.bam//g');  do echo "bsub -W $MINUTES -n $COR -R \"rusage[mem=$RAMMB]\" samtools sort -o BAMsorted/$x.bamsort BAM/$x.bam";done | sh;

echo "Done :)";
