# newmatic

**Create new MAT-files optimized for partial reading and writing of large arrays.**

This tool solves a few problems I ran into when using
[matfile](https://www.mathworks.com/help/matlab/ref/matlab.io.matfile.html),
namely:

+ *Inability to control data chunking*: Arrays in MAT-files are saved in
"chunks". The most natural and performant way to read/write to these arrays is
to access one chunk at a time. MATLAB chooses the chunk size automatically,
and it may (read: almost certainly) not be the most efficient choice for
your workload. The recommended solution is to use third-party tools to
"repack" your MAT-file after you create it (see section "Accelerate Save and
Load Operations for Version 7.3 MAT-Files" in the [MAT-file versions](https://www.mathworks.com/help/matlab/import_export/mat-file-versions.html)
documentation). This should make us all sad.

+ *Repetitive and cryptic [array size initialization](https://www.mathworks.com/help/matlab/import_export/troubleshooting-file-size-increases-unexpectedly-when-growing-an-array.html)*:
Assigning a value to the very last element in the array serves a similar
purpose as pre-allocating arrays for in-memory variables. The recommended
approach is fine, but not easy for the uninitiated to parse and ugly to look at.

Fortunately, (a) MAT-files are HDF5 formatted under the hood, and (b) MATLAB
includes utilities for working with HDF5 files directly (i.e., without any
external tools). `newmatic` provides an alternative interface for creating
"customized" MAT-files that perform well for partial IO. 

