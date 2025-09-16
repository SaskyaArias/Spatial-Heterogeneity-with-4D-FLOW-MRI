function struct = strain_ROI_v3Siemens(structure,mask)


mask(mask==0)=NaN;
n_frames=size(mask,4);

mask0                   = repmat(mask(:,:,1),[1,1,n_frames]);
mask_vector_0           = repmat(mask0,[1,1,1,3]);
mask_vector_dynamic     = repmat(mask,[1,1,1,1,3]);
mask_tensor_0           = repmat(mask0,[1,1,1,3,3]);
mask_tensor_dynamic     = repmat(mask,[1,1,1,1,3,3]);
mask_vector_dynamic(:,:,1,:,:)=[];
mask_vector_dynamic(:,:,end,:,:)=[];
mask_tensor_dynamic(:,:,1,:,:,:)=[];
mask_tensor_dynamic(:,:,end,:,:,:)=[];

size(mask)
%displacements
temp_dx                 =  squeeze(structure.dx(:,:,:,:)).*mask;
struct.dx               =  permute(nanmean(squeeze(nanmean(nanmean(temp_dx,1),2)),1),[2,1]);
struct.dx_sd            =  permute(nanmean(squeeze(nanstd(nanstd(temp_dx,1,1),1,2)),1),[2,1]);

temp_dy                 =  squeeze(structure.dy(:,:,:,:)).*mask;
struct.dy               =  permute(nanmean(squeeze(nanmean(nanmean(temp_dy,1),2)),1),[2,1]);
struct.dy_sd            =  permute(nanmean(squeeze(nanstd(nanstd(temp_dy,1,1),1,2)),1),[2,1]);

temp_dz                 =  squeeze(structure.dz(:,:,:,:)).*mask;
struct.dz               =  permute(nanmean(squeeze(nanmean(nanmean(temp_dz,1),2)),1),[2,1]);
struct.dz_sd            =  permute(nanmean(squeeze(nanstd(nanstd(temp_dz,1,1),1,2)),1),[2,1]);

temp_dr                 =  squeeze(sqrt(temp_dx.^2 + temp_dy.^2 + temp_dz.^2));
struct.dr               =  permute(nanmean(squeeze(nanmean(nanmean(temp_dr,1),2)),1),[2,1]);
struct.dr_sd            =  permute(nanmean(squeeze(nanstd(nanstd(temp_dr,1,1),1,2)),1),[2,1]);


%velocities
temp_vx                 =  squeeze(structure.vx(:,:,:,:)).*mask;
struct.vx               =  permute(nanmean(squeeze(nanmean(nanmean(temp_vx,1),2)),1),[2,1]);
struct.vx_sd            =  permute(nanmean(squeeze(nanstd(nanstd(temp_vx,1,1),1,2)),1),[2,1]);

temp_vy                 =  squeeze(structure.vy(:,:,:,:)).*mask;
struct.vy               =  permute(nanmean(squeeze(nanmean(nanmean(temp_vy,1),2)),1),[2,1]);
struct.vy_sd            =  permute(nanmean(squeeze(nanstd(nanstd(temp_vy,1,1),1,2)),1),[2,1]);

temp_vz                 =  squeeze(structure.vz(:,:,:,:)).*mask;
struct.vz               =  permute(nanmean(squeeze(nanmean(nanmean(temp_vz,1),2)),1),[2,1]);
struct.vz_sd            =  permute(nanmean(squeeze(nanstd(nanstd(temp_vz,1,1),1,2)),1),[2,1]);

temp_vr                 =  squeeze(sqrt(temp_vx.^2 + temp_vy.^2 + temp_vz.^2));
struct.vr               =  permute(nanmean(squeeze(nanmean(nanmean(temp_vr,1),2)),1),[2,1]);
struct.vr_sd            =  permute(nanmean(squeeze(nanstd(nanstd(temp_vr,1,1),1,2)),1),[2,1]);



