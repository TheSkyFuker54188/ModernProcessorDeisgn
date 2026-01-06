#! /usr/bin/env python

import re
import json
import os
import sys
import glob
from termcolor import colored

from typing import *

class MetaConfig:
    compiler: Literal['vivado', 'iverilog']
    test_file: str
    data_path: str
    code_path: str
    byte_code_file_path: bytes
    vivado_testbench_file: str

    def __init__(self):
        pass
    
    @staticmethod
    def from_object(obj: Dict[str, object]) -> "MetaConfig":
        ret = MetaConfig()
        ret.compiler = obj['compiler']
        ret.test_file = obj['test_file']
        ret.data_path = obj['data_path']
        ret.code_path = obj['code_path']

        return ret

def prepareMeta(json_filename) -> MetaConfig:
    json_dir_path = os.path.dirname(json_filename)

    with open(json_filename) as fin:
        metaConfig = MetaConfig.from_object(json.load(fin))

    os.chdir(json_dir_path)
    metaConfig.code_path = os.path.abspath(metaConfig.code_path)
    metaConfig.test_file = os.path.abspath(metaConfig.test_file)
    metaConfig.data_path = os.path.abspath(metaConfig.data_path)

    print(f"Checking {json_filename}")

    if metaConfig.compiler not in ['vivado', 'iverilog']:
        print(colored(f"Unknown compiler: {metaConfig.compiler}", 'red'))

    if not os.path.exists(metaConfig.test_file):
        print(
            colored(f"test_file {metaConfig.test_file} doesn't exist", 'red'))

    if metaConfig.compiler == 'vivado':
        if not metaConfig.test_file.endswith('.xpr'):
            print(
                colored(f"test_file {metaConfig.test_file} has wrong extension name", 'red'))

    if not os.path.exists(metaConfig.data_path):
        print("data_path", metaConfig.data_path, "doesn't exist")

    if not os.path.exists(metaConfig.code_path):
        print(
            colored(f"code_path {metaConfig.code_path} doesn't exist", 'red'))

    with open(metaConfig.code_path, 'rb') as fin:
        im_content = fin.read()

    if metaConfig.compiler == 'vivado' and not metaConfig.code_path.startswith(os.path.dirname(metaConfig.test_file)):
        print(colored(
            f"{metaConfig.code_path} not starts with {os.path.dirname(metaConfig.test_file)}", "yellow"))

    mips_tb_count = 0
    for filename in glob.iglob('**/mips_tb.v', recursive=True):
        print(colored(f"Found mips_tb.v: {filename}", 'green'))
        mips_tb_count += 1
    if mips_tb_count > 1:
        print(colored("More than one mips_tb.v found", 'red'))

    if metaConfig.compiler == 'vivado':
        print(colored("The compiler is Vivado. Please ensure that there is one and only one sim_1 folder under Simulation Sources, which contains one mips_tb.v, and that mips_tb.v is the top-level design.", "yellow"))
    
    filelist = []
    filelist.extend(glob.glob('**/*.v', recursive=True))
    filelist.extend(glob.glob('**/*.sv', recursive=True))
    filelist.extend(glob.glob('**/*.vh', recursive=True))

    for filename in filelist:
        with open(filename, "rb") as fin:
            content = fin.read()
        content = re.sub(rb"`timescale.*", b"`timescale 1us/1us", content)
        if not re.match(rb"`timescale\s+1us\s*/\s*1us", content):
            print(colored(f"Please add \"`timescale 1us/1us\" to the beginning of the file ({filename}) to speed up the simulation.", 'red'))
    
    with open(metaConfig.code_path, 'rb') as fin:
        code_file_content = fin.read()

        matches = re.search(rb'^\s*\$\s*readmemh\s*\(\s*"([^"]+)"', code_file_content, re.IGNORECASE | re.MULTILINE)
        code_file_name = matches.groups()[0] if matches is not None else None

        if code_file_name is not None:
            metaConfig.byte_code_file_path = code_file_name
            print(colored(f"Found readmemh in file: {metaConfig.code_path}", 'green'))
        else:
            print(colored(f'readmemh pattern not found in {metaConfig.code_path}', 'red'))
    
    return metaConfig

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python check.py <meta.json>")
        sys.exit(1)
    
    prepareMeta(sys.argv[1])
