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
SELECT prod_codigo, prod_detalle, SUM(ISNULL(stoc_cantidad, 0))
FROM Producto
LEFT JOIN STOCK ON prod_codigo = stoc_producto
GROUP BY prod_codigo, prod_detalle
ORDER BY prod_detalle;

/*EJERCICIO 4*/
/*Realizar una consulta que muestre para todos los art�culos c�digo, detalle y cantidad de
art�culos que lo componen. Mostrar solo aquellos art�culos para los cuales el stock
promedio por dep�sito sea mayor a 100.*/
SELECT prod_codigo, prod_detalle, count(comp_componente)
FROM Producto
LEFT JOIN Composicion ON  prod_codigo = comp_producto
WHERE prod_codigo IN (SELECT prod_codigo FROM STOCK GROUP BY stoc_producto HAVING AVG(stoc_cantidad) > 100)
GROUP BY prod_codigo, prod_detalle
ORDER BY COUNT(comp_componente) DESC

/*EJERCICIO 5*/
/*Realizar una consulta que muestre c�digo de art�culo, detalle y cantidad de egresos de
stock que se realizaron para ese art�culo en el a�o 2012 (egresan los productos que
fueron vendidos). Mostrar solo aquellos que hayan tenido m�s egresos que en el 2011*/
SELECT prod_codigo, prod_detalle, SUM(item_cantidad) Egresos
FROM Producto
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

SELECT J.empl_codigo AS [C�digo jefe],
	rtrim(J.empl_nombre) + ' ' + rtrim(J.empl_apellido) AS [Nombre jefe],
	E.empl_codigo AS [C�digo empleado],
	rtrim(E.empl_nombre) + ' ' + rtrim(E.empl_apellido) AS [Nombre empleado],
	COUNT(depo_encargado) AS [Dep�sitos asignados]
FROM Empleado J
JOIN DEPOSITO ON depo_encargado = empl_codigo 
JOIN Empleado E ON E.empl_jefe = J.empl_codigo
GROUP BY E.empl_codigo, J.empl_codigo, E.empl_nombre, E.empl_apellido, J.empl_nombre, J.empl_apellido

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

/*EJERCICIO 11*/
/*Realizar una consulta que retorne el detalle de la familia, la cantidad diferentes de
productos vendidos y el monto de dichas ventas sin impuestos. Los datos se deber�n
ordenar de mayor a menor, por la familia que m�s productos diferentes vendidos tenga,
solo se deber�n mostrar las familias que tengan una venta superior a 20000 pesos para
el a�o 2012.*/
SELECT fami_detalle, COUNT(DISTINCT item_producto), SUM(item_precio * item_cantidad)
FROM Familia JOIN Producto ON fami_id = prod_familia
	JOIN Item_factura ON prod_codigo = item_producto
WHERE fami_id IN
	(SELECT prod_familia
	FROM Producto JOIN Item_factura ON prod_codigo = item_producto
	JOIN Factura ON fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero
	WHERE YEAR(fact_fecha) = 2012
	GROUP BY prod_familia
	HAVING SUM(item_cantidad * item_precio) > 20000)
GROUP BY fami_id, fami_detalle
ORDER BY 2 DESC


/*EJERCICIO 12*/
/*Mostrar nombre de producto, cantidad de clientes distintos que lo compraron importe
promedio pagado por el producto, cantidad de dep�sitos en los cuales hay stock del
producto y stock actual del producto en todos los dep�sitos. Se deber�n mostrar
aquellos productos que hayan tenido operaciones en el a�o 2012 y los datos deber�n
ordenarse de mayor a menor por monto vendido del producto*/
SELECT prod_detalle, COUNT(DISTINCT fact_cliente)
FROM Producto
JOIN Item_factura ON prod_codigo = item_producto
JOIN Factura ON fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero
JOIN STOCK ON prod_codigo = stoc_producto
WHERE stoc_cantidad > 0 AND prod_codigo IN (SELECT item_producto FROM Item_factura
											JOIN Factura ON fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero
											WHERE year(Fact_fecha) = 2012)

GROUP BY prod_detalle, prod_precio
ORDER BY prod_precio DESC

SELECT prod_detalle, COUNT(DISTINCT fact_cliente), AVG(item_precio), COUNT(DISTINCT stoc_deposito)
FROM Producto
JOIN Item_factura ON prod_codigo = item_producto
JOIN Factura ON fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero
JOIN STOCK ON prod_codigo = stoc_producto
WHERE stoc_cantidad > 0 AND year(Fact_fecha) = 2012
GROUP BY prod_detalle, prod_precio
ORDER BY prod_precio DESC

