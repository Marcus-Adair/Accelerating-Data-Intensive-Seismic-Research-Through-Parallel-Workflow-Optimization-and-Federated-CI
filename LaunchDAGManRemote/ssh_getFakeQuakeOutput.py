# Copyright: Marcus Adair, Ivan Rodero, University of Utah, SCI Institute
#
# This file SSHs into OSG,  Zips up the output dir with all the requested run
# files, and retrieves it back into the current directory

import paramiko
import sys

def main(arg1):

    dirname = str(arg1)

    # SSH into OSG
    host = "login05.osgconnect.net"
    username = "marcus_adair"
    password = "12345"
    ssh_client = paramiko.client.SSHClient()
    ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh_client.connect(host, username=username, password=password)

    cmmd = "sh movelastdagfiles_and_zip_v2_4.sh " + dirname
    stdin, stdout, stderr = ssh_client.exec_command(cmmd)

    output = f'{stdout.read().decode("utf8")}'

    # Get the name of the tarball from the output and save 
    tarball = output.replace('Compressed the FakeQuake output to ','')
    tarball = tarball.replace('\n', '')

    print('Transferring the file: ' + tarball)

    # Retrieve the tarball

    # open  a client to transfer the output txt file to the local machine
    sftp_client=ssh_client.open_sftp()

    # set up the paths
    remotepath = '/home/marcus_adair/' + dirname + '/' + tarball
    localpath = './' + tarball

    # do the transfer
    sftp_client.get(remotepath, localpath)
    sftp_client.close()

    # close the file objects
    stdin.close()
    stdout.close()
    stderr.close()

    # close the connection
    ssh_client.close()


if __name__== "__main__":
    main(sys.argv[1])


