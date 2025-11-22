--------------------------------
--BACKUP una SOLA base de datos
--------------------------------


--Crear un SP para realizar el backup
--sirve para hacer un respaldo automático de la base de datos ESTANCO, generando un archivo .bak con la fecha y hora en el nombre


USE master;
GO
DROP PROCEDURE IF EXISTS BACKUP_ESTANCO;  --si ya existe borrarlo
GO

CREATE OR ALTER PROCEDURE BACKUP_ESTANCO  --crea el procedimiento (BACKUP_ESTANCO) si no existe, o lo actualiza si sí existe 
    @ruta VARCHAR(256)     --parametro que debo enviar a la carpeta donde se va a guardar el backup
AS
BEGIN
	DECLARE                     --creo las variables para construir el nombre del archivo .bak
	@nombre_BD VARCHAR(50),     --nombre de mi BD a respaldar
	@nombre_BK VARCHAR(256),    --nombre de mi backup final
	@fechaContador VARCHAR(20); --variable donde se guarda fecha y hora actual para que el archivo no se repita

	SET @nombre_BD = 'ESTANCO'; --fijo el nombre de la BD a respaldar (ESTANCO)

	--Guarda todo en esta variable (fechaContador) : esta parte mete año, mes y día   +   esta parte mete hora, min y sg
    SET @fechaContador = CONVERT(VARCHAR(8), GETDATE(), 112) + '_' + REPLACE(CONVERT(VARCHAR(8), GETDATE(), 108), ':', '');
    
	SET @nombre_BK = @ruta + @nombre_BD + '_' + @fechaContador + '.bak';  --construye ese nombre completo
    
	PRINT 'Se va a generar el backup de la base: ' + @nombre_BK;   --muestra en la pantalla
    
	BACKUP DATABASE @nombre_BD TO DISK = @nombre_BK WITH INIT;   --hace un backup completo de la base de datos indicada y lo guarda en el archivo especificado. Si el archivo ya existe, bórralo y créalo de nuevo
    
	PRINT 'Backup completado';
END;
GO

--Para ejecutarlo
EXEC BACKUP_ESTANCO 'C:\BACKUP\';   --Llama al procedimiento y le pasa la ruta donde guardar el backup
GO



	--GETDATE() Obtiene la fecha y hora actuales del servidor. Ejemplo: 2024-02-18 15:42:30.457
	--CONVERT(VARCHAR(8), GETDATE(), 112) . Convierte la fecha en formato YYYYMMDD . Ejemplo 20240218 == 112 = formato ISO 
	--CONVERT(VARCHAR(8), GETDATE(), 108) . Convierte la hora en formato HH:MM:SS  . Ejemplo 15:42:30 == 108
	--REPLACE(..., ':', '') Quita los dos puntos :  , porque no se pueden usar en nombres de archivo
    --Se concatena todo con un guion bajo _
	-- es para crear un nombre de archivo único basado en fecha y hora


	--BACKUP DATABASE @NOMBRE_BD TO DISK = @NOMBRE_BAK WITH INIT;
	----BACKUP DATABASE → Comando de respaldo.
    ----TO DISK = @NOMBRE_BAK → Ruta destino.
    ----WITH INIT → Sobrescribe si ya existía un archivo igual (seguro porque el nombre tiene fecha).


	--PUEDO VALIDAR la carpeta creada con :
	----IF NOT EXISTS (SELECT 1 FROM sys.master_files WHERE physical_name LIKE @ruta + '%')
    ----PRINT '⚠️ La ruta no existe o no es accesible';






-----------------  PASOS a seguir


--PASO 0  Crear la carpeta donde se guardarán los backups 
-----Cualquier ruta donde el servicio de SQL Server tenga permisos de escritura



--PASO 1   Estar en la base master (opcional pero recomendado) Los procedimientos que afectan varias BD suelen guardarse ahí.
--------USE master; GO



--PASO 2   Borrar el procedimiento si ya existía. Evita errores al crearlo de nuevo.
------DROP PROCEDURE IF EXISTS NOMBRE_DEL_PROCEDIMIENTO; GO



--PASO 3   Crear el procedimiento
-----CREATE OR ALTER PROCEDURE NOMBRE_DEL_PROCEDIMIENTO
-----@ruta VARCHAR(256)    -- parámetro donde se guardará el archivo .bak
-----AS BEGIN



--PASO 4   Declarar variables internas
----- DECLARE
----- @nombreBD VARCHAR(50),
----- @nombreArchivo VARCHAR(256),
----- @fechaActual VARCHAR(20);



