# Echo-VR-Server-Error-Monitoring

This script is made for checking of errors running on Echo VR Server Instances.
It will restart them and checks if enough Instances are running at all.

To set it up open the file.
There is a #######THINGS YOU HAVE TO SET UP!!!####### Section you NEED to change

If you give the script an Input behind it, it will use that as the Amount of wanted running server instances.
So like:

```
 pwsh Echo-VR-Server-Error-Monitoring.ps1 5
```
No need to do so

**As this script installes Powershell 7, if it isnt already installed, you might need to start it with admin rights on your first start!**


FEATURES:
- checks for errors
- cheks for chrahed servers
- restarts stuck servers
