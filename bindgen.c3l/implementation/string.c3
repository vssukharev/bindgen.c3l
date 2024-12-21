
module bindgen::bg @private;
import clang;

fn String getFuncName(
  String display_name)
{
  isz upper = 0;
  foreach (i, c : display_name)
  {
    if (c == '(') 
    {
      upper = i - 1;
      break;
    }
  }
  
  return upper >= 0 ? display_name[0..upper] : "";
}

