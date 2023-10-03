/*GU�A SQL GESTI�N DE DATOS*/

/*EJERCICIO 1*/
/*Mostrar el c�digo, raz�n social de todos los clientes cuyo l�mite de cr�dito sea mayor o
igual a $ 1000 ordenado por c�digo de cliente.*/
SELECT clie_codigo, clie_razon_social FROM Cliente
WHERE clie_limite_credito >=1000
ORDER BY clie_codigo;

/*EJERCICIO 2*/
/*Mostrar el c�digo, detalle de todos los art�culos vendidos en el a�o 2012 ordenados por
cantidad vendida.*/
SELECT prod_codigo, prod_detalle FROM Producto
JOIN Item_Factura ON prod_codigo = item_producto
JOIN Factura ON fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
WHERE year(fact_fecha) = 2012
GROUP BY prod_codigo, prod_detalle
ORDER BY sum(item_cantidad);

/*EJERCICIO 3*/
/*Realizar una consulta que muestre c�digo de producto, nombre de producto y el stock
total, sin importar en que deposito se encuentre, los datos deben ser ordenados por
nombre del art�culo de menor a mayor*/
SELECT prod_codigo, prod_nombre, SUM(ISNULL(stoc_cantidad, 0)) FROM roducto LEFT JOIN STOCK ON prod_codigo = stoc_producto
GROUP BY prod_codigo, prod_detalle
ORDER BY prod_deralle;

/*EJERCICIO 4*/
/*Realizar una consulta que muestre para todos los art�culos c�digo, detalle y cantidad de
art�culos que lo componen. Mostrar solo aquellos art�culos para los cuales el stock
promedio por dep�sito sea mayor a 100.*/
SELECT prod_codigo, prod_detalle, count(comp_componente)
FROM Producto LEFT JOIN Composicion ON  prod_codigo = comp_producto
WHERE prod_codigo IN (SELECT prod_codigo FROM STOCK GROUP BY stoc_producto HAVING AVG(stoc_cantidad) > 100)
GROUP BY prod_codigo, prod_detalle
ORDER BY COUNT(comp_componente) DESC

/*EJERCICIO 5*/
/*Realizar una consulta que muestre c�digo de art�culo, detalle y cantidad de egresos de
stock que se realizaron para ese art�culo en el a�o 2012 (egresan los productos que
fueron vendidos). Mostrar solo aquellos que hayan tenido m�s egresos que en el 2011*/
SELECT prod_codigo, prod_detalle, SUM(item_cantidad) Egresos FROM Producto
	JOIN item_factura ON prod_codigo = item_producto
	JOIN Factura ON fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero
WHERE YEAR(fact_fecha) = 2012
GROUP BY prod_codigo, prod_detalle
HAVING SUM(item_cantidad) > (SELECT SUM(item_cantidad) FROM item_factura
	JOIN Factura ON fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero
WHERE YEAR(fact_fecha) = 2011 AND prod_codigo = item_producto)

/*EJERCICIO 6*/
/*Mostrar para todos los rubros de art�culos c�digo, detalle, cantidad de art�culos de ese
rubro y stock total de ese rubro de art�culos. Solo tener en cuenta aquellos art�culos que
tengan un stock mayor al del art�culo �00000000� en el dep�sito �00�.*/
SELECT rubr_id, rubr_detalle, COUNT(DISTINCT prod_codigo) 'Cantidad de productos', SUM(stoc_cantidad) stock
	FROM Rubro LEFT JOIN producto ON prod_rubro = rubr_id
	LEFT JOIN stock ON stoc_producto = prod_codigo
	GROUP BY rubr_id, rubr_detalle
	HAVING SUM(stoc_cantidad) >
	(SELECT stoc_cantidad FROM Stock
	WHERE stoc_producto = '00000000' AND stoc_deposito = '00')
	ORDER BY rubr_id

/*EJERCICIO 8*/
/*Mostrar para el o los art�culos que tengan stock en todos los dep�sitos, nombre del
art�culo, stock del dep�sito que m�s stock tiene.*/
SELECT prod_detalle, MAX(stoc_cantidad) stock
FROM Producto JOIN STOCK ON prod_codigo = stoc_producto
WHERE stoc_cantidad > 0
GROUP BY prod_detalle
HAVING COUNT(*) = (SELECT COUNT(*) -25 FROM DEPOSITO)

/*EJERCICIO 9*/
/*Mostrar el c�digo del jefe, c�digo del empleado que lo tiene como jefe, nombre del
mismo y la cantidad de dep�sitos que ambos tienen asignados.*/
SELECT empl_jefe, empl_codigo, rtrim(empl_nombre) + ' ' + rtrim(empl_apellido) Nombre,
	count(DISTICT d2.depo_codigo), count(DISTICT d2.depo_encargado)
FROM Empleado JOIN DEPOSITO ON depo_encargado = empl_codigo OR depo_encargado = empl_jefe
	LEFT JOIN deposito d2 ON d2.depo_encargado = empl_jefe
GROUP BY empl_jefe, empl_codigo, rtrim(empl_nombre) + ' ' + rtrim(empl_apellido)

/*EJERCICIO 10*/
/*Mostrar los 10 productos m�s vendidos en la historia y tambi�n los 10 productos menos
vendidos en la historia. Adem�s mostrar de esos productos, quien fue el cliente que
mayor compra realizo.*/
SELECT prod_detalle,
(SELECT TOP 1 fact_cliente FROM Factura
JOIN item_factura ON fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero
WHERE item_producto = prod_codigo
GROUP BY fact_cliente
ORDER BY SUM(item_cantidad) DESC)
FROM Producto
WHERE prod_codigo IN
(SELECT TOP 10 item_producto
FROM Item_Factura
GROUP BY item_producto
ORDER BY SUM (item_cantidad) DESC)
OR prod_codigo IN
(SELECT TOP 10 item_producto
FROM Item_Factura
GROUP BY item_producto
ORDER BY SUM (item_cantidad) ASC)