%strain Euler way

temp_E_lambda           = squeeze(structure.E_lambda).*mask_vector_dynamic;
struct.E_lambda         = squeeze(permute(nanmean(squeeze(nanmean(nanmean(temp_E_lambda,2),1)),1),[2,1,3]));
struct.E_lambda_sd      = squeeze(permute(nanmean(squeeze(nanstd(nanstd(temp_E_lambda,1,1),1,2)),1),[2,1,3]));

temp_ShearE_max         = squeeze(structure.ShearE_max).*squeeze(mask_vector_dynamic(:,:,:,:,1));
struct.ShearE_max       = permute(nanmean(squeeze(nanmean(nanmean(temp_ShearE_max,2),1)),1),[2,1]);
struct.ShearE_max_sd    = permute(nanmean(squeeze(nanstd(nanstd(temp_ShearE_max,1,1),1,2)),1),[2,1]);
temp_E_Volumetric       = squeeze(structure.E_Volumetric).*squeeze(mask_vector_dynamic(:,:,:,:,1));
struct.E_Volumetric     = permute(nanmean(squeeze(nanmean(nanmean(temp_E_Volumetric,2),1)),1),[2,1]);
struct.E_Volumetric_sd  = permute(nanmean(squeeze(nanstd(nanstd(temp_E_Volumetric,1,1),1,2)),1),[2,1]);


%strain Lagrange way
temp_L_lambda           = squeeze(structure.L_lambda).*mask_vector_dynamic;
struct.L_lambda         = squeeze(permute(nanmean(squeeze(nanmean(nanmean(temp_L_lambda,2),1)),1),[2,1,3]));
struct.L_lambda_sd      = squeeze(permute(nanmean(squeeze(nanstd(nanstd(temp_L_lambda,1,1),1,2)),1),[2,1,3]));

temp_ShearL_max         = squeeze(structure.ShearL_max).*squeeze(mask_vector_dynamic(:,:,:,:,1));
struct.ShearL_max       = permute(nanmean(squeeze(nanmean(nanmean(temp_ShearL_max,2),1)),1),[2,1]);
struct.ShearL_max_sd    = permute(nanmean(squeeze(nanstd(nanstd(temp_ShearL_max,1,1),1,2)),1),[2,1]);

temp_L_Volumetric       = squeeze(structure.L_Volumetric).*squeeze(mask_vector_dynamic(:,:,:,:,1));
struct.L_Volumetric     = permute(nanmean(squeeze(nanmean(nanmean(temp_L_Volumetric,2),1)),1),[2,1]);
struct.L_Volumetric_sd  = permute(nanmean(squeeze(nanstd(nanstd(temp_L_Volumetric,1,1),1,2)),1),[2,1]);

%strain rate Lagrange way, our regular way

temp_SR_lambda          = squeeze(structure.SR_lambda).*mask_vector_dynamic;
struct.SR_lambda        = squeeze(permute(nanmean(squeeze(nanmean(nanmean(temp_SR_lambda,2),1)),1),[2,1,3]));
struct.SR_lambda_sd     = squeeze(permute(nanmean(squeeze(nanstd(nanstd(temp_SR_lambda,1,1),1,2)),1),[2,1,3]));


temp_ShearSR_max        = squeeze(structure.ShearSR_max).*squeeze(mask_vector_dynamic(:,:,:,:,1));
struct.ShearSR_max      = permute(nanmean(squeeze(nanmean(nanmean(temp_ShearSR_max,2),1)),1),[2,1]);
struct.ShearSR_max_sd   = permute(nanmean(squeeze(nanstd(nanstd(temp_ShearSR_max,1,1),1,2)),1),[2,1]);


