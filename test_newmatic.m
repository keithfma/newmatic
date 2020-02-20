% Unit tests for newmatic package
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


function check(testCase, fname, vars)
    % check that the MAT-file created by newmatic matches expectations
    assertTrue(testCase, isfile(fname));

    mat = matfile(fname);
    
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


% TODO: add tests for newmatic_variable

