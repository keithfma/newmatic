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

% TODO: second pass to set chunking


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

file_obj.(var_name) = empty(zeros(size(dimensions)));
dimensions = num2cell(dimensions);
file_obj.(var_name)(dimensions{:}) = last;
