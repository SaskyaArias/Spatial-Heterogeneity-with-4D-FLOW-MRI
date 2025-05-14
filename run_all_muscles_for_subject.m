function run_all_muscles_for_subject(subjectID, basePath, series, trigger)
    muscles = {'MG', 'SOL', 'LG', 'TA'};

%By Saskya: Copy this to command window to run automatically, just change the subject.  
%series = 1;
%run_all_muscles_for_subject('Subject', '.', series, trigger);
%plot_strain_subvolumes('subject');
            
    
    
    for i = 1:length(muscles)
        muscle = muscles{i};
        filename = sprintf('%s_%s_Segmentation.nrrd', subjectID, upper(muscle));
        fullpath = fullfile(basePath, filename);

        fprintf('🔎 Looking for file: %s\n', fullpath);

        if exist(fullpath, 'file')
            fprintf('\n Processing %s...\n', filename);
            process_single_segmentation(filename, basePath, subjectID, upper(muscle), series, trigger);
        else
            warning('Segmentation file not found: %s\n', fullpath);
        end
    end

    % Export Excel with peak values
    extract_subject_to_excel(subjectID);

      % Save final Data structure only once
    if evalin('base', 'exist(''Data'', ''var'')')
        Data = evalin('base', 'Data');
        finalSaveName = fullfile(basePath, [subjectID '_strain_data_FINAL.mat']);
        save(finalSaveName, 'Data', '-v7.3');
        fprintf(' Final strain data saved to: %s\n', finalSaveName);
    else
        warning('Data struct not found in base workspace. Nothing saved.');
    end


  
end
