#!/usr/bin/env nextflow
/*
========================================================================================
                         base-space-download-fastq-with-checksums
========================================================================================
 https://github.com/ameynert/base-space-download-fastq-with-checksums
----------------------------------------------------------------------------------------
*/

def helpMessage() {
    log.info"""
    Usage:

    The typical command for running the pipeline is as follows:

    bs auth # must be run first as requires authentication via browser
    nextflow run ameynert/base-space-download-fastq-with-checksums --project my_basespace_project --samples sample_list.txt

    Mandatory arguments:
      --project [str]               BaseSpace project name
      --run [str]                   BaseSpace run name (ExperimentName, not RunId)

    Other options:
      --outdir [file]               The output directory where the results will be saved (sub-directory RunId will be created)
      -name [str]                   Name for the pipeline run. If not specified, Nextflow will automatically generate a random mnemonic

    """.stripIndent()
}

// Show help message
if (params.help) {
    helpMessage()
    exit 0
}

/*
 * SET UP CONFIGURATION VARIABLES
 */

// Has the run name been specified by the user?
//  this has the bonus effect of catching both -name and --name
custom_runName = params.name
if (!(workflow.runName ==~ /[a-z]+_[a-z]+/)) {
    custom_runName = workflow.runName
}

if (!params.project) {
    exit 1, "Project name not specified!"
}

if (!params.run) {
    exit 1, "Run name not specified"
}

/*
 * STEP 1 - Get the run name (from the machine)
 */
process get_run_name {

  input:

  output:
  stdout into ch_run_name

  """
  bs list run --filter-field=ExperimentName --filter-term=${params.run} --format=csv | grep -v ExperimentName | cut -d ',' -f 1
  """
}

/*
 * STEP 2 - Get the list of BioSample ids for this run
 */
process get_biosamples {
  
  input:
  
  output:
  file('biosample_ids.txt') into ch_input

  """
  bs run property get --property-name="Input.BioSamples" --name=${params.run} --terse > biosample_ids.txt
  """
}

/*
 * Create channel for input samples
 */
ch_input
    .splitText()
    .set { ch_samples }

/*
 * STEP 3 - Download files for each sample
 */
process download {

    maxForks 1
    publishDir "${params.outdir}"

    input:
    val(biosample_id) from ch_samples
    val(run_name) from ch_run_name

    output:
    file('*')

    script:
    """
    mkdir ${run_name}
    cd ${run_name}
    biosample_name=`bs list biosample --filter-field=Id --format csv --template='{{.BioSampleName}}' --filter-term=${biosample_id}`
    bs-cp --write-md5 //./Projects/${params.project}/samples/\${biosample_name} ./
    md5sum --check md5sum.txt > \${biosample_name}.md5_check
    mv md5sum.txt \${biosample_name}.md5sum.txt
    """
}

