/*EJERCICIO 1*/
/*Hacer una función que dado un artículo y un deposito devuelva un string que
indique el estado del depósito según el artículo. Si la cantidad almacenada es
menor al límite retornar “OCUPACION DEL DEPOSITO XX %” siendo XX el
% de ocupación. Si la cantidad almacenada es mayor o igual al límite retornar
“DEPOSITO COMPLETO”.*/
CREATE FUNCTION ej1 (@articulo char(8), @deposito char(2))
RETURNS char(40)
AS
BEGIN
	DECLARE @stkact decimal(12,2), @stkmaximo decimal(12,2)
	DECLARE @retorno char(40)
	SELECT @stkact = stoc_cantidad, @stkmaximo = stoc_stock_maximo FROM stock
	WHERE stoc_producto = @articulo AND stoc_deposito = @deposito
	IF @stkact >= @stkmaximo
		SELECT @retorno = 'DEPOSITO COMPLETO'
	ELSE
		SET @retorno = 'OCUPACION DEL DEPOSITO' +STR(@stkact / @stkmaximo * 100, 12, 2) + '%'
	RETURN @retorno
END

SELECT stoc_producto, stoc_deposito, dbo.ej1(stoc_producto, stoc_deposito) FROM stock

/*EJERCICIO 2*/
/*Realizar una función que dado un artículo y una fecha, retorne el stock que
existía a esa fecha*/
CREATE FUNCTION dbo.ej2 (@articulo CHAR(8), @fecha SMALLDATETIME)
RETURNS DECIMAL(12,2)
AS
BEGIN
	DECLARE @retorno DECIMAL(12,2)
	SELECT @retorno = SUM(ISNULL(stoc_cantidad, 0)) FROM Item_Factura
	LEFT JOIN Factura ON item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero
	LEFT JOIN Producto ON prod_codigo = item_producto
	LEFT JOIN STOCK ON prod_codigo = stoc_producto
	WHERE prod_codigo = @articulo
	AND fact_fecha >= @fecha
	GROUP BY stoc_cantidad
	RETURN @retorno
END

SELECT prod_codigo, dbo.ej2(prod_codigo, '2010-01-23 00:00:00') FROM Producto

/*EJERCICIO 3*/
/*Cree el/los objetos de base de datos necesarios para corregir la tabla empleado
en caso que sea necesario. Se sabe que debería existir un único gerente general
(debería ser el único empleado sin jefe). Si detecta que hay más de un empleado
sin jefe deberá elegir entre ellos el gerente general, el cual será seleccionado por
mayor salario. Si hay más de uno se seleccionara el de mayor antigüedad en la
empresa. Al finalizar la ejecución del objeto la tabla deberá cumplir con la regla
de un único empleado sin jefe (el gerente general) y deberá retornar la cantidad
de empleados que había sin jefe antes de la ejecución.*/
CREATE OR ALTER PROCEDURE corregir_tabla_empleado @output NUMERIC(6)
	AS
	BEGIN
		DECLARE @cant_gerentes INT
		DECLARE @gerente_codigo NUMERIC(6)
		SET @cant_gerentes = (SELECT COUNT(DISTINCT empl_codigo) FROM Empleado
		WHERE empl_jefe IS NULL)

		IF (@cant_gerentes > 1)
				BEGIN
					SELECT TOP 1 @gerente_codigo = empl_codigo FROM Empleado
					GROUP BY empl_codigo, empl_salario
					ORDER BY empl_salario DESC

					UPDATE Empleado
					SET empl_jefe = @gerente_codigo
					WHERE empl_jefe IS NULL
				END
				SET @output = @cant_gerentes - 1
		RETURN
	END

BEGIN
DECLARE @output NUMERIC(6)
EXECUTE corregir_tabla_empleado @output = 0
PRINT @output
END

/*EJERCICIO 4*/
/*Cree el/los objetos de base de datos necesarios para actualizar la columna de
empleado empl_comision con la sumatoria del total de lo vendido por ese
empleado a lo largo del último año. Se deberá retornar el código del vendedor
que más vendió (en monto) a lo largo del último año.*/
CREATE PROCEDURE ej4 @vendedor NUMERIC(6)
AS
BEGIN
	UPDATE Empleado SET empl_comision =
	(SELECT SUM(fact_total) FROM factura
	WHERE fact_vendedor = empl_codigo AND YEAR(fact_fecha) =
	(SELECT TOP 1 YEAR(fact_fecha) FROM Factura ORDER BY YEAR(fact_fecha) DESC))
	SELECT @vendedor = MAX(empl_comision) FROM Empleado
	RETURN
