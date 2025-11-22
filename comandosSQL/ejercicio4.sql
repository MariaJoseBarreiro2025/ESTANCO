USE ESTANCO;
GO

DROP TABLE IF EXISTS dbo.imagenes
GO

CREATE TABLE dbo.imagenes (	  --Esta tabla servira para almacenar imágenes dentro de SQL Server
   nombre_img VARCHAR(40) PRIMARY KEY NOT NULL,
   nombre_completo VARCHAR (100),
   img_datos VARBINARY (max)
   )
GO

Use master;		--algunas configuraciones, como estas que vamos a habilitar, se tienen que hacer desde MASTER
GO

EXEC sp_configure 'show advanced options', 1; --Activa las opciones avanzadas del servidor SQL, que normalmente están ocultas
GO 
RECONFIGURE WITH OVERRIDE; 
GO 

EXEC sp_configure 'Ole Automation Procedures', 1;  --Habilita un conjunto de funciones que permiten a SQL Server: leer archivos del disco, escribir archivos, automatizar ...
GO 
RECONFIGURE WITH OVERRIDE
GO

--dar permisos de BULK, para importar datos masivos o leer archivos desde disco
ALTER SERVER ROLE [bulkadmin] ADD MEMBER [DESKTOP-0EJKGJS\Mar_Bar] --añado MI USUARIO al rol de bulkear datos
GO


--------------------
-- IMPORTAR IMAGENES
--------------------

USE ESTANCO;
GO

DROP PROCEDURE IF EXISTS dbo.importar_imagen;    
GO
CREATE OR ALTER PROCEDURE dbo.importar_imagen (           --creo procedimiento con 3 parametros
     @img_importar VARCHAR (100), --Nombre que tendrá la imagen dentro de la tabla
     @carpeta_img VARCHAR (1000),  --Carpeta donde está la imagen en el disco
     @img_completa VARCHAR (1000) --Nombre del archivo con su extensión (ej: foto.png)
   )
AS
BEGIN    --declaro variables internas:
   DECLARE @ruta_absoluta VARCHAR (2000);   --ruta completa al archivo
   DECLARE @inserccion_dinamica VARCHAR (2000);  --texto SQL que luego se ejecutará dinámicamente

   SET NOCOUNT ON --para evitar que se vean mensajes molestos: Resultado + limpio

   SET @ruta_absoluta = CONCAT (@carpeta_img,'\', @img_completa); --CONCAT convierte automáticamente los valores a texto, une varios textos en uno solo, formando la ruta completa del archivo.
   SET @inserccion_dinamica = 'insert into dbo.imagenes (nombre_img, nombre_completo, img_datos) ' +  --como es todo varchar no hace falta usar concat o convert
               ' SELECT ' + '''' + @img_importar + '''' + ',' + '''' + @img_completa + '''' + ', * ' + --las comillas simples se hacen con cuatro simples
               'FROM Openrowset( Bulk ' + '''' + @ruta_absoluta + '''' + ', Single_Blob) as img' 
   EXEC (@inserccion_dinamica) -- lee el archivo físicamente desde el PC, lo convierte en un BLOB (cualquier archivo binario grande) y lo guarda en la tabla

   SET NOCOUNT OFF --vuelve a activar la visualización normal de filas afectadas
END
GO


execute dbo.importar_imagen 'cigarrillos','C:\IMAGENES\ENTRADA','cigarrillos.jpg';
GO


SELECT * FROM dbo.imagenes;
GO




--1️ Crea la ruta completa al archivo      SET @ruta_absoluta = CONCAT(@carpeta_img,'\',@img_completa);

--2 Prepara una sentencia SQL dinámica    Porque OPENROWSET no permite variables, así que toca crear un texto SQL manual.

--3 Leer la imagen del disco   OPENROWSET(BULK 'ruta', SINGLE_BLOB)  lee un archivo completo como un único bloque binario (BLOB)

--4️ Insertar la imagen en la tabla    nombre interno, nombre del archivo y datos binarios de la imagen

--5 Ejecutar el SQL dinámico   EXEC(@inserccion_dinamica)

--6️ NOCOUNT ON / OFF    Solo sirve para ocultar mensajes de “(1 row affected)” durante la ejecución.

------- >> Toma una ruta, arma un SQL dinámico, usa OPENROWSET para leer la imagen, y la inserta como VARBINARY en la tabla.





--------------------
-- EXPORTAR IMAGENES
--------------------

USE ESTANCO;
GO


DROP PROCEDURE IF EXISTS dbo.exportar_imagen;
GO

CREATE OR ALTER PROCEDURE dbo.exportar_imagen (   --creo el procedimiento de exportacion
	@img_exportar VARCHAR (100),  -- nombre_img dentro de la tabla
	@carpeta_salida VARCHAR(1000),   -- carpeta destino
	@img_completa VARCHAR(1000)   -- nombre del archivo final ej: foto.jpg
   )

AS
BEGIN
   DECLARE @imagen VARBINARY (max);  --guarda los datos binarios de la imagen (BLOB)
   DECLARE @ruta_absoluta NVARCHAR (2000); --armar la ruta completa del archivo destino
   DECLARE @objeto INT     --almacena el identificador del objeto COM ADODB.Stream
 
   SET NOCOUNT ON
 
   SELECT @imagen = (
         SELECT convert (VARBINARY (max), img_datos, 1)   --Selecciona el campo img_datos (el BLOB) y lo convierte en VARBINARY(MAX)
         FROM dbo.imagenes
         WHERE nombre_img = @img_exportar   --lo guarda en la variable @imagen para luego escribirlo a un archivo
         );                      --tengo la imagen completa cargada en memoria
 
   SET @ruta_absoluta = CONCAT (   --construye la ruta completa, crea un string con la ruta y asi SQL Server sabe dónde debe guardar el archivo
         @carpeta_salida
         ,'\'                 --STRING: C:\IMAGENES\SALIDA\cigarrillos.jpg
         , @img_completa
         );
    BEGIN TRY
     EXEC sp_OACreate 'ADODB.Stream' ,@objeto OUTPUT;   --crea objeto especial de Windows para poder manejar datos binarios como si fuera un archivo
     EXEC sp_OASetProperty @objeto ,'Type',1;  --configura el objeto como “binario
     EXEC sp_OAMethod @objeto,'Open';   --abre el stream (Deja listo el “canal” donde se van a volcar los bytes)
     EXEC sp_OAMethod @objeto,'Write', NULL, @imagen;  --escribe la imagen dentro del stream (le pasa los bytes que estaban en @imagen)
     EXEC sp_OAMethod @objeto,'SaveToFile', NULL, @ruta_absoluta, 2;  --guarda el contenido del stream en un archivo físico (usa la ruta @ruta_absoluta y crea/sobrescribe el archivo.
     EXEC sp_OAMethod @objeto,'Close'; --Cierra el stream (libera el recurso y termina la escritura)
     EXEC sp_OADestroy @objeto;  --Destruye el objeto (borra el objeto COM de memoria para no dejar procesos abiertos)
    END TRY
    
 BEGIN CATCH
  EXEC sp_OADestroy @objeto;  --Si ocurre un error dentro del BEGIN TRY, este bloque se ejecuta automáticamente y sp_OADestroy elimina el objeto en cualquier caso.
 END CATCH
 
   SET NOCOUNT OFF
END
GO

execute dbo.exportar_imagen 'cigarrillos', 'C:\IMAGENES\SALIDA','cigarrillos.jpg';
GO

SELECT * FROM dbo.imagenes;
GO
