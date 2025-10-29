# Proyecto 1 – Bases 2

## 1. Aspectos administrativos

| Forma de trabajo | Individual                  |
| ----------------- | --------------------------- |
| Fecha de entrega  | 12 de octubre del 2025      |
| Hora de entrega   | 10:00 pm                    |
| Lugar             | Repositorio del curso:      |
| Github classroom  | https://classroom.github.com/a/W-fCBWVI |

## 2. Consulta general

Con base a la base de datos de ejemplo de Microsoft, en este caso **Wide World Importers** (**WideWorldImporters-Full.bak**), ustedes deben de preparar una serie de consultas SQL, donde el usuario a través de un sitio web podrá hacer uso de ellas.

### 2.1. Módulo de cliente

Una página web donde se pueda consultar los clientes almacenados en la base de datos, en esta página el usuario podrá hacer uso de un conjunto de filtros y los resultados de este ser expuesto en una tabla.

La tabla deberá contener datos cómo el nombre del cliente, categoría y método de entrega. Los filtros deben ser un texto libre, donde su patrón de búsqueda será por alguna coincidencia de este texto que forme parte de su nombre, los filtros son acumulativos. Debe existir una función restaurar los filtros consulta a todos. Por defecto debe mostrarse en orden alfabético por nombre del cliente **ascendente.**

Al seleccionar un cliente específico de la tabla de resultados, éste en una ventana por aparte, mostrará los detalles de este, como:

-   Nombre del cliente
-   Categoría
-   Grupo de compra (BuyingGroup)
-   Contactos (Primario y alternativo)
-   Cliente para facturar (BillToCustomerID)
-   Métodos de entrega
-   Ciudad de entrega (Deliverylocation)
-   Código postal
-   Teléfono y fax
-   Días de gracia para pagar (Payment days)
-   Sitio web (enlace)
-   Su dirección (Delivery ….., Postal….)
-   En un mapa mostrar su localización

### 2.2. Módulo de proveedores

Una página web donde se pueda consultar los proveedores almacenados en la base de datos, en esta página el usuario podrá hacer uso de un conjunto de filtros y los resultados de este ser expuesto en una tabla.

La tabla deberá contener datos cómo el nombre del proveedor, categoría y método de entrega. Los filtros deben ser un texto libre, donde su patrón de búsqueda será por alguna coincidencia de este texto que forme parte de su nombre y categoría, los filtros son acumulativos. Debe existir una función restaurar los filtros consulta a todos. Por defecto debe mostrarse en orden alfabético por **nombre del proveedor ascendente.**

Al seleccionar un proveedor específico de la tabla de resultados, éste en una ventana por aparte, mostrará sus detalles, como:

-   Código del proveedor (SupplierReference)
-   Nombre del proveedor
-   Categoría (deliverylocation)
-   Contactos (Primario y alternativo)
-   Métodos de entrega
-   Ciudad de entrega
-   Código postal de entrega
-   Teléfono y fax
-   Sitio web
-   Su dirección (Delivery…, Postal…)
-   En un mapa mostrar su localización
-   Nombre del banco
-   Número de cuenta corriente
-   Días de gracia para pagar (Payment days)

### 2.3. Módulo de inventarios

Una página donde se pueda consultar los productos almacenados en la base de datos, en esta página el usuario podrá hacer uso de un conjunto de filtros y los resultados de este ser expuesto en una tabla.

La tabla deberá contener datos cómo el nombre del producto, grupo que pertenece y su cantidad **en inventarios (Holdings).** Los filtros debe ser un texto libre, con excepción de la cantidad, donde su patrón de búsqueda será por alguna coincidencia de este texto que forme parte de su nombre y grupo, los filtros son acumulativos. Debe existir una función restaurar los filtros consulta a todos. Por defecto debe mostrarse en orden alfabético por nombre del producto.

Al seleccionar un producto específico de la tabla de resultados, éste en una ventana por aparte, mostrará los detalles de este, como:

-   Nombre del producto
-   Nombre del proveedor (enlace)
-   Color
-   Unidad de empaquetamiento (UnitPackage)
-   Empaquetamiento (OuterPackage)
-   Cantidad de empaquetamiento (Quantity)
-   Marca
-   Tallas / tamaño
-   Impuesto
-   Precio unitario
-   Precio venta (RecommendedRetailPrice)
-   Paso
-   Palabras claves (Search detail)
-   Cantidad disponible (Quantity on hand)
-   Ubicación

### 2.4. Módulo de ventas

Una página donde se pueda consultar las ventas registradas en la base de datos, en esta página el usuario podrá hacer uso de un conjunto de filtros y los resultados de este ser expuesto en una tabla.

La tabla deberá contener datos cómo el número de factura, fecha (por rango será su filtro), cliente, **método de entrega y el monto (por rango será su filtro).** El nombre del cliente debe ser un texto **libre, donde su patrón de búsqueda será por alguna coincidencia de este texto que forme parte de** su nombre y fechas, los filtros son **acumulativos.** Debe existir una función restaurar los filtros consulta a todos. Por defecto debe mostrarse en orden alfabético por nombre del cliente.

Al seleccionar una venta de la tabla de resultados, éste en una ventana por aparte, mostrará los detalles de este, como:

**Encabezado de la factura**

-   Número de factura
-   Nombre del Cliente (enlace)
-   Método de entrega
-   Número de orden (Customer purchase order number)
-   Persona de contacto
-   Nombre del vendedor
-   Fecha de la factura
-   Instrucciones de entrega

