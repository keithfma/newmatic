% Unit tests for newmatic_variable function
%
% Usage:
%   results = runtests(test_newmatic.m);
% %

function tests = test_newmatic_variable()
    % returns handles to test functions from this file (i.e., those that begin with "test")
    tests = functiontests(localfunctions);
end


function test_newmatic_variable_basic(testCase)
    % size and chunks default to []
    var = newmatic_variable('test', 'double');
    assertTrue(testCase, isempty(var.size));
    assertTrue(testCase, isempty(var.chunks));
    
    % returns what you pass in
    name = 'test';
    dtype = 'double';
    sz = [1, 2, 3];
    chunks = [1, 1, 1];
    var = newmatic_variable(name, dtype, sz, chunks);
    assertTrue(testCase, strcmp(name, var.name));
    assertTrue(testCase, strcmp(dtype, var.type));
    assertTrue(testCase, all(sz == var.size));
    assertTrue(testCase, all(chunks == var.chunks));
end


function test_newmatic_variable_validatation(testCase)
    % name: wrong type
    assertError(testCase, @() newmatic_variable(5, 'double'), 'MATLAB:invalidType');
    
    % name: empty
    assertError(testCase, @() newmatic_variable('', 'double'), 'MATLAB:expectedNonempty');

    % type: wrong type
    assertError(testCase, @() newmatic_variable('test', 5), 'MATLAB:invalidType');
   
    % type: not supported
    assertError(testCase, @() newmatic_variable('test', 'not-a-type'), 'newmatic:unknownDataType')

    % size: wrong type
    assertError(testCase, @() newmatic_variable('test', 'double', 9.9), 'MATLAB:expectedInteger');

    % chunks: wrong type
    assertError(testCase, @() newmatic_variable('test', 'double', [], 9.9), 'MATLAB:expectedInteger');

    % mismatched size and chunks
    assertError(testCase, @() newmatic_variable('test', 'double', [3, 3], 3), ...
        'newmatic:MismatchedSizeAndChunks');
end
