###################################################################
#Code by marcel_One_
#Do what you want with it, but I dont take any responsibility
#Please contact me if you found bugs or want an added feature
#Sorry for weird german variable names at some points or bad english
#Checks for errors and restarts the server. Also checks for the right amount of servers running.
#Echo <3
###################################################################
#21.11.2023 added:
#[TCP CLIENT] [R14NETCLIENT] connection to ws:///login?auth failed
#[TCP CLIENT] [R14NETCLIENT] connection to ws:///login?auth established
#[NETGAME] Service status request failed: 404 Not Found
#22.11.2023 
#the $flags variable is now in "THINGS YOU CAN BUT DONT NEED SET UP!!!"
#added an $region vaiable in THINGS YOU HAVE TO SET UP!!!
#the $flags variable now has the $region variable in it




#######THINGS YOU HAVE TO SET UP!!!#######
# Get the current number of `echovr.exe` processes running
$processName = "echovr" #without .exe, this is the name of the echovr.exe (in most cases its just echovr)
$amountOfInstances = 4 #number of instances you want to run
$global:filepath = "C:\Users\Administrator\Desktop\ready-at-dawn-echo-arena" #the path to your echo-folder (No \ at the end!!!)
$region = "euw";
##############################################################
#Please use one of the following region codes after in $region
#  "uscn", // US Central North (Chicago)
#  "us-central-2", // US Central South (Texas)
#  "us-central-3", // US Central South (Texas)
#  "use", // US East (Virgina)
#  "usw", // US West (California)
#  "euw", // EU West 
#  "jp", // Japan (idk)
#  "sin", // Singapore oce region
##############################################################


#######THINGS YOU CAN BUT DONT NEED SET UP!!!#######
#This are all known errors. If you add one, you might need to change the "check_for_errors" function
$global:errors = "Unable to find MiniDumpWriteDump", "[TCP CLIENT] [R14NETCLIENT] connection to ws:///config closed", "[NETGAME] Service status request failed: 400 Bad Request", "[NETGAME] Service status request failed: 404 Not Found", "[TCP CLIENT] [R14NETCLIENT] connection to ws:///login failed", "[TCP CLIENT] [R14NETCLIENT] connection to ws:///login established"
$global:delay_for_exiting = 30 #seconds, this timer sets the time for the second error check.
$global:delay_for_process_checking = 1 #seconds Delay between each process check
$global:verbose = $false # If set to true, the Jobs/Tasks Output will be visible
$flags =  "-serverregion $region -server -headless -noovr -fixedtimestep -nosymbollookup  -timestep 120" # Flags/Parameters

echo $flags

#DONT CHANGE
[System.Collections.ArrayList]$global:PIDS = @()
$global:startedTime = ((get-date) - (gcim Win32_OperatingSystem).LastBootUpTime | Select TotalSeconds).TotalSeconds
$global:path = "$filepath\bin\win10\$processName.exe" #Path of your echovr.exe
$global:logpath = "$filepath\_local\r14logs"
$global:checkRunningBool = $false # is set to true if the check_for_errors function is running

#This functions checks if enough instances are running. If not it will open enough and add the PIDs to an array $PIDS
function check_for_amount_instances($amount, $path, $processName, $flags){
    $echovrProcesses = Get-Process -Name $processName 
    # If there are less than $amount echovr.exe processes running, start a new one and log PID
        #if not enough start, else check for errors
    if ($echovrProcesses.Count -lt $amountOfInstances) {
        $app = Start-Process -FilePath  $path  $flags -PassThru # start process and get ID
        $global:PIDS += $app.Id # add ID to array
    }
    else
    {
        if($PIDS.count -gt 0){
            if ($checkRunningBool -eq $false)
            {
                $global:checkRunningBool = $true
                check_for_errors
            }
        }
    }
}


