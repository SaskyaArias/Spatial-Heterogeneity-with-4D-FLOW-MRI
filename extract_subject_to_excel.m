function extract_subject_to_excel(subjectID)
    if ~exist('Data', 'var')
        Data = evalin('base', 'Data');
    end

    muscles = {'MG', 'SOL', 'LG', 'TA'};
    fieldList = {'dx','dx_sd','dy','dy_sd','dz','dz_sd','dr','dr_sd', ...
                 'vx','vx_sd','vy','vy_sd','vz','vz_sd','vr','vr_sd', ...
                 'L_lambda','L_lambda_sd','ShearL_max','ShearL_max_sd', ...
                 'L_volumetric','L_volumetric_sd','FAL','FAL_sd'};

    nRows = numel(fieldList);
    filename = sprintf('%s_all_muscles_peak_values.xlsx', subjectID);

    for m = 1:length(muscles)
        muscle = muscles{m};
        varName = sprintf('%s_%s', subjectID, muscle);

        if isfield(Data, varName)
            muscleData = Data.(varName);
            output = cell(nRows+3, 14); % extra 2 rows for region + voxel info
output{1,1} = 'Peak values';
output{2,1} = 'Region Label';
output{3,1} = 'Voxel Count';

% Headers + region info
for s = 1:12
    output{1, s+1} = sprintf('%s_%d', muscle, s);

    % Get anatomical label
    si_labels = ["SI1", "SI2", "SI3"];
    ap_labels = ["AP1", "AP2"];
    ml_labels = ["ML1", "ML2"];

    si_idx = floor((s - 1) / 4) + 1;
    ap_idx = mod(floor((s - 1) / 2), 2) + 1;
    ml_idx = mod((s - 1), 2) + 1;

    region_label = sprintf('%s-%s-%s', ...
        si_labels(si_idx), ap_labels(ap_idx), ml_labels(ml_idx));
    output{2, s+1} = region_label;

    % Voxel count (safe)
try
    vc = Data.(varName).voxel_counts{s};
    output{3, s+1} = vc;
catch
    warning('⚠️ No voxel count for subvolume %d of %s — filling with EMPTY.', s, varName);
    output{3, s+1} = 'EMPTY';  % or NaN if you prefer
end


end

output{1, 14} = sprintf('%s_Whole', muscle);
output{2, 14} = 'Whole Volume';

try
    output{3, 14} = Data.(varName).voxel_count_whole;
catch
    warning('Could not find voxel_count_whole for %s — leaving whole voxel count blank.', varName);
    output{3, 14} = NaN;
end


% Row headers
for i = 1:nRows
    output{i+3,1} = fieldList{i};
end

% Fill subvolume data (safe against empty subvolumes)
for s = 1:12
    S = muscleData.strain_subvolume_peak{1,s};

    if isstruct(S)
        for r = 1:nRows
            output{r+3, s+1} = format_value(S.(fieldList{r}));
        end
    else
        fprintf('⚠️ Subvolume %02d in %s_%s is not a struct — filling with NaNs.\n', ...
            s, subjectID, muscle);
        for r = 1:nRows
            output{r+3, s+1} = NaN;
        end
    end
end


            % Fill whole volume data
            W = muscleData.strain_whole_peak;

 for r = 1:nRows
    val = W.(fieldList{r});
    if isnumeric(val) && isscalar(val) && val == 0
        output{r+1, 14} = NaN;  % or 'no data'
    else
        output{r+3, 14} = format_value(val);

    end



            end

            % Write to individual sheet
            writecell(output, filename, 'Sheet', muscle);
            fprintf('Sheet created for: %s\n', muscle);
        else
            warning('⚠️ Data for %s not found in structure.', varName);
        end
    end

    fprintf('Excel exported: %s\n', filename);
end

function out = format_value(val)
    if isnumeric(val)
        if isscalar(val)
            out = val;
        else
            out = mat2str(val, 4);
        end
    else
        out = 'N/A';
    end
end


