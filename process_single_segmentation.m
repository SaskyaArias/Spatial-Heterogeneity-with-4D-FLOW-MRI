function process_single_segmentation(filename, pathname, subjectID, muscle, series, trigger)

    % Bring variables from the base workspace
    Mg = evalin('base', 'Mg');
    XS = evalin('base', 'XS');
    Data = evalin('base', 'Data');

    segFile = fullfile(pathname, filename);
    seg = nrrdread(segFile);

    if isstruct(seg) && isfield(seg, 'pixelData')
        seg = seg.pixelData;
    end

    segmentation_label = sprintf('%s_%s', subjectID, muscle);
    fprintf('Loaded segmentation: %s\n', segmentation_label);

    if ~exist('Segmentations', 'var')
        Segmentations = struct();
    end
    Segmentations.(segmentation_label) = seg;

    seg_corrected = permute(seg, [2, 1, 3]);
    seg_corrected = flip(seg_corrected, 2);
    seg_corrected = flip(seg_corrected, 2);
    seg_corrected = seg_corrected(:, :, end:-1:1);
    seg_corrected = seg_corrected(:, :, 2:end-1);

    Segmentations.([segmentation_label '_corrected']) = seg_corrected;
    seg_corrected = Segmentations.([segmentation_label '_corrected']);

    outputFolder = fullfile('Segmentations', segmentation_label);
    if ~exist(outputFolder, 'dir')
        mkdir(outputFolder);
    end

% 4. Verification of Corrected Alignment (for Mid Slice)
sliceIdx = round(size(Mg, 3) / 2);
figure('Units', 'pixels', 'Position', [100, 100, 800, 800]);
imshow(mat2gray(Mg(:, :, sliceIdx, 1)), 'InitialMagnification', 400);
set(gca, 'Position', [0 0 1 1]); 
hold on;
contour(seg_corrected(:, :, sliceIdx), [0.5 0.5], 'r', 'LineWidth', 2);
title('Corrected Segmentation Overlay on Image Volume');
print(gcf, 'FinalCorrectedSegmentationOverlay.png', '-dpng', '-r300');
fprintf('Verification image saved as FinalCorrectedSegmentationOverlay.png\n');


% 5. Slice-by-Slice Verification of Segmentation Alignment
minSlices = size(seg_corrected, 3);
numRows = ceil(sqrt(minSlices));
numCols = ceil(minSlices / numRows);
figure('Units', 'normalized', 'Position', [0.1, 0.1, 0.8, 0.8]);
for sliceIdx = 1:minSlices
    subplot(numRows, numCols, sliceIdx);
    imshow(mat2gray(Mg(:, :, sliceIdx, 1)), 'InitialMagnification', 'fit');
    hold on;
    contour(seg_corrected(:, :, sliceIdx), [0.5 0.5], 'r', 'LineWidth', 1);
    title(['Slice ', num2str(sliceIdx)]);
    axis off;
end
sgtitle('Segmentation Overlay Across Slices');
print(gcf, 'Segmentation_Overlay_Grid.png', '-dpng', '-r300');
fprintf('Thumbnail image saved as Segmentation_Overlay_Grid.png\n');



% 6. Compute the Volumetric Strain Mask for the Entire Volume
L_vol_4DFlow = abs(Data(series).strain.L_Volumetric);
strainMask = flip(any(L_vol_4DFlow, 4), 3);  
if ~isequal(size(seg_corrected), size(strainMask))
    error('Mismatch in dimensions between segmentation and strain mask.');
end
segmentationStrainMask = double(seg_corrected) .* double(strainMask);
sliceIdx = round(size(Mg, 3) / 2);
figure('Units', 'pixels', 'Position', [100, 100, 800, 800]); 
imshow(mat2gray(Mg(:, :, sliceIdx, 1)), 'InitialMagnification', 400);
set(gca, 'Position', [0 0 1 1]);
hold on;
contour(segmentationStrainMask(:, :, sliceIdx), [0.5 0.5], 'r', 'LineWidth', 5);
title('Segmentation and Strain Overlay');
print(gcf, 'SegmentationAndStrainOverlay.png', '-dpng', '-r300');
fprintf('Verification image saved as SegmentationAndStrainOverlay.png\n');