/*EJERCICIO 13*/
/*Realizar una consulta que retorne para cada producto que posea composici�n nombre
del producto, precio del producto, precio de la sumatoria de los precios por la cantidad
de los productos que lo componen. Solo se deber�n mostrar los productos que est�n
compuestos por m�s de 2 productos y deben ser ordenados de mayor a menor por
cantidad de productos que lo componen.*/
SELECT P.prod_detalle, P.prod_precio, SUM(C.prod_precio * comp_cantidad)
FROM Composicion
JOIN Producto P ON P.prod_codigo = comp_producto
JOIN Producto C ON C.prod_precio = comp_componente
GROUP BY P.prod_detalle, P.prod_precio
HAVING COUNT(*) >=2
ORDER BY COUNT(*) DESC

/*EJERCICIO 14*/
/*Escriba una consulta que retorne una estad�stica de ventas por cliente. Los campos que
debe retornar son:
C�digo del cliente
Cantidad de veces que compro en el �ltimo a�o
Promedio por compra en el �ltimo a�o
Cantidad de productos diferentes que compro en el �ltimo a�o
Monto de la mayor compra que realizo en el �ltimo a�o
Se deber�n retornar todos los clientes ordenados por la cantidad de veces que compro en
el �ltimo a�o.
No se deber�n visualizar NULLs en ninguna columna*/
SELECT C.clie_codigo AS [C�digo del cliente],
COUNT(DISTINCT fact_numero) AS [Cantidad de veces que compro en el �ltimo a�o],
AVG(fact_total) AS [Promedio por compra en el �ltimo a�o],
COUNT(DISTINCT item_producto) AS [Cantidad de productos diferentes que compro en el �ltimo a�o],
(SELECT TOP 1 fact_total FROM Factura WHERE fact_cliente = C.clie_codigo GROUP BY fact_total ORDER BY fact_total) AS [Monto de la mayor compra que realizo en el �ltimo a�o]
FROM Cliente C
LEFT JOIN Factura ON fact_cliente = C.clie_codigo
JOIN Item_Factura ON fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero
WHERE YEAR(fact_fecha) = (SELECT TOP 1 YEAR(fact_fecha) FROM Factura GROUP BY fact_fecha ORDER BY fact_fecha DESC)
GROUP BY C.clie_codigo

/*EJERCICIO 15*/
/*Escriba una consulta que retorne los pares de productos que hayan sido vendidos juntos
(en la misma factura) m�s de 500 veces. El resultado debe mostrar el c�digo y
descripci�n de cada uno de los productos y la cantidad de veces que fueron vendidos
juntos. El resultado debe estar ordenado por la cantidad de veces que se vendieron
juntos dichos productos. Los distintos pares no deben retornarse m�s de una vez.
Ejemplo de lo que retornar�a la consulta:
PROD1 DETALLE1 PROD2 DETALLE2 VECES
1731 MARLBORO KS 1 7 1 8 P H ILIPS MORRIS KS 5 0 7
1718 PHILIPS MORRIS KS 1 7 0 5 P H I L I P S MORRIS BOX 10 5 6 2*/
SELECT P1.prod_codigo, P1.prod_detalle, P2.prod_codigo, P2.prod_detalle, COUNT(*)
FROM Composicion C1
JOIN Composicion C2 ON C2.comp_producto = C1.comp_producto
LEFT JOIN Producto P1 ON P1.prod_codigo = C1.comp_componente
LEFT JOIN Producto P2 ON P2.prod_codigo = C2.comp_componente
WHERE P1.prod_detalle != P2.prod_detalle
GROUP BY P1.prod_codigo, P1.prod_detalle, P2.prod_codigo, P2.prod_detalle

/*EJERCICIO 16*/
/*Con el fin de lanzar una nueva campa�a comercial para los clientes que menos compran
en la empresa, se pide una consulta SQL que retorne aquellos clientes cuyas compras
son inferiores a 1/3 del monto de ventas del producto que m�s se vendi� en el 2012.
Adem�s mostrar
1. Nombre del Cliente
2. Cantidad de unidades totales vendidas en el 2012 para ese cliente.
3. C�digo de producto que mayor venta tuvo en el 2012 (en caso de existir m�s de 1,
mostrar solamente el de menor c�digo) para ese cliente.*/
SELECT DISTINCT clie_razon_social AS [Nombre del Cliente],
SUM(item_cantidad),
(SELECT TOP 1 prod_codigo
FROM Producto
JOIN Item_Factura ON item_producto = prod_codigo
JOIN Factura ON item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero
WHERE fact_cliente = clie_codigo
GROUP BY prod_codigo, item_producto
ORDER BY COUNT(item_producto) DESC, item_producto ASC) AS [C�digo de producto que mayor venta tuvo en el 2012]
FROM Cliente
JOIN Factura ON fact_cliente = clie_codigo
JOIN Item_Factura ON item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero
WHERE YEAR(fact_fecha) = 2012
GROUP BY clie_codigo, clie_razon_social

