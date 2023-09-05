/*GU�A SQL GESTI�N DE DATOS*/

/*EJERCICIO 1*/
/*Mostrar el c�digo, raz�n social de todos los clientes cuyo l�mite de cr�dito sea mayor o
igual a $ 1000 ordenado por c�digo de cliente.*/
SELECT clie_codigo, clie_razon_social FROM Cliente
WHERE clie_limite_credito >=1000
ORDER BY clie_codigo;

/*EJERCICIO 2*/
/*Mostrar el c�digo, detalle de todos los art�culos vendidos en el a�o 2012 ordenados por
cantidad vendida.*/SELECT prod_codigo, prod_detalle FROM ProductoJOIN Item_Factura ON prod_codigo = item_productoJOIN Factura ON fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numeroWHERE year(fact_fecha) = 2012GROUP BY prod_codigo, prod_detalleORDER BY sum(item_cantidad);