#
# Python file that returns the difference of two time differences. 

import csv
import sys
import datetime
import math

def main(timeBeg, timeEnd, dateBeg, dateEnd):


    datetime_Beg = datetime.datetime.strptime(str(timeBeg +" "+ dateBeg), '%H:%M:%S %Y-%m-%d')

    datetime_End = datetime.datetime.strptime(str(timeEnd +" "+ dateEnd), '%H:%M:%S %Y-%m-%d')

    # Get difference
    timeDiff = datetime_End - datetime_Beg
    
    # Split to an array
    splitTimeDiff = str(timeDiff).split(":")
    hourS = splitTimeDiff[0]
    minS = splitTimeDiff[1]
    secS = splitTimeDiff[2]

    #print(hourS)
    #print(minS)
    #print(secS)

	
    # Convert hours to float
    if(hourS != ''):
        hourS = hourS.lstrip("0")


        if(hourS != ""):
            hour = float(hourS)
        else:
            hour = 0
    else:
        hour = 0


    # Convert minutes to float
    if(minS != ''):
        misS = minS.lstrip("0")


        if(minS != ""):
            #print(minS)
            minute = float(minS)
        else:
            minute = 0
    else:
        minute = 0


    # Convert seconds to float
    if(secS != ''):
        secS = secS.lstrip("0")


        if(secS != ""):
            sec = float(secS)
        else:
            sec = 0
    else:
        sec = 0



    # Convert to minutes in decimal form 
    rtrn = 0 
    if(hourS != "0"):
        rtrn += hour * 60
    if(minS != "0"):
        rtrn += minute
    if(secS != "0"):
        rtrn += sec/60
     
    # round to 4 decimal points
    rtrn = round(rtrn, 4)

    
    # Return the time difference in minutes. Return as minutes in decimal form
    # So its easy to add up and such later
    print(rtrn)




if __name__== "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])
