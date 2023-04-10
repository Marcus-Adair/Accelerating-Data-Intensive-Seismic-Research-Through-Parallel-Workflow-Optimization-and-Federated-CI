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
    print("d1 is "+str(d1))
    print("d2 is "+str(d2))

    d1Str = str(d1)
    d2Str = str(d2)
    splitD1 = d1Str.split(' ')
    splitD2 = d2Str.split(' ')
    d1date = splitD1[0]
    d2date = splitD2[0]


    rtrn = []

    notEqual = True

    while (notEqual):

        # TODO: make if the dates equal the same return this 
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

            print("dtemp is: "+str(dtemp))

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

            print("Inc'ed Date is: "+d1date)


    return rtrn


    




def main(arg1, arg2):

    jobcsvname = str(arg1)  # CSV with the individual jobs times for the DAGMan
    dagcsvname = str(arg2)  # CSV with one row which has the DAGMans totals and phase times

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
    # end of loop -------------------------------




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

        # TODO (Maybe also do it for Phases A, B, and C, but idk if i need it)

        lineCount += 1
    # end of loop -------------------------------


    print("The Range is from "+strArr[0]+' '+strArr[1]+" to "+strArr[2]+' '+strArr[3])
    print("Starting to calculate the instant throughput for every second of the DAGMan ...")

    # data rows of csv file for extracting throughput points
    rows = [] 
    rows2 = [] # for running jobs

    # Loop over the Instant throughput points in time every second
    for d in daterange(DAGManSubDatetime, DAGManTermDatetime):

        addRow = [d, '']
        addRow2 = [d, '']

        completeJobs = 0
        runningJobs = 0

        rupIndex = 0
        for rupTerm in rupTerms:
            
            # use convert to make a datetime out of the job's date and time
            termDatetime = convert(str(rupTerm) + " "+rupDateTerms[rupIndex])

            exDatetime = convert(str(rupExs[rupIndex]) + " " + rupDateExs[rupIndex])

            # if the job terminated at or before the current time (d) then its complete (and its jobcode is 0)
            if (termDatetime <= d):
                
                #print("jobcode is "+ str(rupJobCodes[rupIndex]))
                #if(rupJobCodes[rupIndex] == str(0)):
                
                completeJobs = completeJobs + 1


            # Count running jobs at this second
            if (termDatetime > d): # If the termination time is after the current time
                if (exDatetime <= d): # If the execution time is at or before the current time
                    runningJobs = runningJobs + 1
                


            rupIndex = rupIndex + 1

        waveIndex = 0
        #print("Length of waveEwaveDateExs is: "+ str(len(waveDateExs)))
        for waveTerm in waveTerms:


            if (waveIndex == len(waveExs)) or (waveIndex == len(waveDateExs)):
                break

            #print("waveIndex is: "+str(waveIndex))

            # use convert to make a datetime out of the job's date and time
            termDatetime = convert(str(waveTerm) + " "+waveDateTerms[waveIndex])

            exDatetime = convert(str(waveExs[waveIndex]) + " " + waveDateExs[waveIndex])

            # if the job terminated at or before the current time (d) then its complete (and its jobcode is 0)
            if (termDatetime <= d):
                #if(waveJobCodes[waveIndex] == 0):
                completeJobs = completeJobs + 1

            if (termDatetime > d): # If the termination time is after the current time
                if (exDatetime <= d): # If the execution time is at or before the current time
                    runningJobs = runningJobs + 1

            waveIndex = waveIndex + 1

            





        # Calculate cur runtime ( the difference between current time d and the start )
        currRuntime = d - DAGManSubDatetime
        currRuntimeSec = currRuntime.total_seconds()
        currRuntimeMin = currRuntimeSec/60 # to minutes

        # Throughput is 0 at 0 seconds
        if(currRuntimeMin == 0):
            continue

        instThroughput = completeJobs/currRuntimeMin
        addRow[1] = instThroughput
        rows.append(addRow)

        addRow2[1] = runningJobs
        rows2.append(addRow2)

        #if (runningJobs > 0):
        #    print("Running jobs: "+ str(runningJobs))

        

    # Write CSV file
    fields = ['DateTime','InstThroughput'] # fields of the csv file
    csvfilename = dagcsvname + "_instThroughput_csv" + ".csv"
    with open(csvfilename, 'w') as csvfile: 
        csvwriter = csv.writer(csvfile)
        csvwriter.writerow(fields)
        csvwriter.writerows(rows)

    # Write 2nd CSV file
    fields2 = ['DateTime','RunningJobs'] # fields of the csv file
    csvfilename = dagcsvname + "_runningJobs_csv" + ".csv"
    with open(csvfilename, 'w') as csvfile: 
        csvwriter = csv.writer(csvfile)
        csvwriter.writerow(fields2)
        csvwriter.writerows(rows2)





if __name__== "__main__":
    main(sys.argv[1], sys.argv[2])