END

EXEC dbo.ej4 @vendedor = 01

/*EJERCICIO 5*/
/*Realizar un procedimiento que complete con los datos existentes en el modelo
provisto la tabla de hechos denominada Fact_table tiene las siguiente definición:
Create table Fact_table
( anio char(4),
mes char(2),
familia char(3),
rubro char(4),
zona char(3),
cliente char(6),
producto char(8),
cantidad decimal(12,2),
monto decimal(12,2)
)
Alter table Fact_table
Add constraint primary key(anio,mes,familia,rubro,zona,cliente,producto)*/

CREATE OR ALTER PROCEDURE migrar_fact_table	
	AS
		BEGIN
			INSERT INTO Fact_table (anio, mes, familia, rubro, zona, cliente, producto, cantidad, monto)
			SELECT (YEAR(fact_fecha), MONTH(fact_fecha), fami_id, rubr_id, clie_codigo, prod_codigo, item_cantidad, item_cantidad * item_precio)
			FROM Item_Factura LEFT JOIN Factura ON fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero
			LEFT JOIN Cliente ON clie_codigo = fact_cliente
			LEFT JOIN Producto ON prod_codigo = item_producto
			LEFT JOIN Rubro ON rubr_id = prod_rubro
			LEFT JOIN Familia ON fami_id = prod_familia
		END

/*EJERCICIO 6*/
/*Realizar un procedimiento que si en alguna factura se facturaron componentes
que conforman un combo determinado (o sea que juntos componen otro
producto de mayor nivel), en cuyo caso deberá reemplazar las filas
correspondientes a dichos productos por una sola fila con el producto que
componen con la cantidad de dicho producto que corresponda.*/
CREATE OR ALTER PROCEDURE combinar_productos
	AS
		BEGIN
			DECLARE @consulta TABLE(item_tipo CHAR(1), item_sucursal CHAR(4), item_producto CHAR(8), item_cantidad DECIMAL(12,2))

			INSERT INTO Item_Factura (item_tipo, item_sucursal, item_producto, item_cantidad)
			SELECT DISTINCT I1.item_tipo, I1.item_sucursal, PC.prod_codigo, COUNT(PC.prod_codigo) AS[item_cantidad] FROM Factura
			JOIN Item_Factura I1 ON I1.item_tipo + I1.item_sucursal + I1.item_numero = fact_tipo + fact_sucursal + fact_numero
			JOIN Item_Factura I2 ON I2.item_tipo + I2.item_sucursal + I2.item_numero = fact_tipo + fact_sucursal + fact_numero
			JOIN Producto P1 ON P1.prod_codigo = I1.item_producto
			JOIN Producto P2 ON P2.prod_codigo = I2.item_producto
			JOIN Composicion C1 ON C1.comp_componente = I1.item_producto
			JOIN Composicion C2 ON C2.comp_componente = I2.item_producto
			JOIN Producto PC ON PC.prod_codigo = C1.comp_producto
			WHERE C1.comp_componente != C2.comp_componente
			AND C1.comp_producto = C2.comp_producto
			GROUP BY I1.item_tipo, I1.item_sucursal, PC.prod_codigo

			DELETE FROM Item_Factura
			WHERE item_tipo + item_sucursal + item_numero IN (SELECT item_tipo + item_sucursal + item_numero FROM @consulta)

		END

/*EJERCICIO 7*/
/*Hacer un procedimiento que dadas dos fechas complete la tabla Ventas. Debe
insertar una línea por cada artículo con los movimientos de stock generados por
las ventas entre esas fechas. La tabla se encuentra creada y vacía.*/
IF OBJECT_ID('Ventas','U') IS NOT NULL
	DROP TABLE Ventas
GO

CREATE TABLE Ventas(
	vent_producto CHAR(8),
	vent_detalle CHAR(50),
	vent_movimientos INT,
	vent_precio_prom DECIMAL(12,1),
	vent_renglon INT IDENTITY PRIMARY KEY,
	vent_ganancia CHAR(6) NOT NULL
)