**Detalle de la factura**

-   Nombre del producto (enlace)
-   Cantidad
-   Precio unitario
-   Impuesto aplicado
-   Monto del impuesto
-   Total por línea

## 3. Datos estadísticos

1.  La montos más altos, bajos y compra promedio que se le hace a los proveedores, esto resultados agrupados por proveedor y categoría (tabla PurchaseOrders). Hacer uso de **Rollup** y permitir filtrar por categoría y nombre del proveedor mediante entrada libre **de texto.**
2.  La montos más altos, bajos y ventas promedio que hacen los clientes, esto resultados agrupados por cliente y categoría (tabla Invoices). Hacer uso de **Rollup** y permitir filtrar por nombre del cliente y categoría mediante entrada libre de texto.
3.  Top 5 de los productos que generan más ganancia en las ventas por año, debe poder filtrarse por años. Estos deben ser años válidos en la base de datos (Usar **dense_rank** y **partitions**)
4.  Top 5 de los clientes que tienen mayor cantidad de facturas emitidas a su nombre por año y mostrar el monto total facturado. Debe poder filtrarse por rango años. Estos deben ser años válidos en la base de datos (Usar **dense_rank** y **partitions**)
5.  Top 5 de los proveedores que tienen mayor cantidad de órdenes de compras emitidas a su nombre y mostrar el monto total por año. Debe poder filtrarse por rango años y estos deben ser años válidos en la base de datos (Usar **dense_rank** y **partitions**)

## 4. Puntos por evaluar

El objetivo del proyecto está que todo el proceso de búsqueda y transformación de los datos esté del lado de la base de datos, por lo tanto, el acceso a este será por medio de **procedimientos almacenados.** Es importante además el uso correcto de las **Vistas**

Debe crear métodos y pantallas para permitir la inserción, modificación y borrado de nuevos elementos para todas las tablas donde se hace referencia en el módulo de **inventarios.** El estudiante además debe investigar sobre el uso de sinónimos y saber en que forma debe aplicar este en toda la solución.

La función principal de la interfaz será la presentación de datos y envío de parámetros para que la base de datos responda con la solicitud, por lo que el proceso de revisión del proyecto se tomará en cuenta la perspectiva del código, así verificar que no hay manipulación o agrupación de datos desde la aplicación web.

Por último, la arquitectura de la aplicación debe de estar separado tanto el **_frontend_** y el **_backend_** por lo que la comunicación entre ambas aplicaciones será por medio de servicios. Para el desarrollo de la aplicación web se recomienda React

La apariencia o presentación de la **aplicación web será muy importante**, por tanto, debe considerar lo siguiente:

-   Validación de datos
-   Colores
-   Alineación
-   Uso correcto de los componentes
-   Presentación
-   Mensaje de errores
-   Ser intuitivo

## 6. Rúbrica

|                       | Usabilidad | Funcionalidad | Total |
| --------------------- | ---------- | ------------- | ----- |
| **SQL Server**        |            |               | **50**  |
| Estadísticas          |            | 10            |       |
| Clientes              |            | 10            |       |
| Proveedores           |            | 10            |       |
| Productos             |            | 10            |       |
| Ventas                |            | 10            |       |
| **API**               |            |               | **10**  |
| **Aplicación**        |            |               |       |
| Módulo clientes       | 4          | 3.5           | 7.5   |
| Módulo proveedores    | 4          | 3.5           | 7.5   |
| Módulo inventarios    | 4          | 3.5           | 7.5   |
| Módulo de ventas      | 4          | 3.5           | 7.5   |
| Estadísticas          | 4          | 6             | 10    |
| **Total**             |            |               | **100** |

## 7. Entregables

Subir el proyecto al repositorio del curso:

1.  Crear un archivo README.md dentro del repositorio del github y dentro de este anotar los **objetivos alcanzados y aquellos no.**
2.  Además, dentro del README.md agregar un enlace con el video de su aplicación en **ejecución, subirlo a youtube, debe contener audio donde la persona explique su uso,** funcionamiento y aquellos detalles que desee resaltar.
3.  Crear una carpeta llamado Script, y dentro de este los procedimientos almacenados y otros objetos que ustedes crearon adicionales. El archivo debe tener extensión .sql
4.  También, el script donde se ejecute las consultas de los procedimientos almacenados usados en la aplicación a modo de ejemplo
5.  Crear una carpeta llamada WebSite y dentro de este el código de su aplicación web
6.  Crear una carpeta llamada Api y dentro de este los archivos creados para configurar este servicio.

## 8. Referencias

-   WideWorldImporters database catalog: https://docs.microsoft.com/en-us/sql/samples/wide-world-importers-olto-database-catalog?view=sql-server-ver15
-   Dens_rank: https://docs.microsoft.com/en-us/sql/t-sql/functions/dense-rank-transact-sql?view=sql-server-ver15
-   Best Practices: https://tilierdigital.com/blog/12-web-design-best-practices-for-2021/
-   Colors: https://www.websitebuilderexpert.com/designing-websites/how-to-choose-color-for-your-website/
-   What is usability: https://careerfoundry.com/en/blog/ux-design/what-is-usability/
-   Free Themes for React: https://www.creative-tim.com/templates/react-free
-   Material UI: https://material-ui.com/es/getting-started/templates/