# base-space-download-fastq-with-checksums
Download FASTQ files from Illumina BaseSpace via the CLI with checksums

## Running

Requires bs and bs-cp from (BaseSpace Sequence Hub CLI)[https://developer.basespace.illumina.com/docs/content/documentation/cli/cli-overview] to be on the path - no Conda packages available. Start by authenticating against the account you want to download from, this has to be done interactively because it requires you to enter your credentials into the Basespace website.

The project and run names can be found in the Basespace dropdown menu MY DATA > Projects. Note that this is the run name assigned by the sequencing facility, not the run ID from the machine (e.g. 200423_NB551016_0613_AHLGWCBGXF).

Reads for all the BioSamples in the run will be downloaded to a subfolder of the output folder. The subfolder will be named using the run ID from the machine.

```
bs auth
nextflow run ameynert/base-space-download-fastq-with-checksums \
  --project <project_name> \
  --run <run_name> \
  --outdir data
```
