# Author: Marcus Adair, Research Asst. for Ivan Rodero. May 2023, SCI Institute, University of Utah
#
# Python Script that Simulates cloudbursting combined with OSG jobs to calculate instant throughput for
# every second of a runtime among other things. It uses real OSG submission, execution, and termination times 
# to step through their runtimes and simulate cloudbursting some of those jobs. The aim to is improve throughput and
# runtime. 

import csv
import sys
import datetime
import time
from itertools import chain
import subprocess

# Converts date and time from OSG log files that were in the csv into python datetime
def convert(date_time):
    datetime_str = datetime.datetime.strptime(date_time, '%H:%M:%S %Y-%m-%d')
    return datetime_str

# Creates a range to loop over which is every second or minute of DAGman from submission to termination
def daterange(d1, d2):

    # isolate the date
    #print("d1 is "+str(d1))
    #print("d2 is "+str(d2))
    d1Str = str(d1)
    d2Str = str(d2)
    splitD1 = d1Str.split(' ')
    splitD2 = d2Str.split(' ')
    d1date = splitD1[0]
    d2date = splitD2[0]

    rtrn = []

    notEqual = True

    while (notEqual):

        # if the dates equal the same
        if (d1date == d2date):
            # Make a list of every second in the datetime until d2 from d1 (d1 is either the start
            # of the day or if d1 was on the same day its from that)
            append = (d1 + datetime.timedelta(seconds=i) for i in range((d2 - d1).seconds + 1))
            copy = list(append)
            rtrn = chain(rtrn, copy)

            notEqual = False # Dates are equal
        else:
            # create new datetime 'dtemp' with date of d1 and 23:59:59        
            dtemp = convert('23:59:59 '+d1date)
            #print("dtemp is: "+str(dtemp))

            # if dates are not the same create a range from the start till the end of the day
            append = (d1 + datetime.timedelta(seconds=i) for i in range((dtemp - d1).seconds + 1))
            copy = list(append)
            rtrn = chain(rtrn, copy)
        
            # increment dtemp by 1 day until its the same as d1, update datetime dtemp with inc date and 23:59:59
            incDatetime = dtemp + datetime.timedelta(days=1) # Increment by a day 
            dtempStr = str(incDatetime)
            splitDtemp = dtempStr.split(' ')
            d1date = splitDtemp[0]
            d1 = convert("00:00:00 "+d1date)
            #print("Inc'ed Date is: "+d1date)

    return rtrn

    

