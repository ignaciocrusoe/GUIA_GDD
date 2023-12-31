/*EJERCICIO 1*/
/*Hacer una funci�n que dado un art�culo y un deposito devuelva un string que
indique el estado del dep�sito seg�n el art�culo. Si la cantidad almacenada es
menor al l�mite retornar �OCUPACION DEL DEPOSITO XX %� siendo XX el
% de ocupaci�n. Si la cantidad almacenada es mayor o igual al l�mite retornar
�DEPOSITO COMPLETO�.*/
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
/*Realizar una funci�n que dado un art�culo y una fecha, retorne el stock que
exist�a a esa fecha*/
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
en caso que sea necesario. Se sabe que deber�a existir un �nico gerente general
(deber�a ser el �nico empleado sin jefe). Si detecta que hay m�s de un empleado
sin jefe deber� elegir entre ellos el gerente general, el cual ser� seleccionado por
mayor salario. Si hay m�s de uno se seleccionara el de mayor antig�edad en la
empresa. Al finalizar la ejecuci�n del objeto la tabla deber� cumplir con la regla
de un �nico empleado sin jefe (el gerente general) y deber� retornar la cantidad
de empleados que hab�a sin jefe antes de la ejecuci�n.*/
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
empleado a lo largo del �ltimo a�o. Se deber� retornar el c�digo del vendedor
que m�s vendi� (en monto) a lo largo del �ltimo a�o.*/
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
provisto la tabla de hechos denominada Fact_table tiene las siguiente definici�n:
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
producto de mayor nivel), en cuyo caso deber� reemplazar las filas
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
insertar una l�nea por cada art�culo con los movimientos de stock generados por
las ventas entre esas fechas. La tabla se encuentra creada y vac�a.*/
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
productos facturados que tengan composici�n y en los cuales el precio de
facturaci�n sea diferente al precio del c�lculo de los precios unitarios por
cantidad de sus componentes, se aclara que un producto que compone a otro,
tambi�n puede estar compuesto por otros y as� sucesivamente, la tabla se debe
crear y est� formada por las siguientes columnas*/
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
/*Crear el/los objetos de base de datos que ante alguna modificaci�n de un �tem de
factura de un art�culo con composici�n realice el movimiento de sus
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

/*EJERCICIO 10*/
/*Crear el/los objetos de base de datos que ante el intento de borrar un art�culo
verifique que no exista stock y si es as� lo borre en caso contrario que emita un
mensaje de error.*/
CREATE OR ALTER TRIGGER tr_eliminar_producto ON Producto INSTEAD OF DELETE
	AS
		BEGIN
			DECLARE @producto CHAR(8)
			DECLARE C_PRODUCTO CURSOR FOR 
				SELECT prod_codigo FROM deleted

			OPEN C_PRODUCTO
			FETCH NEXT FROM C_PRODUCTO INTO @producto

			WHILE @@FETCH_STATUS = 0
				BEGIN
					DECLARE @stock DECIMAL(12,2)
					SELECT @stock = SUM(stoc_cantidad) FROM STOCK
					WHERE stoc_producto = @producto
					GROUP BY stoc_producto

					IF @stock <= 0
						DELETE FROM Producto WHERE prod_codigo = @producto
					ELSE
						RAISERROR('No se pudo borrar el producto %s', 16, 1, @producto)

						FETCH NEXT FROM C_PRODUCTO INTO @producto
				END

			SELECT prod_codigo FROM Producto
		END

DELETE FROM Producto WHERE prod_codigo IN (SELECT TOP 1 prod_codigo FROM Producto)

