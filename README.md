# Genetics-Workshop-Mexico-LAI-2024

Ancestry pipeline
=================

## Description ##
Overall description: Run PCA on a VCF, phase data, convert phased data to RFMix format, run local ancestry with RFMix, collapse RFMix output into bed files, alter bed files, plot karyograms, estimate global ancestry proportions, run TRACTS, generate PCAMask input, run PCA on PCAMask output (ASPCA).

This workshop gives information about how to run through phasing, local ancestry inference, generate collapsed bed files, plot karyograms, estimate global ancestry proportion from local ancestry proportions, generate and run ASPCA, and run TRACTS to model migration events, proportions, and timings.

Each step can be followed with the 1000 Genomes data (ftp://ftp-trace.ncbi.nih.gov/1000genomes/ftp/release/20130502/supporting/hd_genotype_chip/) and systematically through this pipeline by downloading a toy dataset here: https://www.dropbox.com/sh/zbwka9u09f73gwo/AABc6FNl9fVBPjby8VQWzyeXa?dl=0. Slides from a tutorial I gave from ASHG 2015 using 1000 Genomes data are available here: http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/data_collections/1000_genomes_project/working/20151008_ASHG15_tutorial/20151008_ASHG15_admixture.pdf.


## Pipeline Map ##
#### 0.) Phase #####
  * Run SHAPEIT4 phasing
  * Make RFMix input

##### 1.) Infer local ancestry #####
  * Run RFMix

##### 2.1) Collapse inferred data #####
  * Collapse RFMix output into TRACTS-compatible bed files
  * Posthoc bed file filter (OPTIONAL)
  * Plot ancestry karyograms
  * Estimate global ancestry proportions from local ancestry inference



## 0.) Phase ###
##### Overview #####
Any phasing tool will do, such as SHAPEIT2, BEAGLE, or HAPI-UR. I usually run SHAPEIT2 (documentation here: http://www.shapeit.fr/) for ~100s of samples in two steps, first in check mode to identify SNPs that are incompatible and need to be excluded (also useful for summary info, which tells you about mendelian inconsistencies). For larger datasets (~1000s+), HAPI-UR is more accurate and orders of magnitude faster.

```
for i in {1..22};
do plink \
--bfile ACB_example \
--chr ${i} \
--make-bed \
--out ACB_example_chr${i};
done
```

#### 1) SHAPEIT4 check ####
Run according to the documentation. Examples as follows:

```
for i in {1..22}; 
do shapeit \
-check \
--input-ref 1000GP_Phase3_chr${i}.hap.gz \
1000GP_Phase3_chr${i}.legend.gz \
1000GP_Phase3.sample \
-B ACB_example_chr${i} \
--input-map genetic_map_chr${i}_combined_b37.txt \
--output-log ACB_example_chr${i}.mendel; 
done
```

Note: 1000 Genomes reference panels and genetic maps can be downloaded here: https://mathgen.stats.ox.ac.uk/impute/1000GP_Phase3.html.
Be sure to remove fully missing SNPs.

#### 2) SHAPEIT4 phasing ####
Second, I run the phasing algorithm itself (usually with a reference panel like phase 1 1000 Genomes), which takes some time and memory, for example as follows:

```
for i in {1..22}; 
do shapeit \
--input-ref 1000GP_Phase3_chr${i}.hap.gz \
1000GP_Phase3_chr${i}.legend.gz \
1000GP_Phase3.sample \
-B ACB_example_chr${i} \
--duohmm \
--input-map genetic_map_chr${i}_combined_b37.txt \
--exclude-snp ACB_example_chr${i}.mendel.snp.strand.exclude \
--output-max ACB_example_chr${i}.haps.gz \
ACB_example_chr${i}.sample; done
```

Phasing should be parallelized across chromosomes and can be run with plink files or VCF files. 
The output logs from SHAPEIT2 indicate whether Medelian errors are present in family designations in plink .fam files. 
I have not yet found a way to run SHAPEIT2 incorporating family information with VCF files. The output files are *.haps and *.sample files. 


## 1.) Infer local ancestry ##
#### Run RFMix ####


```
for i in {1..22}; do \
python RunRFMix.py \
-e 2 \
-w 0.2 \
--num-threads 4 \
--use-reference-panels-in-EM \
--forward-backward \
PopPhased \
CEU_YRI_ACB_chr${i}.alleles \
CEU_YRI_ACB.classes \
CEU_YRI_ACB_chr${i}.snp_locations \
-o CEU_YRI_ACB_chr${i}.rfmix; done
```

## 2.1) Collapse inferred data ##
#### Collapse RFMix output into TRACTS-compatible bed files ####
After running RFMix, I always collapse the output into bed files and generate karyogram plots to ensure that there weren't upstream issues, such as class file errors, phasing technical artifacts, sample mixups, etc. I wrote a script to do this, which can be run for example as follows:
```
python collapse_ancestry.py \
--rfmix CEU_YRI_ACB_chr1.rfmix.2.Viterbi.txt \
--snp_locations CEU_YRI_ACB_chr1.snp_locations \
--fbk CEU_YRI_ACB_chr1.rfmix.5.ForwardBackward.txt \
--fbk_threshold 0.9 \
--ind HG02481 \
--ind_info CEU_YRI_ACB.sample \
--pop_labels EUR,AFR \
--chrX \
--out HG02481; done; done
```

Note: all autosomes must have successfully completed, and including chromosome X is optional with the flag. The order of the population labels correspond with the order of labels in the classes file.

#### Posthoc bed file filter (OPTIONAL) ####
After the first bed file is created, it might be desirable to mask certain regions, for example if a particular region is shown to be frequently misspecified empirically in the reference panel. I have only used this script once, so it almost assuredly has some bugs, but I have provided it here as a starting point in case posthoc masking is a desirable feature. An example run is as follows:

```
cat bed_files.txt | while read line; do \
python mask_lcr_bed.py \
--bed ${line} \
--out ${line}2;
done
```

#### Plot ancestry karyograms ####
I have also written a visualization script to plot karyograms, which can be run for example as follows:
```
IND='HG02481'; python plot_karyogram.py \
--bed_a ${IND}_A.bed \
--bed_b ${IND}_B.bed \
--ind ${IND} \
--out ${IND}.png
```
Example output looks like the following:

![alt tag](https://aliciarmartindotcom.files.wordpress.com/2012/02/hg02481.png?w=800)

This script accepts a centromere bed file (see Dropbox data).

To do:
* Fix plot_karyogram.py so that the rounding at the ends of chromosomes occurs because the first and last chromosome tracts have been identified in the script, rather than required in the centromere bed file

#### Estimate global ancestry proportions from local ancestry inference ####

The last step is to calculate global ancestry proportions from the tracts. This can be useful to compare to orthogonal methods, i.e. ADMIXTURE, to see how well the ancestry estimates agree. This step can be run as follows:
```
for POP in ACB ASW CLM MXL PEL PUR; do python lai_global.py \
--bed_list bed_list_${POP}.txt \
--ind_list ${POP}.inds \
--pops AFR,EUR,NAT \
--out lai_global_${POP}.txt; done
```
The bed_list input here is a text file with a list of bed files, two per line and separated by whitespace, where each row corresponds to a single individual. For example:
```
ind1_a.bed    ind1_b.bed
ind2_a.bed    ind2_b.bed...
```
The ind_list input has individual IDs that will be used to summarize the output. The pops option specifies all of the populations to estimate global proportion ancestry for. I created this option so that UNK tracts could be easily dropped from global proportion ancestry estimated. An example txt output file is attached.


