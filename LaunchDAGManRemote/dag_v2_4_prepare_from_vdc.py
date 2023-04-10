# Copyright: Marcus Adair, Ivan Rodero, University of Utah, SCI Institute
#
#	This file is called over VDC and sends the FakeQuake input files to the OSG, ssh's into OSG,
#	and calls a script which prepares those sent files and launches the DAGMan
#
#   *NOTE: this has been edited so that if you use this, you have enter
#          in your own personal OSG username, password, and login node number.
#          If running this you also need to edit your OSG profile and add an
#          SSH Public Key for the machine you want to launch Fakequakes off of.           
# ----------------------------------------------------------------------------


# This is the main and only function. This compresses the input files, sends them
# To the OSG, SSH's into it and runs FakeQuakes over the OSG. 
#
# To call this just import dag_v2_3_prepare_from_vdc in a file and then 
# procede to call dag_v2_3_prepare_from_vdc.main() with all  of the arguments sent
# in as strings
def main(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11):

    import datetime
    import paramiko 
    import tarfile
    import os
    import glob
    import shutil


    # Get and set the parameter vars as chosen by the User 
    numrupbundles = str(arg1)

    modfile = str(arg2)
    faultfile = str(arg3)
    xyzfile = str(arg4)
    mshoutfile = str(arg5)
    gflistfile = str(arg6)

    utmzone = str(arg7)
    timeepi = str(arg8)
    targetmw = str(arg9)
    maxslip = str(arg10)
    hypocenter = str(arg11)


    # Make a unique name for prepinput based off of the fault geomety and current date/time:  
    # take off the extension from the fault file to make a name based off of it
    uniquename = faultfile.replace('.fault', '')

    
    curr_datetime = datetime.datetime.now()
    curr_datetime = str(curr_datetime.year) + "-" + str(curr_datetime.month) + "-" + str(curr_datetime.day) + "_" + str(curr_datetime.hour) + "." + str(curr_datetime.minute)  + "." + str(curr_datetime.second)
    uniquename = uniquename  + "_" + curr_datetime

    
    # The files to compress and send in to OSG for fakequakes
    file_arr = [modfile, faultfile, xyzfile, mshoutfile, gflistfile]

    # check if there are .npy files (distance matrices) submitted to be recycled
    npy_list = glob.glob('*.npy')
    npylength = len(npy_list)
    if npylength != 0:

        # If there are .npy files
        # Create a dir       
        npydir = 'distancematrices'
        parent_dir = "./"
        path = os.path.join(parent_dir, npydir)           
        os.mkdir(path)

        # move the distance matrices to it
        for file in npy_list:
            shutil.move(file, npydir)
        
        # compress the entire directory into a tarball
        npyfile = 'distancematrices.tar.gz'
        tar = tarfile.open(npyfile,"w:gz")
        tar.add("./distancematrices/", arcname=npydir)
        tar.close()

        # add tarball to list of files to be further compressed and sent to OSG as input
        file_arr.append(npyfile)  


    # Check if user submitted a ruptures.list and then rupture files to be recycled
    ruplist_list = glob.glob('ruptures.list')
    ruplistlength = len(ruplist_list)

    # If there is one
    if ruplistlength != 0:
        # get the number of lines in the ruptures.list
        with open('ruptures.list') as f:
            line_count = 0
            for line in f:
                line_count += 1

        # check for ruptures .rupt and .log files
        rupt_list = glob.glob('*.rupt')
        log_list = glob.glob('*.log')
        ruptlength = len(rupt_list)
        loglength = len(log_list)

        # if the amount of ruptures on the list matches the amount of ruptures files input
        if line_count == ruptlength and line_count == loglength:

            # Make directory called 'ruptures' in the current dir
            rupdir = "ruptures"
            parent_dir = "./" 
            path = os.path.join(parent_dir, rupdir)           
            os.mkdir(path)

            # Move the rupture files there
            for ruptfile in rupt_list:
                shutil.move(ruptfile, "ruptures")
            for logfile in log_list:
                shutil.move(logfile, "ruptures")
            
            # compress the entire directory into a tarball
            ruptarball = 'ruptures.tar.gz'
            tar = tarfile.open(ruptarball,"w:gz")
            tar.add("./ruptures/", arcname=rupdir)
            tar.close()

            # add the rupture files to the list of files to compress
            file_arr.append('ruptures.list')
            file_arr.append(ruptarball)


             

    # Check if user prepared mseeds, if mseeds were passed in, compress them to be sent to OSG
    mseedsprepped = False
    mseed_list = glob.glob('*.mseed')
    mseedlength = len(mseed_list)

    # If mseeds were submitted
    if mseedlength != 0:
        # this is True so mseeds will be transferred seperate from other files cause they're big files
        mseedsprepped = True  

        # Make a directory to hold mseeds
        mseeddir = 'mseeds'
        parent_dir = "./"
        path = os.path.join(parent_dir, mseeddir)           
        os.mkdir(path)

        # move the G matrices (.mseed files) to it
        for file in mseed_list:
            shutil.move(file, mseeddir)
        
        # compress the entire directory into a tarball - it will be transferred alone to public
        mseedfile = 'mseeds.tar.gz'
        tar = tarfile.open(mseedfile,"w:gz")
        tar.add("./mseeds/", arcname=mseeddir)
        tar.close()


    # COMPRESS ALL OF THE INPUT FILES:
    # The name of the tarball to transfer to OSG containing all the input files
    filetotransfer = uniquename + "_input.tar.gz"

    # Make a directory to hold things and compress
    uniquedir = uniquename + "_input"
    parent_dir = "./" 
    path = os.path.join(parent_dir, uniquedir)           
    os.mkdir(path)

    # move the input files there
    for file in file_arr:
        shutil.move(file, uniquedir)

    # wrap up the dir to a tarball
    tar = tarfile.open(filetotransfer,"w:gz")
    uniquedirpath = parent_dir + uniquedir + "/"
    tar.add(uniquedirpath, arcname=uniquedir)
    tar.close()




    # Start to transfer input files to OSG home
    # ssh into OSG and call the prepare script to launch the DAGman (& include vars)
    # ---------------------------------

    # SSH into OSG
    host = "login[TODO: Enter in login node number].osgconnect.net"
    username = "[TODO: Enter in personal OSG username]"
    password = "TODO: Enter in personal OSG username"
    ssh_client = paramiko.client.SSHClient()
    ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh_client.connect(host, username=username, password=password)

    sftp_client=ssh_client.open_sftp()  
    local_path = "./" 
    sftp_client.put(local_path + filetotransfer,'/home/marcus_adair/' + filetotransfer)


    # Transfer mseeds to OSG public if prepared
    if mseedsprepped:
        
        # path of the folder where large mseeds are held and passed to OSG nodes from 
        remote_mseed_path="/public/marcus_adair/prepinput/" + uniquename + "/"

        try:
            sftp_client.chdir(remote_mseed_path)  # Test if remote_path exists
        except IOError:
            sftp_client.mkdir(remote_mseed_path)  # Create remote_path
            sftp_client.chdir(remote_mseed_path)
        sftp_client.put(local_path + "mseeds.tar.gz", remote_mseed_path + "mseeds.tar.gz")  

    sftp_client.close()


    # Exectute the script which prepares FakeQuakes to be ran inside of OSG :
    # (put together command with variable set by user and then execute)
    cmmd = "sh dag_v2_4_prepare_for_OSG.sh "+ uniquename + " " + numrupbundles + " " + modfile + " " + faultfile + " " + xyzfile + " " + mshoutfile + " " + gflistfile + " " + utmzone + " " + timeepi + " " + targetmw + " " + maxslip + " " + hypocenter
    stdin, stdout, stderr = ssh_client.exec_command(cmmd)


    # Decode the output and any errors
    print(f'STDOUT: {stdout.read().decode("utf8")}')
    print(f'STDEERR: {stderr.read().decode("utf8")}')

    # Get return code
    #print(f'Return code: {stdout.channel.recv_exit_status()}')

    # close the file objects
    stdin.close()
    stdout.close()
    stderr.close()

    # close the connection
    ssh_client.close()

    print('This run is occuring over OSG in the unique folder: ' + uniquename)


    # Clean up all the prepared input files
    # -------------------------------------------------
    # Delete the tarball with all the input files
    location = "./"
    file_to_delete = filetotransfer
    path = os.path.join(location, file_to_delete)
    os.remove(path)

    #  Delete all the input files inside of the unique dir and then delete the empty dir
    dir_to_delete = uniquedir + "/"
    path = os.path.join(location, dir_to_delete)
    files_to_delete = os.listdir(path)
    for file in files_to_delete:
        file_path = os.path.join(path, file)
        os.unlink(file_path)  
    os.rmdir(path)
 

    # Delete/clean up the distancematrices folder and all the files in it
    if os.path.exists('./distancematrices/'):
        dir_to_delete = "distancematrices/"
        path = os.path.join(location, dir_to_delete)
        files_to_delete = os.listdir(path)
        for file in files_to_delete:
            file_path = os.path.join(path, file)
            os.unlink(file_path) 
        os.rmdir(path)

    # Delete/clean up the mseeds folder and all the files in it
    if os.path.exists('./mseeds/'):
        dir_to_delete = "mseeds/"
        path = os.path.join(location, dir_to_delete)
        files_to_delete = os.listdir(path)
        for file in files_to_delete:
            file_path = os.path.join(path, file)
            os.unlink(file_path)   
        os.rmdir(path)

    # Delete/clean up the mseeds tarball and all the files in it
    if os.path.exists('./mseeds.tar.gz'):
        location = "./"
        file_to_delete = 'mseeds.tar.gz'
        path = os.path.join(location, file_to_delete)
        os.remove(path)

    # Delete/clean up the ruptures folder and all the files in it
    if os.path.exists('./ruptures/'):
        dir_to_delete = "ruptures/"
        path = os.path.join(location, dir_to_delete)
        files_to_delete = os.listdir(path)
        for file in files_to_delete:
            file_path = os.path.join(path, file)
            os.unlink(file_path)  
        os.rmdir(path)
