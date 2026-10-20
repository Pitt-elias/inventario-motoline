# inventario-motoline
# Notas de Arquitectura - Inventario Motoline

## 1. Entidades y Modelos
- **Repuesto:** Representa la pieza o repuesto de moto. 
  - Atributos: ID, código único (SKU), nombre, categoría, precio, stock y marcas compatibles.
- **Proveedor:** El almacén que provee las piezas.
- **Categoría:** Clasificación del repuesto (Frenos, Transmisión, Lubricantes, etc.).

## 2. Relaciones lógicas
- Una **Categoría** puede tener muchos **Repuestos** (Relación 1 a Muchos).
- Un **Repuesto** pertenece a una única **Categoría** (FK: `categoryId`).
- El **Inventario** se conecta con el servicio de **Mecánica a Domicilio** a través de un puente comercial (el botón de compra con instalación).

**Para reconectar la ruta de flutter:** export PATH="$PATH:`pwd`/flutter/bin"

**Para ejecutar el proyecto:** flutter create . --platforms=web --project-name=inventario_motoline

**Para guardar en git hub** 
git add .
git commit -m ""
git push origin main
