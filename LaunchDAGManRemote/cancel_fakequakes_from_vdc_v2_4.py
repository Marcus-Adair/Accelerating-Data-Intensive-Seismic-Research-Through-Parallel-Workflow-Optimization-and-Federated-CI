# Copyright: Marcus Adair, Ivan Rodero, University of Utah, SCI Institute
#
#   This files takes in a cluster-ID which covers all jobs in a single DAGMan run.
#   It SSH's into OSG and user that cluster-ID to cancel the entire DAGMan run.

import sys
import paramiko

def cancel(arg1):


    # Get the ID passed in which covers all jobs in a FakeQuakes DAGMan run
    clusterID = str(arg1)

    # SSH into OSG
    host = "login05.osgconnect.net"
    username = "marcus_adair"
    password = "12345"
    ssh_client = paramiko.client.SSHClient()
    ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh_client.connect(host, username=username, password=password)

    # Build the command to cancel a FakeQuakes run
    cmmd = "condor_rm " + clusterID
    
    # Execute the command and save the return info
    stdin, stdout, stderr = ssh_client.exec_command(cmmd)

    # Decode the output and any errors
    #print(f'STDIN: {stdin.read().decode("utf8")}')
    print(f'STDOUT: {stdout.read().decode("utf8")}')
    print(f'STDEERR: {stderr.read().decode("utf8")}')

    # close the file objects
    stdin.close()
    stdout.close()
    stderr.close()

    # close the connection
    ssh_client.close()

    print('All jobs removed for the FakeQuakes run under the ID: ' + clusterID)

if __name__== "__main__":
    cancel(sys.argv[1])
