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

% TODO: reduce single use vars
% TODO: move to own function

% get file property lists from reference
ref_fid = H5F.open(ref_file, 'H5F_ACC_RDONLY', 'H5P_DEFAULT');
ref_fcpl = H5F.get_create_plist(ref_fid);

% create new file (fail if exists)
out_fcpl = H5P.copy(ref_fcpl);
out_fid = H5F.create(out_file, 'H5F_ACC_EXCL', out_fcpl, 'H5P_DEFAULT');

% copy over datasets (a.k.a., variables), applying chunking as needed
for ii = 1:length(varargin)
    var = varargin{ii};
    
    ref_ds_id = H5D.open(ref_fid, var.name);
    ref_ds_type = H5D.get_type(ref_ds_id);
    ref_ds_space = H5D.get_space(ref_ds_id);
    ref_ds_cpl = H5D.get_create_plist(ref_ds_id);
    
    out_ds_cpl = H5P.copy(ref_ds_cpl);
    H5P.set_chunk(out_ds_cpl, flip(var.chunks))
    out_ds_id = H5D.create(out_fid, var.name, ref_ds_type, ref_ds_space, out_ds_cpl);
    
    % note: assume that only this one attribute exists (cribbed from manual inspection of files
    %   created by matfile function)
    ref_attr_id = H5A.open(ref_ds_id, 'MATLAB_class');
    ref_attr_type = H5A.get_type(ref_attr_id);
    ref_attr_space = H5A.get_space(ref_attr_id);
    ref_attr_data = H5A.read(ref_attr_id);
    
    out_attr_id = H5A.create(out_ds_id, 'MATLAB_class', ref_attr_type, ref_attr_space, 'H5P_DEFAULT');
    H5A.write(out_attr_id, 'H5ML_DEFAULT', ref_attr_data);
    
    H5A.close(ref_attr_id);
    H5D.close(ref_ds_id);
    
    H5A.close(out_attr_id);
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


function h5repack(file_obj, vars)
% Apply specified chunking using external utility h5repack
%
% note: requires h5repack be installed on system
%
% Arguments:
%   file_obj: matfile object
%   vars: one or more variable definition structs, as created by 
%       newmatic_variable(), see help for that function for more details
% %     
path = file_obj.Properties.Source;

chunk_args = {};
for ii = 1:length(vars)
    var = vars{ii};
    if ~isempty(var.chunks)
        chunks = var.chunks(end:-1:1);  % variable dimensions are inverted in HDF file by MATLAB
        chunk_args{end+1} = sprintf('-l %s:CHUNK=%s', var.name, strjoin(string(chunks), 'x')); %#ok!
    end
end

if ~isempty(chunk_args)

    temp_file = [tempname, '.mat'];
    
    args = [{'h5repack', '-i', path, '-o', temp_file}, chunk_args];
    cmd = strjoin(args, ' ');
    fprintf('%s\n', cmd);
   
    status = system(cmd);
    assert(status == 0, 'Failed to update chunks with h5repack system utility');

    status = movefile(temp_file, path);
    assert(status == 1, 'Failed to overwrite original file');
end
    

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

if ~isempty(dimensions) 
    file_obj.(var_name) = empty(zeros(size(dimensions)));
    dimensions = num2cell(dimensions);
    file_obj.(var_name)(dimensions{:}) = last;
else
    % handle unspecified size by creating an empty array of the correct type
    file_obj.(var_name) = empty();
end
