# Automation R on CentOS7

Powerfull script Powershell for R automatization.

It be able to send Mail of errors and log it.

N.B.

**This repository is for research purposes only**

---

## Installation

How to have a nice installation of ***Automation R***

- 1. Setup SendGrid for mail:
  - 1.1 View the file [SENDGRID](./SendGrid.md) for installation method;

- 2. Download scripts:

  - 2.1 Download or Clone on your PC;

- 3. For all program settings view [Settings](./Settings.md)

- 4. Install Powershell:

  - 4.1 For Powershell installation on CentOs redirect to Non Officale Guide [CentOs Installation Guide](https://linuxhint.com/install_powershell_centos/);

- 5. Into PowerShell Console with Administrator role install these Modules:

  *for Linux user: **sudo pwsh** into shell*

  ``` PowerShell
  Install-Module -Name PSSendGrid -RequiredVersion 0.3.0 -Force
  
  Install-Module PoShLog -RequiredVersion 2.2.0-preview1 -Force
  
  Install-Module -Name PoShLog.Enrichers -RequiredVersion 1.0.0 -Force
  
  Install-Module -Name Transferetto -RequiredVersion 0.0.10 -AllowClobber -Force
  ```

  \* In case it will no longer be possible to download the versions, it will be necessary to install offline the modules that are inside the Modules folder       

    Exit from Administrator Console;

- 6. Run script:
     6.1 into new shell: ./IsRunning.ps1 **Windows User**
     6.1 into new shell: pwsh IsRunning.ps1 **Linux User**
---

## Notes

- *IsRunning.ps1 file:*
	
	- Is the only one that is called by the CronTab;
	- If one of the following checks is successful, the program will be blocked:
		1.If a files download is in progress (by checking the Download.start file);
		2.If a production is in progress (by checking the Production.start file);
		3.If a previous production has failed (by checking the Production.fail file)
	- It has its own log file into /Logs folder;
	- It does not send mails. Because it would get a lot of failure mails if the program is running
	- Inside the .start, .end and .fail files, the program will write which files it is processing
- *Main program Logs:*

  - Log file is located in the / Logs folder and is named: log(production data).txt
  - Program will send an email of the logs, which will be written in the body of the same,filtered in this way:
    - non-blocking errors for production, such as the latest historical files,
    - production blocking errors, such as R script breaking;
    - production was successful;


---


## Contributing

For your question send un email to: nicolas.gentilucci@live.it

---

## License

Automation R for CentOs7 is Copyright © 2022 Nicolas Gentilucci. It is free
software, and may be redistributed under the terms specified in the
[LICENSE](./License.pdf) file.