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


##################################################
######              Usage                   ######
##################################################

# this requires one input, a link to the genome 
# as shown below for cassava:

# sh 01_DownloadGenome.sh -f ftp://ftp.ensemblgenomes.org/pub/plants/release-50/fasta/manihot_esculenta/dna/Manihot_esculenta.Manihot_esculenta_v6.dna.toplevel.fa.gz

##################################################
######              Script                  ######
##################################################

while getopts f: flag
do
    case "${flag}" in
        f) IN=${OPTARG};;
    esac
done

echo "Sequence to download is:"
echo $IN 

echo "making directory called GENOME";Next up we should format the data

mkdir GENOME
cd GENOME

# download the genome
echo "Downloading the genome";
wget $IN


cd ..


# unzip the data
GZ=$(echo $IN | sed 's/.*\///g')
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
bowtie2-build GENOME/genome.fasta GENOME/genome

echo "Done :)"; First off we we will donload
