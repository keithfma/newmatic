% Unit tests for newmatic function
%
% Usage:
%   results = runtests(test_newmatic.m);
% %


function tests = test_newmatic()
    % returns handles to test functions from this file (i.e., those that begin with "test")
    tests = functiontests(localfunctions);
end


function setup(testCase)
    % per-test fixture
    testCase.TestData.filename = [tempname, '.mat'];
end


function teardown(testCase)
    % per-test fixture cleanup
    delete(testCase.TestData.filename);
end


function result = in_cell_array(value, array)
    % return true if 'value' is found in cell array 'array', else False
    result = any(cellfun(@(x) strcmp(value, x), array));
end
    
    
function check(testCase, fname, vars)
    % check that the MAT-file created by newmatic matches expectations
    assertTrue(testCase, isfile(fname));

    mat = matfile(fname);
    
    mat_info = h5info(fname);
    mat_chunks = containers.Map();
    for ii = 1:length(mat_info.Datasets)
        mat_chunks(mat_info.Datasets(ii).Name) = mat_info.Datasets(ii).ChunkSize;
    end
    
    for ii = 1:length(vars)
        var = vars(ii);
       
        % variable exists?
        assertTrue(testCase, in_cell_array(var.name, who(mat)));
        
        % variable data type matches expectations?
        assertTrue(testCase, strcmp(var.type, class(mat.(var.name))));
        
        % variable size matches expectations?
        if ~isempty(var.size)
            assertEqual(testCase, length(var.size), length(size(mat, var.name)));
            assertTrue(testCase, all(var.size == size(mat, var.name)));
        end
        
        % variable chunking matches expectations?
        if ~isempty(var.chunks)
            assertTrue(testCase, all(var.chunks == mat_chunks(var.name)));
        end
        
    end

end


function test_single_variable_nosize_nochunks(testCase)
    fname = testCase.TestData.filename;    
    var = newmatic_variable('x', 'single');
    newmatic(fname, var);
    check(testCase, fname, var);
end
    

function test_single_variable_nochunks(testCase)
    fname = testCase.TestData.filename;    
    var = newmatic_variable('x', 'single', [10, 20, 30]);
    newmatic(fname, var);
    check(testCase, fname, var);
end


function test_single_variable(testCase)
    fname = testCase.TestData.filename;    
    var = newmatic_variable('x', 'single', [10, 20, 30], [10, 10, 10]);
    newmatic(fname, var);
    check(testCase, fname, var);
end


function test_multi_variable_nosize_nochunks(testCase)
    fname = testCase.TestData.filename;
    vars = {...
        newmatic_variable('x', 'uint8'), ...
        newmatic_variable('y', 'single'), ...
        newmatic_variable('z', 'double')};
    newmatic(fname, vars{:});
    check(testCase, fname, cell2mat(vars));
end
        

function test_multi_variable_nochunks(testCase)
    fname = testCase.TestData.filename;
    vars = {...
        newmatic_variable('x', 'uint8', [30, 20]), ...
        newmatic_variable('y', 'single', [5, 10]), ...
        newmatic_variable('z', 'double', [40, 50, 10])};
    newmatic(fname, vars{:});
    check(testCase, fname, cell2mat(vars));
end
   

function test_multi_variable(testCase)
    fname = testCase.TestData.filename;
    vars = {...
        newmatic_variable('x', 'uint8', [30, 20], [15, 10]), ...
        newmatic_variable('y', 'single', [5, 10], [5, 5]), ...
        newmatic_variable('z', 'double', [40, 50, 10], [10, 10, 10])};
    newmatic(fname, vars{:});
    check(testCase, fname, cell2mat(vars));
end
   

function test_input_validation(testCase)
    a_var = newmatic_variable('x', 'double');

    % path type incorrect
    assertError(testCase, @() newmatic(5, a_var), 'MATLAB:invalidType');

    % protect against overwriting
    fname = testCase.TestData.filename;
    fclose(fopen(fname, 'w'));  % create file by touching it
    assertError(testCase, @() newmatic(fname, a_var), 'newmatic:OverwriteError');
end


function test_preserve_logical_dtype(testCase)
    fname = testCase.TestData.filename;
    mat = newmatic(fname, newmatic_variable('x', 'logical', [100, 200], [50, 100]));
    mat.x(:, :) = false(100, 200);
    
    % data read back from file should still be logical
    assertClass(testCase, mat.x, 'logical');
end
    