/*EJERCICIO 17*/
/*Escriba una consulta que retorne una estad�stica de ventas por a�o y mes para cada
producto.
La consulta debe retornar:
PERIODO: A�o y mes de la estad�stica con el formato YYYYMM
PROD: C�digo de producto
DETALLE: Detalle del producto
CANTIDAD_VENDIDA= Cantidad vendida del producto en el periodo
VENTAS_A�O_ANT= Cantidad vendida del producto en el mismo mes del periodo
pero del a�o anterior
CANT_FACTURAS= Cantidad de facturas en las que se vendi� el producto en el
periodo
La consulta no puede mostrar NULL en ninguna de sus columnas y debe estar ordenada
por periodo y c�digo de producto.*/
SELECT CONCAT(YEAR(fact_fecha), RIGHT('0' + RTRIM(MONTH(fact_fecha)),2)) AS [PERIODO],
	   prod_codigo AS [PROD],
	   prod_detalle AS [DETALLE],
	   SUM(ISNULL(item_cantidad, 0)) AS [CANTIDAD_VENDIDA],
	   ISNULL((SELECT SUM(I.item_cantidad) FROM Item_Factura I
	    JOIN Factura F2 ON F2.fact_tipo + F2.fact_sucursal + F2.fact_numero = I.item_tipo + I.item_sucursal + I.item_numero
		WHERE I.item_producto = prod_codigo
		AND YEAR(F2.fact_fecha) = YEAR(F1.fact_fecha) - 1
		AND MONTH(F2.fact_fecha) = MONTH(F1.fact_fecha)
		),0) AS [CANT_FACTURAS_A�O_ANTERIOR],
		ISNULL(COUNT(*),0) AS [CANT_FACTURAS]
FROM Item_Factura
LEFT JOIN Factura F1 ON F1.fact_tipo + F1.fact_sucursal + F1.fact_numero = item_tipo + item_sucursal + item_numero
LEFT JOIN Producto ON prod_codigo = item_producto
GROUP BY fact_fecha, prod_codigo, prod_detalle, YEAR(fact_fecha), MONTH(fact_fecha)
ORDER BY fact_fecha, prod_codigo

/*EJERCICIO 18*/
/*Escriba una consulta que retorne una estad�stica de ventas para todos los rubros.
La consulta debe retornar:
DETALLE_RUBRO: Detalle del rubro
VENTAS: Suma de las ventas en pesos de productos vendidos de dicho rubro
PROD1: C�digo del producto m�s vendido de dicho rubro
PROD2: C�digo del segundo producto m�s vendido de dicho rubro
CLIENTE: C�digo del cliente que compro m�s productos del rubro en los �ltimos 30
d�as
La consulta no puede mostrar NULL en ninguna de sus columnas y debe estar ordenada
por cantidad de productos diferentes vendidos del rubro.*/
SELECT 
	ISNULL(rubr_detalle, 'Sin descripcion') AS [Rubro],
	ISNULL(SUM(item_cantidad * item_precio), 0) AS [Ventas],
	ISNULL((SELECT TOP 1 item_producto
			FROM Producto
			JOIN Item_Factura ON prod_codigo = item_producto
			WHERE prod_rubro = rubr_id
			GROUP BY item_producto
			ORDER BY SUM(item_cantidad) DESC), 0) AS [PROD1],
	ISNULL((SELECT TOP 1 item_producto FROM Producto
			JOIN Item_Factura ON prod_codigo = item_producto
			WHERE prod_rubro = rubr_id
			AND item_producto NOT IN
			(SELECT TOP 1 item_producto FROM Producto
			JOIN Item_Factura ON prod_codigo = item_producto
			WHERE prod_rubro = rubr_id
			GROUP BY item_producto
			ORDER BY SUM(item_cantidad) DESC) 
			GROUP BY item_producto
			ORDER BY SUM(item_cantidad) DESC), '-') AS [PROD2],
	ISNULL((SELECT TOP 1 fact_cliente
			FROM Producto
			JOIN Item_Factura ON prod_codigo = item_producto
			JOIN Factura ON item_numero + item_sucursal + item_tipo =
			fact_numero + fact_sucursal + fact_tipo
			WHERE fact_fecha >
			(SELECT DATEADD(DAY, -30, MAX(fact_fecha)) FROM Factura)
			AND prod_rubro = rubr_id
			GROUP BY fact_cliente
			ORDER BY SUM(item_cantidad) DESC), '-') AS [Cliente]
FROM Rubro
JOIN Producto ON rubr_id = prod_rubro
JOIN Item_Factura ON prod_codigo = item_producto
GROUP BY rubr_id, rubr_detalle
ORDER BY COUNT(DISTINCT prod_codigo)