%% 8. Smart Partition Strategy (PCA-Aligned 3×2×2)
% Uses uniform binning for most muscles, and global cross-sectional k-means for TA

% Get voxel coordinates
[x, y, z] = ind2sub(size(seg_corrected), find(seg_corrected));
coords = [x, y, z];

% PCA alignment
[coeff, ~, ~] = pca(coords);
pca_coords = coords * coeff;

if contains(lower(segmentation_label), 'ta') || contains(lower(segmentation_label), 'tib')
    fprintf('🔍 Using PCA-aligned + global k-means strategy (optimized for TA)\n');

    % Step 1: SI slicing (PC1)
    si_edges = linspace(min(pca_coords(:,1)), max(pca_coords(:,1)), 4);
    si_bin = discretize(pca_coords(:,1), si_edges);  % 1–3

    % Step 2: Determine ML/AP axis assignments using dot products
    ml_dir = [1, 0, 0];  % X
    ap_dir = [0, 1, 0];  % Y

    alignment_pc2_ml = abs(dot(coeff(:,2), ml_dir));
    alignment_pc2_ap = abs(dot(coeff(:,2), ap_dir));
    alignment_pc3_ml = abs(dot(coeff(:,3), ml_dir));
    alignment_pc3_ap = abs(dot(coeff(:,3), ap_dir));

    if alignment_pc2_ml > alignment_pc2_ap
        ml_axis = 2; ap_axis = 3;
        fprintf('💡 TA: PC2 aligned with ML (%.3f), PC3 aligned with AP (%.3f)\n', alignment_pc2_ml, alignment_pc3_ap);
    else
        ml_axis = 3; ap_axis = 2;
        fprintf('💡 TA: PC2 aligned with AP (%.3f), PC3 aligned with ML (%.3f)\n', alignment_pc2_ap, alignment_pc3_ml);
    end

    x_extent = range(coords(:,1));  % ML
    y_extent = range(coords(:,2));  % AP
    fprintf('📏 TA anatomical extent — ML: %d, AP: %d (voxels)\n', x_extent, y_extent);

    % Step 3: Global k-means clustering on corrected ML/AP plane
    cross_section = [pca_coords(:, ap_axis), pca_coords(:, ml_axis)];  % AP vs ML
    num_clusters = 4;
    rng(1);
    [cluster_idx, cluster_centers] = kmeans(cross_section, num_clusters, 'Replicates', 5);

    % Step 4: Convert clusters into AP/ML labels using cluster center sorting
    [~, ml_order] = sort(cluster_centers(:,2));  % ML is now 2nd col
    [~, ap_order] = sort(cluster_centers(:,1));  % AP is now 1st col

    apml_map = zeros(num_clusters, 2);
    for c = 1:num_clusters
        ap_idx = find(ap_order == c);
        ml_idx = find(ml_order == c);
        apml_map(c, :) = [ap_idx > 2, ml_idx > 2] + 1;
    end

    % Step 5: Assign full 3D region index
    region_idx = zeros(length(coords), 1);
    valid = ~isnan(si_bin);
    for i = find(valid)'
        si = si_bin(i);
        cluster = cluster_idx(i);
        ap = apml_map(cluster, 1);
        ml = apml_map(cluster, 2);
        region = (si - 1) * 4 + (ap - 1) * 2 + ml;
        region_idx(i) = region;
    end


else
    % Default: PCA-aligned 3×2×2 uniform binning for all other muscles
    fprintf(' Using PCA-aligned 3×2×2 uniform binning strategy\n');

   % Define anatomical reference directions in image space
ml_dir = [1, 0, 0];  % Mediolateral = X-axis
ap_dir = [0, 1, 0];  % Anteroposterior = Y-axis

