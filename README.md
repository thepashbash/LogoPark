# LogoPark
Siemens Logo! 8 PLC REST API application example in delphi.<br>
Here you see how it looks like an open-source ready-for-use windows application written in Delphi which allow you to control a pair of relays and monitor the status of the Logo!8's two digital inputs in real time.<br>
Useful barely for Siemens Logo! 8 PLC.<br>
All you have to do is just a few steps:
-	Power up your Logo!8 and connect to PC via ethernet
-	Lunch the Siemens LogoSoft Comfort software, create new network project, through on Diagram Editor a couple of digital inputs and outputs terminated with dummy flags and upload this stuff into PLC. You may use TestProject.mnp file.
-	Compile Delphi project LogoPark, edit sLogoMainIP parameter in LogoPark.ini file and start the application
