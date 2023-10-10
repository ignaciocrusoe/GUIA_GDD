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