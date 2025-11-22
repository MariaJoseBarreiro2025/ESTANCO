
--meto material en mis tablas

USE ESTANCO;
GO

INSERT INTO Categoria (Id_categoria,categoria)
VALUES 
(1, 'tabaco'), (2,'loteria'),(3,'sellos'),(4,'regalos'),(5,'prensa'),(6,'comestibles'),(7,'bebidas');
GO


INSERT INTO Productos (Id_producto, Nombre, Descripcion,Precio,Stock,CATEGORIA_ID_categoria)
VALUES
(1, 'Cigarrillos Marlboro', 'Cajetilla de 20 cigarrillos', 6.00, 200, 1),
(2, 'Tabaco de liar Pueblo', 'Bolsa de tabaco rubio para liar 30g', 7.20, 150, 1),
(3, 'Boleto Lotería Nacional', 'Décimo de sorteo semanal', 3.00, 500, 2),
(4, 'Boleto Euromillones', 'Apuesta sencilla de Euromillones', 2.50, 400, 2),
(5, 'Sello nacional', 'Sello postal para cartas ordinarias', 0.80, 1000, 3),
(6, 'Encendedor Zippo', 'Mechero metálico recargable con grabado', 29.90, 25, 4),
(7, 'Revista deportiva', 'Revista mensual de deportes', 4.50, 80, 5),
(8, 'Chicles Mentolados', 'Paquete de chicles sabor menta', 1.20, 300, 6),
(9, 'Botella de agua', 'Agua mineral 50cl', 1.00, 200, 7),
(10, 'Refresco cola', 'Lata de refresco sabor cola 33cl', 1.50, 250, 7);
GO



--UNION --Une los resultados de dos consultas y elimina los duplicados (como si fueran un solo listado sin repetir)
----------Muestra una lista combinada de productos y categorías
SELECT 
	Id_producto AS CODIGO, 
	Nombre AS COLUMNA2
FROM ESTANCO.dbo.Productos
UNION
SELECT 
	Id_categoria AS CODIGO,
	categoria AS COLUMNA2
FROM ESTANCO.dbo.CATEGORIA;
GO



--UNION ALL --muestra TODOS los registros, incluidos duplicados, no compara

SELECT 
    Id_producto AS CODIGO, 
    Nombre AS COLUMNA2
FROM ESTANCO.dbo.Productos

UNION ALL

SELECT 
    Id_categoria AS CODIGO,
    categoria AS COLUMNA2
FROM ESTANCO.dbo.Categoria;
GO



--INTERSECT --muestra solo los registros que existen en las dos consultas (los repetidos)
--------------Busca nombres que estén tanto en Categoría como en Producto, en mi caso no tengo ninguno repetido en mis tablas
SELECT 
    categoria AS NOMBRE
FROM ESTANCO.dbo.Categoria

INTERSECT

SELECT 
    Nombre AS NOMBRE
FROM ESTANCO.dbo.Productos;
GO




--EXCEPT --muestra los registros que están en la primera consulta, pero no en la segunda (dame lo que hay aquí, pero no allá)
SELECT 
    categoria AS NOMBRE
FROM ESTANCO.dbo.Categoria

EXCEPT

SELECT 
    Nombre AS NOMBRE
FROM ESTANCO.dbo.Productos;
GO




INSERT INTO Productos (Id_producto, Nombre, Descripcion,Precio,Stock,CATEGORIA_ID_categoria)
VALUES
(5, 'Sello nacional', 'Sello postal para cartas ordinarias', 0.80, 1000, 3);
GO



SELECT * FROM PRODUCTOS;
go


SELECT * FROM CATEGORIA;
go



DELETE FROM ESTANCO.dbo.CATEGORIA WHERE ID_categoria = 8;
GO


---------------------------
--TRANSACCIONES EXPLICITAS
---------------------------


--TRY-CATCH


BEGIN TRY
	BEGIN TRANSACTION 
		INSERT INTO ESTANCO.dbo.CATEGORIA (Id_categoria,categoria)  VALUES  (8, 'papeleria');  --intento insertar una nueva categoría (papelería)   NO DA ERROR
		--UPDATE ESTANCO.dbo.PRODUCTOS SET Precio = 'siete' WHERE ID_producto = 1; --intento actualizar el precio de los cigarrillos, pero en decimal pongo letras que me darán error porque tiene que ser números. DARÁ ERROR
		DELETE FROM ESTANCO.dbo.CATEGORIA WHERE ID_categoria = 3; --borrar de productos el ID_categoria 3 que son los sellos y la clave foránea, porque si lo quito de categoría productos depende de ello (es el padre) DA ERROR DEPENDE
		--DELETE FROM ESTANCO.dbo.PRODUCTOS WHERE CATEGORIA_ID_categoria = 15; --se hace la operación, pero como NO existe no hay cambio, y no es un error, entonces no salta el ROLLBACK.
	COMMIT TRANSACTION
