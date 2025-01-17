#!/usr/bin/env bash

scriptDir=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

[ ! -z ${ATLASPROD_PATH+x} ] || ( echo "Env var ATLASPROD_PATH path to the directory needs to be defined." && exit 1 )
[ ! -z ${BASELINE_META_DESTINATION+x} ] || ( echo "Env var BASELINE_META_DESTINATION path to the baseline baseline meta analysis directory needs to be defined." && exit 1 )
[ ! -z ${CELLTYPE_STUDIES+x} ] || ( echo "Env var CELLTYPE_STUDIES comma separated cell types baseline studies needs to be defined." && exit 1 )
[ ! -z ${TISSUE_STUDIES+x} ] || ( echo "Env var TISSUE_STUDIES comma separated tissue baseline studies needs to be defined." && exit 1 )
[ ! -z ${ATLAS_EXPS+x} ] || ( echo "Env var ATLAS_EXPS path to the staging directory needs to be defined." && exit 1 )


export outpath_path=${BASELINE_META_DESTINATION}/baseline_metanalysis_output_$(date "+%Y-%m-%d")
mkdir -p "$outpath_path"

# Set path (this is done at this level since this will be executed directly):
for mod in data-exports-bulk/bin; do
    export PATH=$ATLASPROD_PATH/$mod:$PATH
done

## Run the normalisation and batch correction of gtex and associated studies
RUV_normalisation.R "$TISSUE_STUDIES" "tissues" "$outpath_path"
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to normalise Gtex associated studies"
    exit 1
fi

## Run the normalisation and batch correction of blueprint studies
RUV_normalisation.R "$CELLTYPE_STUDIES" "cell_types" "$outpath_path"
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to normlalise blueprint associated studies"
    exit 1
fi

## combine corrected gtex and blueorint
RUV_combine.R "tissues" "cell_types" "$outpath_path"
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to combine studies"
    exit 1
fi

