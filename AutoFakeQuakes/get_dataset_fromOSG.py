# Copyright: Marcus Adair, Ivan Rodero, University of Utah, SCI Institute
#
# This file SSHs into OSG and grabs a tarball called inputfiles.tar.gz from
# the requested dataset folder in OSG

import paramiko
import sys

def main(arg1):

    dataset = str(arg1)

    # SSH into OSG
    host = "login05.osgconnect.net"
    username = "marcus_adair"
    password = "12345"
    ssh_client = paramiko.client.SSHClient()
    ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh_client.connect(host, username=username, password=password)

    print('Transferring files as inputfiles.tar.gz from the data set: ' + dataset)


    # Retrieve the tarball containing the input files from the requested dataset:

    # open  a client to transfer the output txt file to the local machine
    sftp_client=ssh_client.open_sftp()

    # set up the paths
    remotepath = '/home/marcus_adair/fakequakes_datasets/' + dataset + '/inputfiles.tar.gz'
    localpath = './inputfiles.tar.gz'

    # do the transfer
    sftp_client.get(remotepath, localpath)
    sftp_client.close()

    # close the file objects
    #stdin.close()
    #stdout.close()
    #stderr.close()

    # close the connection
    ssh_client.close()


if __name__== "__main__":
    main(sys.argv[1])