/*EJERCICIO 11*/
/*Cree el/los objetos de base de datos necesarios para que dado un c�digo de
empleado se retorne la cantidad de empleados que este tiene a su cargo (directa o
indirectamente). Solo contar aquellos empleados (directos o indirectos) que
tengan un c�digo mayor que su jefe directo.*/
CREATE OR ALTER FUNCTION cantidad_de_empleados (@jefe NUMERIC(6))
RETURNS INT
AS
	BEGIN
		DECLARE @empleado INT
		DECLARE @cant_empleados INT
		SELECT @cant_empleados = COUNT(*) FROM Empleado WHERE empl_jefe = @jefe
		DECLARE c_empleado CURSOR FOR SELECT empl_codigo FROM Empleado WHERE empl_jefe = @jefe
		OPEN c_empleado
		FETCH NEXT FROM c_empleado INTO @empleado

		WHILE @@FETCH_STATUS = 0
			BEGIN
				SET @cant_empleados = @cant_empleados + dbo.cantidad_de_empleados(@empleado)
				FETCH NEXT FROM c_empleado INTO @empleado
			END

		CLOSE c_empleadO
		DEALLOCATE c_empleado
		RETURN @cant_empleados
	END

/*EJERCICIO 12*/
/*Cree el/los objetos de base de datos necesarios para que nunca un producto
pueda ser compuesto por s� mismo. Se sabe que en la actualidad dicha regla se
cumple y que la base de datos es accedida por n aplicaciones de diferentes tipos
y tecnolog�as. No se conoce la cantidad de niveles de composici�n existentes.*/
CREATE OR ALTER FUNCTION f_esta_compuesto_por_si_mismo (@producto, @componente)
AS
	BEGIN
		DECLARE @producto2

		IF @producto = @componente
			RETURN 1

		DECLARE c_composicion CURSOR FOR SELECT comp_componente FROM Composicion WHERE comp_producto = @componente
		OPEN c_composicion
		FETCH NEXT FROM c_composicion INTO @producto2

		BEGIN TRANSACTION
		WHILE @@FETCH_STATUS = 0
			BEGIN
				IF dbo.f_esta_compuesto_por_si_mismo(@producto, @producto2)
					RETURN 1

				FETCH NEXT FROM c_composicion INTO @producto2
			END
		CLOSE c_composicion
		DEALLOCATE c_composicion
		RETURN 0
	END
GO

CREATE OR ALTER TRIGGER tr_composicion ON Composicion AFTER INSERT, UPDATE
AS
	BEGIN
		IF (SELECT COUNT(*) FROM inserted WHERE dbo.f_esta_compuesto_por_si_mismo(comp_producto, comp_componente) = 1) > 0
		ROLLBACK
	END
GO

/*EJERCICIO 13*/
/*Cree el/los objetos de base de datos necesarios para implantar la siguiente regla
�Ning�n jefe puede tener un salario mayor al 20% de las suma de los salarios de
sus empleados totales (directos + indirectos)�. Se sabe que en la actualidad dicha
regla se cumple y que la base de datos es accedida por n aplicaciones de
diferentes tipos y tecnolog�as*/
CREATE OR ALTER TRIGGER tr_salario_jefe ON Empleado AFTER INSERT, UPDATE
AS
	BEGIN
		DECLARE @empleado_tr NUMERIC(6)
		DECLARE @sueldo_tr DECIMAL(12,2) = 0
		DECLARE c_empleado_tr CURSOR FOR SELECT empl_codigo, empl_salario FROM inserted
		OPEN c_empleado_tr
		FETCH NEXT FROM c_empleado_tr INTO @empleado_tr, @sueldo_tr

		BEGIN TRANSACTION
		WHILE @@FETCH_STATUS = 0
			BEGIN
				IF @sueldo_tr >= 0.2 * dbo.f_sueldos_empleados(@empleado_tr)
					ROLLBACK

				FETCH NEXT FROM c_empleado INTO @empleado_tr, @sueldo_tr
			END
		COMMIT TRANSACTION
	END
GO

CREATE OR ALTER FUNCTION f_sueldos_empleados (@jefe NUMERIC(6))
RETURNS INT
AS
	BEGIN
		DECLARE @suma_sueldos DECIMAL(12,2) = 0
		DECLARE @sueldo DECIMAL(12,2) = 0
		DECLARE @empleado NUMERIC(6)
		DECLARE c_empleado CURSOR FOR SELECT empl_codigo, empl_salario FROM Empleado WHERE empl_jefe = @jefe
		OPEN c_empleado
		FETCH NEXT FROM c_empleado INTO @empleado, @sueldo

		WHILE @@FETCH_STATUS = 0
			BEGIN
				SET @suma_sueldos = @suma_sueldos + @sueldo + dbo.f_sueldos_empleados(@empleado)
				FETCH NEXT FROM c_empleado INTO @empleado, @sueldo
			END

		CLOSE c_empleado
		DEALLOCATE c_empleado
		RETURN @suma_sueldos
	END
