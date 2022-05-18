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
      --access_token[str]           BaseSpace access token for authorized account

    Other options:
      --outdir [file]               The output directory where the results will be saved (sub-directory RunId will be created)
      -name [str]                   Name for the pipeline run. If not specified, Nextflow will automatically generate a random mnemonic
      --dragen                      FASTQ was output from DRAGEN BaseSpace component

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

dragen_flag = ""
if (params.dragen) {
  dragen_flag = "-d"
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
 * STEP 2 - Get the run id (from the machine)
 */
process get_run_id {

  input:

  output:
  stdout into ch_run_id

  """
  bs list run --filter-field=ExperimentName --filter-term=${params.run} --format=csv | grep -v ExperimentName | cut -d ',' -f 2
  """
}

/*
 * STEP 3 - Get the list of sample ids and names for the run
 */
  process get_samples {
  
    input:
    val(run_id) from ch_run_id
 
    output:
    stdout into ch_samples

    """
    get_sample_ids.py ${dragen_flag} ${params.access_token} ${run_id - ~/\s+/} | grep -v Undetermined | tee samples.txt
    """
  }

/*
 * Create channel for input samples
 */
ch_samples
    .splitCsv()
    .map { row -> tuple(row[0], row[1]) }
    .set { ch_biosamples }

/*
 * Split channel for input samples
 */
ch_biosamples
    .into { ch_biosamples1; ch_biosamples2 }

/*
 * Split channel for run name
 */
ch_run_name
    .into { ch_run_name1; ch_run_name2; ch_run_name3 }

/*
 * STEP 4 - Download files for each sample
 */
process download {

    validExitStatus 0,1
    maxForks 1
    publishDir "${params.outdir}/${run_name - ~/\s+/}", mode: 'move',
              saveAs: {filename ->
                  if (filename.indexOf("err") >= 0) filename
                  else if (filename.indexOf("md5") >= 0) filename
                  else if (filename.indexOf("fastq") >= 0) filename
                  else null
              }

    input:
    tuple val(sample_id), val(biosample_id) from ch_biosamples1
    val(run_name) from ch_run_name1

    output:
    file('*fastq*')
    file('*err')
    file('*md5*')
    file('*.sample.txt') into ch_sample_files1

    when:
    !params.dragen

    script:
    """
    bs-cp --write-md5 //./Projects/${params.project}/samples/${sample_id} ./ 2> ${biosample_id}.err
    md5sum --check md5sum.txt > ${biosample_id}.md5_check
    mv md5sum.txt ${biosample_id}.md5sum.txt
    echo ${biosample_id} > ${biosample_id}.sample.txt
    """
}

/*
 * STEP 4 - Download DRAGEN samples
 */
process download_dragen {

    validExitStatus 0,1
    maxForks 1
    publishDir "${params.outdir}/${run_name - ~/\s+/}", mode: 'move',
              saveAs: {filename ->
                  if (filename.indexOf("err") >= 0) filename
                  else if (filename.indexOf("md5") >= 0) filename
                  else if (filename.indexOf("fastq") >= 0) filename
                  else null
              }

    input:
    tuple val(sample_id), val(biosample_id) from ch_biosamples2
    val(run_name) from ch_run_name2

    output:
    file('*fastq*')
    file('*err')
    file('*md5*')
    file('*.sample.txt') into ch_sample_files2

    when:
    params.dragen

    script:
    """
    dataset_id=`bs list datasets --project-id=${params.project} --is-type=common.fastq --filter-term=${biosample_id}  --format=csv | grep -v DataSetType | cut -f 2 -d ',' | head -n 1`
    bs-cp --write-md5 //./Datasets/\${dataset_id} ./ 2> ${biosample_id}.err
    md5sum --check md5sum.txt > ${biosample_id}.md5_check
    mv md5sum.txt ${biosample_id}.md5sum.txt
    echo ${biosample_id} > ${biosample_id}.sample.txt
    """
}

/*
 * STEP 5 - Collect the sample names
 */
process collect_samples {

    publishDir "${params.outdir}/${run_name - ~/\s+/}", mode: 'move'

    input:
    val(run_name) from ch_run_name3
    file(files) from ch_sample_files1.collect().concat(ch_sample_files2.collect())

    output:
    file(sample_file)

    script:
    sample_file = "samples.txt"
    """
    cat ${files} >> ${sample_file}
    """
}
