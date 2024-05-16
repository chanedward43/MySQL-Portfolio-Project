CREATE DATABASE cleaning;
USE cleaning;

CREATE TABLE data_cleaning (
    UniqueID INT,
    ParcelID VARCHAR(20),
    LandUse VARCHAR(50),
    PropertyAddress VARCHAR(255),
    SaleDate DATE,
    SalePrice INT,
    LegalReference VARCHAR(50),
    SoldAsVacant VARCHAR(3),
    OwnerName VARCHAR(255),
    OwnerAddress VARCHAR(255),
    Acreage DECIMAL(5,2),
    TaxDistrict VARCHAR(50),
    LandValue INT,
    BuildingValue INT,
    TotalValue INT,
    YearBuilt INT,
    Bedrooms INT,
    FullBath INT,
    HalfBath INT
);

SET GLOBAL local_infile=1;

LOAD DATA INFILE 'C:/Users/Edward/Desktop/SQL/Data Cleaning/Nashville Housing Data for Data Cleaning.csv'
INTO TABLE data_cleaning
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(UniqueID, ParcelID, LandUse, PropertyAddress, @SaleDate, SalePrice, LegalReference, SoldAsVacant, OwnerName, OwnerAddress, @Acreage, @TaxDistrict, @LandValue, @BuildingValue, @TotalValue, @YearBuilt, @Bedrooms, @FullBath, @HalfBath)
SET SaleDate = STR_TO_DATE(@SaleDate, '%M %d, %Y'), 
    SalePrice = NULLIF(SalePrice, ''),
    Acreage = NULLIF(@Acreage, ''),
    TaxDistrict = NULLIF(@TaxDistrict, ''),
    LandValue = NULLIF(@LandValue, ''),
    BuildingValue = NULLIF(@BuildingValue, ''),
    TotalValue = NULLIF(@TotalValue, ''),
    YearBuilt = NULLIF(@YearBuilt, ''),
    Bedrooms = NULLIF(@Bedrooms, ''),
    FullBath = NULLIF(@FullBath, ''),
    HalfBath = NULLIF(NULLIF(TRIM(@HalfBath), ''), 0);

----------------------------------------------------------------------------------------------------------
/*

CLeaning Data in SQL Queries

*/

SELECT *
FROM data_cleaning;
----------------------------------------------------------------------------------------------------------
-- Standardize Data Format

SELECT SaleDate, CONVERT(SaleDate, DATE) AS ConvertedSaleDate
FROM data_cleaning;

SET SQL_SAFE_UPDATES = 0;
UPDATE data_cleaning
SET SaleDate = CONVERT(SaleDate, DATE);
SET SQL_SAFE_UPDATES = 1;

----------------------------------------------------------------------------------------------------------
-- Populate Property Address data

SET SQL_SAFE_UPDATES = 0; -- Changing '' to null
UPDATE data_cleaning
SET PropertyAddress = NULL
WHERE PropertyAddress = '';
SET SQL_SAFE_UPDATES = 1;

SELECT *
FROM data_cleaning
WHERE PropertyAddress is null;

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM data_cleaning a
JOIN data_cleaning b
ON a.ParcelID = b.ParcelID
AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is null;

SET SQL_SAFE_UPDATES = 0; -- If same ParcelID and propertyaddress doesn't exist add that propertyaddress
UPDATE data_cleaning a
JOIN data_cleaning b ON a.ParcelID = b.ParcelID AND a.UniqueID <> b.UniqueID
SET a.PropertyAddress = COALESCE(a.PropertyAddress, b.PropertyAddress)
WHERE a.PropertyAddress IS NULL;
SET SQL_SAFE_UPDATES = 1;

----------------------------------------------------------------------------------------------------------
-- Breaking out Address into Individual Columns (Address, City, State)

SELECT PropertyAddress
FROM data_cleaning;

SELECT 
    SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress) - 1) AS Address1, -- Getting Address before the comma
    SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) + 1) AS City, -- Getting City after the comma
    SUBSTRING(OwnerAddress, LOCATE(',', PropertyAddress, LOCATE(',', PropertyAddress) + 1) - 2) AS State -- Getting State after the comma
FROM 
    data_cleaning;

SET SQL_SAFE_UPDATES = 0; 

ALTER TABLE data_cleaning
ADD PropertySplitAddress NVARCHAR(255);

UPDATE data_cleaning
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress) - 1); -- Setting Address before the comma

ALTER TABLE data_cleaning
ADD PropertySplitCity NVARCHAR(255);

UPDATE data_cleaning
SET PropertySplitCity = SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) + 1); -- Setting City after the comma

ALTER TABLE data_cleaning
ADD OwnerSplitState NVARCHAR(255);

UPDATE data_cleaning
SET OwnerSplitState = SUBSTRING(OwnerAddress, LOCATE(',', PropertyAddress, LOCATE(',', PropertyAddress) + 1) - 2); -- Setting State after the comma

SET SQL_SAFE_UPDATES = 1;

SELECT *
FROM data_cleaning;

----------------------------------------------------------------------------------------------------------
-- Change Y and N to Yes and No is "Sold as Vacant" field

SELECT DISTINCT(SoldAsVacant), Count(SoldAsVacant)
FROM data_cleaning
GROUP BY SoldAsVacant
ORDER BY 2;

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
     ELSE SoldAsVacant
     END as CovertConvention
FROM data_cleaning;

SET SQL_SAFE_UPDATES = 0;
UPDATE data_cleaning
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
     ELSE SoldAsVacant
     END;
SET SQL_SAFE_UPDATES = 1;

----------------------------------------------------------------------------------------------------------
-- Remove Duplicates

WITH RowNumCTE AS( -- Using CTE to find all duplicated rows
SELECT *,
	ROW_NUMBER() OVER(
    PARTITION BY ParcelID,
				 PropertyAddress,
                 SalePrice,
                 SaleDate,
                 LegalReference
                 ORDER BY
					UniqueID
                    ) row_num
FROM data_cleaning
-- order by ParcelID;
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
Order by PropertyAddress;

SET SQL_SAFE_UPDATES = 0;
DELETE FROM data_cleaning -- Deleting all duplicated rows (not/cant use CTE to delete)
WHERE UniqueID IN (
    SELECT UniqueID
    FROM (
        SELECT 
            *,
            ROW_NUMBER() OVER (
                PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
                ORDER BY UniqueID
            ) AS row_num
        FROM data_cleaning
    ) AS subquery
    WHERE row_num > 1
);
SET SQL_SAFE_UPDATES = 1;

----------------------------------------------------------------------------------------------------------
-- Delete Unused Columns

Select *
FROM data_cleaning;

SET SQL_SAFE_UPDATES = 0;
ALTER TABLE data_cleaning 
DROP COLUMN OwnerAddress,
DROP COLUMN TaxDistrict,
DROP COLUMN PropertyAddress;
SET SQL_SAFE_UPDATES = 1;