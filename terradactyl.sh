#! /bin/bash

SERVICE_ACCOUNT="test-service-account@test.gserviceaccount.com"
SERVICE_CREDENTIALS="$(pwd)/service_account.json"
INPUT_METADATA=""
CONCURRENT_JOBS=10
while getopts "a:s:m:c:" opt; do
    case $opt in
        a) SERVICE_ACCOUNT="$OPTARG"
        ;;
        s) SERVICE_CREDENTIALS="$OPTARG"
        ;;
        m) INPUT_METADATA="$OPTARG"
        ;;
        c) CONCURRENT_JOBS="$OPTARG"
        ;;
    esac
done

# Check if the variable is set and the file exists
if [[ -z "$SERVICE_ACCOUNT" && -z "$SERVICE_CREDENTIALS" && -z "$INPUT_METADATA" ]]; then
    echo "The -a -s and -m options are required."
    exit 1
fi

if [[ ! -f "$INPUT_METADATA" ]]; then
    echo "The specified INPUT_METADATA file does not exist: $INPUT_METADATA"
    exit 1
fi

if [[ ! -f "$SERVICE_CREDENTIALS" ]]; then
    echo "The specified SERVICE_CREDENTIAL file does not exist: $SERVICE_CREDENTIALS"
    exit 1
fi

JOBFOLDER="terradactyl_$(openssl rand -hex 5)"

# Cleanup steps
cleanup() {
    rm -r "$JOBFOLDER"
}

# Set a trap to execute the cleanup function on EXIT
trap cleanup EXIT

mkdir -p $JOBFOLDER/tmp

#de-duplicate rows
awk -F, 'BEGIN {OFS=","} NR == 1 {for (i=1; i<=NF; i++) col[$i] = i} !seen[$col["Sample ID"], $col["Latitude"], $col["Longitude"], $col["Sample Date"], $col["Spatial Uncertainty"]]++' "$INPUT_METADATA" > "$JOBFOLDER/deduplicate_metadata.csv"

DEDUPLICATE_METADATA="$JOBFOLDER/deduplicate_metadata.csv"

header=$(head -n 1 $DEDUPLICATE_METADATA)

OUTPUT_METADATA="MetadataOutput_Metabarcoding.csv"
# split input file
tail -n +2 $DEDUPLICATE_METADATA | split -l 1 - $JOBFOLDER/tmp/temp_
for file in $JOBFOLDER/tmp/temp_*; do
    if [[ ! "$file" =~ \.csv$ ]]; then
        (echo "$header"; cat "$file") > "${file}.csv"
        rm $file
    fi
done

# run metadata_extractor.py in parallel
echo "Processing $(basename $INPUT_METADATA) ..."
parallel -j $CONCURRENT_JOBS "output_file=\$(mktemp); echo \$output_file; cat {}; retries=3; while ((retries > 0)); do python terradactyl.py --input {} --output \$output_file --account $SERVICE_ACCOUNT --credentials $SERVICE_CREDENTIALS && if [[ -s \$output_file ]]; then tail -n +2 \$output_file | cat >> $JOBFOLDER/output.txt; head -n 1 \"\$output_file\" | cat > $JOBFOLDER/headers.txt; break; else ((retries--)); fi; done; rm \$output_file" ::: $JOBFOLDER/tmp/temp_*.csv
echo "Done."

# combine headers and outfile
cat "$JOBFOLDER/headers.txt" "$JOBFOLDER/output.txt" > $JOBFOLDER/$OUTPUT_METADATA

#cleanup
cleanup
