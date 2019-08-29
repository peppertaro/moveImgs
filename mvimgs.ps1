$YYYYMM = (Get-Date -UFormat '+%Y%m');
## Skip first line as it is only a description
 $dvs = adb devices | Select-Object -Skip 1;
    ## Get Device Serial number
    $dvcount=$dvs.count-1;
    if($dvcount -gt 0 ){
        if($dvcount -eq 1){
            $dvsn=$dvs[0].split('device')[0] -replace '\s+','';
        }else{
            $dvsn=new-object System.String[] ($dvcount)
            for($i=0; $i -lt $dvcount; $i++){
                ## split line by a word 'device' and remove space to get device serial number
                $dvsn[$i]=$dvs[$i].split('device')[0] -replace '\s+','';
            }
        }
        foreach($SN in $dvsn){
            $adbsh = "adb -s $SN shell";
            $sdcard = "$adbsh printenv EXTERNAL_STORAGE";
            $sdDir = Invoke-Expression $sdcard;
            if($sdDir.count -gt 1){
                $sdDir = $sdDir.trim() -ne "";
            }
            ##Set variables to prepare for finding Camera Storage
                $DirToDecide="$sdDir/DCIM/";
                $DirToDecidecmd="$adbsh ls $DirToDecide";
                $DirCh = Invoke-Expression $DirToDecidecmd;
                ##rm blank lines
                $DirCh= $DirCh.trim() -ne "";
                $FileAm=0;
                $CameraDir="";
                ## Check and set $CameraDir when it contains maximum imgs/videos
                foreach($Dir in $DirCh){
                    $FileDir="$DirToDecidecmd'$Dir/*.{jpg,jpeg,png,gif,mp4,m4a,mov,mpeg} 2>/dev/null'";
                    $Filelgth=Invoke-Expression $FileDir;
                    if($Filelgth.length -gt 0 ){
                        $Filelgth=$Filelgth.trim() -ne "";
                        if($Filelgth.length -gt $FileAm){
                            $FileAm= $Filelgth.length;
                            $CameraDir=$Dir;
                        }
                    }
                }
            if($CameraDir -ne ""){
                $MvToDir="$sdDir/DCIM/$CameraDir";
                ##prepare to move
                    $ListToMvcmd="$adbsh ls -al '$MvToDir/*.{jpg,jpeg,png,gif,mp4,m4a,mov,mpeg} 2>/dev/null'";
                    $ListToMv= Invoke-Expression $ListToMvcmd;
                ##rm blank lines
                    $ListToMv=$ListToMv.trim() -ne "";
                ##get date with format YYYY-MM
                    $dateKey=(Get-Date -UFormat '+%Y-%m');
                ## Create file directory if it does not exist 
                    $mkfiledir = "$adbsh mkdir -p $MvToDir/$YYYYMM";
                    Invoke-Expression $mkfiledir;
                ##Set blank Arrays to store
                    $line=New-Object System.String[] $ListToMv.count;
                    $date=New-Object System.String[] $ListToMv.count;
                    $name=New-Object System.String[] $ListToMv.count;
                ##Make date / name variables and move if it matches the date
                    $fileCount=0;
                    for($i=0; $i -lt $ListToMv.length; $i++){
                        $data=$ListToMv[$i].split(' ');
                        $date[$i]=$data[$data.length-3];
                        $name[$i]=$data[$data.length-1];
                         if($name[$i] -match '/'){
                                $splnm=$name[$i].split('/');
                                $name[$i]=$splnm[$splnm.length-1];
                            }
                        if($date[$i] -match $dateKey){
                            $filename=$name[$i]                           
                            $MvToDircmd="$adbsh mv '$MvToDir/$filename $MvToDir/$YYYYMM/ 2>/dev/null'";
                            Invoke-Expression $MvToDircmd;
                            $fileCount++;
                        }
                    }
                    echo "We moved $fileCount imgs/videos to $YYYYMM directory";
            }else{
                $getdvName= "$adbsh getprop ro.product.model";
                $dvName=Invoke-Expression $getdvName;
                echo "on $dvName, No file is needed to move! Enjoy your life ^^";
            }
        }
        echo "Everything is okay in the end, if it's not ok, then it's not the end."
    }else{
        echo "It seems you did not connect any device.";
        echo "If you have connected and see this message, please re-confirm the device is in debug mode."
    }
    $host.UI.RawUI.ReadKey();