CREATE OR ALTER PROCEDURE completar_tabla_ventas (@fecha_inicio SMALLDATETIME, @fecha_fin SMALLDATETIME)
	AS
		BEGIN
		DECLARE @producto CHAR(8)
		DECLARE @detalle CHAR(50)
		DECLARE @movimientos INT
		DECLARE @precio DECIMAL(12,2)
		DECLARE @ganancia DECIMAL(12,2)

		DECLARE c_ventas CURSOR FOR
			SELECT prod_codigo, prod_detalle, COUNT(item_producto), AVG(item_precio), SUM(item_cantidad * item_precio) - SUM(item_cantidad * prod_precio)
			FROM Producto JOIN Item_Factura ON prod_codigo = item_producto
			JOIN Factura ON item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero
			WHERE fact_fecha BETWEEN @fecha_inicio AND @fecha_fin
			GROUP BY prod_codigo, prod_detalle

		OPEN c_ventas
		FETCH NEXT FROM c_ventas INTO @producto, @detalle, @movimientos, @precio, @precio, @ganancia

		WHILE @@FETCH_STATUS = 0
			BEGIN
				INSERT INTO Ventas (vent_producto, vent_detalle, vent_movimientos, vent_precio_prom, vent_ganancia)
				VALUES (@producto, @detalle, @movimientos, @precio, @ganancia)

				FETCH NEXT FROM c_ventas INTO @producto, @detalle, @movimientos, @precio, @precio, @ganancia
			END
			CLOSE c_ventas
			DEALLOCATE c_ventas
		END

		EXEC dbo.completar_tabla_ventas '2012-01-01', '2012-06-01'
		SELECT * FROM Ventas

/*EJERCICIO 8*/
/*Realizar un procedimiento que complete la tabla Diferencias de precios, para los
productos facturados que tengan composición y en los cuales el precio de
facturación sea diferente al precio del cálculo de los precios unitarios por
cantidad de sus componentes, se aclara que un producto que compone a otro,
también puede estar compuesto por otros y así sucesivamente, la tabla se debe
crear y está formada por las siguientes columnas*/
IF OBJECT_ID('Diferencias','U') IS NOT NULL
	DROP TABLE Diferencias
GO

CREATE TABLE Diferencias ( 
	dif_codigo char(8),
	dif_detalle char(50),
	dif_cantidad NUMERIC(6,0),
	dif_precio_generado DECIMAL(12,2),
	dif_precio_facturado DECIMAL(12,2),
)
GO

CREATE OR ALTER PROCEDURE completar_tabla_diferencias
	AS
		BEGIN
		DECLARE @codigo CHAR(8)
		DECLARE @detalle CHAR(50)
		DECLARE @cantidad INT
		DECLARE @precio_generado DECIMAL(12,2)
		DECLARE @rpecio_facturado DECIMAL(12,2)

		DECLARE c_diferencias CURSOR FOR
			SELECT  prod_codigo, prod_detalle, COUNT(item_producto), @precio_generado, fact_total 
			FROM Item_Factura
			LEFT JOIN Factura ON fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero
			LEFT JOIN Producto ON prod_codigo = item_cantidad
			WHERE prod_codigo IN (SELECT DISTINCT comp_producto FROM Composicion)
			AND fact_total != (SELECT @precio_generado = SUM(item_cantidad * item_precio) FROM Factura
								LEFT JOIN Item_Factura ON fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero
								WHERE prod_codigo = @prod_codigo)


		OPEN c_diferencias
		FETCH NEXT FROM c_diferencias INTO @producto, @detalle, @cantidad, @precio_generado, @rpecio_facturado

		WHILE @@FETCH_STATUS = 0
			
				INSERT INTO Diferencias(dif_codigo, dif_detalle, dif_cantidad, dif_precio_generado, dif_precio_facturado)
				VALUES (@codigo, @detalle, @cantidad, @precio_generado, @rpecio_facturado)

				FETCH NEXT FROM c_diferencias INTO @producto, @detalle, @cantidad, @precio_generado, @rpecio_facturado
			END

		END

/*EJERCICIO 9*/
/*Crear el/los objetos de base de datos que ante alguna modificación de un ítem de
factura de un artículo con composición realice el movimiento de sus
correspondientes componentes.*/
CREATE OR ALTER TRIGGER ON Item_Factura FOR UPDATE
	AS
	BEGIN
		UPDATE STOCK SET stoc_cantidad = stoc_cantidad - (SELECT comp_cantidad * (I.item_cantidad - D.item_cantidad)
														  FROM inserted I JOIN deleted D ON I.item_tipo + I.item_sucursal + I.item_numero + I.item_producto = 
														  D.item_tipo + D.item_sucursal + D.item_numero + D.item_producto
														  JOIN Composicion ON comp_producto = I.item_producto
														  WHERE comp_componente = stoc_producto AND stoc_deposito = (SELECT TOP 1 stoc_deposito
																													 FROM STOCK WHERE stoc_producto = comp_componente 
																													 ORDER BY stoc_cantidad DESC)
														  )
														  

	END
GO