# Main Method to run cloudbursting simulations
#
# Takes in the csv files containing job times and DAGMan times, parses them to get OSG job times and
# simulate cloudbursting. Also takes in up to 9 additional arguments which control the parameters of the
# simulation via flags (eg. -v=1) that can be passed in any order.
def main(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11):

    jobcsvname = str(arg1)  # CSV with the individual jobs times for the DAGMan
    dagcsvname = str(arg2)  # CSV with one row which has the DAGMans totals and phase times
    
    # Simulation parameter vars (defaults) ---------------- #

    # threshold for when throughput goes below this do cloudbursting
    threshold = 34

    # Set the constant/average time for rupture and wave jobs in seconds 
    ruptureJobTimeSeconds = 287
    waveJobTimeSeconds = 144 # 15 min
    

    # Set the time in seconds for when we should check throughput against threshold (set to 1 to check every second if throughput goes below thresh)
    probeTimeSeconds = 120
    cloudMinuteCost = 0.00019 # Dollar amount per minute 
    cloudUseSeconds = 0

    # Set the minutes that we allow OSG jobs to wait on the queue for execution until we cloudburst them instead
    maxWaitTime = 60

    metThresholdInit = False
    metThreshDeactivated = False
    verbosePrint = False

    # In Minutes, the time we wait since the last submission to do cloudbursting 
    submissionWaitTime = 5


    # Customize parameters if the user optionally passes them in via a flag (they can be passed in any order)
    # ---------------------------------------------------------------------
    # -t: sets threshol in jobs/min for when throughput goes below this we cloudburst
    # -r: sets the time of rupture jobs in seconds
    # -w: sets the time of wave jobs in seconds
    # -p: sets the time in seconds of how often we probe to check threshold for cloudbursting
    # -c: sets the cost in dollars how how much a minute of cloud resources cost in simulation
    # -q: sets the max wait time in minutes that we allow jobs to wait on the OSG queue before cloudbursting them
    # -m: set whether the met threshold policy should be used. If its greater than 0 than the policy is deactivated
    # -v: enable verbose printing
    # -s: sets the time in minutes that we wait since the last OSG submission to do cloudbursting
    if (not arg3 == -1):
        if(arg3.startswith("-t")):
            threshold = int(arg3[3:])
            print("Threshold parameter set to: "+str(threshold)+ " jobs per minute")
        if(arg3.startswith("-r")):
            ruptureJobTimeSeconds = int(arg3[3:])
            print("Rupture job time parameter set to: "+str(ruptureJobTimeSeconds)+" seconds")
        if(arg3.startswith("-w")):
            waveJobTimeSeconds = int(arg3[3:])
            print("Wave job time parameter set to: "+str(waveJobTimeSeconds)+" seconds")
        if(arg3.startswith("-p")):
            probeTimeSeconds = int(arg3[3:])
            print("Probe time parameter set to: "+str(probeTimeSeconds)+" seconds")
        if(arg3.startswith("-c")):
            cloudMinuteCost = float(arg3[3:])
            print("Cloud cost parameter set to: $"+str(cloudMinuteCost)+" per minute")
        if(arg3.startswith("-q")):
            maxWaitTime = int(arg3[3:])
            print("Queue wait time parameter set to: "+str(maxWaitTime)+" minutes")
        if(arg3.startswith("-m")):
            val = int(arg3[3:])
            if (val > 0):
                metThresholdInit = True
                metThreshDeactivated = True
                print("Met threshold to cloudburst policy disabled")
        if(arg3.startswith("-v")):
            val = int(arg3[3:])
            if (val > 0):
                verbosePrint = True
                print("Verbose print option enabled")
        if(arg3.startswith("-s")):
            submissionWaitTime = int(arg3[3:])
            print("Submission gap time parameter set to: "+str(submissionWaitTime)+" minutes")
    if (not arg4 == -1):
        if(arg4.startswith("-t")):
            threshold = int(arg4[3:])
            print("Threshold parameter set to: "+str(threshold)+ " jobs per minute")
        if(arg4.startswith("-r")):
            ruptureJobTimeSeconds = int(arg4[3:])
            print("Rupture job time parameter set to: "+str(ruptureJobTimeSeconds)+" seconds")
        if(arg4.startswith("-w")):
            waveJobTimeSeconds = int(arg4[3:])
            print("Wave job time parameter set to: "+str(waveJobTimeSeconds)+" seconds")
        if(arg4.startswith("-p")):
            probeTimeSeconds = int(arg4[3:])
            print("Probe time parameter set to: "+str(probeTimeSeconds)+" seconds")
        if(arg4.startswith("-c")):
            cloudMinuteCost = float(arg4[3:])
            print("Cloud cost parameter set to: $"+str(cloudMinuteCost)+" per minute")
        if(arg4.startswith("-q")):
            maxWaitTime = int(arg4[3:])
            print("Queue wait time parameter set to: "+str(maxWaitTime)+" minutes")
        if(arg4.startswith("-m")):
            val = int(arg4[3:])
            if (val > 0):
                metThresholdInit = True
                metThreshDeactivated = True
                print("Met threshold to cloudburst policy disabled")
        if(arg4.startswith("-v")):
            val = int(arg4[3:])
            if (val > 0):
                verbosePrint = True
                print("Verbose print option enabled")
        if(arg4.startswith("-s")):
            submissionWaitTime = int(arg4[3:])
            print("Submission gap time parameter set to: "+str(submissionWaitTime)+" minutes")
    if (not arg5 == -1):
        if(arg5.startswith("-t")):
            threshold = int(arg5[3:])
            print("Threshold parameter set to: "+str(threshold)+ " jobs per minute")
        if(arg5.startswith("-r")):
            ruptureJobTimeSeconds = int(arg5[3:])
            print("Rupture job time parameter set to: "+str(ruptureJobTimeSeconds)+" seconds")
        if(arg5.startswith("-w")):
            waveJobTimeSeconds = int(arg5[3:])
            print("Wave job time parameter set to: "+str(waveJobTimeSeconds)+" seconds")
        if(arg5.startswith("-p")):
            probeTimeSeconds = int(arg5[3:])
            print("Probe time parameter set to: "+str(probeTimeSeconds)+" seconds")
        if(arg5.startswith("-c")):
            cloudMinuteCost = float(arg5[3:])
            print("Cloud cost parameter set to: $"+str(cloudMinuteCost)+" per minute")
        if(arg5.startswith("-q")):
            maxWaitTime = int(arg5[3:])
            print("Queue wait time parameter set to: "+str(maxWaitTime)+" minutes")
        if(arg5.startswith("-m")):
            val = int(arg5[3:])
            if (val > 0):
                metThresholdInit = True
                metThreshDeactivated = True
                print("Met threshold to cloudburst policy disabled")
        if(arg5.startswith("-v")):
            val = int(arg5[3:])
            if (val > 0):
                verbosePrint = True
                print("Verbose print option enabled")
        if(arg5.startswith("-s")):
            submissionWaitTime = int(arg5[3:])
            print("Submission gap time parameter set to: "+str(submissionWaitTime)+" minutes")
    if (not arg6 == -1):
        if(arg6.startswith("-t")):
            threshold = int(arg6[3:])
            print("Threshold parameter set to: "+str(threshold)+ " jobs per minute")
        if(arg6.startswith("-r")):
            ruptureJobTimeSeconds = int(arg6[3:])
            print("Rupture job time parameter set to: "+str(ruptureJobTimeSeconds)+" seconds")
        if(arg6.startswith("-w")):
            waveJobTimeSeconds = int(arg6[3:])
            print("Wave job time parameter set to: "+str(waveJobTimeSeconds)+" seconds")
        if(arg6.startswith("-p")):
            probeTimeSeconds = int(arg6[3:])
            print("Probe time parameter set to: "+str(probeTimeSeconds)+" seconds")
        if(arg6.startswith("-c")):
            cloudMinuteCost = float(arg6[3:])
            print("Cloud cost parameter set to: $"+str(cloudMinuteCost)+" per minute")
        if(arg6.startswith("-q")):
            maxWaitTime = int(arg6[3:])
            print("Queue wait time parameter set to: "+str(maxWaitTime)+" minutes")
        if(arg6.startswith("-m")):
            val = int(arg6[3:])
            if (val > 0):
                metThresholdInit = True
                metThreshDeactivated = True
                print("Met threshold to cloudburst policy disabled")
        if(arg6.startswith("-v")):
            val = int(arg6[3:])
            if (val > 0):
                verbosePrint = True
                print("Verbose print option enabled")
        if(arg6.startswith("-s")):
            submissionWaitTime = int(arg6[3:])
            print("Submission gap time parameter set to: "+str(submissionWaitTime)+" minutes")
    if (not arg7 == -1):
        if(arg7.startswith("-t")):
            threshold = int(arg7[3:])
            print("Threshold parameter set to: "+str(threshold)+ " jobs per minute")
        if(arg7.startswith("-r")):
            ruptureJobTimeSeconds = int(arg7[3:])
            print("Rupture job time parameter set to: "+str(ruptureJobTimeSeconds)+" seconds")
        if(arg7.startswith("-w")):
            waveJobTimeSeconds = int(arg7[3:])
            print("Wave job time parameter set to: "+str(waveJobTimeSeconds)+" seconds")
        if(arg7.startswith("-p")):
            probeTimeSeconds = int(arg7[3:])
            print("Probe time parameter set to: "+str(probeTimeSeconds)+" seconds")
        if(arg7.startswith("-c")):
            cloudMinuteCost = float(arg7[3:])
            print("Cloud cost parameter set to: $"+str(cloudMinuteCost)+" per minute")
        if(arg7.startswith("-q")):
            maxWaitTime = int(arg7[3:])
            print("Queue wait time parameter set to: "+str(maxWaitTime)+" minutes")
        if(arg7.startswith("-m")):
            val = int(arg7[3:])
            if (val > 0):
                metThresholdInit = True
                metThreshDeactivated = True
                print("Met threshold to cloudburst policy disabled")
        if(arg7.startswith("-v")):
            val = int(arg7[3:])
            if (val > 0):
                verbosePrint = True
                print("Verbose print option enabled")
        if(arg7.startswith("-s")):
            submissionWaitTime = int(arg7[3:])
            print("Submission gap time parameter set to: "+str(submissionWaitTime)+" minutes")
    if (not arg8 == -1):
        if(arg8.startswith("-t")):
            threshold = int(arg8[3:])
            print("Threshold parameter set to: "+str(threshold)+ " jobs per minute")
        if(arg8.startswith("-r")):
            ruptureJobTimeSeconds = int(arg8[3:])
            print("Rupture job time parameter set to: "+str(ruptureJobTimeSeconds)+" seconds")
        if(arg8.startswith("-w")):
            waveJobTimeSeconds = int(arg8[3:])
            print("Wave job time parameter set to: "+str(waveJobTimeSeconds)+" seconds")
        if(arg8.startswith("-p")):
            probeTimeSeconds = int(arg8[3:])
            print("Probe time parameter set to: "+str(probeTimeSeconds)+" seconds")
        if(arg8.startswith("-c")):
            cloudMinuteCost = float(arg8[3:])
            print("Cloud cost parameter set to: $"+str(cloudMinuteCost)+" per minute")
        if(arg8.startswith("-q")):
            maxWaitTime = int(arg8[3:])
            print("Queue wait time parameter set to: "+str(maxWaitTime)+" minutes")
        if(arg8.startswith("-m")):
            val = int(arg8[3:])
            if (val > 0):
                metThresholdInit = True
                metThreshDeactivated = True
                print("Met threshold to cloudburst policy disabled")
        if(arg8.startswith("-v")):
            val = int(arg8[3:])
            if (val > 0):
                verbosePrint = True
                print("Verbose print option enabled")
        if(arg8.startswith("-s")):
            submissionWaitTime = int(arg8[3:])
            print("Submission gap time parameter set to: "+str(submissionWaitTime)+" minutes")
    if (not arg9 == -1):
        if(arg9.startswith("-t")):
            threshold = int(arg9[3:])
            print("Threshold parameter set to: "+str(threshold)+ " jobs per minute")
        if(arg9.startswith("-r")):
            ruptureJobTimeSeconds = int(arg9[3:])
            print("Rupture job time parameter set to: "+str(ruptureJobTimeSeconds)+" seconds")
        if(arg9.startswith("-w")):
            waveJobTimeSeconds = int(arg9[3:])
            print("Wave job time parameter set to: "+str(waveJobTimeSeconds)+" seconds")
        if(arg9.startswith("-p")):
            probeTimeSeconds = int(arg9[3:])
            print("Probe time parameter set to: "+str(probeTimeSeconds)+" seconds")
        if(arg9.startswith("-c")):
            cloudMinuteCost = float(arg9[3:])
            print("Cloud cost parameter set to: $"+str(cloudMinuteCost)+" per minute")
        if(arg9.startswith("-q")):
            maxWaitTime = int(arg9[3:])
            print("Queue wait time parameter set to: "+str(maxWaitTime)+" minutes")
        if(arg9.startswith("-m")):
            val = int(arg9[3:])
            if (val > 0):
                metThresholdInit = True
                metThreshDeactivated = True
                print("Met threshold to cloudburst policy disabled")
        if(arg9.startswith("-v")):
            val = int(arg9[3:])
            if (val > 0):
                verbosePrint = True
                print("Verbose print option enabled")
        if(arg9.startswith("-s")):
            submissionWaitTime = int(arg9[3:])
            print("Submission gap time parameter set to: "+str(submissionWaitTime)+" minutes")
    if (not arg10 == -1):
        if(arg10.startswith("-t")):
            threshold = int(arg10[3:])
            print("Threshold parameter set to: "+str(threshold)+ " jobs per minute")
        if(arg10.startswith("-r")):
            ruptureJobTimeSeconds = int(arg10[3:])
            print("Rupture job time parameter set to: "+str(ruptureJobTimeSeconds)+" seconds")
        if(arg10.startswith("-w")):
            waveJobTimeSeconds = int(arg10[3:])
            print("Wave job time parameter set to: "+str(waveJobTimeSeconds)+" seconds")
        if(arg10.startswith("-p")):
            probeTimeSeconds = int(arg10[3:])
            print("Probe time parameter set to: "+str(probeTimeSeconds)+" seconds")
        if(arg10.startswith("-c")):
            cloudMinuteCost = float(arg10[3:])
            print("Cloud cost parameter set to: $"+str(cloudMinuteCost)+" per minute")
        if(arg10.startswith("-q")):
            maxWaitTime = int(arg10[3:])
            print("Queue wait time parameter set to: "+str(maxWaitTime)+" minutes")
        if(arg10.startswith("-m")):
            val = int(arg10[3:])
            if (val > 0):
                metThresholdInit = True
                metThreshDeactivated = True
                print("Met threshold to cloudburst policy disabled")
        if(arg10.startswith("-v")):
            val = int(arg10[3:])
            if (val > 0):
                verbosePrint = True
                print("Verbose print option enabled")
        if(arg10.startswith("-s")):
            submissionWaitTime = int(arg10[3:])
            print("Submission gap time parameter set to: "+str(submissionWaitTime)+" minutes")
    if (not arg11 == -1):
        if(arg11.startswith("-t")):
            threshold = int(arg11[3:])
            print("Threshold parameter set to: "+str(threshold)+ " jobs per minute")
        if(arg11.startswith("-r")):
            ruptureJobTimeSeconds = int(arg11[3:])
            print("Rupture job time parameter set to: "+str(ruptureJobTimeSeconds)+" seconds")
        if(arg11.startswith("-w")):
            waveJobTimeSeconds = int(arg11[3:])
            print("Wave job time parameter set to: "+str(waveJobTimeSeconds)+" seconds")
        if(arg11.startswith("-p")):
            probeTimeSeconds = int(arg11[3:])
            print("Probe time parameter set to: "+str(probeTimeSeconds)+" seconds")
        if(arg11.startswith("-c")):
            cloudMinuteCost = float(arg11[3:])
            print("Cloud cost parameter set to: $"+str(cloudMinuteCost)+" per minute")
        if(arg11.startswith("-q")):
            maxWaitTime = int(arg11[3:])
            print("Queue wait time parameter set to: "+str(maxWaitTime)+" minutes")
        if(arg11.startswith("-m")):
            val = int(arg11[3:])
            if (val > 0):
                metThresholdInit = True
                metThreshDeactivated = True
                print("Met threshold to cloudburst policy disabled")
        if(arg11.startswith("-v")):
            val = int(arg11[3:])
            if (val > 0):
                verbosePrint = True
                print("Verbose print option enabled")
        if(arg11.startswith("-s")):
            submissionWaitTime = int(arg11[3:])
            print("Submission gap time parameter set to: "+str(submissionWaitTime)+" minutes")

    # ------------------------- #

        # Init vars for storing data
    DAGManSubDatetime=''
    DAGManTermDatetime=''
    DAGManRuntime=''

    rupSubs = []
    rupExs = []
    rupTerms = []

    rupDateSubs = []
    rupDateExs = []
    rupDateTerms = []

    waveSubs = []
    waveExs = []
    waveTerms = []
    
    waveDateSubs = []
    waveDateExs = []
    waveDateTerms = []

    rupJobCodes = []
    waveJobCodes = []

    # Init the number of wave and rupture jobs for the batch
    waveJobs = 0
    ruptureJobs = 0
    cloudburstingWaveJobs = {}
    cloudburstingRuptureJobs = {}

    # loop over the csv and store the execution and termination times for jobs into arrays for use later
    file = open(jobcsvname, "r") 
    lineIndex = 0
    for line in file:
        if (lineIndex == 0):
            lineIndex = lineIndex + 1
            continue

        strArr = line.split(',')

        if (strArr[0] != ""):
            rupSubs.append(strArr[0])
            ruptureJobs += 1
        if (strArr[1] != ""):
            rupExs.append(strArr[1])
        if (strArr[2] != ""):
            rupTerms.append(strArr[2])
        if (strArr[3] != ""):
            rupDateSubs.append(strArr[3])
        if (strArr[4] != ""):
            rupDateExs.append(strArr[4])
        if (strArr[5] != ""):
            rupDateTerms.append(strArr[5])
        if (strArr[6] != ""):
            waveSubs.append(strArr[6])
            waveJobs += 1
        if (strArr[7] != ""):
            waveExs.append(strArr[7])
        if (strArr[8] != ""):
            waveTerms.append(strArr[8])
        if (strArr[9] != ""):
            waveDateSubs.append(strArr[9])
        if (strArr[10] != ""):
            waveDateExs.append(strArr[10])
        if (strArr[11] != ""):
            waveDateTerms.append(strArr[11])
        if (strArr[12] != ""):
            if (strArr[0] != ""):
                rupJobCodes.append(strArr[12])
            elif (strArr[6] != ""):
                waveJobCodes.append(strArr[12])
        lineIndex = lineIndex + 1
    # end of loop ------------------------------- #
    totalJobs = lineIndex-1
    rupJobCount = len(rupSubs)
    #waveJobCount = len(waveSubs)


    # Go through wabe job termination times and find the last one
    waveInd = 0
    maxTermTime = convert(waveTerms[waveInd]+' '+waveDateTerms[waveInd])
    for waveTerm in waveTerms:
        termTime = convert(waveTerm+' '+waveDateTerms[waveInd])
        if (termTime > maxTermTime):
            maxTermTime = termTime
        waveInd = waveInd + 1 
    

    # Read the csv file with the DAGMan runtime
    lineCount = 0
    file = open(dagcsvname, "r") 
    for line in file:

        if (lineCount == 0):
            lineCount += 1
            continue

        strArr = line.split(',')

        # Get the start and stop time of the DAGMan and save 
        DAGManSubDatetime = convert(strArr[0]+' '+strArr[1])
        DAGManTermDatetime = convert(strArr[2]+' '+strArr[3])

        # Get the Total runtime from using the submission and termination time from DAGman
        DAGManRuntime = DAGManTermDatetime - DAGManSubDatetime

        print(DAGManRuntime)

        lineCount += 1
    # end of loop -------------------------------


    print("The Range is from "+strArr[0]+' '+strArr[1]+" to "+strArr[2]+' '+strArr[3])
    print("Starting the simulation ...")

    # The end time of the simulation, this should be changed when cloudbursting sim ends earlier than actual OSG run
    endDateTime = maxTermTime
    print("Max term Time is: "+str(maxTermTime))

    # data rows of csv file for extracting throughput points
    rows = [] 

    completeJobs = 0
    cloudburstingWaveJobID = 1
    cloudburstingRuptureJobID = 1
    osgRupJobs = 0
    osgWaveJobs = 0
    cloudRupJobs = 0
    cloudWaveJobs = 0
    ruptureJobsComplete = False

    cloudburstedJob = 1
    OSGjobs = 1

    lastSubmittedOSGJob = convert(str(rupSubs[0]) + " "+rupDateSubs[0]) # init 

    cloudburstedJobsFromThreshR = 0
    belowThreshCountR = 0
    cloudburstedJobsFromThreshW = 0
    belowThreshCountW = 0
    burstedFromLongWaitCountR = 0
    submissionGapBurstCountR = 0
    burstedFromLongWaitCountW = 0
    submissionGapBurstCountW = 0

    curSeconds = 0
    waitBurstCooldownStack = 0 # time in minutes

    # THE MAIN SIMULATION LOOP: -------------------------------------------------------- #
    # Loop over every second of the runtime and compute the number of complete jobs and runtime to get instant throughput
    for d in daterange(DAGManSubDatetime, maxTermTime):
    #for d in daterange(DAGManSubDatetime, DAGManTermDatetime):

        addRow = [d, '']

        # Check for if OSG jobs are done ------------------ #
        if (not ruptureJobsComplete):
            # Compute the number of complete OSG jobs this second. 
            rupIndex = 0
            N = range(len(rupTerms))
            for n in N:
            #for rupTerm in rupTerms:
                if (rupIndex == len(rupExs)) or (rupIndex == len(rupDateExs)):
                        print("BREAKING in ruptures!!!!")
                        break
                # use convert to make a datetime out of the job's date and time
                subDatetime = convert(str(rupSubs[rupIndex]) + " "+rupDateSubs[rupIndex])
                termDatetime = convert(str(rupTerms[rupIndex]) + " "+rupDateTerms[rupIndex])
                exDatetime = convert(str(rupExs[rupIndex]) + " " + rupDateExs[rupIndex])
                if(subDatetime == d):
                    if (verbosePrint):
                        print("Submitting an OSG rupture job"+" (osg job: "+str(OSGjobs)+")")
                        OSGjobs = OSGjobs + 1
                        lastSubmittedOSGJob = subDatetime # reset time of cloudburst cooldown when osg jobs are being submitted
                        waitBurstCooldownStack = 0
                if(exDatetime == d):
                    if (verbosePrint):
                        print("Executing an OSG rupture job")

                # if the job terminated at or before the current time (d) then its complete (and its jobcode is 0)
                if (termDatetime <= d):
                    completeJobs = completeJobs + 1
                    osgRupJobs = osgRupJobs + 1
                    if ((osgRupJobs+cloudRupJobs) == rupJobCount):
                        ruptureJobsComplete = True

                    if(verbosePrint):
                        print("rupture job complete in OSG at: "+str(d)+" (the termTime is: "+str(termDatetime)+")"+" ("+str(completeJobs)+"/"+str(totalJobs)+" done)")
                    # Remove complete job from list for time performance
                    rupSubs.pop(rupIndex)
                    rupExs.pop(rupIndex)
                    rupTerms.pop(rupIndex)
                    rupDateSubs.pop(rupIndex)
                    rupDateExs.pop(rupIndex)
                    rupDateTerms.pop(rupIndex)
                    rupJobCodes.pop(rupIndex)

                    rupIndex = rupIndex - 1 # adjust for deleted item list, everything shifts down

                rupIndex = rupIndex + 1 # Adjust for shifted list

        if (ruptureJobsComplete):
            waveIndex = 0
            N = range(len(waveTerms))
            for n in N:
            #for waveTerm in waveTerms:

                if (waveIndex == len(waveExs)) or (waveIndex == len(waveDateExs)):
                    print("BREAKING in waves!!!!")
                    break

                # use convert to make a datetime out of the job's date and time
                subDatetime = convert(str(waveSubs[waveIndex]) + " "+waveDateSubs[waveIndex])
                termDatetime = convert(str(waveTerms[waveIndex]) + " "+waveDateTerms[waveIndex])
                exDatetime = convert(str(waveExs[waveIndex]) + " " + waveDateExs[waveIndex])
                if(subDatetime == d):
                    if (verbosePrint):
                        print("Submitting an OSG wave job"+" (osg job: "+str(OSGjobs)+")")
                        OSGjobs = OSGjobs + 1
                        lastSubmittedOSGJob = subDatetime
                        waitBurstCooldownStack = 0 # reset time of cloudburst cooldown when osg jobs are being submitted
                if(exDatetime == d):
                    if (verbosePrint):
                        print("Executing an OSG wave job")

                # if the job terminated at or before the current time (d) then its complete (and its jobcode is 0)
                if (termDatetime <= d):
                    completeJobs = completeJobs + 1
                    osgWaveJobs = osgWaveJobs + 1
                    if(verbosePrint):
                        print("wave job complete in OSG at: "+str(d)+" (the termTime is: "+str(termDatetime)+")"+" ("+str(completeJobs)+"/"+str(totalJobs)+" done)")
                    # Remove complete job from list for time performance
                    waveSubs.pop(waveIndex)
                    waveExs.pop(waveIndex)
                    waveTerms.pop(waveIndex)
                    waveDateSubs.pop(waveIndex)
                    waveDateExs.pop(waveIndex)
                    waveDateTerms.pop(waveIndex)
                    waveJobCodes.pop(waveIndex)

                    waveIndex = waveIndex - 1 # Adjust for shifted list

                waveIndex = waveIndex + 1

        # Check for if cloud jobs are done ------------------------ #
        cloudComputedaSecond = False
        # Cloudbursted rupture jobs
        if (not ruptureJobsComplete):
            toRemoveList = []
            for jobID, timeSeconds in cloudburstingRuptureJobs.items():
                # The the cloudbursting jobs is still running
                if (timeSeconds < ruptureJobTimeSeconds ):
                    newTime = timeSeconds + 1
                    cloudburstingRuptureJobs[jobID] = newTime    # Increment its runtime by a second
                    cloudComputedaSecond = True
                else:
                    # Else the jobs is complete, 
                    completeJobs = completeJobs + 1
                    cloudRupJobs = cloudRupJobs + 1
                    if ((osgRupJobs+cloudRupJobs) == rupJobCount):
                        ruptureJobsComplete = True
                    toRemoveList.append(jobID)
                    if(verbosePrint):
                        print("rupture job complete in cloud at: "+str(d)+" ("+str(completeJobs)+"/"+str(totalJobs)+" done)")
            # Remove complete cloud jobs from list of running
            for toRemove in toRemoveList:
                cloudburstingRuptureJobs.pop(toRemove)

        if (ruptureJobsComplete):
            # Cloudbursted wave jobs
            toRemoveList = []
            for jobID, timeSeconds in cloudburstingWaveJobs.items():

                # The the cloudbursting jobs is still running
                if (timeSeconds < waveJobTimeSeconds ):
                    newTime = timeSeconds + 1
                    cloudburstingWaveJobs[jobID] = newTime    # Increment its runtime by a second
                    cloudComputedaSecond = True
                else:
                    # Else the jobs is complete, 
                    completeJobs = completeJobs + 1
                    cloudWaveJobs = cloudWaveJobs + 1
                    toRemoveList.append(jobID)
                    if(verbosePrint):
                        print("wave job complete in cloud at: "+str(d)+" ("+str(completeJobs)+"/"+str(totalJobs)+" done)")
            # Remove complete jobs from the list for time performance
            for toRemove in toRemoveList:
                cloudburstingWaveJobs.pop(toRemove)

        # Increment the time used for cloudcomputing
        if (cloudComputedaSecond):
            cloudUseSeconds = cloudUseSeconds + 1 

        # ---------- Done with job time increment and checking for completion --------------

        
        # Calculate cur runtime ( the difference between current time d and the start )
        currRuntime = d - DAGManSubDatetime
        currRuntimeSec = currRuntime.total_seconds()
        currRuntimeMin = currRuntimeSec/60 # to minutes

        # Throughput is 0 at 0 seconds
        if(currRuntimeMin == 0):
            continue

        instThroughput = completeJobs/currRuntimeMin

        #Check to see if we have initially met the aimed threshold
        if (not metThresholdInit):
            if (instThroughput >= threshold):
                metThresholdInit = True
                print("Threshhold ("+str(threshold)+") met at "+str(d)+"!")

        # ------------- Done with throughput calc, now do cloudbursting --------------------- #


        # Policy 1:
        # Do cloudburting if have initially met the aimed throughput threshold
        if (metThresholdInit):
            if (currRuntimeSec % probeTimeSeconds ==  0): # Check if below threshold every set amount of seconds 
                if (instThroughput < threshold):
                    belowThreshCount = belowThreshCount + 1
                    if (completeJobs >= ruptureJobs):
                        # Remove a wave job from the list of OSG jobs
                        if (len(waveSubs) > 0):
                            cloudbursted = False
                            # If its not already submitted on OSG
                            subDatetime = convert(str(waveSubs[len(waveSubs)-1]) + " "+waveDateSubs[len(waveDateSubs)-1])
                            if (subDatetime > d):
                                print("Cloudbursting a wave job at: "+str(d)+" . it was supposed to be subbed on OSG at: "+str(subDatetime)+" ..."+"(cloud job: "+str(cloudburstedJob))
                                cloudburstedJob = cloudburstedJob + 1
                                waveSubs.pop(len(waveSubs)-1)
                                waveExs.pop(len(waveExs)-1)
                                waveTerms.pop(len(waveTerms)-1)
                                waveDateSubs.pop(len(waveSubs)-1)
                                waveDateExs.pop(len(waveExs)-1)
                                waveDateTerms.pop(len(waveTerms)-1)
                                waveJobCodes.pop(len(waveTerms)-1)
                                # Add it to the list of cloudbursting jobs
                                # Job id is the index+1 of the removed job from the OSG list, runtime value starts at 0 seconds
                                cloudburstingWaveJobs[cloudburstingWaveJobID] = 0
                                cloudburstingWaveJobID = cloudburstingWaveJobID + 1
                                cloudbursted = True
                                cloudburstedJobsFromThreshW = cloudburstedJobsFromThreshW + 1
                        else:
                            if(verbosePrint):
                                print("out of osg wave jobs to cloudburst")

                    else:
                        if (len(rupSubs) > 0):
                            cloudbursted = False
                            # If its not already submitted on OSG
                            subDatetime = convert(str(rupSubs[len(rupSubs)-1]) + " "+rupDateSubs[len(rupDateSubs)-1])

                            # The the next job to cloudburst is not already submitted
                            if (subDatetime > d):
                            
                                print("Cloudbursting a rupture job at: "+str(d)+" . It was supposed to be subbed on OSG at: "+str(subDatetime)+" ..."+"(cloud job: "+str(cloudburstedJob))
                                cloudburstedJob = cloudburstedJob + 1
                                # Remove a rupture job from the list of OSG jobs
                                rupSubs.pop(len(rupSubs)-1)
                                rupExs.pop(len(rupExs)-1)
                                rupTerms.pop(len(rupTerms)-1)
                                rupDateSubs.pop(len(rupSubs)-1)
                                rupDateExs.pop(len(rupExs)-1)
                                rupDateTerms.pop(len(rupTerms)-1)
                                rupJobCodes.pop(len(rupTerms)-1)
                                # Add it to the list of cloudbursting jobs
                                # Job id is the index+1 of the removed job from the OSG list, runtime value starts at 0 seconds
                                cloudburstingRuptureJobs[cloudburstingRuptureJobID] = 0
                                cloudburstingRuptureJobID = cloudburstingRuptureJobID + 1
                                cloudbursted = True
                                cloudburstedJobsFromThreshR = cloudburstedJobsFromThreshR + 1
                        else:
                            if(verbosePrint):
                                print("out of osg rupture jobs to cloudburst")
                else:
                    if(verbosePrint):
                        print("threshold met. Instant throughput is: "+str(instThroughput))

        # -------------------


        # Policy 2:
        # Go through  jobs that are submitted but not executed and cloud burst them if they're on the OSG queue too long
        if (completeJobs >= ruptureJobs):
            # If still in first phase doing rupture jobs
            waveIndex = len(waveSubs) - 1 
            N = range(len(waveSubs))
            for n in N:
                # If a job is submitted before the current time iteration
                subDatetime = convert(str(waveSubs[waveIndex]) + " "+waveDateSubs[waveIndex])
                if(subDatetime < d):
                    # If OSG job is submitted but not executed currently
                    exDatetime = convert(str(waveExs[waveIndex]) + " "+waveDateSubs[waveIndex])
                    if (exDatetime > d):
                        #print("Wave job is submitted but not executed...")
                        subTime = d - subDatetime
                        time_obj = datetime.datetime.strptime(str(subTime), "%H:%M:%S")
                        submissionMinutes = time_obj.hour * 60 + time_obj.minute + time_obj.second / 60
                        # If the time of the OSG job on the queue is longer than than max time we allow, cloudburst it
                        if(submissionMinutes > maxWaitTime):
                            print("Cloudbursting a wave job that was on the queue too long ...  Wait time was: "+str(submissionMinutes) +"(cloud job: "+str(cloudburstedJob))
                            cloudburstedJob = cloudburstedJob + 1
                            waveSubs.pop(waveIndex)
                            waveExs.pop(waveIndex)
                            waveTerms.pop(waveIndex)
                            waveDateSubs.pop(waveIndex)
                            waveDateExs.pop(waveIndex)
                            waveDateTerms.pop(waveIndex)
                            waveJobCodes.pop(waveIndex)
                            cloudburstingWaveJobs[cloudburstingWaveJobID] = 0
                            cloudburstingWaveJobID = cloudburstingWaveJobID + 1
                            burstedFromLongWaitCountW = burstedFromLongWaitCountW + 1
                            # After cloudbursting a wave job that is waiting too long, break out of the loop and go to the next second of the simulation
                            # So cloudburst OSG jobs that are waiting too long once every second

                            waveIndex = waveIndex + 1
                            break

                waveIndex = waveIndex - 1
                
        else:
            # Else in second phase doing wave jobs
            rupIndex = len(rupSubs) - 1 
            N = range(len(rupSubs))
            for n in N:
            #for rupSub in rupSubs:
                # If a job is submitted before the current time iteration
                subDatetime = convert(str(rupSubs[rupIndex]) + " "+rupDateSubs[rupIndex])
                if(subDatetime < d):
                    # If OSG job is submitted but not executed currently
                    exDatetime = convert(str(rupSubs[rupIndex]) + " "+rupDateSubs[rupIndex])
                    if (exDatetime > d):
                        #print("Rupture job is submitted but not executed...")
                        subTime = d - subDatetime
                        time_obj = datetime.datetime.strptime(str(subTime), "%H:%M:%S")
                        submissionMinutes = time_obj.hour * 60 + time_obj.minute + time_obj.second / 60
                        # If the time of the OSG job on the queue is longer than than max time we allow, cloudburst it
                        if(submissionMinutes > maxWaitTime):
                            print("Cloudbursting a rup job that was on the queue too long ...  Wait time was: "+str(submissionMinutes)+"(cloud job: "+str(cloudburstedJob))
                            cloudburstedJob = cloudburstedJob + 1
                            rupSubs.pop(rupIndex)
                            rupExs.pop(rupIndex)
                            rupTerms.pop(rupIndex)
                            rupDateSubs.pop(rupIndex)
                            rupDateExs.pop(rupIndex)
                            rupDateTerms.pop(rupIndex)
                            rupJobCodes.pop(rupIndex)
                            cloudburstingRuptureJobs[cloudburstingRuptureJobID] = 0
                            cloudburstingRuptureJobID = cloudburstingRuptureJobID + 1
                            burstedFromLongWaitCountR = burstedFromLongWaitCountR + 1
                            # After cloudbursting a rupture job that is waiting too long, break out of the loop and go to the next second of the simulation
                            # So cloudburst OSG jobs that are waiting too long once every second
                            rupIndex = rupIndex + 1
                            break

                rupIndex = rupIndex - 1
        # --------------------------------------------


        # Policy 3:
        # If the time from the last sumbitted OSG job and current time iteration d is greater than we want, cloudburst -------------------
        if (d > lastSubmittedOSGJob):
            timeSinceLastOSG_sub = d - lastSubmittedOSGJob
            time_obj = datetime.datetime.strptime(str(timeSinceLastOSG_sub), "%H:%M:%S")
            waitMinutes = time_obj.hour * 60 + time_obj.minute + time_obj.second / 60
        
            # cloudburst if waiting a long time in between OSG submission 
            if(waitMinutes-waitBurstCooldownStack > submissionWaitTime):

                if (completeJobs >= ruptureJobs):
                    if (len(waveSubs) > 0):
                        cloudbursted = False
                        # Cloudburst the last job on the queue
                        subDatetime = convert(str(waveSubs[len(waveSubs)-1]) + " "+waveDateSubs[len(waveDateSubs)-1])
                        # If its not already submitted on OSG
                        if (subDatetime > d):
                            print("Cloudbursting a wave job because time in between submission too long ...")
                            waveSubs.pop(len(waveSubs)-1)
                            waveExs.pop(len(waveExs)-1)
                            waveTerms.pop(len(waveTerms)-1)
                            waveDateSubs.pop(len(waveSubs)-1)
                            waveDateExs.pop(len(waveExs)-1)
                            waveDateTerms.pop(len(waveTerms)-1)
                            waveJobCodes.pop(len(waveTerms)-1)
                            # Add it to the list of cloudbursting jobs
                            # Job id is the index+1 of the removed job from the OSG list, runtime value starts at 0 seconds
                            cloudburstingWaveJobs[cloudburstingWaveJobID] = 0
                            cloudburstingWaveJobID = cloudburstingWaveJobID + 1
                            cloudbursted = True
                            submissionGapBurstCountW = submissionGapBurstCountW +1

                        if (cloudbursted):
                            waitBurstCooldownStack = waitBurstCooldownStack + 5
                    else:
                        if(verbosePrint):
                            print("out of osg rupture jobs to cloudburst on submission gap ")
                else:
                    if (len(rupSubs) > 0):
                        cloudbursted = False
                        # Grab the last job on the OSG submission queue
                        subDatetime = convert(str(rupSubs[len(rupSubs)-1]) + " "+rupDateSubs[len(rupDateSubs)-1])
                        # The the next job to cloudburst is not already submitted
                        if (subDatetime > d):
                        
                            print("Cloudbursting a rupture job because time in between submission too long ...")
                            # Remove a rupture job from the list of OSG jobs
                            rupSubs.pop(len(rupSubs)-1)
                            rupExs.pop(len(rupExs)-1)
                            rupTerms.pop(len(rupTerms)-1)
                            rupDateSubs.pop(len(rupSubs)-1)
                            rupDateExs.pop(len(rupExs)-1)
                            rupDateTerms.pop(len(rupTerms)-1)
                            rupJobCodes.pop(len(rupTerms)-1)
                            # Add it to the list of cloudbursting jobs
                            # Job id is the index+1 of the removed job from the OSG list, runtime value starts at 0 seconds
                            cloudburstingRuptureJobs[cloudburstingRuptureJobID] = 0
                            cloudburstingRuptureJobID = cloudburstingRuptureJobID + 1
                            cloudbursted = True
                            submissionGapBurstCountR = submissionGapBurstCountR + 1

                        if (cloudbursted):
                            waitBurstCooldownStack = waitBurstCooldownStack + 5
                    else:
                        if(verbosePrint):
                            print("out of osg rupture jobs to cloudburst on submission gap ")
                    

                
        # ----------------------------------------

        # Take throughput for both OSG and cloud 
        addRow[1] = instThroughput
        rows.append(addRow)

        #print("Instant throughput is: "+ str(instThroughput)+ " at "+str(curSeconds)+ " seconds.")
        curSeconds += 1

        # If all the jobs are complete (from OSG and cloudbursting) before the OSG runtime is done
        if (completeJobs >= totalJobs):
            endDateTime = d
            print("The completeJobs ("+ str(completeJobs)+") is >= to totalJobs ("+str(totalJobs)+"), breaking out of daterange loop")
            break
        if (len(waveSubs) == 0):
            endDateTime = d
            print("The length of waveSubs in OSG was 0, all done or cloudbursted ")
            break
            
    # Done with the daterange loop and the OSG jobs ----------------------------------- #

    
   
    completedJobs = completeJobs # Save the number of jobs completed over OSG
    
    # If some are, let them finish, keep track of how many seconds it takes keep track of total instant throughput for every second
    if (len(cloudburstingWaveJobs)>0):
        print("There are still running wave jobs after OSG loop")
        finishingWaveJobs = True

        while (finishingWaveJobs):
            cloudJobsComplete = True
            completeJobs = completedJobs
            addRow = [endDateTime, '']
            cloudComputedaSecond = False

            # For every cloudbursting job, increments its time by a second
            for jobID, timeSeconds in cloudburstingWaveJobs.items():
                # If the job is still running after the OSG jobs finish
                if (timeSeconds < waveJobTimeSeconds ):
                    cloudJobsComplete = False # If any job is still running then the jobs aren't complete
                    # Incremement the runtime by 1 second                    
                    newTime = timeSeconds + 1
                    cloudburstingWaveJobs[jobID] = newTime
                    cloudComputedaSecond = True
                else:
                    completeJobs += 1
                    cloudWaveJobs = cloudWaveJobs + 1
            if (cloudJobsComplete):
                finishingWaveJobs = False # trigger end of loop if all jobs complete 

            # increment the date time by 1 second for every extra second of cloud computing after OSG jobs are done
            endDateTime = endDateTime + datetime.timedelta(seconds=1)

            # Calculate cur runtime and throughput
            currRuntime = endDateTime - DAGManSubDatetime
            currRuntimeSec = currRuntime.total_seconds()
            currRuntimeMin = currRuntimeSec/60 # to minutes
            instThroughput = completeJobs/currRuntimeMin

            if (cloudComputedaSecond):
                cloudUseSeconds = cloudUseSeconds + 1 # Increment the time used for cloudcomputing

            # Add a row which is a second and the throughput
            addRow[1] = instThroughput
            rows.append(addRow)

    # ------------- Done with Simulation --------------------- #
    print("---- Done with Simulation -----------------------")

    print("TOTAL JOBS COMPUTED IS: "+str(totalJobs))
    print("The length of complete rupture OSG jobs is:"+str(osgRupJobs))
    print("The length of complete wave OSG jobs is:"+str(osgWaveJobs))
    print("The length of complete rupture cloud jobs is:"+str(cloudRupJobs))
    print("The length of complete wave cloud jobs is:"+str(cloudWaveJobs))
    print("This totals to: "+str(osgRupJobs+osgWaveJobs+cloudRupJobs+cloudWaveJobs))
    print("The number of completeJobs is: "+str(completeJobs))
    print ("--------------------------")
    print("The number that was below threshold was: "+str(belowThreshCountR+belowThreshCountW)+" ("+str(belowThreshCountR)+"were rup and "+str(belowThreshCountW)+" were wave)")
    print("The number of jobs that got cloudbursted due to low threshold is: "+str(cloudburstedJobsFromThreshR+cloudburstedJobsFromThreshW)+" ("+str(cloudburstedJobsFromThreshR)+"were rup and "+str(cloudburstedJobsFromThreshW)+" were wave)")
    print("The number of jobs that got cloudbursted after gap in submission is: "+str(submissionGapBurstCountR+submissionGapBurstCountW)+" ("+str(submissionGapBurstCountR)+"were rup and "+str(submissionGapBurstCountW)+" were wave)")
    print("The number of jobs that got cloudbursted from waiting on the queue too long is: "+str(burstedFromLongWaitCountR+burstedFromLongWaitCountW)+" ("+str(burstedFromLongWaitCountR)+"were rup and "+str(burstedFromLongWaitCountW)+" were wave)")
    cloudDecimal = (cloudRupJobs+cloudWaveJobs)/(osgRupJobs+osgWaveJobs+cloudRupJobs+cloudWaveJobs)
    cloudPercent = cloudDecimal * 100
    formattedCloudPercentage = "{:.2f}%".format(cloudPercent)  # Format the percentage to two decimal places
    print("The percentage of jobs completed on cloud/VDC resources is: "+formattedCloudPercentage)
    cloudDecimal = (cloudRupJobs)/(osgRupJobs+cloudRupJobs)
    cloudPercent = cloudDecimal * 100
    formattedCloudPercentage = "{:.2f}%".format(cloudPercent) 
    print("The percentage of rup jobs completed on cloud/VDC: "+formattedCloudPercentage)
    cloudDecimal = (cloudWaveJobs)/(osgWaveJobs+cloudWaveJobs)
    cloudPercent = cloudDecimal * 100
    formattedCloudPercentage = "{:.2f}%".format(cloudPercent)  
    print("The percentage of wave jobs completed on cloud/VDC: "+formattedCloudPercentage+"\n")


    # Write CSV file with instant throughput every second of the OSG + Cloudbursting simulation runtime 
    fields = ['DateTime','InstThroughput'] # fields of the csv file
    csvfilename = dagcsvname + "_CloudbursingSimulation_"+str(round(time.time())) + ".csv"
    with open(csvfilename, 'w') as csvfile: 
        csvwriter = csv.writer(csvfile)
        csvwriter.writerow(fields)
        csvwriter.writerows(rows)


    # Print the cost of cloud comput resources in the simulation
    cloudCost = cloudMinuteCost * (cloudUseSeconds/60)
    print("At $"+str(cloudMinuteCost)+" per minute of cloud compute, and "+str((cloudUseSeconds/60))+" compute minutes, the cloud cost was: $"+str(cloudCost))

    # Call a script to report the average throughput and runtime of the simulation
    subprocess.call(["python", "avgThrghptSecs.py", csvfilename]) 
    print("-----------------------------------")
    print("Parameters:")
    print("Threshold: "+str(threshold))
    print("Cloud rupture job time in seconds: "+str(ruptureJobTimeSeconds))
    print("Cloud wave job time in seconds: "+str(waveJobTimeSeconds))
    print("Threhold probe time in seconds for burting: "+str(probeTimeSeconds))
    print("Cloud cost per min. in $: "+str(cloudMinuteCost))
    if(metThreshDeactivated):
        print("Burst after met threshold policy deactivated")
    else:
        print("Burst after met threshold policy activated")
    print("Max wait time for jobs till bursting in minutes: "+str(maxWaitTime))
    print("Time we wait since last submission to cloudburst in minues: "+str(submissionWaitTime))
    print("-----------------------------------")
    print("Name of the file of output throughput:"+str(csvfilename))
    print("-----------------Done------------------")




if __name__== "__main__":

    arg1 = -1
    arg2 = -1
    arg3 = -1
    arg4 = -1
    arg5 = -1
    arg6 = -1
    arg7 = -1
    arg8 = -1
    arg9 = -1
    arg10 = -1
    arg11 = -1
    if(sys.argv[1]):
        arg1 = sys.argv[1]
    if(sys.argv[2]):
        arg2 = sys.argv[2]
    if(len(sys.argv)>3):
        arg3 = sys.argv[3]
    if(len(sys.argv)>4):
        arg4 = sys.argv[4]
    if(len(sys.argv)>5):
        arg5 = sys.argv[5]
    if(len(sys.argv)>6):
        arg6 = sys.argv[6]
    if(len(sys.argv)>7):
        arg7 = sys.argv[7]
    if(len(sys.argv)>8):
        arg8 = sys.argv[8]
    if(len(sys.argv)>9):
        arg9 = sys.argv[9]
    if(len(sys.argv)>10):
        arg10 = sys.argv[10]
    if(len(sys.argv)>11):
        arg11 = sys.argv[11]

    main(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11)
