# PowerShell script to help create GHS JSON
# This will read the text and help format it

$text = @"
1 ALL YOUR ANXIETY
 1.
 Admonition
 Is there a heart o'er-bound by sorrow?
 Is there a life weighed down by care?
 Come to the cross, each burden bearing,
 All  your  anxiety - leave it there.
 All your anxiety, all your care,
 Bring to the Mercy seat, leave it there;
 Never a burden He cannot bear,
 Never a Friend like Jesus.
 2.
 3.
 No other Friend so keen to help you;
 No other Friend so quick to hear;
 No other place to leave your burden;
 No other one to hear your prayer.
 Come then, at once, delay no longer;
 Heed His entreaty, kind and sweet;
 You need not fear a disappointment;
 You shall find peace at the mercy seat.
"@

Write-Host "Script ready to process hymns"
Write-Host "Total lines in sample: $($text -split "`n" | Measure-Object).Count"
