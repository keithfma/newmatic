function mat = newmatic(path, varargin)
% function mat = newmatic(path, varargin)
% 
% Create new MAT-file with allocated arrays and specified chunking
%
% Arguments:
%   path: path to the output file to create, will fail if file exists
%   varargin: one or more variable definition structs, as created by 
%       newmatic_variable(), see help for that function for more details
%
% Return:
%   new matfile object with specified variables allocated
% % 

assert(~isfile(path), 'Output file exists!');

mat = matfile(path, 'Writable', true);


for ii = 1:length(varargin)
    var = varargin{ii};
    allocate(mat, var.name, var.type, var.size);

end

h5repack(mat, varargin);  % TODO: replace with native version when ready


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