GO

SELECT empl_codigo, dbo.f_sueldos_empleados(empl_codigo) FROM Empleado

/*EJERCICIO 14*/
/*Agregar el/los objetos necesarios para que si un cliente compra un producto
compuesto a un precio menor que la suma de los precios de sus componentes
que imprima la fecha, que cliente, que productos y a qu� precio se realiz� la
compra. No se deber� permitir que dicho precio sea menor a la mitad de la suma
de los componentes.*/
CREATE OR ALTER TRIGGER tr_compra_producto_compuesto ON Factura FOR INSERT
AS
	BEGIN
		DECLARE @producto CHAR(8)
		DECLARE @precio DECIMAL(12,2)
		DECLARE c_factura CURSOR FOR SELECT item_producto, item_precio FROM inserted JOIN Item_Factura ON item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero
		FETCH NEXT FROM c_factura INTO @producto, @precio
		BEGIN TRANSACTION
		WHILE @@FETCH_STATUS = 0
			BEGIN
				IF @precio <= 0.5 * dbo.f_precio_componentes(@producto)
					ROLLBACK

				FETCH NEXT FROM c_factura INTO @producto, @precio
			END
		CLOSE c_factura
		DEALLOCATE c_factura
		COMMIT TRANSACTION
	END
GO

CREATE OR ALTER FUNCTION f_precio_componentes(@producto CHAR(8))
RETURNS DECIMAL(12,2)
AS
	BEGIN
		DECLARE @producto_v CHAR(8)
		DECLARE @precio DECIMAL(12,2)
		DECLARE @suma_precio DECIMAL(12,2)
		DECLARE c_producto CURSOR FOR SELECT prod_codigo, prod_precio FROM Producto JOIN Composicion ON comp_componente = prod_codigo WHERE comp_producto = @producto
		OPEN c_producto
		FETCH NEXT FROM c_producto INTO @producto_v, @precio
		WHILE @@FETCH_STATUS = 0
			BEGIN
				IF (SELECT COUNT(*) FROM Composicion WHERE comp_producto = @producto_v) = 0
					RETURN @precio
				ELSE	
					SET @suma_precio = @suma_precio + dbo.f_precio_componentes(@producto_v)	
					FETCH NEXT FROM c_producto INTO @producto_v, @precio
			END
		CLOSE c_producto
		DEALLOCATE c_producto
		RETURN @suma_precio
	END
GO

SELECT comp_producto, dbo.f_precio_componentes(comp_producto) FROM Composicion
GO

/*EJERCICIO 15*/
/*Cree el/los objetos de base de datos necesarios para que el objeto principal
reciba un producto como parametro y retorne el precio del mismo.
Se debe prever que el precio de los productos compuestos sera la sumatoria de
los componentes del mismo multiplicado por sus respectivas cantidades. No se
conocen los nivles de anidamiento posibles de los productos. Se asegura que
nunca un producto esta compuesto por si mismo a ningun nivel. El objeto
principal debe poder ser utilizado como filtro en el where de una sentencia
select.*/
CREATE OR ALTER FUNCTION f_precio_producto (@producto CHAR(8))
RETURNS DECIMAL(12,2)
AS
BEGIN
	DECLARE @precio DECIMAL(12,2)
	IF NOT EXISTS (SELECT * FROM Composicion WHERE comp_producto = @producto)
	BEGIN
		SELECT @precio = prod_precio FROM Producto WHERE prod_codigo = @producto
	END
	ELSE
	BEGIN
		DECLARE @componente CHAR(8)
		DECLARE @cantidad_componente INT
		DECLARE c_producto CURSOR FOR SELECT comp_componente, comp_cantidad FROM Composicion WHERE comp_producto = @producto
		OPEN c_producto
		FETCH NEXT FROM c_producto INTO @componente, @cantidad_componente
		WHILE @@FETCH_STATUS = 0
		BEGIN
			FETCH NEXT FROM c_producto INTO @componente, @cantidad_componente
			SET @precio = @precio + dbo.f_precio_producto(@componente) * @cantidad_componente
		END
	END
	RETURN @precio
