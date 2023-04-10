#   Authored by Marcus Adair, SCI Institute, University of Utah, Feb. 2023
#
#   Extracts submission and execution data from a txt file and writes it
#   to a CSV  
#
import csv
import sys


def main(arg1):

    txtname = str(arg1)

    # fields of the csv file 
    fields = ['RupWait', 'RupEx', 'WaveWait', 'WaveEx'] 
        
    # data rows of csv file 
    rows = [] 

    addRow = ["","","",""]
    lineCount = 0

    rupBeg = "Rupture-Bundle:"
    rupSubStr = " to go through submission until execution."
    rupExStr = "minutes to complete successfully."
    waveBeg = "fakequakes_run"
    waveSubStr = "minutes from submission to execution."
    waveExStr = "completion to make waveforms for 2 ruptures."


    # Read the txt file
    file = open(txtname, "r") 
    for line in file:

        # Extract execution and wait times for rupture jobs.
        if (line.startswith(rupBeg) and line.endswith(rupSubStr + "\n")):

            strArr = line.split(" ")
            toAdd = strArr[2]

            addRow[0] = toAdd

        elif (line.startswith(rupBeg) and line.endswith(rupExStr + "\n")):

            strArr = line.split(" ")
            toAdd = strArr[2]

            addRow[1] = toAdd

        # Extract execution and wait times for waveform jobs.
        elif (line.startswith(waveBeg) and line.endswith(waveSubStr + "\n")):

            strArr = line.split(" ")
            toAdd = strArr[2]

            addRow[2] = toAdd
    
        elif (line.startswith(waveBeg) and line.endswith(waveExStr + "\n")):

            strArr = line.split(" ")
            toAdd = strArr[2]

            addRow[3] = toAdd

        else: 
            continue

        # Increment then reset the count every 2 lines
        lineCount += 1
        if (lineCount > 1):
            lineCount = 0
            rows.append(addRow)
            addRow = ["","","",""]

    # After reading the txt file, write it's time stats to a csv file ---------------------------- #

    # name of csv file 
    csvfilename = txtname + "_to_CSV" + ".csv"

    # Write CSV file 
    with open(csvfilename, 'w') as csvfile: 
        # creating a csv writer object 
        csvwriter = csv.writer(csvfile) 
            
        # writing the fields 
        csvwriter.writerow(fields) 
            
        # writing the data rows 
        csvwriter.writerows(rows)



if __name__== "__main__":
    main(sys.argv[1])