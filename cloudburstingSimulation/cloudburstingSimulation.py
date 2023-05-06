# Python Script that calculates the throughput at and moment for a DAGMan run
import csv
import sys
import datetime
from itertools import chain

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
# Takes in the csv files containing job times and DAGMan times, parses them to get OSG job times and
# simulate cloudbursting.
def main(arg1, arg2):

    jobcsvname = str(arg1)  # CSV with the individual jobs times for the DAGMan
    dagcsvname = str(arg2)  # CSV with one row which has the DAGMans totals and phase times

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

    # Simulation vars ---------------- #

    # threshold for when throughput goes below this do cloudbursting
    threshold = 15

    # Set the constant/average time for rupture and wave jobs in seconds 
    ruptureJobTimeSeconds = 144
    waveJobTimeSeconds = 400 # 15 min
    

    # Set the time in seconds for when we should check throughput against threshold (set to 1 to check every second if throughput goes below thresh)
    probeTimeSeconds = 1 

    # Init the number of wave and rupture jobs for the batch
    waveJobs = 0
    ruptureJobs = 0

    cloudburstingWaveJobs = {}
    cloudburstingRuptureJobs = {}

    # ------------------------- #

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
    totalJobs = lineIndex


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

    
    metThresholdInit = False


    print("The Range is from "+strArr[0]+' '+strArr[1]+" to "+strArr[2]+' '+strArr[3])
    print("Starting the simulation ...")

    # The end time of the simulation, this should be changed when cloudbursting sim ends earlier than actual OSG run
    endDateTime = DAGManTermDatetime

    # data rows of csv file for extracting throughput points
    rows = [] 
    completeOSGJobs = 0

    curSeconds = 0
    # Loop over every second of the runtime and compute the number of complete jobs and runtime to get instant throughput
    for d in daterange(DAGManSubDatetime, DAGManTermDatetime):

        addRow = [d, '']

        completeJobs = 0

        # Compute the number of complete OSG jobs this second. 
        rupIndex = 0
        
        for rupTerm in rupTerms:
            
            # use convert to make a datetime out of the job's date and time
            termDatetime = convert(str(rupTerm) + " "+rupDateTerms[rupIndex])
            exDatetime = convert(str(rupExs[rupIndex]) + " " + rupDateExs[rupIndex])

            # if the job terminated at or before the current time (d) then its complete (and its jobcode is 0)
            if (termDatetime <= d):
                completeJobs = completeJobs + 1

            #if(termDatetime == d):
                #print("Ruptre job is finished at" + str(d))
            
            rupIndex = rupIndex + 1

        waveIndex = 0
        for waveTerm in waveTerms:

            if (waveIndex == len(waveExs)) or (waveIndex == len(waveDateExs)):
                print("BREAKING!!!!")
                break

            # use convert to make a datetime out of the job's date and time
            termDatetime = convert(str(waveTerm) + " "+waveDateTerms[waveIndex])
            exDatetime = convert(str(waveExs[waveIndex]) + " " + waveDateExs[waveIndex])

            # if the job terminated at or before the current time (d) then its complete (and its jobcode is 0)
            if (termDatetime <= d):
                completeJobs = completeJobs + 1

            #if(termDatetime == d):
            #    print("Wave job is finished at" + str(d))

            waveIndex = waveIndex + 1


        # Cloudbursted rupture jobs
        for jobID, timeSeconds in cloudburstingRuptureJobs.items():
            # The the cloudbursting jobs is still running
            if (timeSeconds < ruptureJobTimeSeconds ):
                newTime = timeSeconds + 1
                cloudburstingRuptureJobs[jobID] = newTime    # Increment its runtime by a second
            else:
                # Else the jobs is complete, 
                completeJobs = completeJobs + 1
                #print("A cloudbursted rupture job finished during OSG range")

        # Cloudbursted wave jobs
        for jobID, timeSeconds in cloudburstingWaveJobs.items():

            # The the cloudbursting jobs is still running
            if (timeSeconds < waveJobTimeSeconds ):
                newTime = timeSeconds + 1
                cloudburstingWaveJobs[jobID] = newTime    # Increment its runtime by a second
            else:
                # Else the jobs is complete, 
                completeJobs = completeJobs + 1
                #print("A cloudbursted wave job finished during OSG range")



        # Calculate cur runtime ( the difference between current time d and the start )
        currRuntime = d - DAGManSubDatetime
        currRuntimeSec = currRuntime.total_seconds()
        currRuntimeMin = currRuntimeSec/60 # to minutes

        # Throughput is 0 at 0 seconds
        if(currRuntimeMin == 0):
            continue

        instThroughput = completeJobs/currRuntimeMin

        # Check to see if we have initially met the aimed threshold
        if (not metThresholdInit):
            if (instThroughput >= threshold):
                metThresholdInit = True
                print("Threshhold met!")

        #print(str(d))
        # Do cloudburting if have initially met the aimed throughput threshold
        if (metThresholdInit):
            if (currRuntimeSec % probeTimeSeconds ==  0): # Check if below threshold every set amount of seconds 
                if (instThroughput < threshold):
                    if (completeJobs >= ruptureJobs):
                        

                        # Remove a wave job from the list of OSG jobs

                        
                        if (len(waveSubs) > 0):
                            # If its not already submitted on OSG
                            subDatetime = convert(str(waveSubs[len(waveSubs)-1]) + " "+waveDateSubs[len(waveDateSubs)-1])
                            print(str(subDatetime))
                            print("D in wave is: "+str(d))

                            if (subDatetime > d):
                                print("Cloudbursting a wave job ...")
                                waveSubs.remove(waveSubs[len(waveSubs)-1])
                                waveExs.remove(waveExs[len(waveExs)-1])
                                waveTerms.remove(waveTerms[len(waveTerms)-1])
                                print(len(waveSubs))

                                # Add it to the list of cloudbursting jobs
                                # Job id is the index+1 of the removed job from the OSG list, runtime value starts at 0 seconds
                                cloudburstingWaveJobs[len(waveSubs)] = 0
                    else:
                        

                        if (len(rupSubs) > 0):
                            # If its not already submitted on OSG
                            subDatetime = convert(str(rupSubs[len(rupSubs)-1]) + " "+rupDateSubs[len(rupDateSubs)-1])
                            print(str(subDatetime))
                            print("D in rup is: "+str(d))
                            # The the next job to cloudburst is not already submitted
                            if (subDatetime > d):
                            
                                print("Cloudbursting a rupture job ...")
                                # Remove a rupture job from the list of OSG jobs
                                rupSubs.remove(rupSubs[len(rupSubs)-1])
                                rupExs.remove(rupExs[len(rupExs)-1])
                                rupTerms.remove(rupTerms[len(rupTerms)-1])
                                print(len(rupSubs))
                                # Add it to the list of cloudbursting jobs
                                # Job id is the index+1 of the removed job from the OSG list, runtime value starts at 0 seconds
                                cloudburstingRuptureJobs[len(rupSubs)] = 0


        addRow[1] = instThroughput
        rows.append(addRow)

        #print("Instant throughput is: "+ str(instThroughput)+ " at "+str(curSeconds)+ " seconds.")
        curSeconds += 1

        # If all the jobs are complete (from OSG and cloudbursting) before the OSG runtime is done
        allComplete = False
        if (completeJobs >= totalJobs):
            endDateTime = d
            print("The completeJobs ("+ str(completeJobs)+") is >= to totalJobs ("+str(totalJobs)+"), breaking out of daterange loop")
            allComplete = True
        if (allComplete):
            break


    # Done with the daterange loop and the OSG jobs ----------------------------------- #



    # Check if cloud jobs are still running
    runningWaveJobs = False
    for jobID, timeSeconds in cloudburstingWaveJobs.items():
        # If the cloud job is still running
        if (timeSeconds < waveJobTimeSeconds ):
            runningWaveJobs = True
            break

   
    completeOSGjobs = completeJobs # Save the number of jobs completed over OSG
    
    # If some are, let them finish, keep track of how many seconds it takes keep track of total instant throughput for every second
    if (runningWaveJobs): 
        print("There are still running wave jobs after OSG loop")
        finishingWaveJobs = True
        extraSeconds = 0

        while (finishingWaveJobs):
            cloudJobsComplete = True
            completeJobs = completeOSGjobs
            addRow = [endDateTime, '']

            # For every cloudbursting job
            for jobID, timeSeconds in cloudburstingWaveJobs.items():
                # If the job is still running after the OSG jobs finish
                if (timeSeconds < waveJobTimeSeconds ):
                    cloudJobsComplete = False
                    # Incremement the runtime by 1 second                    
                    newTime = timeSeconds + 1
                    cloudburstingWaveJobs[jobID] = newTime
                else:
                    completeJobs += 1 

            if (cloudJobsComplete):
                finishingWaveJobs = False # trigger end of loop if all jobs complete 


            # increment the date time by 1 second for every extra second of cloud computing after OSG jobs are done
            endDateTime = endDateTime + datetime.timedelta(seconds=1)

            # Calculate cur runtime 
            currRuntime = endDateTime - DAGManSubDatetime
            currRuntimeSec = currRuntime.total_seconds()
            currRuntimeMin = currRuntimeSec/60 # to minutes

            instThroughput = completeJobs/currRuntimeMin


            # Add a row which is a second and the throughput then
            addRow[1] = instThroughput
            rows.append(addRow)

    # ------------- Done with Simulation --------------------- #



    # Write CSV file with instant throughput every second of the OSG + Cloudbursting simulation runtime 
    fields = ['DateTime','InstThroughput'] # fields of the csv file
    csvfilename = dagcsvname + "_CloudbursingSimulation" + ".csv"
    with open(csvfilename, 'w') as csvfile: 
        csvwriter = csv.writer(csvfile)
        csvwriter.writerow(fields)
        csvwriter.writerows(rows)




if __name__== "__main__":
    main(sys.argv[1], sys.argv[2])

