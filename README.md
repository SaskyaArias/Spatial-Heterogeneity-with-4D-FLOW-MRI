# Spatial-Heterogeneity-with-4D-FLOW-MRI

This repository contains MATLAB code for analyzing spatial heterogeneity of calf muscle strain and strain rate using 4D Flow MRI. It is part of a medical physics research project at San Diego State University, focusing on biomechanics during isometric plantarflexion at different force levels.

This study evaluates how strain and strain rate vary regionally across muscles by computing:

Eulerian, Lagrangian, and strain rate tensors
Fractional anisotropy (FA_E, FA_L, FA_SR)
Subvolume-based strain heterogeneity using PCA-aligned segmentation
The goal is to better understand localized mechanical behavior in healthy muscle tissue.

📂 Code Features

Preprocessing pipeline for 4D Flow MRI segmentation masks
PCA-based subvolume generation (3×2×2 partitioning)
Voxelwise eigenvalue decomposition to compute strain and FA metrics
Regional analysis and comparison between subvolumes and whole muscle
Automated plotting and data export to .mat and .xlsx

🛠 Requirements

MATLAB R2024b
Image Processing Toolbox
Custom or existing NRRD file reader (e.g., nrrdread.m)
4D Flow MRI-derived displacement and segmentation data

# 1. 4D Flow MRI Preprocessing

Make sure the Siemens 4D Flow DICOM folders are in your working directory. These should include the magnitude image and the three velocity components. The code expects them to be processed in the following order:

Magnitude (highest series number)
V<sub>x</sub> (second lowest)
V<sub>y</sub> (second highest)
V<sub>z</sub> (lowest)
Add the folder to your MATLAB path, then run the script using only the uncommented lines. Commented sections are kept for reference and are not required to run the pipeline.

# 2. Run Segmentation and Strain Analysis

Before running this section:

Make sure siemens_final.mat is loaded in your MATLAB workspace.
Ensure the segmentation .nrrd files for each muscle (MG, SOL, LG, TA) are located in the current working directory or in the specified basePath.
Then run on command window:

series = 1;

run_all_muscles_for_subject('SubjectID', '.', series, trigger);

plot_strain_subvolumes('SubjectID');

Replace 'SubjectID' with your actual subject name. This will process all four muscles, save strain results, generate strain plots, and export the summary Excel file.
