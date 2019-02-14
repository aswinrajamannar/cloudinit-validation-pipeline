#!/usr/bin/python3

import argparse
import subprocess


def make_argument_parser():
    """
    Build command line argument parser.
    :return: Parser for command line
    :rtype argparse.ArgumentParser
    """

    parser = argparse.ArgumentParser(description="Test deploys/destroys an Azure image with test scenarios specified in a test yaml file")

    parser.add_argument("--managed_image_name", required=True,
            help="Name of the operating system image as a URN alias, URN, custom image name or ID, or VHD blob URI")
    parser.add_argument("--resource_group", required=True,
            help="Name of the resource group")
    parser.add_argument("--location", required=True,
            help="Location in which to create VMs and related resources")
    parser.add_argument("--testyaml", required=True,
            help="YAML file containing test scenarios")
    parser.add_argument("--subscription_id", required=True,
            help="Name or ID of subscription.")

    return parser


def main():
    args = make_argument_parser().parse_args()


if __name__ == '__main__':
    main()

