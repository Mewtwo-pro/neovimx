import re
import subprocess
import os
from pathlib import Path
directorio = Path(__file__).parent
    
path_salida = directorio 
archivo_md = directorio / "info_history.md"
    
def procesar_markdown_a_audio(md_filename=archivo_md, modelo_path="es_ES-davefx-medium.onnx", piper_path="./piper/piper"):
    # Verificar que el archivo Markdown exista
    if not os.path.exists(md_filename):
        print(f"Error: No se encuentra el archivo {md_filename}")
        return

    with open(md_filename, 'r', encoding='utf-8') as f:
        contenido = f.read()

    # Expresión regular para capturar:
    # 1. El número del índice (ej: 1, 3, 4)
    # 2. El título de la sección
    # 3. El contenido del cuerpo hasta el siguiente título "###" o el fin del archivo
    patron = re.compile(r'^###\s+(\d+)\.\s+([^\n]+)\n(.*?)(?=^###|\Z)', re.MULTILINE | re.DOTALL)
    
    coincidencias = patron.findall(contenido)
    
    if not coincidencias:
        print("No se encontraron títulos con el formato especificado (ej. '### 1. ').")
        return

    for match in coincidencias:
        numero_indice, titulo, texto_cuerpo = match
        
        # Limpiar saltos de línea extra o espacios en el cuerpo
        texto_cuerpo = texto_cuerpo.strip()
        
        # Combinar el título y el cuerpo para que la voz lea ambos de forma fluida
        texto_completo = f"{titulo}. {texto_cuerpo}"
        
        # Nombre del archivo de salida basado en el número del índice
        output_filename = f"{path_salida}/video/mensaje{numero_indice}.wav"
        
        print(f"[{numero_indice}] Generando {output_filename} ('{titulo}')...")
        
        # Construir comando y pasar el texto mediante stdin (igual que el pipe de bash)
        cmd = [piper_path, "--model", modelo_path, "--output_file", output_filename]
        
        try:
            proceso = subprocess.Popen(
                cmd, 
                stdin=subprocess.PIPE, 
                stdout=subprocess.PIPE, 
                stderr=subprocess.PIPE, 
                text=True
            )
            stdout, stderr = proceso.communicate(input=texto_completo)
            
            if proceso.returncode == 0:
                print(f"   -> ¡Guardado con éxito como {output_filename}!")
            else:
                print(f"   -> Error en Piper: {stderr.strip()}")
                
        except Exception as e:
            print(f"   -> Excepción al ejecutar el proceso: {e}")

if __name__ == "__main__":
    # Asegúrate de que tu archivo markdown se llame 'file.md' o cambia el nombre aquí
    procesar_markdown_a_audio(archivo_md)
