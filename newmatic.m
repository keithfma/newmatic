function mat = newmatic(out_file, varargin)
% function mat = newmatic(out_file, varargin)
% 
% Create new MAT-file with allocated arrays and specified chunking
%
% Arguments:
%   out_file: path to the output file to create, will fail if file exists
%   varargin: one or more variable definition structs, as created by 
%       newmatic_variable(), see help for that function for more details
%
% Return:
%   new matfile object with specified variables allocated
% % 

% sanity checks
validateattributes(out_file, {'char'}, {'nonempty'});
assert(~isfile(out_file), 'newmatic:OverwriteError', 'Output file exists!');

% filename for reference .mat, deleted on function exit
ref_file = [tempname, '.mat'];
ref_file_cleanup = onCleanup(@() delete(ref_file));

ref_mat = matfile(ref_file, 'Writable', true);
for ii = 1:length(varargin)
    var = varargin{ii};
    allocate(ref_mat, var.name, var.type, var.size);
end
delete(ref_mat);

% get file property lists from reference
ref_fid = H5F.open(ref_file, 'H5F_ACC_RDONLY', 'H5P_DEFAULT');
ref_fcpl = H5F.get_create_plist(ref_fid);

% create new file (fail if exists)
out_fcpl = H5P.copy(ref_fcpl);
out_fid = H5F.create(out_file, 'H5F_ACC_EXCL', out_fcpl, 'H5P_DEFAULT');

% copy datasets (a.k.a., variables), applying chunking as needed
for ii = 1:length(varargin)
    var = varargin{ii};
    
    ref_ds_id = H5D.open(ref_fid, var.name);
    
    out_ds_cpl = H5P.copy(H5D.get_create_plist(ref_ds_id));
    if ~isempty(var.chunks)
        H5P.set_chunk(out_ds_cpl, flip(var.chunks))
    end
    
    out_ds_id = H5D.create(...
        out_fid, ...
        var.name, ...
        H5D.get_type(ref_ds_id), ...
        H5D.get_space(ref_ds_id), ...
        out_ds_cpl);
    
    % copy dataset attributes
    ref_ds_info = H5O.get_info(ref_ds_id);
    
    for ref_attr_idx = 0:ref_ds_info.num_attrs - 1
       
        ref_attr_id = H5A.open_by_idx(...
            ref_fid, var.name, 'H5_INDEX_NAME', 'H5_ITER_DEC', ref_attr_idx);
    
        out_attr_id = H5A.create(...
            out_ds_id, ...
            H5A.get_name(ref_attr_id), ...
            H5A.get_type(ref_attr_id), ...
            H5A.get_space(ref_attr_id), ...
            'H5P_DEFAULT');
        H5A.write(out_attr_id, 'H5ML_DEFAULT', H5A.read(ref_attr_id));
    end
        
    H5A.close(ref_attr_id);
    H5A.close(out_attr_id);

    H5D.close(ref_ds_id);    
    H5D.close(out_ds_id);
    
end

H5F.close(ref_fid);
H5F.close(out_fid);

% copy over the userblock
% read userblock from reference
% note: the userblock is a binary header prefixed to the file, and is opaque to the HDF5
%   library. It is also essential for MATLAB to believe us that this is a valid MAT file.
ref_userblock = H5P.get_userblock(ref_fcpl);
ref_map = memmapfile(ref_file);
out_map = memmapfile(out_file, 'Writable', true);
out_map.Data(1:ref_userblock) = ref_map.Data(1:ref_userblock);

mat = matfile(out_file, 'Writable', true);


function allocate(file_obj, var_name, data_type, dimensions)
% function allocate(file_obj, var_name, data_type, dimensions)
%
% Allocate space in matfile output variable
% 
% Arguments:
%   file_obj: matfile object, open for writing
%   data_type: function handle for the variable data type, e.g., @double
%   var_name: string, name of variable to allocate in matfile
%   dimensions: 1D array, size of variable to allocate
% %
if isempty(dimensions); dimensions = [1, 1]; end 

switch data_type
    
    case 'double'
        empty = @double.empty;
        last = NaN;

    case 'single'
        empty = @single.empty;
        last = single(NaN);
        
    case 'uint8'
        empty = @uint8.empty;
        last = uint8(0);
    
    case 'logical'
        empty = @logical.empty;
        last = false;
        
    otherwise
        error('Bad value for data_type: %s', data_type);
end

file_obj.(var_name) = empty(zeros(size(dimensions)));
dimensions = num2cell(dimensions);
file_obj.(var_name)(dimensions{:}) = last;
