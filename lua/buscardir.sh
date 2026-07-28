#!/bin/bash

# Leer el término de búsqueda directamente desde el portapeles
termino=$(xclip -selection clipboard -o)

# Limpiar espacios en blanco o saltos de línea al inicio/final
termino=$(echo "$termino" | xargs)

# Validar que el portapeles no esté vacío
if [ -z "$termino" ]; then
    echo "El portapeles está vacío o no contiene texto."
    exit 1
fi


# Buscar directorios y guardar los resultados en un array
mapfile -t resultados < <(find . -maxdepth 1 -type d -iname "${termino}*" ! -path . | sed 's|^\./||')

# Contar cuántos resultados hay
total=${#resultados[@]}

if [ $total -eq 0 ]; then
    echo "No se encontraron coincidencias para '$termino'."
elif [ $total -eq 1 ]; then
    # Copiar el único resultado de vuelta al portapeles
    echo -n "${resultados[0]}" | xclip -selection clipboard
    echo "¡Coincidencia única : '${resultados[0]}'!"
else
    echo "Hay más de una coincidencia ($total resultados):"
    for r in "${resultados[@]}"; do
        echo " - $r"
    done
fi