#This function checks the logs for errors specified in the $errors array
function check_for_errors(){

    #check each PIDs logfiles last line
    for ($count = $PIDS.count -1; $count -ge 0; $count--){
        $pfad_logs = $logpath+"\*_" + $PIDS[$count] + ".log" #the path of the specified logfile
        [string[]]$arrayFromFile = Get-Content -Path $pfad_logs
        # delete the first X charachters (the datetime) and delete IP:Port, will probably need to remove more for new found errors
        $line_clean = $arrayFromFile[$arrayFromFile.count -1].Substring(25) -replace "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*:[0-9]*", "" -replace "\?auth=.*&displayname=.* ", " "
        #if one of the errors in our "error" array contains the content of the last logged line
        if ( $errors -contains $line_clean ){
            #start a new task for the check if the error will stay. That way the loop doesnt need to interrupt like with sleep
            Start-Job -ScriptBlock $Function:check_for_error_consistency -ArgumentList $line_clean, $PIDS[$count], $errors, $delay_for_exiting, $logpath 
            #remove the PID with an error from the PID array
            $global:PIDS.Remove($PIDS[$count])
            echo ("after "+ $PIDS)
            echo ($line_clean)


        }
    }
    $global:checkRunningBool = $false
}

#function to check if the specified error is still present after $errorDelayCheckTime
function check_for_error_consistency($line_clean, $ID, $errors, $delay_for_exiting, $logpath){
    $errorindex = -1 #probably not needed to set here, but to get sure i set out outside the for below
    Start-Sleep -Seconds $delay_for_exiting
    #get the index of the specified error, to check if we got the same error and not just an random error from the array
    $check = $true
    for ($a = 0; $check -eq $true; $a++){
        # if the index content is the previous error, save the indexno and stop the for loop
        if ($errors[$a] -contains $line_clean){
            $errorindex = $a
            $check = $false
        }
        #if this happens, i am stupid D: (Okay, I am also if it doesnt...)
        if ( $a -gt $errors.count ){
            Write-Host "Unknown Problem in check_for_error_consistency. Contact marcel_One_"
            break;
        }
    
    }
    $pfad_logs = $logpath+"\*_" + $ID + ".log" #the path of the specified logfile
    [string[]]$arrayFromFile = Get-Content -Path $pfad_logs #get every line of that file
    # delete the first X charachters (the datetime) and delete IP:Port, will probably need to remove more for different error
    $line_clean = $arrayFromFile[$arrayFromFile.count -1].Substring(25) -replace "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*:[0-9]*", "" -replace "\?auth=.*&displayname=.* ", " "
    #if one of the errors in out error array contains the content of the last logged line kill the process, else add the PID back as an output
    if ( $errors[$errorindex] -contains $line_clean ){
        taskkill /F /PID $ID
    }
    else{
        Write-Output "addPID.$ID"
    }
        
}



#function to check the output, echo the output and react on the dependent output if needed
function check_every_output_of_jobs(){
    $IDofJobs = Get-Job -State Running | Select Id
    foreach ($job in $IDofJobs){
        $result = Receive-Job -Id $job.Id -Wait -AutoRemoveJob
        #If verbose is active output everything from the jobs
        if ($verbose -eq $true){
            echo $result      
        }

        #If the result contents an PID, remove the string before it and add the PID back to the PIDS array
        if ($result -like "addPID.*"){
            $PIDtoAddToArray = $result.Substring(7) # remove the string
            $global:PIDS += $PIDtoAddToArray # add ID to array
        }
    }
}


#Check if all the PIDs in the PIDS Array are still running (one might be crashed)
function check_if_PIDs_in_Array_are_running(){
    for ($count = $PIDS.count -1; $count -ge 0; $count--){
    #foreach ($ID in $PIDS){
        if ( (Get-Process -Id $PIDS[$count]) -eq $null){
             #If the process isnt running, remove it from the PIDS array
            $global:PIDS.Remove($PIDS[$count])
        }
    }
}


while ($true) {
    #If the realtime is higher or equal to the last logged starttime, run this function and relog the new time
    if (((get-date) - (gcim Win32_OperatingSystem).LastBootUpTime | Select TotalSeconds).TotalSeconds -ge $startedTime + $delay_for_process_checking){
        check_for_amount_instances $amountOfInstances $path $processName $flags
        check_if_PIDs_in_Array_are_running
        $global:startedTime = ((get-date) - (gcim Win32_OperatingSystem).LastBootUpTime | Select TotalSeconds).TotalSeconds        
    }
    check_every_output_of_jobs
} 