%strain rate Euler way (static mask)
temp_SR_E_lambda        = squeeze(structure.SR_lambda).*mask_vector_dynamic;
struct.SR_E_lambda      = squeeze(permute(nanmean(squeeze(nanmean(nanmean(temp_SR_E_lambda,2),1)),1),[2,1,3]));
struct.SR_E_lambda_sd   = squeeze(permute(nanmean(squeeze(nanstd(nanstd(temp_SR_E_lambda,1,1),1,2)),1),[2,1,3]));

temp_ShearSR_E_max      = squeeze(structure.ShearSR_max).*squeeze(mask_vector_dynamic(:,:,:,:,1));
struct.ShearSR_E_max    = permute(nanmean(squeeze(nanmean(nanmean(temp_ShearSR_E_max,2),1)),1),[2,1]);
struct.ShearSR_E_max_sd = permute(nanmean(squeeze(nanstd(nanstd(temp_ShearSR_E_max,1,1),1,2)),1),[2,1]);

%% Fractional Anisotropy (FAE) saskya
% FA (Fractional Anisotropy Euler) Strain
% Ensure the mask is replicated across the dimensions of FAE
if size(mask, 3) < size(structure.FAE, 3)
    mask = padarray(mask, [0 0 size(structure.FAE, 3) - size(mask, 3)], 'post');
elseif size(mask, 3) > size(structure.FAE, 3)
    mask = mask(:, :, 1:size(structure.FAE, 3));
end

mask_vector_dynamic = repmat(mask, [1, 1, 1, size(structure.FAE, 4)]);

% Mask the FAE data using mask_vector_dynamic
temp_FAE = structure.FAE .* mask_vector_dynamic;

% Step 5: Calculate the mean and standard deviation of FAE
struct.FAE = permute(nanmean(squeeze(nanmean(nanmean(temp_FAE, 1), 2)), 1), [2, 1]);
struct.FAE_sd = permute(nanmean(squeeze(nanstd(nanstd(temp_FAE, 1, 1), 1, 2)), 1), [2, 1]);

% FA (Fractional Anisotropy lagrain) Strain
% Ensure the mask is replicated across the dimensions of FAL
if size(mask, 3) < size(structure.FAL, 3)
    mask = padarray(mask, [0 0 size(structure.FAL, 3) - size(mask, 3)], 'post');
elseif size(mask, 3) > size(structure.FAL, 3)
    mask = mask(:, :, 1:size(structure.FAL, 3));
end

mask_vector_dynamic = repmat(mask, [1, 1, 1, size(structure.FAL, 4)]);

% Mask the FAL data using mask_vector_dynamic
temp_FAL = structure.FAL .* mask_vector_dynamic;

% Step 5: Calculate the mean and standard deviation of FAL
struct.FAL = permute(nanmean(squeeze(nanmean(nanmean(temp_FAL, 1), 2)), 1), [2, 1]);
struct.FAL_sd = permute(nanmean(squeeze(nanstd(nanstd(temp_FAL, 1, 1), 1, 2)), 1), [2, 1]);


% FA (Fractional Anisotropy Strain Rate) Strain
% Ensure the mask is replicated across the dimensions of FAL
if size(mask, 3) < size(structure.FASR, 3)
    mask = padarray(mask, [0 0 size(structure.FASR, 3) - size(mask, 3)], 'post');
elseif size(mask, 3) > size(structure.FASR, 3)
    mask = mask(:, :, 1:size(structure.FASR, 3));
end

mask_vector_dynamic = repmat(mask, [1, 1, 1, size(structure.FASR, 4)]);

% Mask the FAL data using mask_vector_dynamic
temp_FASR = structure.FASR .* mask_vector_dynamic;

% Step 5: Calculate the mean and standard deviation of FAL
struct.FASR = permute(nanmean(squeeze(nanmean(nanmean(temp_FASR, 1), 2)), 1), [2, 1]);
struct.FASR_sd = permute(nanmean(squeeze(nanstd(nanstd(temp_FASR, 1, 1), 1, 2)), 1), [2, 1]);


end