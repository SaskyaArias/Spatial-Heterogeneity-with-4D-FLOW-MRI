function plot_strain_subvolumes(subjectID)
    % Load the final saved Data structure
    filename = sprintf('%s_strain_data_FINAL.mat', subjectID);
    if ~isfile(filename)
        error('File not found: %s', filename);
    end

    load(filename, 'Data');

    % Manually load trigger (you said it’s in siemens_final.mat)
    load('siemens_final.mat', 'trigger');

    muscles = {'MG', 'SOL', 'LG', 'TA'};

    for m = 1:length(muscles)
        muscle = muscles{m};
        segmentation_label = sprintf('%s_%s', subjectID, muscle);

        if ~isfield(Data, segmentation_label)
            warning('No data for %s — skipping.', segmentation_label);
            continue;
        end

        numSubVolumes = length(Data.(segmentation_label).strain_subvolume);

        % --- WHOLE MUSCLE ---
        wholeFolder = fullfile('Segmentations', segmentation_label, 'StrainPlots', 'WholeMuscle');

        if ~exist(wholeFolder, 'dir')
            mkdir(wholeFolder);
        end

        try
            prevDir = pwd;
            cd(wholeFolder);
            strain_mvc_plots_v2Siemens(Data.(segmentation_label).strain_whole, 'WholeMuscle', trigger);
            cd(prevDir);
            fprintf('✅ Whole muscle plot complete for %s\n', segmentation_label);
        catch ME
            cd(prevDir);
            warning('⚠️ Failed whole muscle plot for %s: %s', segmentation_label, ME.message);
        end

        % --- SUBVOLUMES ---
        for subIndex = 1:numSubVolumes
            strain_data = Data.(segmentation_label).strain_subvolume{subIndex};

            if ~isempty(strain_data)
                % ✅ Use number-only label (01 to 12)
                region_label = sprintf('%02d', subIndex);

                regionFolder = fullfile('Segmentations', segmentation_label, 'StrainPlots', region_label);

                if ~exist(regionFolder, 'dir')
                    mkdir(regionFolder);
                end

                try
                    prevDir = pwd;
                    cd(regionFolder);
                    fprintf('📊 Plotting Subvolume %s for %s...\n', region_label, segmentation_label);
                    strain_mvc_plots_v2Siemens(strain_data, region_label, trigger);
                    cd(prevDir);
                catch ME
                    cd(prevDir);
                    warning('⚠️ Failed to plot Subvolume %s (%s): %s', region_label, segmentation_label, ME.message);
                end
            else
                fprintf('⏭️ Skipping Subvolume %02d: No strain data available.\n', subIndex);
            end
        end
    end
end
