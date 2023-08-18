$process = Start-Process $Args[0] -WorkingDirectory $Args[1] -PassThru

return $process.Id