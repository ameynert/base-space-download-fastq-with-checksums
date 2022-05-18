#!/usr/bin/env python
from __future__ import print_function
import re
import os
import sys
import shutil
import argparse
import collections
import json
import requests

def get_sample_ids(access_token, run_id, dragen):

    api_endpoint = 'https://api.basespace.illumina.com/v1pre3/runs/{}?access_token={}'

    request = requests.get(api_endpoint.format(run_id, access_token))
    output = json.loads(request.text)

    if "Response" in output:
        response = output["Response"]
        if "Properties" in response:
            properties = response["Properties"]
            if "Items" in properties:
                items = properties["Items"]
                has_output_samples = 0
                if dragen:
                    for item in items:
                        if item["Name"] == "Input.BioSamples":
                            has_output_samples = 1
                            sample_items = item["Items"]
                            for sample in sample_items:
                                print(sample["Id"] + "," + sample["UserSampleId"])
                else:
                    for item in items:
                        if item["Name"] == "Output.Samples":
                            has_output_samples = 1
                            sample_items = item["Items"]
                            for sample in sample_items:
                                print(sample["Id"] + "," + sample["Name"])
                if not has_output_samples:
                    print("No Output.Samples item found in response", file=sys.stderr)
                    print(json.dumps(output, indent=4, sort_keys=True), file=sys.stderr)
                    exit(1)
            else:
                print(json.dumps(output, indent=4, sort_keys=True), file=sys.stderr)
                exit(1)
        else:
            print(json.dumps(output, indent=4, sort_keys=True), file=sys.stderr)
            exit(1)
    else:
        print(json.dumps(output, indent=4, sort_keys=True), file=sys.stderr)
    exit(1)

if __name__ == "__main__":
   parser = argparse.ArgumentParser(description=""" Fetches the output sample ids from a BaseSpace run using the V1 API.""")
   parser.add_argument("access_token", metavar='Access token', nargs='?', default='.',
                                   help="Access token for BaseSpace account.")
   parser.add_argument("run_id", metavar='Run id', nargs='?', default='.',
                                   help="Numerical BaseSpace run id. ")
   parser.add_argument("-d", "--dragen", help="FASTQ generated by DRAGEN", action="store_true")
   args = parser.parse_args()
   get_sample_ids(args.access_token, args.run_id, args.dragen)

