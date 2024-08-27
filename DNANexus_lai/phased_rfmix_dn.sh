#!/bin/bash

# Set up directories
base_dir="/projects/popgen_v2"
data_dir="$base_dir/merged_mais-phase"
output_dir="$base_dir/output"

# Ensure the output directory exists
mkdir -p "$output_dir"

# Step 1: Run SHAPEIT4 for Phasing
echo "Running SHAPEIT4 for phasing..."
shapeit4 \
  --input "$data_dir/input.vcf" \
  --map "$data_dir/genetic_map.txt" \
  --region 1-22 \
  --output "$output_dir/phased_output.vcf" \
  --log "$output_dir/shapeit4.log"

# Check if SHAPEIT4 completed successfully
if [ $? -eq 0 ]; then
    echo "SHAPEIT4 completed successfully."
else
    echo "SHAPEIT4 failed." >&2
    exit 1
fi

# Step 2: Run RfMix for Local Ancestry Inference
echo "Running RfMix..."
rfmix \
  --input-classes "$data_dir/classes.txt" \
  --input-genetic-map "$data_dir/genetic_map.txt" \
  --input-sample-map "$data_dir/sample_map.txt" \
  --input-vcf "$output_dir/phased_output.vcf" \
  --output-dir "$output_dir/rfmix_output"

# Check if RfMix completed successfully
if [ $? -eq 0 ]; then
    echo "RfMix completed successfully."
else
    echo "RfMix failed." >&2
    exit 1
fi

echo "Pipeline completed successfully."
