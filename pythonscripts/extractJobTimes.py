#   Authored by Marcus Adair, SCI Institute, University of Utah, Mar. 2023
#
#   Extracts submission and execution data from a txt file and writes it
#   to a CSV  
#
import csv
import sys


def main(arg1):

    # txt file to parse
    txtname = str(arg1)

    # fields of the csv file 
    jobfields = ['RupSub', 'RupEx', 'RupTerm','RupSubDate', 'RupExDate', 'RupTermDate',  'WaveSub', 'WaveEx', 'WaveTerm','WaveSubDate', 'WaveExDate', 'WaveTermDate',  'JobCode'] 

    # data rows of csv file 
    jobrows = [] 

    addRow = ["","","","","","","","","","", "","",""]
    lineCount = 0


    # For the DAGMan total and phase times/dates
    dagfields = ['DagSub','DagSubDate', 'DagTerm', 'DagTermDate', 'DagRuntime', 'ASub','ASubDate', 'ATerm', 'ATermDate', 'ARuntime','BSub','BSubDate', 'BTerm','BTermDate', 'BRuntime','CSub','CSubDate', 'CTerm', 'CTermDate', 'CRuntime'  ]
    dagrows = []
    addDagRow = ['','','','','','','','','','','','','','','','','','','','']


    appendDagRow = False


    # Read the txt file
    file = open(txtname, "r") 
    for line in file:

        # Extract sub, ex, and term times/dates for rupture jobs and wave jobs.
        if (line.startswith("RupJob-") and "submitted" in line):
            strArr = line.split(" ")
            toAdd = strArr[4]
            addRow[0] = toAdd
            toAdd = strArr[8]
            addRow[3] = toAdd.rstrip()

        elif (line.startswith("RupJob-") and "executed" in line):
            strArr = line.split(" ")
            toAdd = strArr[4]
            addRow[1] = toAdd
            toAdd = strArr[8]
            addRow[4] = toAdd.rstrip()

        elif (line.startswith("RupJob-") and "terminated" in line):
            strArr = line.split(" ")
            toAdd = strArr[4]
            addRow[2] = toAdd

            toAdd = strArr[8]
            addRow[5] = toAdd.rstrip()




        elif (line.startswith("WaveJob-") and "submitted" in line):
            strArr = line.split(" ")
            toAdd = strArr[4]
            addRow[6] = toAdd

            toAdd = strArr[8]
            addRow[9] = toAdd.rstrip()
            
        elif (line.startswith("WaveJob-") and "executed" in line):
            strArr = line.split(" ")
            toAdd = strArr[4]
            addRow[7] = toAdd
            toAdd = strArr[8]
            addRow[10] = toAdd.rstrip()

        elif (line.startswith("WaveJob-") and "terminated" in line):
            strArr = line.split(" ")
            toAdd = strArr[4]
            addRow[8] = toAdd
            toAdd = strArr[8]
            addRow[11] = toAdd.rstrip()


        elif ("had an exit code of:" in line):
            strArr = line.split(" ")
            toAdd = strArr[6]
            addRow[12] = toAdd.rstrip()




        # Hand the first lines of the txt file which its the DAGMan totat and phase times
        elif (line.startswith("DAGMan submitted")):
            strArr = line.split(" ")
            toAdd = strArr[3]
            addDagRow[0] = toAdd

            toAdd = strArr[6]
            addDagRow[1] = toAdd

            toAdd = strArr[10]
            addDagRow[2] = toAdd

            toAdd = strArr[13]
            addDagRow[3] = toAdd

            toAdd = strArr[17]
            addDagRow[4] = toAdd.rstrip()

        elif (line.startswith("A-Phase submitted")):
            strArr = line.split(" ")
            toAdd = strArr[3]
            addDagRow[5] = toAdd

            toAdd = strArr[6]
            addDagRow[6] = toAdd

            toAdd = strArr[10]
            addDagRow[7] = toAdd

            toAdd = strArr[13]
            addDagRow[8] = toAdd

            toAdd = strArr[17]
            addDagRow[9] = toAdd.rstrip()

        elif (line.startswith("B-Phase submitted")):
            strArr = line.split(" ")
            toAdd = strArr[3]
            addDagRow[10] = toAdd

            toAdd = strArr[6]
            addDagRow[11] = toAdd

            toAdd = strArr[10]
            addDagRow[12] = toAdd

            toAdd = strArr[13]
            addDagRow[13] = toAdd

            toAdd = strArr[17]
            addDagRow[14] = toAdd.rstrip()

        elif (line.startswith("C-Phase submitted")):
            strArr = line.split(" ")
            toAdd = strArr[3]
            addDagRow[15] = toAdd

            toAdd = strArr[6]
            addDagRow[16] = toAdd

            toAdd = strArr[10]
            addDagRow[17] = toAdd

            toAdd = strArr[13]
            addDagRow[18] = toAdd

            toAdd = strArr[17]
            addDagRow[19] = toAdd.rstrip()

            appendDagRow = True




        else:
            continue
            


        # Increment then reset the count every 4 lines (a row of the csv is made from every 4 ines)
        if (line.startswith("WaveJob-") or line.startswith("RupJob-")):
            lineCount += 1
        if (lineCount > 3):
            lineCount = 0
            jobrows.append(addRow)
            addRow = ["","","","","","","","","","", "","",""]

        if (appendDagRow == True):
            dagrows.append(addDagRow)
            appendDagRow = False




    # After reading the txt file, write it's time stats to a csv file ---------------------------- #

    # name of csv file 
    csvfilename = txtname + "_jobTimes_to_CSV" + ".csv"

    # Write CSV file 
    with open(csvfilename, 'w') as csvfile: 
        
        csvwriter = csv.writer(csvfile) # creating a csv writer object 
        csvwriter.writerow(jobfields) # writing the fields  
        csvwriter.writerows(jobrows) # writing the data rows





    csvfilename = txtname + "_dagTimes_to_CSV" + ".csv"

    # Write CSV file 
    with open(csvfilename, 'w') as csvfile: 
        csvwriter = csv.writer(csvfile)
        csvwriter.writerow(dagfields)
        csvwriter.writerows(dagrows)



    



if __name__== "__main__":
    main(sys.argv[1])