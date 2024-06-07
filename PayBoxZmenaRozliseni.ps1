Add-Type -AssemblyName System.Windows.Forms


function checkAdminPriveleges{
    $adminPriveledges =  ([Security.Principal.WindowsPrincipal] `
  [Security.Principal.WindowsIdentity]::GetCurrent() `
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator);
    Write-Output $adminPriveledges;
}

function showMessageBox{
    param(
        [string]$message
    )
    [System.Windows.Forms.MessageBox]::Show($message);
}





if (-Not(checkAdminPriveleges)){
    # If administrator priveleges are not granted as for them
    try{
        # starts same script with admin priveleges
        Start-Process powershell -Verb runAs -ArgumentList ("-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments);
    
    }
    catch{
        # If user denies admin priveleges display error message
        showMessageBox("Must run script with admninistrator priveleges");
        
    }
    finally{
    # kill script due to either elevation or denial of permissions
        exit;
    }
   
}

# define path to needed registries
$regPath = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Configuration";


$sizeXName = "PrimSurfSize.cx";
$sizeYName = "PrimSurfSize.cy";
$xSize = 1280;
$ySize = 1024;
$allChanged = $true;


#check registry path, if not valid kill script
if (-Not (Test-Path($regPath))){
    showMessageBox('Registry path is not valid');
    exit;

}
else {
    # get registry paths that contain PrimSurfSize.cx and .cy using propery field
    $registries = Get-ChildItem -Path $regPath -Recurse | Where-Object {$_.Property -contains $sizeXName -and $_.Property -contains $sizeYName};
}

#run code to change registries
foreach ($registry in $registries){
        
       Set-ItemProperty -Path $registry.PSPath -Name $sizeXName -Value $xSize;
       Set-ItemProperty -Path $registry.PSPath -Name $sizeYName -Value $ySize;
   
	
}

# check that all registries have actually been changed to desired values
foreach ($reg in $registries){
    $x = Get-ItemPropertyValue $reg.PSPath -Name $sizeXName;
    $y = Get-ItemPropertyValue $reg.PSPath -Name $sizeYName;
    if (-Not($x -eq $xSize -and $y -eq $ySize)){
        # set to false if a registry has not been changed to the needed value
        $allChanged = $false;
    }
}
# show result of script
showMessageBox($(If($allChanged){"All registries have been successfuly changed"} else {"An error has occured"}));
