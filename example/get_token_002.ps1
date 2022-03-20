function Test-PSOneScript
{
  <#
      .SYNOPSIS
      Parses a PowerShell Script (*.ps1, *.psm1, *.psd1)

      .DESCRIPTION
      Invokes the simple PSParser and returns tokens and syntax errors

      .EXAMPLE
      Test-PSOneScript -Path c:\test.ps1
      Parses the content of c:\test.ps1 and returns tokens and syntax errors

      .EXAMPLE
      Get-ChildItem -Path $home -Recurse -Include *.ps1,*.psm1,*.psd1 -File |
         Test-PSOneScript |
         Out-GridView

      parses all PowerShell files found anywhere in your user profile

      .EXAMPLE
      Get-ChildItem -Path $home -Recurse -Include *.ps1,*.psm1,*.psd1 -File |
         Test-PSOneScript |
         Where-Object Errors

      parses all PowerShell files found anywhere in your user profile
      and returns only those files that contain syntax errors

      .LINK
      https://powershell.one
  #>

  param
  (
    # Path to PowerShell script file
    # can be a string or any object that has a "Path" 
    # or "FullName" property:
    [String]
    [Parameter(Mandatory,ValueFromPipeline)]
    [Alias('FullName')]
    $Path
  )
  
  begin
  {
    $errors = $null
  }
  process
  {
    # create a variable to receive syntax errors:
    $errors = $null
    # tokenize PowerShell code:
    $code = Get-Content -Path $Path -Raw -Encoding Default
    Write-Output $code
    
    # return the results as a custom object
    [PSCustomObject]@{
      Name = Split-Path -Path $Path -Leaf
      Path = $Path
      Tokens = [Management.Automation.PSParser]::Tokenize($code, [ref]$errors)
      Errors = $errors | Select-Object -ExpandProperty Token -Property Message
    }  
  }
}

# 执行函数
$Path = ".\data\example-004.ps1"
$result = Test-PSOneScript -Path $Path
$errors = $result.Errors.Count -gt 0
$tokens = $result.Tokens.Type | Sort-Object -Unique

# 输出结果
Write-Output ($result)
Write-Output ($errors,"`n")
Write-Output ($tokens)