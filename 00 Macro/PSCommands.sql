-- OS reboot history
get-eventlog System | where-object {$_.EventID -eq "6005"} | sort -desc TimeGenerated