#------------------------------------------------------
# 第一部分：批量读取文件
# By: Eastmount CSDN 2022-03-12
#------------------------------------------------------
function Read_csv_powershell 
{
  param (
    [parameter(Mandatory=$true)]
    [System.String]$inputfile,
    [System.String]$outputfile
  )

  # 读取CSV文件
  $content = Import-CSV $inputfile
  $list = [System.Collections.ArrayList]@()
  foreach($line in $content) {
    $no = $line.("no")
    $code = $line.("decoded code")
    $name = $line.("family name")
    $label = $line.("label")
    # Write-Output($no, $code, $name)

    # 转换抽象语法树AST和Token
    try {
      $ast = Convert-CodeToAst -str $code
      #Write-Output($ast)
      $token = get_token_text -str $code
      #Write-Output($token)
      $char = get_char -str $code
      #Write-Output($char)
    } 
    catch [System.Exception] {
      'exception info:{0}' -f $_.Eception.Message
      continue
    }
    $list.add([PSCustomObject]@{
      no = $no
      code = $code
      name = $name
      label = $label
      ast = $ast
      token = $token
      char = $char
    })
  }
  $list | ConvertTo-Csv -NoTypeInformation | out-file $outputfile -Encoding ascii -Force
  Write-Output($list)
}

#------------------------------------------------------
# 第二部分：提取并拼接AST节点内容
#------------------------------------------------------
function add_blanks 
{
    param (
      [parameter(Mandatory=$true)]
      [System.Array]$arr
    )
    $strNode = ''
    foreach($elem in $arr) {
        if($strNode.Length -ne 0) { #不等于
            $elem = " " + $elem
        }
        $strNode = $strNode + $elem
    }
    return $strNode
}

# 函数：提取Powershell代码的抽象语法树(AST)
function Convert-CodeToAst
{
  param
  (
    [Parameter(Mandatory)]   # 强制参数
    [System.String]$str      # 执行ps代码
  )

  # 构建hashtable
  $hierarchy = @{}
  $result = [System.Collections.ArrayList]@()

  # 创建Scipt代码块
  $code = [ScriptBlock]::Create($str)

  # 提取AST
  $code.Ast.FindAll( { $true }, $true) |
  ForEach-Object {
    # take unique object hash as key
    $id = 0;
    if($_.Parent) {
      $id = $_.Parent.GetHashCode()
    }
    Write-Debug('{0}:{1}' -f $_.GetType().Name,$id)

    if ($hierarchy.ContainsKey($id) -eq $false) {
      $hierarchy[$id] = [System.Collections.ArrayList]@()
    }
    $null = $hierarchy[$id].Add($_)
    # add ast object to parent
  }
  
  # 递归可视化树
  function Visualize-Tree($Id)
  {
    # 每级缩进
    $hierarchy[$id] | ForEach-Object {
      # 获取当前AST对象的id
      $newid = $_.GetHashCode()

      # 递归其子节点（if any)
      if ($hierarchy.ContainsKey($newid))
      {
        Visualize-Tree -id $newid
      }
      $null = $result.Add($_.GetType().Name)
    }
  }

  # 使用AST根对象开始可视化
  Visualize-Tree -id $code.Ast.GetHashCode()
  # Write-Output ($result,"`n")

  # result存储根节点内容
  $strNode = add_blanks -arr $result
  return $strNode
}

#------------------------------------------------------
# 第三部分：提取并拼接Token内容
#------------------------------------------------------
# 函数：拼接Token内容
function get_token_text 
{
  param (
    [Parameter(Mandatory)]   # 强制参数
    [System.String]$str      # 执行ps代码
  )

  # 创建Scipt代码块
  $code = [ScriptBlock]::Create($str)

  # 提取token
  $errors = $null
  $tokens = [System.Management.Automation.PSParser]::Tokenize($code, [ref]$errors)
  $syntaxError = $errors | Select-Object -ExpandProperty Token -Property Message
  $token_texts = $tokens.Content
  # Write-Output ($token_texts)

  # 拼接字符串
  $strToken = ''
  foreach($elem in $token_texts) {
    $elem = $elem | Out-String   #Object转String
    $text = $elem.Trim()
    if($strToken.Length -ne 0) {  #不等于
      $text = " " + $text
    }
    $strToken = $strToken + $text
  }
  # Write-Output ("Get Texts:")
  # Write-Output ($strToken,$strToken.Length)

  return $strToken
}

#------------------------------------------------------
# 第四部分：按字符分割
#------------------------------------------------------
function get_char
{
  param (
    [Parameter(Mandatory)]   # 强制参数
    [System.String]$str      # 执行ps代码
  )

  $k = 0
  $length = $str.Length
  $strChar = ''
  while ($k -lt $length) {
    $ch = $str[$k]
    $k = $k + 1
    if ($ch -eq " ") {       # 空格跳过
      continue
    }
    if ($strChar.length -ne 0) {     # 首个字符跳过
      $ch = " " + $ch
    }
    $strChar = $strChar + $ch
  }
  return $strChar
}


#------------------------------------------------------
# 主函数：读取CSV文件并提取AST和Token
#------------------------------------------------------
$inputCSV = '.\data\malicious_sample_all.csv'
$outputCSV = '.\data\malicious_sample_all_result.csv'
# 注意input是系统自带变量
Read_csv_powershell -inputfile $inputCSV -outputfile $outputCSV
