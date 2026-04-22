#!/bin/bash

# Colores para una mejor visualización en la terminal
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # Sin Color

# --- 1. Preguntar al usuario cuántas imágenes quiere ---

# Set values directly in the code
NUM_DOGS=100   
NUM_CATS=100 

# --- 2. Crear las carpetas necesarias ---
mkdir -p data/dogs data/cats

# --- 3. Función para descargar imágenes con reintentos ---
descargar_imagen() {
    local tipo=$1          # "dog" o "cat"
    local index=$2         # Número de la imagen
    local max_intentos=5   # Reintentará hasta 5 veces si falla

    # Seleccionar la URL de la API según el tipo de animal
    if [ "$tipo" = "dog" ]; then
        api_url="https://dog.ceo/api/breeds/image/random"
    else
        api_url="https://api.thecatapi.com/v1/images/search"
    fi

    for ((intento=1; intento<=max_intentos; intento++)); do
        # Obtener la respuesta JSON de la API
        response=$(curl -s "$api_url")
        
        # Extraer la URL de la imagen del JSON usando jq
        if [ "$tipo" = "dog" ]; then
            image_url=$(echo "$response" | jq -r '.message')
        else
            image_url=$(echo "$response" | jq -r '.[0].url')
        fi

        # Verificar que la URL no sea nula ni vacía
        if [ -n "$image_url" ] && [ "$image_url" != "null" ]; then
            # Obtener la extensión del archivo (ej: .jpg, .png, .gif)
            extension="${image_url##*.}"
            extension="${extension%%\?*}"
            # Validar que la extensión sea de imagen; si no, usar .jpg por defecto
            if [[ ! "$extension" =~ ^(jpg|jpeg|png|gif)$ ]]; then
                extension="jpg"
            fi

            # Nombre del archivo: "dogs/dog_1.jpg", etc.
	filename="data/${tipo}s/${tipo}_${index}.${extension}"
            
            # Descargar la imagen
            if curl -s -o "$filename" "$image_url"; then
                echo -e "  ${GREEN}✓ Descargado:${NC} $filename"
                return 0
            else
                echo -e "  ${YELLOW}⚠ Intento $intento para $tipo $index: falló la descarga. Reintentando...${NC}" >&2
            fi
        else
            echo -e "  ${YELLOW}⚠ Intento $intento para $tipo $index: no se obtuvo una URL válida. Reintentando...${NC}" >&2
        fi
        sleep 1 # Pequeña pausa antes de reintentar
    done

    echo -e "  ${RED}✗ Error: No se pudo descargar $tipo $index después de $max_intentos intentos.${NC}" >&2
    return 1
}

# --- 4. Descargar las imágenes en dos tandas ---
echo -e "\n${GREEN}🐕 Descargando $NUM_DOGS imágenes de perros...${NC}"
for ((i=1; i<=NUM_DOGS; i++)); do
    descargar_imagen "dog" "$i"
done

echo -e "\n${GREEN}🐈 Descargando $NUM_CATS imágenes de gatos...${NC}"
for ((i=1; i<=NUM_CATS; i++)); do
    descargar_imagen "cat" "$i"
done

# --- 5. Mensaje final ---
echo -e "\n${GREEN}¡Proceso completado! Las imágenes están en las carpetas 'dogs' y 'cats'.${NC}"
