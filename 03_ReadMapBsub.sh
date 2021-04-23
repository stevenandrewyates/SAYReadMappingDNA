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
 
# -F is the directory with the FASTQ data
# -G is the directory with the genome
# -R is the RAM, in GB
# -N is the number of cores
# -M is the time in hours.

# bash $SCRATCH/03_ReadMapBsub.sh -N 3 -R 2 -M 2 -F FASTQ -G GENOME


##################################################
######              Script                  ######
##################################################

while getopts G:F:R:N:M: flag
do
    case "${flag}" in
        F) FASTQ=${OPTARG};;
        G) GEN=${OPTARG};;
 	R) RAM=${OPTARG};;
        N) COR=${OPTARG};;
	M) TIME=${OPTARG};;
    esac
done

echo "Sequence to download is:";
echo $IN; 
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
echo "looking in directory $FASTQ for fastq files";  
ls $FASTQ | grep "1.fastq" | sed 's/1.fastq//g' > FASTQlist.txt


# find the genome reference
echo "looking in folder $GEN for a genome";
GENOME=$(ls $GEN | grep '1.bt2' | grep -v rev | sed 's/.1.bt2//g')


# load bowtie2
echo "loading bowtie2 module"
module load bowtie2

# make a directory called SAM to output the data
echo "make a directory called SAM to output the data"
mkdir SAM

# making directory MapAlign to store read mapping log
mkdir MapAlign

echo "executing these bsub jobs";
for x in $(cat FASTQlist.txt);  do echo "bsub -W $MINUTES -n $COR -R \"rusage[mem=$RAMMB]\" -e MapAlign/$x.txt bowtie2 --no-unal -p $COR -x  $GEN/$GENOME  -1 $FASTQ/${x}1.fastq -2 $FASTQ/${x}2.fastq -S SAM/$x.sam ";done


for x in $(cat FASTQlist.txt);  do echo "bsub -W $MINUTES -n $COR -R \"rusage[mem=$RAMMB]\" -e MapAlign/$x.txt bowtie2 --no-unal -p $COR -x  $GEN/$GENOME  -1 $FASTQ/${x}1.fastq -2 $FASTQ/${x}2.fastq -S SAM/$x.sam ";done | sh




echo "Done :)";
