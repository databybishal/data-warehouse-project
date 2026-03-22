/********************************************************************
-- Script: Setup DataWarehouse Database
-- Description: Drops and recreates the 'DataWarehouse' database
--              and creates the bronze, silver, and gold schemas.
-- WARNING: Running this script will permanently delete the existing
--          DataWarehouse database if it exists.
********************************************************************/

-- Switch to master database to manage databases
USE master;
GO 

-- Drop existing DataWarehouse database if it exists
IF EXISTS(SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
    ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouse;
END;
GO

-- Create a new DataWarehouse database
CREATE DATABASE DataWarehouse;
GO

-- Switch to the new database
USE DataWarehouse;
GO

-- Create ETL layer schemas
CREATE SCHEMA bronze;   
GO

CREATE SCHEMA silver;   
GO

CREATE SCHEMA gold;     
GO