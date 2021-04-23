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

# bash $SCRATCH/04_ReadMapBsubBAM.sh -N 1 -R 1 -M 1 -S SAM -G genome.fasta



##################################################
######              Script                  ######
##################################################

while getopts G:S:R:N:M: flag
do
    case "${flag}" in
        S) SAM=${OPTARG};;
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
echo "looking in directory $SAM for fastq files";  
ls $SAM| grep "sam" > SAMlist.txt

# load bowtie2
echo "loading samtools module"
module load samtools

# make a directory called BAM to output the data
echo "make a directory called BAM to output the data"
mkdir BAM

echo "executing these bsub jobs";
for x in $(cat SAMlist.txt | sed 's/.sam//g');  do echo "bsub -W $MINUTES -n $COR -R \"rusage[mem=$RAMMB]\" samtools view -bt GENOME/$GEN -o BAM/$x.bam SAM/$x.sam";done;


for x in $(cat SAMlist.txt | sed 's/.sam//g');  do echo "bsub -W $MINUTES -n $COR -R \"rusage[mem=$RAMMB]\" samtools view -bt GENOME/$GEN -o BAM/$x.bam SAM/$x.sam";done | sh;




echo "Done :)";
