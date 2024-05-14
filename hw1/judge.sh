make scanner
./scanner < $1 > output
golden_scanner < $1 > golden_output
diff output golden_output