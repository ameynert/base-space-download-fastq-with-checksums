#!/usr/bin/env python

import re
import os
import sys
import shutil
import argparse
import collections
import json
import requests

def get_sample_ids(access_token, run_id):

    api_endpoint = 'https://api.basespace.illumina.com/v1pre3/runs/{}?access_token={}'

    request = requests.get(api_endpoint.format(run_id, access_token))
    output = json.loads(request.text)

    if output.has_key("Response"):
        response = output["Response"]
        if response.has_key("Properties"):
            properties = response["Properties"]
            if properties.has_key("Items"):
                items = properties["Items"]
                for item in items:
                    if item["Name"] == "Output.Samples":
                        sample_items = item["Items"]
                        for sample in sample_items:
                            print(sample["Id"] + "," + sample["Name"])
    else:
        print(json.dumps(output, indent=4, sort_keys=True))

if __name__ == "__main__":
   parser = argparse.ArgumentParser(description=""" Fetches the output sample ids from a BaseSpace run using the V1 API.""")
   parser.add_argument("access_token", metavar='Access token', nargs='?', default='.',
                                   help="Access token for BaseSpace account.")
   parser.add_argument("run_id", metavar='Run id', nargs='?', default='.',
                                   help="Numerical BaseSpace run id. ")
   args = parser.parse_args() 
   get_sample_ids(args.access_token, args.run_id)

