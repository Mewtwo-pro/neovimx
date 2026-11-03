import re
from pathlib import Path
directorio = Path(__file__).parent
    
archivo = directorio / "info_history.md"
    
def extraer_titulos_numerados(ruta_archivo):
    # Expresión regular: 
    # ^     -> Inicio de línea
    # ###   -> Los tres numerales y el espacio
    # \d+   -> Uno o más dígitos
    # \.    -> Un punto literal
    patron = re.compile(r'^### \d+\.')
    
    try:
        with open(ruta_archivo, 'r', encoding='utf-8') as archivo:
            for linea in archivo:
                linea_limpia = linea.strip()
                if patron.match(linea_limpia):
                    print(linea_limpia)
                    
    except FileNotFoundError:
        print(f"El archivo '{ruta_archivo}' no fue encontrado.")

# Uso del script (asumiendo que tu archivo se llama 'ejemplo.md')
extraer_titulos_numerados(archivo)
