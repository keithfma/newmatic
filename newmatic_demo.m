%% Newmatic
%
% Create new MAT-files optimized for partial reading and writing of large arrays

%% Overview
%
% The purpose of this tool is to provide more and easier control over MAT-file formatting. In
% particular, I had some performance problems with partial IO for large arrays and found the
% solutions suggested by Mathworks to be pretty clunky. The three features that |newmatic| 
% includes are:
% 
% # Creating new array variables with a specified type
% # Allocating the array size (see <https://www.mathworks.com/help/matlab/import_export/troubleshooting-file-size-increases-unexpectedly-when-growing-an-array.html here>)
% # Defining sane chunk sizes (see "Accelerate Save and Load Operations for Version 7.3 MAT-Files" <https://www.mathworks.com/help/matlab/import_export/mat-file-versions.html here>)
%
% For our test case, we will make save a relatively large 3D array to a MAT-file one "page" at a 
%   time, and then read it back in the same way. This tasks mimics the task that inspired me to 
%   write this tool, namely partial reads from a stack of image arrays.
%
% TLDR: *Using newmatic makes partial access roughly the same speed as reading/writing whole
% variables, and  does not have a significant impact on file size*. For this specific example,
% setting a sane chunk size yields ~20x speedup.
%
% Note: The fact that read timings are systematically lower than write times is likely an artifact
%  of data caching in the underlying HDF5 library (see <https://support.hdfgroup.org/HDF5/doc/H5.user/Caching.html here>).
%  Because we write before reading in this test, we likely end up reading from (fast) cache rather
%  than (slow) disk. For this reason, the _relative_ times are more important than the absolute
%  times.
%
% Here is the test data:

num_row = 2000;
num_col = 1000;
num_img = 50;

images = randi(255, num_row, num_col, num_img, 'uint8');


%% Complete read/write with native MATLAB tools
%
% As a baseline, we will use native MATLAB matfile() to write the data at once  

% get a temporary file name
native_complete_file = [tempname, '.mat'];
native_complete_cleanup = onCleanup(@() delete(native_complete_file));

% create a matfile object
native_complete_mat = matfile(native_complete_file, 'Writable', true);

% populate the file at once
tic;
native_complete_mat.images = images;
native_complete_write_time = toc;
fprintf('Native-complete, write: %.3f s\n', native_complete_write_time);

% read the images back in from the file one at a time
tic;
[~] = native_complete_mat.images;
native_complete_read_time = toc; 
fprintf('Native-complete, read: %.3f s\n', native_complete_read_time);

% get the file size
native_complete_file_size = dir(native_complete_file).bytes/1024/1024;


%% Partial read/write with native MATLAB tools
%
% Now let's try using native MATLAB matfile() to do read and write the data one image at a time
% (i.e., partial IO). This is the real use case we are interested in.

% get a temporary file name
native_partial_file = [tempname, '.mat'];
native_partial_cleanup = onCleanup(@() delete(native_partial_file));

% create a matfile object
native_partial_mat = matfile(native_partial_file, 'Writable', true);

% allocate the array
%   see: https://www.mathworks.com/help/matlab/import_export/troubleshooting-file-size-increases-unexpectedly-when-growing-an-array.html
native_partial_mat.images = uint8.empty(0, 0, 0);
native_partial_mat.images(num_row, num_col, num_img) = uint8(0);

% populate the file one image at a time
tic;
for ii = 1:num_img
    native_partial_mat.images(:, :, ii) = images(:, :, ii);
end
native_partial_write_time = toc;
fprintf('Native-partial, write: %.3f s\n', native_partial_write_time);

% read the images back in from the file one at a time
tic;
for ii = 1:num_img
    [~] = native_partial_mat.images(:, :, ii);
end
native_partial_read_time = toc;
fprintf('Native-partial, read: %.3f s\n', native_partial_read_time);

% get the file size
native_partial_file_size = dir(native_partial_file).bytes/1024/1024;


%% Partial read/write with newmatic
%
% Now for the good stuff. Let's use |newmatic| to create our file, and then read and write the data
% one image at a time. We will choose a chunk size that neatly matches our planned access pattern
% (i.e, an image).

% get a temporary file name
newmatic_partial_file = [tempname, '.mat'];
newmatic_partial_cleanup = onCleanup(@() delete(newmatic_partial_file));

% create a matfile object with newmatic
var_size = [num_row, num_col, num_img];
var_chunk = [num_row, num_col, 1];
newmatic_partial_mat = newmatic(newmatic_partial_file, newmatic_variable('images', 'uint8', var_size, var_chunk));

% populate the file one image at a time
tic;
for ii = 1:num_img
    newmatic_partial_mat.images(:, :, ii) = images(:, :, ii);
end
newmatic_partial_write_time = toc;
fprintf('Newmatic-partial, write: %.3f s\n', newmatic_partial_write_time);

% read the images back in from the file one at a time
tic;
for ii = 1:num_img
    [~] = newmatic_partial_mat.images(:, :, ii);
end
newmatic_partial_read_time = toc;
fprintf('Newmatic-partial, read: %.3f s\n', newmatic_partial_read_time);

% get the file size
newmatic_partial_file_size = dir(newmatic_partial_file).bytes/1024/1024;


%% Complete read/write with newmatic
%
% To round out the comparison, let's read/write whole variables using newmatic

% get a temporary file name
newmatic_complete_file = [tempname, '.mat'];
newmatic_complete_cleanup = onCleanup(@() delete(newmatic_complete_file));

% create a matfile object with newmatic
var_size = [num_row, num_col, num_img];
var_chunk = [num_row, num_col, 1];
newmatic_complete_mat = newmatic(newmatic_complete_file, newmatic_variable('images', 'uint8', var_size, var_chunk));

% populate the file at-once
tic;
newmatic_complete_mat.images = images;
newmatic_complete_write_time = toc;
fprintf('Newmatic-complete, write: %.3f s\n', newmatic_complete_write_time);

% read the images back in from the file at-once
tic;
[~] = newmatic_complete_mat.images;
newmatic_complete_read_time = toc;
fprintf('Newmatic-complete, read: %.3f s\n', newmatic_complete_read_time);

% get the file size
newmatic_complete_file_size = dir(newmatic_complete_file).bytes/1024/1024;


%% Comparison
%
% To make the comparison a bit easier, check out the tabulated results below:

results = table(...
    round([native_complete_write_time; newmatic_complete_write_time; native_partial_write_time; newmatic_partial_write_time], 2), ...
    round([native_complete_read_time; newmatic_complete_read_time; native_partial_read_time; newmatic_partial_read_time], 2), ...
    round([native_complete_file_size; newmatic_complete_file_size; native_partial_file_size; newmatic_partial_file_size], 2), ...
    'RowNames', {'native-complete', 'newmatic-complete', 'native-partial', 'newmatic-partial'}, ...
    'VariableNames', {'write-time-seconds', 'read-time-seconds', 'file-size-MB'}...
    );
disp(results);