END

/*EJERCICIO 16*/
/* Desarrolle el/los elementos de base de datos necesarios para que ante una venta
automaticamante se descuenten del stock los articulos vendidos. Se descontaran
del deposito que mas producto poseea y se supone que el stock se almacena
tanto de productos simples como compuestos (si se acaba el stock de los
compuestos no se arman combos)
En caso que no alcance el stock de un deposito se descontara del siguiente y asi
hasta agotar los depositos posibles. En ultima instancia se dejara stock negativo
en el ultimo deposito que se desconto.*/
CREATE OR ALTER TRIGGER t_ventas_stock ON Factura AFTER INSERT
AS
BEGIN
	DECLARE @cantidad INT
	DECLARE @producto CHAR(8)
	DECLARE @deposito CHAR(2)
	DECLARE c_ventas CURSOR FOR SELECT item_producto item_cantidad FROM inserted
								JOIN Item_Factura ON item_sucursal + item_tipo + item_numero = fact_sucursal + fact_tipo + fact_numero
								
	OPEN c_ventas
	FETCH NEXT FROM c_ventas INTO @producto, @cantidad
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @deposito = (SELECT TOP 1 stoc_deposito
					 FROM STOCK
					 WHERE stoc_producto = @producto
					 AND stoc_cantidad > @cantidad) 
		UPDATE STOCK SET stoc_cantidad = stoc_cantidad - @cantidad
		WHERE stoc_deposito = @deposito
		FETCH NEXT FROM c_ventas INTO @producto, @cantidad
	END
	CLOSE c_ventas
	DEALLOCATE c_ventas
END

/*EJERCICIO 17*/
/*Sabiendo que el punto de reposicion del stock es la menor cantidad de ese objeto
que se debe almacenar en el deposito y que el stock maximo es la maxima
cantidad de ese producto en ese deposito, cree el/los objetos de base de datos
necesarios para que dicha regla de negocio se cumpla automaticamente. No se
conoce la forma de acceso a los datos ni el procedimiento por el cual se
incrementa o descuenta stock.*/
CREATE TRIGGER t_ ON STOCK FOR INSERT,UPDATE
AS
BEGIN
	DECLARE @producto CHAR(8)
	DECLARE	@deposito CHAR(8)
	DECLARE	@cantidad DECIMAL (12,2)
	DECLARE	@minimo DECIMAL (12,2)
	DECLARE	@maximo DECIMAL (12,2)

	DECLARE cursor_inserted CURSOR FOR SELECT stoc_producto,stoc_deposito, stoc_punto_reposicion, stoc_stock_maximo FROM inserted
	OPEN cursor_inserted
	FETCH NEXT FROM cursor_inserted
	INTO @producto, @deposito, @cantidad, @minimo, @maximo
	BEGIN TRANSACTION
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @cantidad > @maximo
			BEGIN
				PRINT 'Se est� excediendo la cantidad maxima del producto ' + @producto + ' en el deposito ' + @deposito + ' por ' + STR(@cantidad - @maximo) + ' unidades. No se puede realizar la operacion'
				ROLLBACK
			END

		ELSE IF @cantidad < @minimo
			BEGIN
				PRINT 'El producto ' + @producto + ' en el deposito ' + @deposito + ' se encuentra por debajo del minimo. Reponer!'
			END
		FETCH NEXT FROM cursor_inserted
		INTO @producto, @deposito, @cantidad, @minimo, @maximo
	END
	COMMIT TRANSACTION
	CLOSE cursor_inserted
	DEALLOCATE cursor_inserted
END
GO