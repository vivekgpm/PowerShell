$Global:wfRunningInstance = [System.Collections.ArrayList]@()
$Global:wfArray  = [System.Collections.ArrayList]@()
$Global:wfItemInstances = [System.Collections.ArrayList]@()  
  
   function GetListitemWorkflowInstance($listName){
   
   $wfRunningInstance = [System.Collections.ArrayList]@()
   try{
   
   #Get List object
   $list=Get-PnPList -Identity $listName

   Write-Host "Total Items in the list- " $list.ItemCount #Item count in the list

   $listItems= (Get-PnPListItem -List $listName -Fields "Title","Author","Editor").FieldValues #Get list items
   
   foreach($listItem in $listItems){    
   
   #Check running workflow instaces for the items
   $status  = Get-PnPWorkflowInstance -List $listName -ListItem $listItem.ID  | Select Status,WorkflowSubscriptionId |  Select-String Started, "In Progress", Terminated
        
   if($status.Length -gt 0){       
        $arrayM =  $status              
        $arr = $arrayM -split '='        
        if($arr){
            if($arr.Contains("}")){
                $f2 = $arr[2].Replace("}","")
                $New = $wfRunningInstance+=$f2 #Adding workflow definition ID into array
                Write-Host "0"
                }
            else{
                if($arr[2].Contains("}")){
                $f2 = $arr[2].Replace("}","")
                
                $New = $wfRunningInstance+=$f2  #Adding workflow definition ID into array
                
                }
                else{
                $New = $wfRunningInstance+=$arr[2]#Adding workflow definition ID into array                
                }                
               }
            }
        }        
      } 
    }
    catch{
        Write-Host "Error"
        Write-Host $_
        } 
        
        #If there are running instances, check workflow subcriptions
       if($wfRunningInstance.Count -gt 0){
        #GetSiteOwners
        GetWorkflowDefinitions -wfr $wfRunningInstance
       }
       else{
        Write-Host "There are running instances of the workflow"
       }     
   }

   #Gets site owners of the current site
   function GetSiteOwners($wfNames  = [System.Collections.ArrayList]@()){
    
    $siteOwners  = [System.Collections.ArrayList]@()
    #Get all the site users
    $users = Get-PnPUser

    foreach($user in $users){
        if($user.IsSiteAdmin){ #Checks for Site Admin
           $New = $siteOwners+= $user.Title +"(" + $user.Email +")"    
        }
    }
    #Emailing to Site owners and running instance workflow names
    if($siteOwners.Count -gt 0){
        $mailBody = "The list contains following running instances of the workflow <br/>" 
        $mailBody +=  $wfNames | Out-String
        $mailBody += "<br/>"
        $mailBody += "Site Owners name as follows:- <br/><br/>"
        $mailBody += $siteOwners 
        Send-PnPMail -To $toemailaddress -Subject $subject -Body $mailBody -From $fromemailaccount -Password $Password
    }
   }
   
  
   function GetWorkflowDefinitions($wfr  = [System.Collections.ArrayList]@()){
    # All the workflow subscriptions
    $wfd = Get-PnPWorkflowSubscription
    
    
    foreach($wfw in $wfd){           
        foreach($wR in $wfr){
            #Comparing with running instances           
            if($wR -match $wfw.Id)
            {                           
                 $New = $wfItemInstances+=$wfw.Name # get the workflow name
            }
        }    
    }
    
    if( $wfItemInstances.Count -gt 0){
        GetSiteOwners -wfNames $wfItemInstances
    }
   }
#Connect to the site
Connect-PnPOnline -Url $SiteURl -Credentials (Get-Credential)

#Check the 2013 workflow instace for the given list
GetListitemWorkflowInstance -listName $ListTitle