END TRY
BEGIN CATCH
	--THROW; --me dice el error y me lo para (no necesitando rollback)
	ROLLBACK TRANSACTION
	PRINT 'error';
END CATCH


--SQL intenta ejecutar las instrucciones dentro del bloque TRY
--Si todo sale bien, llega a COMMIT TRANSACTION
--Si ocurre un error: Se salta directamente al bloque CATCH
--Allí se revisa si la transacción sigue abierta con @@TRANCOUNT
--Si está abierta → se hace ROLLBACK TRANSACTION para deshacer todo y PRINT para mostrarlo
--Con THROW se detiene todo y muestra cual es el problema






--XACT_ABORT ON
--Si cualquier sentencia dentro de una transacción da error, cancela toda la transacción automáticamente
--y haz ROLLBACK sin que yo tenga que escribirlo  (o todo se hace, o nada se hace )

SET XACT_ABORT ON;

	BEGIN TRANSACTION 
		INSERT INTO ESTANCO.dbo.CATEGORIA (Id_categoria,categoria)  VALUES  (8, 'papeleria');
		UPDATE ESTANCO.dbo.PRODUCTOS SET Precio = 'siete' WHERE ID_producto = 1;  --va a dar error de conversión de datos
	COMMIT TRANSACTION


--SQL Server detiene la ejecución inmediatamente.
--Revierte todo lo hecho (hace ROLLBACK automático).
--No llega a ejecutar el COMMIT TRANSACTION.
--No se ejecuta, porque el error anterior interrumpe la ejecución antes de llegar aquí

















--DOS OPERACIONES EN EL MISMO PROCEDIMIENTO:
--QUIERO ACTUALIZAR PRECIO E INSERTAR UNA NUEVA CATEGORÍA(papeleria)

--USE ESTANCO;
--GO
--
--DROP PROCEDURE IF EXISTS prueba_transaccion;
--GO
--CREATE OR ALTER PROCEDURE prueba_transaccion
--@Id_producto INT,
--@Precio DECIMAL(10,2),
--@categoria VARCHAR(100)  ---luego calculo el ID en la fila
---AS
--BEGIN
	--DECLARE @ID_variableMAX INT;
	--SELECT MAX(ID_categoria) + 1 FROM CATEGORIA; --con este SELECT obtengo 8, que es el número más alto +1
	--SELECT @ID_variableMAX = MAX(ID_categoria) + 1 FROM CATEGORIA; --con el select de antes, lo asigno así a mi variable
	--SET @ID_variableMAX = (SELECT TOP 1 Id_categoria FROM CATEGORIA ORDER BY Id_categoria DESC); --otra opción con SET loquesea = loquesea (mi select)

	--PRINT ('La variable es ' + @ID_variableMAX + ' toma esa.'); --esto va a fallar porque hay un elemento INT, tienen que ser todos varchar
	--PRINT CONCAT('La variable es ', @ID_variableMAX, ' toma esa.', GETDATE()); --concat transforma todo lo que haya a varchar, hayq ue usar comas
	--PRINT ('La variable es ' + CAST(@ID_variableMAX AS VARCHAR(20))+ ' toma esa.'); --con cast convierto algo a algo, aquí necesito un varchar, fijate en los +

	--BEGIN TRY
	  --BEGIN TRANSACTION
		--INSERT INTO CATEGORIA (ID_categoria, categoria) VALUES (@ID_variableMAX, @categoria);

		--IF EXISTS (SELECT * FROM PRODUCTOS WHERE Id_producto = @Id_producto)
			--BEGIN
				--PRINT ('Exito');
				--UPDATE PRODUCTOS SET Precio = @Precio WHERE Id_producto = @Id_producto; --esta sentencia funciona
			--END
		--ELSE
			--BEGIN
				--PRINT ('Fracaso');
				--UPDATE PRODUCTOS SET ID_producto = NULL;
			--END
	  --COMMIT TRANSACTION
	 --END TRY

	 --BEGIN CATCH
		--PRINT('VOy a hacer el ROLLBACK');
		--ROLLBACK TRANSACTION;
	 --END CATCH
--END;
--GO

--EXEC  prueba_transaccion 2, 20.00, peluches;

--SELECT * FROM CATEGORIA;

--SELECT * FROM PRODUCTOS;
--GO

--DELETE FROM CATEGORIA WHERE ID_categoria = 10;