--PASO 5  Asignar nombre de la base a respaldar
------SET @nombreBD = 'NOMBRE_DE_LA_BD';



--PASO 6  Generar la fecha y hora para el nombre del archivo
-----SET @fechaActual = CONVERT(VARCHAR(8), GETDATE(), 112) + '_' +  REPLACE(CONVERT(VARCHAR(8), GETDATE(), 108), ':', '');



--PASO 7  Armar el nombre completo del archivo
----- SET @nombreArchivo = @ruta + @nombreBD + '_' + @fechaActual + '.bak';



--PASO 8  Mostrar mensaje informativo
-----PRINT 'Generando backup en: ' + @nombreArchivo;



--PASO 9  Ejecutar el comando de backup
-----BACKUP DATABASE @nombreBD    TO DISK = @nombreArchivo     WITH INIT;    -- borra el archivo si existía antes



--PASO 10  Mensaje final
-----PRINT 'Backup finalizado correctamente';  END;   GO



--PASO 11 Ejecutar el procedimiento
------EXEC NOMBRE_DEL_PROCEDIMIENTO 'C:\BACKUP\';  GO




---------------------------------------------
--BACKUPS MULTIPLES bases de datos con WHILE
--------------------------------------------

DROP PROCEDURE IF EXISTS BACKUPS_MULTIPLES;    --borra el SP anterior si existía
GO

CREATE OR ALTER PROCEDURE BACKUPS_MULTIPLES    --crea (o actualiza) el procedimiento llamado así
    @ruta VARCHAR(256)   --la carpeta donde se guardarán los .bak
AS
BEGIN   --comienza el cuerpo del procedimiento
    DECLARE        --declaracion de variables
        @nombre_BD VARCHAR(50),      --nombre de la BD actualmente procesada
        @nombre_BK VARCHAR(256),     --ruta + nombre del archivo .bak que se va a crear
        @fechaContador VARCHAR(20),  --timestamp (fecha+hora) para el nombre.
        @cantidad_BACKUPS INT,       --número total de filas (bases) a respaldar
        @actual_BACKUP INT;          --contador para el WHILE

--Tabla temporal que almacena las bases pendientes de backup, con ID incremental para poder recorrerlas con WHILE 
    CREATE TABLE #Bases_a_respaldar (
        ID_respaldo INT IDENTITY(1,1),   --autoincremental
        nombre_BD_respaldo VARCHAR(200)   --para guardar el nombre de cada BD a respaldar
    );
--Pueblo la tabla temporal con las BD que quiero
    INSERT INTO #Bases_a_respaldar
    SELECT name
    FROM sys.databases    --inserta en la tabla temporal los nombres obtenidos desde sysdatabases filtrando por los que aparecen en el IN
    WHERE name IN ('ESTANCO', 'pubs', 'Northwind'); -- las BD que quiera entre comas , puedo usar NOT IN 
-----De aquí salen en la tabla temporal 3 filas de las 3 BD

--Calcula cuantos backups hay que hacer:
    SELECT @cantidad_BACKUPS = MAX(ID_respaldo)
    FROM #Bases_a_respaldar;

--Comprobación y bucle WHILE
    IF (@cantidad_BACKUPS IS NOT NULL AND @cantidad_BACKUPS > 0)
    BEGIN
        SET @actual_BACKUP = 1;
        WHILE (@actual_BACKUP <= @cantidad_BACKUPS)
        BEGIN    --Asigno a la variable @nombre_BD el nombre de la base correspondiente al registro actual
            SELECT @nombre_BD = nombre_BD_respaldo
            FROM #Bases_a_respaldar
            WHERE ID_respaldo = @actual_BACKUP;

			--Genero fecha+hora única para el archivo .bak
            SET @fechaContador  = CONVERT(VARCHAR(8), GETDATE(), 112) + '_' + REPLACE(CONVERT(VARCHAR(8), GETDATE(), 108), ':', '');
          
		    --Construyo el nombre completo del archivo .bak (ruta + nombre BD + fecha + extensión)
		     SET @nombre_BK = @ruta + @nombre_BD + '_' + @fechaContador + '.bak';

           --print @NOMBRE_BAK si quiero ver cómo va la cosa
			PRINT 'Creando backup de la base: ' + @nombre_BK;

           --haz el backup 
            BACKUP DATABASE @nombre_BD   --qué quiero respaldar  
            TO DISK = @nombre_BK   --dónde guardarlo
            WITH INIT;  --sobreescribe si ya existe, se usa cuando quieres un archivo de backup único y limpio

            PRINT 'Backup completado: ' + @nombre_BD;
            SET @actual_BACKUP = @actual_BACKUP + 1;
        END
    END

    DROP TABLE #Bases_a_respaldar;

