Certainly! Here's the expanded version that includes explanations of the two main components of the pipeline:

```markdown
# Genetics-Workshop-Mexico-LAI-2024

## Running DNAnexus

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

## Ancestry Pipeline

### **Description**
This pipeline is designed to perform local ancestry inference on phased genetic data. The pipeline takes phased data, formats it for RFMix, runs the local ancestry inference using RFMix, collapses the RFMix output into BED files, plots karyograms, and estimates global ancestry proportions.

**Key References:**
- **1000 Genomes Data:** [Link](ftp://ftp-trace.ncbi.nih.gov/1000genomes/ftp/release/20130502/supporting/hd_genotype_chip/)
- **Human Genome Diversity Project (HGDP):** [Link](https://www.internationalgenome.org/data-portal/data-collection/hgdp)

Slides from a tutorial are available in this repository.

---

### **Pipeline Map**

#### **0. Phase**
  * **Run SHAPEIT4 Phasing:** This step involves phasing the genetic data, which is crucial for accurate local ancestry inference. Phasing aligns the sequences on homologous chromosomes and estimates the most likely sequence of alleles.
  * **Prepare RFMix Input:** After phasing, the data is formatted into a structure compatible with RFMix, which will be used for local ancestry inference.

#### **1. Infer Local Ancestry**
  * **Run RFMix:** This is the core step of the pipeline where local ancestry is inferred for each individual. RFMix uses reference populations to assign ancestry to each segment of the genome, providing a detailed picture of an individual's ancestry composition.

#### **2.1 Collapse Inferred Data**
  * **Collapse RFMix Output into TRACTS-Compatible BED Files:** The output from RFMix is processed to generate BED files that are compatible with the TRACTS software, which is used for further analysis and visualization.
  * **Posthoc BED File Filter (OPTIONAL):** An optional step where the BED files can be filtered to remove low-confidence regions or other unwanted data.
  * **Plot Ancestry Karyograms:** Visualization of the inferred ancestry along the genome, typically displayed in karyogram format.
  * **Estimate Global Ancestry Proportions from Local Ancestry Inference:** Summarize the local ancestry results to estimate overall ancestry proportions for each individual.

---

### **0. Phase**

#### **Overview**

This step involves running a phasing algorithm (e.g., SHAPEIT4) that arranges the genetic data in a phased format. Phasing is critical as it allows for the correct interpretation of genetic variants by distinguishing between the two sets of chromosomes an individual inherits from their parents.

Here's an example of how to run SHAPEIT4 across all chromosomes:

```bash
for i in {1..22}; 
do shapeit4 \
  --input "$data_dir/input${i}.vcf" \
  --map "$data_dir/genetic_map${i}.txt" \
  --region 1-22 \
  --output "$output_dir/phased_output${i}.vcf" \
  --log "$output_dir/shapeit4${i}.log"; done
```

Phasing should be parallelized across chromosomes and can be run with PLINK files or VCF files.

---

### **1. Infer Local Ancestry**

#### **Run RFMix**

RFMix is a powerful tool that uses phased genetic data and reference panels to infer local ancestry. In this step, the tool assigns ancestry labels to different segments of the genome, giving a detailed breakdown of where different ancestries are located on each chromosome.

Here’s how to run RFMix:

```bash
for i in {1..22}; do \
rfmix \
  --input-classes "$data_dir/classes.txt" \
  --input-genetic-map "$data_dir/genetic_map.txt" \
  --input-sample-map "$data_dir/sample_map.txt" \
  --input-vcf "$output_dir/phased_output.vcf" \
  --output-dir "$output_dir/rfmix_output${i}"; done
```

---

### **2.1 Collapse Inferred Data**

#### **Collapse RFMix Output into TRACTS-Compatible BED Files**

After running RFMix, the inferred ancestry data is collapsed into BED files that are compatible with TRACTS, a tool used for analyzing and visualizing ancestry tracts.

```bash
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

Note: All autosomes must have completed successfully, and including chromosome X is optional with the `--chrX` flag. The order of population labels should match the order in the classes file.

---

#### **Plot Ancestry Karyograms**

A karyogram is a visual representation of the chromosomes and the inferred ancestry across them. This step uses a script to plot the karyograms based on the BED files generated earlier.

```bash
IND='HG02481'; python plot_karyogram.py \
--bed_a ${IND}_A.bed \
--bed_b ${IND}_B.bed \
--ind ${IND} \
--out ${IND}.png
```

Example output might look like this:

![Karyogram](https://aliciarmartindotcom.files.wordpress.com/2012/02/hg02481.png?w=800)

This script can also accept a centromere BED file (available in Dropbox data).

*To Do:*
- Fix `plot_karyogram.py` to automatically round the ends of chromosomes, instead of relying on the centromere BED file.

---

#### **Estimate Global Ancestry Proportions from Local Ancestry Inference**

The final step is to estimate global ancestry proportions, which are summarized from the local ancestry data. This comparison can be useful for assessing agreement with other methods like ADMIXTURE.

```bash
for POP in ACB ASW CLM MXL PEL PUR; do python lai_global.py \
--bed_list bed_list_${POP}.txt \
--ind_list ${POP}.inds \
--pops AFR,EUR,NAT \
--out lai_global_${POP}.txt; done
```

The `bed_list` input is a text file listing the BED files, two per line (one per individual). For example:

```text
ind1_a.bed    ind1_b.bed
ind2_a.bed    ind2_b.bed
```

The `ind_list` input contains the individual IDs for summarizing the output. The `--pops` option specifies the populations for which to estimate global ancestry proportions. This allows for the exclusion of unknown (UNK) tracts from the estimation. An example output file is attached.
```

### Summary of Main Components:

1. **Phasing (Step 0)**: Phasing aligns genetic variants on homologous chromosomes, creating the foundation for accurate local ancestry inference. This step uses algorithms like SHAPEIT4, which arrange the sequences in a way that differentiates between the two sets of chromosomes inherited from the parents.

2. **Local Ancestry Inference (Step 1)**: This step uses RFMix to assign ancestry to segments of the genome. By comparing an individual’s phased genetic data to reference populations, RFMix provides a detailed breakdown of ancestry across the genome. This information is crucial for understanding the genetic makeup of an individual and identifying regions of the genome that come from specific ancestral populations.
```

This version provides a detailed explanation of the two main components of the pipeline—phasing and local ancestry inference—while maintaining a clear and organized structure in the Markdown format.