% Check alignment of PC2 and PC3 with anatomical axes
alignment_pc2_ml = abs(dot(coeff(:,2), ml_dir));
alignment_pc2_ap = abs(dot(coeff(:,2), ap_dir));
alignment_pc3_ml = abs(dot(coeff(:,3), ml_dir));
alignment_pc3_ap = abs(dot(coeff(:,3), ap_dir));

% Decide which PCA axis is ML and which is AP
if alignment_pc2_ml > alignment_pc2_ap
    ml_axis = 2;
    ap_axis = 3;
    fprintf('💡 PC2 aligned with ML (%.3f), PC3 aligned with AP (%.3f)\n', ...
        alignment_pc2_ml, alignment_pc3_ap);
else
    ml_axis = 3;
    ap_axis = 2;
    fprintf('💡 PC2 aligned with AP (%.3f), PC3 aligned with ML (%.3f)\n', ...
        alignment_pc2_ap, alignment_pc3_ml);
end

% Also print anatomical extents from raw segmentation
x_extent = range(coords(:,1));  % ML
y_extent = range(coords(:,2));  % AP
fprintf('📏 Anatomical extent — ML: %d, AP: %d (voxels)\n', x_extent, y_extent);

% Now define the bin edges dynamically
si_edges = linspace(min(pca_coords(:,1)), max(pca_coords(:,1)), 4);  % PC1 = SI
ml_edges = linspace(min(pca_coords(:,ml_axis)), max(pca_coords(:,ml_axis)), 3);
ap_edges = linspace(min(pca_coords(:,ap_axis)), max(pca_coords(:,ap_axis)), 3);

% Bin each voxel into a region (3x2x2)
si_bin = discretize(pca_coords(:,1), si_edges);
ml_bin = discretize(pca_coords(:,ml_axis), ml_edges);
ap_bin = discretize(pca_coords(:,ap_axis), ap_edges);

% Initialize and assign region index
region_idx = zeros(length(coords), 1);
valid = ~(isnan(si_bin) | isnan(ap_bin) | isnan(ml_bin));
for i = find(valid)'
    si = si_bin(i);
    ap = ap_bin(i);
    ml = ml_bin(i);
    region = (si - 1) * 4 + (ap - 1) * 2 + ml;
    region_idx(i) = region;
end

end

% Build label volume
label_volume = zeros(size(seg_corrected));
linearInd = sub2ind(size(seg_corrected), x, y, z);
label_volume(linearInd) = region_idx;

% Restore SubvolumeMasks from base workspace if it exists
if evalin('base', 'exist(''SubvolumeMasks'', ''var'')')
    SubvolumeMasks = evalin('base', 'SubvolumeMasks');
else
    SubvolumeMasks = struct();
end

% Build label volume
label_volume = zeros(size(seg_corrected));
linearInd = sub2ind(size(seg_corrected), x, y, z);
label_volume(linearInd) = region_idx;

% Store into structure
SubvolumeMasks.(segmentation_label) = cell(1, 12);
for r = 1:12
    SubvolumeMasks.(segmentation_label){r} = (label_volume == r);
end
numSubVolumes = 12;
subvolume_masks = SubvolumeMasks.(segmentation_label);


fprintf(' Subvolume partitioning complete: 12 regions created for %s\n', segmentation_label);

%%
% 8.1 Updated Visualization: Subvolume Masks with Anatomical Labels (fixed padding, no shrink)
si_labels = ["SI1", "SI2", "SI3"];
ap_labels = ["AP1", "AP2"];
ml_labels = ["ML1", "ML2"];

pad = 20;  % adjust margin size as needed