END;
GO

EXEC BACKUPS_MULTIPLES 'C:\BACKUP\';
GO



--------------------------------------------------------------------------------------------------------------------



----------
--CURSOR
----------

USE ESTANCO;
GO
--declarar variables para guardar los valores de cada fila
DECLARE @id_empleado INT;  --el número del empleado
DECLARE @nombre NVARCHAR(100); --su nombre
DECLARE @total_ventas INT; --cuantas ventas hizo

--declarar el cursor (lo CREA)
DECLARE Empleados_Cursor CURSOR FOR
    SELECT ID_empleado, Nombre
    FROM EMPLEADOS;

--abrir el cursor
OPEN Empleados_Cursor;

-- Primer FETCH (trae la primera fila) lee la primera fila y carga sus datos en las variables
--“Cursor, tráeme el siguiente empleado y guárdalo en estas variables”
FETCH NEXT FROM Empleados_Cursor INTO @id_empleado, @nombre;

--Mientras haya filas válidas, mientras el FETCH haya traído algo válido (o sea, todavía hay empleados que ver), sigue haciendo cosas
WHILE @@FETCH_STATUS = 0
BEGIN
    --Calculamos las ventas de ese empleado
    SELECT @total_ventas = COUNT(*) --cuenta cuantas ventas hay y guarda ese numero en la variable @total_ventas
    FROM VENTAS  --en que tabla se van a contar las filas
    WHERE EMPLEADOS_ID_empleado = @id_empleado; --filtra solo las ventas del empleado actual

    --imprime un mensaje por empleado con su número de ventas
    PRINT CONCAT('Empleado: ', @nombre, ' | Ventas realizadas: ', @total_ventas);

    --avanza a la siguiente fila, al siguiente empleado
    FETCH NEXT FROM Empleados_Cursor INTO @id_empleado, @nombre;
END

--Cerrar y liberar el cursor
CLOSE Empleados_Cursor;       --cierra el cursor (como cerrar la lista)
DEALLOCATE Empleados_Cursor;   --borra el cursor de la memoria (como guardar el cuaderno)
GO



---------------------
--BACKUPS CON CURSOR
---------------------

USE master   --usar la base master (los backups se hacen desde aquí)
GO

DECLARE @name VARCHAR(50)          --database name 
DECLARE @path VARCHAR(256)         --carpeta destino 
DECLARE @fileName VARCHAR(256)     --nombre completo del archivo
DECLARE @fileDate VARCHAR(20)      --fecha para el nombre 

SET @path = 'C:\Backup\'    --carpeta donde se guardaran los backups

SELECT @fileDate = CONVERT(VARCHAR(20),GETDATE(),112)  --fecha actual en formato AAAAMMDD

--declaro el cursor
DECLARE db_cursor CURSOR FOR 
SELECT name 
FROM MASTER.dbo.sysdatabases           --tambien funciona solo sysdatabases
WHERE name NOT IN ('master','model','msdb','tempdb') 

--abro el cursor
OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @name  

--mientras haya bases por recorrer
WHILE @@FETCH_STATUS = 0  
BEGIN  
      
      SET @fileName = @path + @name + '_' + @fileDate + '.BAK'  --construir el nombre del archivo
	  --PRINT 'Haciendo copia de seguridad de la base: ' + @name;
      BACKUP DATABASE @name TO DISK = @fileName    --hacer el backup
	  --PRINT 'Backup completado: ' + @fileName;

      FETCH NEXT FROM db_cursor INTO @name    ---siguiente base 
END 

--cerrar y eliminar el cursor
CLOSE db_cursor  
DEALLOCATE db_cursor 





----------------------------------
--BACKUP con cursor de mi sola BD
-----------------------------------

--USE master;
--GO

--DECLARE @name VARCHAR(50);       -- nombre de la base
--DECLARE @path VARCHAR(256);      -- carpeta destino
--DECLARE @fileName VARCHAR(256);  -- nombre completo del archivo
--DECLARE @fileDate VARCHAR(20);   -- fecha para el nombre

-- carpeta donde se guardarán los backups
--SET @path = 'C:\Backup\';

-- fecha actual en formato AAAAMMDD
--SELECT @fileDate = CONVERT(VARCHAR(20), GETDATE(), 112);

