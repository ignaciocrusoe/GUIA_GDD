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
CREATE OR ALTER PROCEDURE corregir_tabla_empleado
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
		RETURN (@cant_gerentes - 1)	
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
	WHERE fact_vendedor = empl_codigos AND YEAR(fact_fecha) =
	(SELECT TOP 1 YEAR(fact_fecha) FROM Factura ORDER BY YEAR(fact_fecha) DESC))
	SELECT @vendedor = MAX(empl_comision) FROM Empleado
	RETURN
END