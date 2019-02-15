#!/usr/bin/python3

import argparse
import subprocess
import uuid
import yaml


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


class TestImage:

    def __init__(self, img, rg, loc, testyaml):
        self.img = img
        self.rg = rg
        self.loc = loc
        self.testyaml = testyaml

    def runtests(self):
        with open(self.testyaml) as f:
            try:
                tests = yaml.safe_load(f)
            except yaml.YAMLError as e:
                print('[!] Failed to load test yaml file: {}'.format(self.testyaml))
                raise e

            for test in tests:
                self.runtest(test)

    def runtest(self, test):
        print('[*] Test info: test: {}, image: {}, resource group: {}, location: {}'.format(
            test['test_name'], self.img, self.rg, self.loc))

        test_script_fname = test['test_script']
        cloudinit_fname = test.get('cloudinit_file')

        deployment_tester = SingleVMDeploymentTest(
                img=self.img,
                rg=self.rg,
                loc=self.loc,
                cloudinit_fname=cloudinit_fname)


class SingleVMDeploymentTest:
    def __init__(self, img, rg, loc, cloudinit_fname=None):
        self.vmname = 'cloudinittest-' + str(uuid.uuid4())
        print('[*] Deploying VM with name: {}'.format(self.vmname))

        test_user = 'dummy'
        test_pw = 'Test!' + str(uuid.uuid4())

        command = ['az', 'vm', 'create',
                '--authentication-type', 'password',
                '--admin-username', test_user,
                '--admin-password', test_pw,
                '--name', self.vmname,
                '--image', img,
                '--resource-group', rg,
                '--location', loc]
        if cloudinit_fname is not None:
            command.extend(['--custom-data', cloudinit_fname])
        print(command)

        output = subprocess.check_output(command)

        print(output)




def main():
    args = make_argument_parser().parse_args()

    print('[*] Setting subscription_id to {}'.format(args.subscription_id))
    subprocess.run(['az', 'account', 'set', '-s', args.subscription_id])

    image_tester = TestImage(
            img=args.managed_image_name,
            rg=args.resource_group,
            loc=args.location,
            testyaml=args.testyaml)

    image_tester.runtests()


if __name__ == '__main__':
    main()