figure('Color','w');
for r = 1:12
    subplot(3, 4, r);

    % 2D projections
    mask2d = max(SubvolumeMasks.(segmentation_label){r}, [], 3);
    seg2d  = max(seg_corrected, [], 3);

    % pad both mask and seg with black (zeros) — same scale preserved
    mask2d_show = padarray(mask2d, [pad pad], 0, 'both');
    seg2d_show  = padarray(seg2d,  [pad pad], 0, 'both');

    % show padded mask
    imshow(mask2d_show, 'InitialMagnification','fit'); hold on

    % overlay contour thicker
    contour(seg2d_show, [0.5 0.5], 'r', 'LineWidth', 2, 'Clipping','off');
    axis image off

    % title
    si_idx = floor((r - 1) / 4) + 1;
    ap_idx = mod(floor((r - 1) / 2), 2) + 1;
    ml_idx = mod((r - 1), 2) + 1;
    title(sprintf('%s-%s-%s', si_labels(si_idx), ap_labels(ap_idx), ml_labels(ml_idx)));
end

exportgraphics(gcf, fullfile(outputFolder, [segmentation_label '_PCAAligned_SubvolumeMasks.png']), 'Resolution', 300);
fprintf('Saved PCA-aligned subvolume mask visualization with padding + thick contour.\n');

% 8.3 Labeled 3D Rendering with Distinct Colors (Centroid Labels Only)

figure('Color', 'w', 'Position', [100, 100, 1400, 1600]);
hold on;
axis equal off;
view(3);
title('Labeled Subvolumes (Centroid Labels)', 'FontSize', 16);
camlight;
lighting gouraud;

% Maximally distinct colors
distinctColors = [
    1 0 0; 0 1 0; 0 0 1; 1 1 0; 1 0 1; 0 1 1;
    0.5 0 0; 0 0.5 0; 0 0 0.5; 0.5 0.5 0; 0.5 0 0.5; 0 0.5 0.5
];

si_labels = ["SI1", "SI2", "SI3"];
ap_labels = ["AP1", "AP2"];
ml_labels = ["ML1", "ML2"];
anatomical_labels = strings(1, 12);

for r = 1:12
    mask = SubvolumeMasks.(segmentation_label){r};
    fv = isosurface(mask, 0.5);
    
    % Skip empty surfaces
    if isempty(fv.vertices)
        continue;
    end

    % Draw region
    p = patch(fv);
    p.FaceColor = distinctColors(r, :);
    p.EdgeColor = 'none';
    p.FaceAlpha = 1.0;

    % Compute centroid of region
    [x, y, z] = ind2sub(size(mask), find(mask));
    centroid = mean([x, y, z], 1);

  % Label with subvolume number (1–12)
