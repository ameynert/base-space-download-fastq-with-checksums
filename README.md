# BaseSpace download FASTQ with checksums

Downloads FASTQ files from Illumina BaseSpace via the CLI with md5 checksums.

## Requirements

Requires a Conda installation.

Requires bs and bs-cp from [BaseSpace Sequence Hub CLI](https://developer.basespace.illumina.com/docs/content/documentation/cli/cli-overview) to be on the path - there are no Conda packages available.

*For University of Edinburgh users only: Anaconda and the CLI is in the module system.*

```
module load anaconda
module load igmm/apps/BaseSpaceCLI/0.10.7
```

## BaseSpace access token

Log in to [BaseSpace Developers](https://developer.basespace.illumina.com/) with your BaseSpace account credentials. Create a new **native** application, call it whatever you like. Click on the 'Credentials' tab, and copy the access token from the text box. Save it somewhere, e.g. in a file `$HOME/.basespace_access_token`. This is the value you pass to the `--access_token` parameter in this pipeline.

![Your Access token](https://user-images.githubusercontent.com/6746627/135823532-8a125293-9f78-4a5d-b6bc-1424561589c5.png)

## BaseSpace authentication

Authenticate against the account you want to download from. This has to be done interactively because the command generates a URL which you need to copy & paste into a browser. You'll be directed to the Basespace website to sign in.

```
bs auth
```

## Get the run name

Log in to the BaseSpace website and look in the RUNS section for your run name. Note that this is the run name assigned by the sequencing facility, not the run ID from the machine (e.g. 200423_NB551016_0613_AHLGWCBGXF). If the run name isn't visible in the table, click through to the run page.

![Run names](https://user-images.githubusercontent.com/6746627/135824500-2752411f-0a76-4dd3-9785-43c69bb6692c.png)

## Get the project name or id

The project name can be found either in the PROJECTS section as for the run name, or by clicking through to the project page.

![Project name](https://user-images.githubusercontent.com/6746627/135824717-845cce97-8a00-4679-a90c-cd0af0413998.png)

If your run has gone through basecalling more than once, use the project id (numeric, found in the URL when viewing the project) instead of the name, as the name may be duplicated.

![Project id](https://user-images.githubusercontent.com/6746627/135824793-a926673e-726a-4a7e-b334-8e307990884f.png)

## Download the run

Reads for all the samples in the run will be downloaded to a subfolder of the output folder, named using the run ID from the machine.

The runs will be moved to a sub-folder of `<output_dir>` named by the run id (e.g. `200423_NB551016_0613_AHLGWCBGXF`) as this is more likely to be an invariant format than the run names assigned by the sequencing facility. The output folder will contain the gzipped FASTQ files for each sample, a text file of format **sample.md5sum.txt** containing the md5 checksums, a text file of format **sample.md5_check** with the results of checking those, and a text file **samples.txt** with the list of sample ids.

```
nextflow run ameynert/base-space-download-fastq-with-checksums \
  --access_token <access_token> \
  --project <project_name> \
  --run <run_name> \
  --outdir <output_dir>
```

*For sequencing from the University of Edinburgh Clinical Research Facility*

If you are downloading a NextSeq 550 run, use the command as above. For a NextSeq 2000 run, add the parameter `--dragen`. For anyone else, you may need to experiment with this flag.

