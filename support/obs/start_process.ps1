$exe_path = $args[0]
$exe_name = (Get-ChildItem $exe_path).BaseName
$working_dir = Split-Path $exe_path -Parent

# check for existing process first
$process = Get-Process $exe_name -ErrorAction SilentlyContinue

if ( !$process ) {
    #if not already running, start it
    $new_pid = (Start-Process $exe_path -WorkingDirectory $working_dir -PassThru).Id
}
else {
    $new_pid = $process.Id
}

Write-Output $new_pid
# return $obs_pid