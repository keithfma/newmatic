function var = newmatic_variable(name, data_type, sz, chunks)
% function var = newmatic_variable(name, data_type, sz, chunks)
% 
% Create variable specification structure for use with newmatic() function
%
% Arguments:
%   name: string, name of the variable
%   data_type: string, variable data type, e.g., 'single'
%   sz: vector of integers, size of the variable array, can be set to [] to
%       skip defining the array size, default is []
%   chunks: vector of integers, chunk size for the data in the stored array, can
%       be set to [] to skip defining chunk size, default is []
% %

SUPPORTED_DATA_TYPES = {
    'single', ...
    'double', ...
    'int8', ...
    'int16', ...
    'int32'	, ...
    'int64'	, ...
    'uint8'	, ...
    'uint16', ...
    'uint32', ...
    'uint64', ...
    'logical'};

narginchk(1, 4);

% set defaults
if nargin < 2; data_type = 'double'; end
if nargin < 3; sz = []; end
if nargin < 4; chunks = []; end

% sanity checks
validateattributes(name, {'char'}, {'nonempty'});

validateattributes(data_type, {'char'}, {'nonempty'});
assert(in_cell_array(data_type, SUPPORTED_DATA_TYPES), ...
    'newmatic:unknownDataType', 'Unknown data type');

if ~isempty(sz)
    validateattributes(sz, {'numeric'}, {'integer', 'vector'});
end

if ~isempty(chunks)
    validateattributes(chunks, {'numeric'}, {'integer', 'vector'});
end

if ~isempty(sz) && ~isempty(chunks)
    assert(length(sz) == length(chunks), ...
        'newmatic:MismatchedSizeAndChunks', 'Size and chunks length must match');
end

var = struct(...
    'name', name, ...
    'type', data_type, ...
    'size', sz, ...
    'chunks', chunks);


function result = in_cell_array(value, array)
% Return true if 'value' is found in cell array 'array', else False
result = any(cellfun(@(x) strcmp(value, x), array));