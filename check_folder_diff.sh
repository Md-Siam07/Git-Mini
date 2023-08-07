#!/bin/bash

tc=0
# Check if the script is run with two valid folder names as arguments
if [ $# -ne 2 ]; then
  echo "Usage: $0 <path_to_folder1> <path_to_folder2>"
  exit 1
fi

# Extract the folder names from the provided arguments
folder1="$1"
folder2="$2"

# Check if the folders exist
if [ ! -d "$folder1" ] || [ ! -d "$folder2" ]; then
  echo "Error: Both folders must exist."
  exit 1
fi

is_csharp_file() {
  local file="$1"
  # Extract the file extension using substring manipulation
  extension="${file##*.}"
  # Check if the extension is ".cs"
  if [ "$extension" = "cs" ]; then
    return 0 # File is a C# file
  else
    return 1 # File is not a C# file
  fi
}

countLines() {
  if [ $# -ne 1 ]; then
    echo "Usage: $0 <path_to_csharp_file>"
    exit 1
  fi

  # Extract the file name and extension from the provided argument
  file_name="$1"
  extension="${file_name##*.}"

  # Check if the file extension is C#
  if [ "$extension" != "cs" ]; then
    echo "Error: Only C# files (with .cs extension) are supported."
    exit 1
  fi

  # Use awk to filter out lines containing comments and then count the lines of code
  lines_of_code=$(awk '/\/\*/ {in_block=1; next} in_block && /\*\// {in_block=0; next} /^\s*\/\// || /^\s*\/\*/ || in_block { next } NF { count++ } END { print count }' "$file_name")
  lines_starting_with_slash_slash=$(grep -c '^[[:space:]]*//' "$file_name")
  lines_of_code=$((lines_of_code-$lines_starting_with_slash_slash))
  # Output the result
  echo  "$lines_of_code"
  return $lines_of_code
}

# Function to compare files in two folders
compare_files() {
  folder1="$1"
  folder2="$2"
  
  # Find all files in the first folder and iterate over them
  find "$folder1" -type f | while read file1_path; do
    # Get the relative path of the file with respect to the first folder
    relative_path="${file1_path#$folder1}"
    file2_path="$folder2$relative_path"

    if ! is_csharp_file "$file2_path" || ! is_csharp_file "$file1_path"; then
      continue
    fi
    # Check if the file exists in the second folder
    if [ -f "$file2_path" ]; then
      # Compare the content of the files
      diff_result=$(diff "$file1_path" "$file2_path")
      if [ -z "$diff_result" ]; then
        continue
      else
        echo "Changes found in $relative_path:"
        echo "$diff_result"
      
        # Count the number of lines with changes in the diff_result
        added_lines=$(echo "$diff_result" | grep -E '^>')
        removed_lines=$(echo "$diff_result" | grep -E '^<') 
        added_lines_count=$(echo "$added_lines" | wc -l)
        removed_lines_count=$(echo "$removed_lines" | wc -l)
        # echo "$added_lines_count $removed_lines_count"
        total_change=$(($added_lines_count+$removed_lines_count))
        tc=$(($tc + $total_change))
        echo "added: $added_lines_count, removed: $removed_lines_count, total: $total_change"
      fi
    else
      echo "File $relative_path is deleted from the first folder."
      new_change=$(countLines "$file1_path")
      tc=$(($tc + $new_change))
      echo "total deleted lines $new_change"
    fi
  done

  # Find all files in the second folder and check for files created in the second folder
  find "$folder2" -type f | while read file2_path; do
    # Get the relative path of the file with respect to the second folder
    relative_path="${file2_path#$folder2}"
    file1_path="$folder1$relative_path"

    # Check if the file exists in the first folder
    if [ ! -f "$file1_path" ]; then
      if is_csharp_file "$file2_path"; then
        echo "File $relative_path is created in the second folder."
        new_change=$(countLines "$file2_path")
        tc=$(($tc + $new_change))
        echo "total added lines $new_change"
      fi
    fi
  done
}
# Call the function to compare files in both folders
compare_files "$folder1" "$folder2"
echo "Total changes: $tc"
