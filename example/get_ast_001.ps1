function Convert-CodeToAst
{
  param
  (
    [Parameter(Mandatory)]   # 强制参数
    [ScriptBlock]
    $Code
  )


  # build a hashtable for parents
  $hierarchy = @{}

  $code.Ast.FindAll( { $true }, $true) |
  ForEach-Object {
    # take unique object hash as key
    $id = $_.Parent.GetHashCode()
    if ($hierarchy.ContainsKey($id) -eq $false)
    {
      $hierarchy[$id] = [System.Collections.ArrayList]@()
    }
    $null = $hierarchy[$id].Add($_)
    # add ast object to parent
    
  }
  
  # visualize tree recursively
  function Visualize-Tree($Id, $Indent = 0)
  {
    # use this as indent per level:
    $space = '--' * $indent
    $hierarchy[$id] | ForEach-Object {
      # output current ast object with appropriate
      # indentation:
      '{0}[{1}]: {2}' -f $space, $_.GetType().Name, $_.Extent
    
      # take id of current ast object
      $newid = $_.GetHashCode()
      # recursively look at its children (if any):
      if ($hierarchy.ContainsKey($newid))
      {
        Visualize-Tree -id $newid -indent ($indent + 1)
      }
    }
  }

  # start visualization with ast root object:
  Visualize-Tree -id $code.Ast.GetHashCode()
}

Convert-CodeToAst -Code {$a=1}