-- declaramos el cursor (solo con la base ESTANCO)
--DECLARE db_cursor CURSOR FOR
--SELECT name
--FROM sys.databases
--WHERE name = 'ESTANCO';  -- solo mi base  <<<<<<<<<<<<<<<<<<<<<<

-- abrir el cursor
--OPEN db_cursor;

-- leer la primera (y única) base
--FETCH NEXT FROM db_cursor INTO @name;

-- mientras haya bases por recorrer
--WHILE @@FETCH_STATUS = 0
--BEGIN
    -- construir el nombre del archivo
    --SET @fileName = @path + @name + '_' + @fileDate + '.BAK';

    -- hacer el backup
    --PRINT 'Haciendo copia de seguridad de la base: ' + @name;
    --BACKUP DATABASE @name TO DISK = @fileName;

    --PRINT 'Backup completado: ' + @fileName;

    -- siguiente base (aunque aquí solo habrá una)
   -- FETCH NEXT FROM db_cursor INTO @name;
--END

-- cerrar y eliminar el cursor
--CLOSE db_cursor;
--DEALLOCATE db_cursor;
--GO








---------------------------------
--BACKUP MULTIPLES bases de datos
---------------------------------

--USE master;
--GO
--DROP PROCEDURE IF EXISTS BACKUP_TRES_BD;
--GO

--CREATE OR ALTER PROCEDURE BACKUP_TRES_BD
    --@ruta VARCHAR(256)
--AS
--BEGIN
   --DECLARE 
       -- @fecha VARCHAR(20),
        --@archivo VARCHAR(256);

    -- Generar cadena fecha-hora solo una vez
    --SET @fecha = CONVERT(VARCHAR(8), GETDATE(), 112) + '_' +  REPLACE(CONVERT(VARCHAR(8), GETDATE(), 108), ':', '');

    -- ================= BACKUP ESTANCO =================
    --SET @archivo = @ruta + 'ESTANCO_' + @fecha + '.bak';
    --PRINT 'Backup de ESTANCO → ' + @archivo;
    --BACKUP DATABASE ESTANCO TO DISK = @archivo WITH INIT;

    -- ================= BACKUP PUBS ====================
    --SET @archivo = @ruta + 'PUBS_' + @fecha + '.bak';
    --PRINT 'Backup de PUBS → ' + @archivo;
    --BACKUP DATABASE PUBS TO DISK = @archivo WITH INIT;

    -- ================= BACKUP NORTHWIND ===============
    --SET @archivo = @ruta + 'NORTHWIND_' + @fecha + '.bak';
    --PRINT 'Backup de NORTHWIND → ' + @archivo;
    --BACKUP DATABASE Northwind TO DISK = @archivo WITH INIT;

    --PRINT ' Backup de las 3 bases completado.';
--END;
--GO

-- Para ejecutarlo:
--EXEC BACKUP_TRES_BD 'C:\BACKUP\';
--GO






---------------------------------------------------
--Procedimiento con WHILE (versión sencilla y clara)
---------------------------------------------------


--USE master;
--GO
--DROP PROCEDURE IF EXISTS BACKUP_3_BD;
--GO

--CREATE OR ALTER PROCEDURE BACKUP_3_BD
    ----@ruta VARCHAR(256)
--AS
--BEGIN
    --DECLARE 
     -----@fecha VARCHAR(20),
     -----@archivo VARCHAR(256),
     -----@BD VARCHAR(50),
     -----@contador INT = 1;


    -- Tabla temporal con los nombres de las bases
    --DECLARE @listaBD TABLE (ID INT IDENTITY(1,1), NombreBD VARCHAR(50));
    --INSERT INTO @listaBD VALUES ('ESTANCO'), ('PUBS'), ('NORTHWIND');

    -- Fecha para que todos los backups tengan el mismo timestamp
    --SET @fecha = CONVERT(VARCHAR(8), GETDATE(), 112) + '_' +
                -- REPLACE(CONVERT(VARCHAR(8), GETDATE(), 108), ':', '');

    --WHILE @contador <= (SELECT COUNT(*) FROM @listaBD)
    --BEGIN
        --SELECT @BD = NombreBD FROM @listaBD WHERE ID = @contador;

        --SET @archivo = @ruta + @BD + '_' + @fecha + '.bak';

        --PRINT 'Backup de ' + @BD + ' → ' + @archivo;

        --BACKUP DATABASE @BD TO DISK = @archivo WITH INIT;

        --SET @contador = @contador + 1;  -- avanzar al siguiente
    --END

   --PRINT '✅ Backups de ESTANCO, PUBS y NORTHWIND completados.';
--END;
--GO
