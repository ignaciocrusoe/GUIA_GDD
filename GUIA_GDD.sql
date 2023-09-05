/*GUÍA SQL GESTIÓN DE DATOS*/

/*EJERCICIO 1*/
/*Mostrar el código, razón social de todos los clientes cuyo límite de crédito sea mayor o
igual a $ 1000 ordenado por código de cliente.*/
SELECT clie_codigo, clie_razon_social FROM Cliente
WHERE clie_limite_credito >=1000
ORDER BY clie_codigo;

/*EJERCICIO 2*/
/*Mostrar el código, detalle de todos los artículos vendidos en el año 2012 ordenados por
cantidad vendida.*/SELECT prod_codigo, prod_detalle FROM ProductoJOIN Item_Factura ON prod_codigo = item_productoJOIN Factura ON fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numeroWHERE year(fact_fecha) = 2012GROUP BY prod_codigo, prod_detalleORDER BY sum(item_cantidad);