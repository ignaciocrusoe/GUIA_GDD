/*GUÍA SQL GESTIÓN DE DATOS*/

/*EJERCICIO 1*/
/*Mostrar el código, razón social de todos los clientes cuyo límite de crédito sea mayor o
igual a $ 1000 ordenado por código de cliente.*/
SELECT clie_codigo, clie_razon_social FROM Cliente
WHERE clie_limite_credito >=1000
ORDER BY clie_codigo;

/*EJERCICIO 2*/
/*Mostrar el código, detalle de todos los artículos vendidos en el año 2012 ordenados por
cantidad vendida.*/
SELECT prod_codigo, prod_detalle FROM Producto
JOIN Item_Factura ON prod_codigo = item_producto
JOIN Factura ON fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
WHERE year(fact_fecha) = 2012
GROUP BY prod_codigo, prod_detalle
ORDER BY sum(item_cantidad);

/*EJERCICIO 3*/
/*Realizar una consulta que muestre código de producto, nombre de producto y el stock
total, sin importar en que deposito se encuentre, los datos deben ser ordenados por
nombre del artículo de menor a mayor*/
SELECT prod_codigo, prod_nombre, SUM(ISNULL(stoc_cantidad, 0)) FROM roducto LEFT JOIN STOCK ON prod_codigo = stoc_producto
GROUP BY prod_codigo, prod_detalle
ORDER BY prod_deralle;

/*EJERCICIO 4*/
/*Realizar una consulta que muestre para todos los artículos código, detalle y cantidad de
artículos que lo componen. Mostrar solo aquellos artículos para los cuales el stock
promedio por depósito sea mayor a 100.*/
SELECT prod_codigo, prod_detalle, count(comp_componente)
FROM Producto LEFT JOIN Composicion ON  prod_codigo = comp_producto
WHERE prod_codigo IN (SELECT prod_codigo FROM STOCK GROUP BY stoc_producto HAVING AVG(stoc_cantidad) > 100)
GROUP BY prod_codigo, prod_detalle
ORDER BY COUNT(comp_componente) DESC

/*EJERCICIO 5*/
/*Realizar una consulta que muestre código de artículo, detalle y cantidad de egresos de
stock que se realizaron para ese artículo en el año 2012 (egresan los productos que
fueron vendidos). Mostrar solo aquellos que hayan tenido más egresos que en el 2011*/
SELECT prod_codigo, prod_detalle, SUM(item_cantidad) Egresos FROM Producto
	JOIN item_factura ON prod_codigo = item_producto
	JOIN Factura ON fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero
WHERE YEAR(fact_fecha) = 2012
GROUP BY prod_codigo, prod_detalle
HAVING SUM(item_cantidad) > (SELECT SUM(item_cantidad) FROM item_factura
	JOIN Factura ON fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero
WHERE YEAR(fact_fecha) = 2011 AND prod_codigo = item_producto)

/*EJERCICIO 6*/
/*Mostrar para todos los rubros de artículos código, detalle, cantidad de artículos de ese
rubro y stock total de ese rubro de artículos. Solo tener en cuenta aquellos artículos que
tengan un stock mayor al del artículo ‘00000000’ en el depósito ‘00’.*/
SELECT rubr_id, rubr_detalle, COUNT(DISTINCT prod_codigo) 'Cantidad de productos', SUM(stoc_cantidad) stock
	FROM Rubro LEFT JOIN producto ON prod_rubro = rubr_id
	LEFT JOIN stock ON stoc_producto = prod_codigo
	GROUP BY rubr_id, rubr_detalle
	HAVING SUM(stoc_cantidad) >
	(SELECT stoc_cantidad FROM Stock
	WHERE stoc_producto = '00000000' AND stoc_deposito = '00')
	ORDER BY rubr_id

/*EJERCICIO 8*/
/*Mostrar para el o los artículos que tengan stock en todos los depósitos, nombre del
artículo, stock del depósito que más stock tiene.*/
SELECT prod_detalle, MAX(stoc_cantidad) stock
FROM Producto JOIN STOCK ON prod_codigo = stoc_producto
WHERE stoc_cantidad > 0
GROUP BY prod_detalle
HAVING COUNT(*) = (SELECT COUNT(*) -25 FROM DEPOSITO)