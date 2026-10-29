import subprocess
import re
from pathlib import Path
directorio = Path(__file__).parent

# Portapapeles
texto = subprocess.check_output(
    ["xclip", "-selection", "clipboard", "-o"],
    text=True
)

m = re.search(
    r'selectCtrl\(fullBody\s*,\s*preSelect,\s*(\d+),\s*&fullBody\[\d+\]->(\w+)',
    texto
)
archivo = directorio / "code.txt"
if m:
    numero = int(m.group(1))
    control = m.group(2)
    expresion = f"""\
           if (multiSelectMode){{
                selectCtrlMulti(fullBody,{numero},&fullBody[{numero}]->{control});
            }}else{{
                selectCtrl(fullBody,preSelect,{numero},&fullBody[{numero}]->{control},selectAll);
            }}
    """
    with open(archivo, "w") as f:
        f.write(expresion)
else :
    print("no expresion template")

mi_list = ["pTop_x", "pTop_y", "pBottom_x", "pBottom_y","pLeft_x","pLeft_y","pRight_x","pRight_y","kTop" , "kBottom", "kRight", "kLeft", "radius", "rotTop", "rotBottom", "rotLeft", "rotRight"]
with open(archivo , "w") as f:
    for i in mi_list  :
        expresion = f"""{{"{i}", attr.{i}}},\n"""
        f.write(expresion)
    
