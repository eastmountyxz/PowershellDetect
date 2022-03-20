# the code that you want tokenized:
$code = {
  # this is some test code
  $service = Get-Service |
    Where-Object Status -eq Running
}


# create a variable to receive syntax errors:
$errors = $null
# tokenize PowerShell code:
$tokens = [System.Management.Automation.PSParser]::Tokenize($code, [ref]$errors)

# analyze errors:
if ($errors.Count -gt 0)
{
  # move the nested token up one level so we see all properties:
  $syntaxError = $errors | Select-Object -ExpandProperty Token -Property Message
  $syntaxError
}
else
{
  $tokens
}