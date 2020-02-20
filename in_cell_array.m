function result = in_cell_array(value, array)
% function result = in_cell_array(value, array)
% 
% Return true if 'value' is found in cell array 'array', else False
% % 

result = any(cellfun(@(x) strcmp(value, x), array));
