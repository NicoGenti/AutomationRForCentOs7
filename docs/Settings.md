# /Scripts/Config/VariabiliGlobali.psm1



**ATTENTION**
 When you set the Variables into VariabiliGlobali.psm1:

- **Don't delete " " ** In Section "# Variables set by User" 
  *Example:* 
``` powershell
$RFolderName = "NAME FOLDER R SCRIPT" #OLD
$RFolderName = "prototype-r"	#NEW
```


- **Don't delete $ ** In Section "System Variables" 
  *Example:* 

``` powershell
$Global:useEmailSmartpeg = $true
```


  - 1 If you download the Zip, extract the Zip archive anywhere you want on your PC;

  - 2 navigate into subfolder *Config* and open *VariabiliGlobali.psm1* with text editor  for settings;

  - 3 set *$Global:rootFolder* with the **FULL PATH** of Automation R for CentOs7 Folder;
    
    ```powershell
    $Global:rootFolder = "YOUR FULL PATH OF AUTOMATION SCRIPT"
    ```
    
  - 4 set $RFolderName with the name of RScript folder (**NOT FULL PATH, ONLY NAME**);
    
    ```powershell
    $Global:RFolderName = "NAME FOLDER R SCRIPT"
    ```

  - 5 set FTP variables;
    
    ```powershell
    $Global:serverFTP = "YOUR SERVER FTP"
    $Global:userFTP = "YOUR USER FTP"
    $Global:passFTP = "YOUR PASSWORD FTP"
    ```
    
  - 6 set GIT variables (*ID Project and ID Repository can be retrieve trough API Devops*):
    
      ```powershell
    $Global:userGit = "DEVOPS USERNAME"
    $Global:passGIT = "DEVOPS TOKEN"
    $Global:IdProject = "ID PROJECT" 
    $Global:IdRepo = "ID REPOSITORY"
    $Global:organization = "ORGANIZATION NAME"
    $Global:gitBranch = "BRANCH GIT NAME"
    ```
    
  - 7 set parameter for Mail and Client Mail *(About SendGrid Token view [SendGrid Guide](./SendGrid.md))*

    ```powershell
      - function Send-Mail() {
            Param (
                $Body
          )
    
      $Parameters = @{
          FromAddress = "EMAIL SMARTPEG SENDER ADDRESS"
          ToAddress   = "EMAIL ADMINISTRATOR RECEIVER ADDRESS"
          Subject     = "YOUR SUBJECT"
          Body        = $Body
          Token       = "YOUR SENDGRID TOKEN"
          FromName    = "NAME OF SENDER"
      }
      Send-PSSendGridMail @Parameters
      }
      
      - function Send-MailToClient() {
        Param (
            $Body
        )
    
    $Parameters = @{
        FromAddress = ""
        ToAddress   = ""
        Subject     = ""
        Body        = $Body
        Token       = ""
        FromName    = ""
    }
    Send-PSSendGridMail @Parameters
    }
    ```

**ONLY FOR EXPERT**

- It's possible enable or disable some program features:
```powershell
# Set $true for send Email
$Global:useEmail = $true
# Set $true for send Email to your Client
$Global:useEmailToClient = $true 
```

- When you move some system folder you need to write the new correct path in section "System Folders";
``` powershell
  $Global:outputFTPPath = '/output' #old
  $Global:outputFTPPath = '/files'  #new
```
