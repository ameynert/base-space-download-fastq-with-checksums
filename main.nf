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
      --samples [file]              List of samples ids, one per line

    Other options:
      --outdir [file]               The output directory where the results will be saved
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

if (params.samples) {
    ch_input = file(params.samples, checkIfExists: true)
} else {
    exit 1, "List of samples not specified!"
}

if (!params.project) {
    exit 1, "Project name not specified!"
}

/*
 * Create channel for input samples
 */
ch_input
    .splitText()
    .into { ch_samples }

/*
 * STEP 1 - Download files for each sample
 */
process download {

    maxForks 1
    publishDir "${params.outdir}"

    input:
    set val(name) from ch_samples

    output:
    set val(name), file('*.fastq.gz') into ch_

    script:
    """
    bs-cp --write-md5 //./Projects/${params.project}/samples/${name} ./
    md5sum --check md5sum.txt > ${name}.md5_check
    mv md5sum.txt ${name}.md5sum.txt
    """
}
