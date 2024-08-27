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

 I run the phasing algorithm itself (usually with a reference panel like phase 1 1000 Genomes), which takes some time and memory, for example as follows:

```
for i in {1..22}; 
do shapeit4 \
  --input "$data_dir/input${i}.vcf" \
  --map "$data_dir/genetic_map${i}.txt" \
  --region 1-22 \
  --output "$output_dir/phased_output${i}.vcf" \
  --log "$output_dir/shapeit4${i}.log"; done
```

Phasing should be parallelized across chromosomes and can be run with plink files or VCF files. 


## 1.) Infer local ancestry ##
#### Run RFMix ####


```
for i in {1..22}; do \
rfmix \
  --input-classes "$data_dir/classes.txt" \
  --input-genetic-map "$data_dir/genetic_map.txt" \
  --input-sample-map "$data_dir/sample_map.txt" \
  --input-vcf "$output_dir/phased_output.vcf" \
  --output-dir "$output_dir/rfmix_output${i}"; done
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



### **Step 1: Set Up Your DNAnexus Project**

1. **Upload Your Script and Data Files**:
   - Ensure your script (`phased_rfmix_dn.sh`) and all required data files (e.g., `input.vcf`, `genetic_map.txt`, `classes.txt`, `sample_map.txt`) are uploaded to your DNAnexus project.

   ```bash
   dx upload phased_rfmix_dn.sh
   dx upload input.vcf genetic_map.txt classes.txt sample_map.txt
   ```

2. **Test Your Script**:
   - Run your script in DNAnexus to ensure everything is functioning as expected. You can do this through the DNAnexus platform’s UI or by using the `dx run` command.

   ```bash
   dx run your_applet_or_workflow_name --input_vcf=input.vcf --genetic_map=genetic_map.txt --classes_txt=classes.txt --sample_map=sample_map.txt
   ```

---

### **Step 2: Create a Snapshot of Your DNAnexus Project**

1. **Navigate to Your Project in DNAnexus**:
   - Make sure you are within the correct DNAnexus project context.

   ```bash
   dx select project-xxxx  # Replace project-xxxx with your project ID
   ```

2. **Create the Snapshot**:
   - Use the following command to create a snapshot of your entire project. This snapshot captures all files, scripts, and workflows at this point in time.

   ```bash
   dx create snapshot --name my_rfMix_workflow_snapshot
   ```

   - Replace `my_rfMix_workflow_snapshot` with a name that describes the snapshot.

---

### **Step 3: Verify the Snapshot**

1. **List All Snapshots**:
   - Check that your snapshot has been created by listing all snapshots in your project.

   ```bash
   dx list snapshots
   ```

2. **View Snapshot Details**:
   - To see more details about your snapshot, use the `dx describe` command.

   ```bash
   dx describe --details my_rfMix_workflow_snapshot
   ```

   - Replace `my_rfMix_workflow_snapshot` with the name of your snapshot.

---

### **Step 4: Navigate to and Use the Snapshot**

1. **Navigate to the Snapshot**:
   - To work within the snapshot, navigate to it using the following command.

   ```bash
   dx cd $DX_PROJECT_CONTEXT_ID:snapshot-my_rfMix_workflow_snapshot
   ```

   - Replace `$DX_PROJECT_CONTEXT_ID` with your project’s ID and `my_rfMix_workflow_snapshot` with the snapshot name.

2. **Run Workflows from the Snapshot**:
   - You can run your applets or workflows from within this snapshot as if you were working in the main project environment.

   ```bash
   dx run your_applet_or_workflow_name --input_vcf=input.vcf --genetic_map=genetic_map.txt --classes_txt=classes.txt --sample_map=sample_map.txt
   ```

---

### **Step 5: Restore or Duplicate the Snapshot (If Needed)**

1. **Duplicate the Snapshot to a New Project**:
   - If you ever need to restore or revert to the snapshot, create a new project based on the snapshot.

   ```bash
   dx new project "Restored Project from Snapshot"
   dx cp -r snapshot-my_rfMix_workflow_snapshot/* project-xxxx:
   ```

   - Replace `snapshot-my_rfMix_workflow_snapshot` with your snapshot name and `project-xxxx` with the new project ID.

---

### **Complete Example Workflow**

Here’s how the entire process might look in practice:

```bash
# Step 1: Set Up Your DNAnexus Project
dx upload phased_rfmix_dn.sh
dx upload input.vcf genetic_map.txt classes.txt sample_map.txt

dx run your_applet_or_workflow_name --input_vcf=input.vcf --genetic_map=genetic_map.txt --classes_txt=classes.txt --sample_map=sample_map.txt

# Step 2: Create a Snapshot of Your DNAnexus Project
dx select project-xxxx  # Ensure you're in the correct project
dx create snapshot --name my_rfMix_workflow_snapshot

# Step 3: Verify the Snapshot
dx list snapshots
dx describe --details my_rfMix_workflow_snapshot

# Step 4: Navigate to and Use the Snapshot
dx cd $DX_PROJECT_CONTEXT_ID:snapshot-my_rfMix_workflow_snapshot
dx run your_applet_or_workflow_name --input_vcf=input.vcf --genetic_map=genetic_map.txt --classes_txt=classes.txt --sample_map=sample_map.txt

# Step 5: Restore or Duplicate the Snapshot (If Needed)
dx new project "Restored Project from Snapshot"
dx cp -r snapshot-my_rfMix_workflow_snapshot/* project-xxxx:
```