text(centroid(2), centroid(1), centroid(3), num2str(r), ...
    'Color', 'b', 'FontSize', 12, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center', 'Clipping', 'off');

end

%  Export figure after the loop
exportgraphics(gcf, fullfile(outputFolder, [segmentation_label '_LabeledSubvolume3D_Centroid.png']), 'Resolution', 300);
fprintf(' Saved labeled subvolume figure with centroid-based labels.\n');

%%


% Step 9: Strain for Subvolumes with Anatomical Labels

frames = size(XS, 4);  % Number of 4D frames

% Ensure Data.(segmentation_label) exists before assigning fields
if ~isfield(Data, segmentation_label)
    Data.(segmentation_label) = struct();
end

Data.(segmentation_label).strain_subvolume = cell(1, numSubVolumes);
Data.(segmentation_label).strain_subvolume_peak = cell(1, numSubVolumes);

% Define anatomical labels
si_labels = ["SI1", "SI2", "SI3"];  % Superior-Inferior
ap_labels = ["AP1", "AP2"];         % Anterior-Posterior
ml_labels = ["ML1", "ML2"];         % Medial-Lateral

for subIndex = 1:numSubVolumes
    this_mask = subvolume_masks{subIndex};

    % Compute anatomical label
    si_index = floor((subIndex - 1) / 4) + 1;
    ap_index = mod(floor((subIndex - 1) / 2), 2) + 1;
    ml_index = mod(subIndex - 1, 2) + 1;
    region_label = sprintf('%s-%s-%s', ...
        si_labels(si_index), ap_labels(ap_index), ml_labels(ml_index));

    if nnz(this_mask) == 0
        fprintf('Skipping %s (No segmentation data)\n', region_label);
        Data.(segmentation_label).strain_subvolume{subIndex} = [];
        Data.(segmentation_label).strain_subvolume_peak{subIndex} = [];
        continue;
    end

    % Get actual nonzero slices
    slice_range = find(squeeze(any(any(this_mask, 1), 2)));  % Slices with segmentation
    if isempty(slice_range)
        fprintf('%s: No slices with segmentation.\n', region_label);
        continue;
    end
    startSlice = min(slice_range);
    endSlice   = max(slice_range);
    num_slices = endSlice - startSlice + 1;

    % Initialize dynamic mask and assign mask within correct slice range
    dynamic_mask = zeros(size(XS));
    dynamic_mask(:, :, startSlice:endSlice, :) = ...
        repmat(this_mask(:, :, startSlice:endSlice), [1, 1, 1, frames]);

    fprintf('%s: Slices [%d - %d] | Nonzero voxels in dynamic_mask: %d\n', ...
        region_label, startSlice, endSlice, nnz(dynamic_mask));

    if nnz(dynamic_mask) == 0
        warning('%s: Dynamic mask is empty. Skipping.', region_label);
        continue;
    end

    % Apply strain computation
    Data.(segmentation_label).strain_subvolume{subIndex} = ...
        strain_ROI_v3Siemens(Data(series).strain, double(dynamic_mask));
    
    Data.(segmentation_label).strain_subvolume_peak{subIndex} = ...
        peak_ROI_SiemensV2(Data.(segmentation_label).strain_subvolume{subIndex});

    Data.(segmentation_label).voxel_counts{subIndex} = nnz(dynamic_mask);

end

% Step 10: Strain for Whole Muscle
fprintf('Processing Whole Volume Dynamic Strain...\n');

[~, ~, seg_slices] = ind2sub(size(seg_corrected), find(seg_corrected > 0));
whole_start = min(seg_slices);
whole_end   = max(seg_slices);

whole_volume_dynamic_mask = zeros(size(XS));
whole_volume_dynamic_mask(:,:,whole_start:whole_end,:) = ...
    repmat(seg_corrected(:,:,whole_start:whole_end), [1, 1, 1, frames]);

% Optional: assign general strain field into the current segmentation label
Data.(segmentation_label).strain = Data(series).strain;


Data.(segmentation_label).strain_whole = ...
    strain_ROI_v3Siemens(Data.(segmentation_label).strain, double(whole_volume_dynamic_mask));

Data.(segmentation_label).voxel_count_whole = nnz(whole_volume_dynamic_mask);


Data.(segmentation_label).strain_whole_peak = ...
    peak_ROI_SiemensV2(Data.(segmentation_label).strain_whole);


%%
% Step 11: Save Results

% Create output folder if it doesn't exist
if ~exist('Segmentations', 'dir')
    mkdir('Segmentations');
end


%save(['Segmentations/' segmentation_label '_strain_data.mat'], 'Data', '-v7.3');
fprintf('Strain data saved to: Segmentations/%s_strain_data.mat\n', segmentation_label);

% Define anatomical labels
si_labels = ["SI1", "SI2", "SI3"];
ap_labels = ["AP1", "AP2"];
ml_labels = ["ML1", "ML2"];

% Loop through each subvolume and display its corresponding label
for subIndex = 1:numSubVolumes
    % Compute anatomical label
    si_index = floor((subIndex - 1) / 4) + 1;
    ap_index = mod(floor((subIndex - 1) / 2), 2) + 1;
    ml_index = mod(subIndex - 1, 2) + 1;

    region_label = sprintf('%s-%s-%s', ...
        si_labels(si_index), ap_labels(ap_index), ml_labels(ml_index));

    % Print subvolume info
    fprintf('Subvolume %2d → %s | Data Type: %s\n', ...
        subIndex, region_label, class(Data.(segmentation_label).strain_subvolume_peak{subIndex}));
end

 fprintf('Completed processing of %s\n', segmentation_label);

assignin('base', 'Data', Data);
assignin('base', 'SubvolumeMasks', SubvolumeMasks);  



end
