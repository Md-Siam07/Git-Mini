#!/bin/bash

# Check if the script is run with two valid file names as arguments
if [ $# -ne 2 ]; then
  echo "Usage: $0 <path_to_file1> <path_to_file2>"
  exit 1
fi

# Extract the file names from the provided arguments
file1="$1"
file2="$2"

# Check if the files exist
if [ ! -f "$file1" ] || [ ! -f "$file2" ]; then
  echo "Error: Both files must exist."
  exit 1
fi

# Use diff command to get the difference between the two files and store it in a variable
diff_result=$(diff "$file1" "$file2")

# Use grep to find added lines (lines present only in the second file)
added_lines=$(echo "$diff_result" | grep -E '^>')

# Use grep to find removed lines (lines present only in the first file)
removed_lines=$(echo "$diff_result" | grep -E '^<')

# Count the number of lines in each category
added_lines_count=$(echo "$added_lines" | wc -l)
removed_lines_count=$(echo "$removed_lines" | wc -l)

# Print the results
echo "Added lines:"
echo "$added_lines"

echo -e "\nRemoved lines:"
echo "$removed_lines"

echo -e "\nModified lines:"
echo "$modified_lines"

# Calculate the total change count
total_change=$((added_lines_count + removed_lines_count))

echo "Added lines count: $added_lines_count"
echo "Removed lines count: $removed_lines_count"
echo -e "\nTotal change count: $total_change"
