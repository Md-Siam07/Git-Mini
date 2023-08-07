# Check if the script is run with a valid C# file name as an argument
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
echo "Number of lines of uncommented code in $file_name: $lines_of_code"
