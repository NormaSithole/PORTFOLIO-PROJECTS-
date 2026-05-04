-- ============================================================
-- Cleaning Data in MySQL
-- ============================================================

SELECT * FROM `nashvillehousing-portfolioproject`.`nashville housing data for data cleaning`;

-- --------------------------------------------------------
-- Standardize Date Format
-- --------------------------------------------------------

-- Add new column
ALTER TABLE `nashvillehousing-portfolioproject`.`nashville housing data for data cleaning`
ADD COLUMN SaleDateConverted DATE;

-- Populate it
UPDATE `nashvillehousing-portfolioproject`.`nashville housing data for data cleaning`
SET SaleDateConverted = DATE(SaleDate);

-- --------------------------------------------------------
-- Populate Property Address data
-- --------------------------------------------------------

SELECT *
FROM `nashvillehousing-portfolioproject`.`nashville housing data for data cleaning`
ORDER BY ParcelID;

-- Preview the fix
SELECT
    a.ParcelID, a.PropertyAddress,
    b.ParcelID, b.PropertyAddress,
    IFNULL(a.PropertyAddress, b.PropertyAddress)
FROM `nashvillehousing-portfolioproject`.`nashville housing data for data cleaning` a
JOIN `nashvillehousing-portfolioproject`.`nashville housing data for data cleaning` b
    ON  a.ParcelID = b.ParcelID
    AND a.`UniqueID ` <> b.`UniqueID `
WHERE a.PropertyAddress IS NULL;

-- Apply the fix (MySQL requires the JOIN inside UPDATE)
UPDATE `nashvillehousing-portfolioproject`.`nashville housing data for data cleaning` a
JOIN `nashvillehousing-portfolioproject`.`nashville housing data for data cleaning` b
    ON  a.ParcelID = b.ParcelID
    AND a.`UniqueID ` <> b.`UniqueID `
SET a.PropertyAddress = IFNULL(a.PropertyAddress, b.PropertyAddress)
WHERE a.PropertyAddress IS NULL;

-- --------------------------------------------------------
-- Split Property Address into Address + City
-- --------------------------------------------------------

ALTER TABLE `nashvillehousing-portfolioproject`.`nashville housing data for data cleaning`
ADD COLUMN PropertySplitAddress VARCHAR(255),
ADD COLUMN PropertySplitCity    VARCHAR(255);

UPDATE `nashvillehousing-portfolioproject`.`nashville housing data for data cleaning`
SET
    PropertySplitAddress = SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress) - 1),
    PropertySplitCity    = TRIM(SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) + 1));

-- --------------------------------------------------------
-- Split Owner Address into Address, City, State
-- --------------------------------------------------------

ALTER TABLE `nashvillehousing-portfolioproject`.`nashville housing data for data cleaning`
ADD COLUMN OwnerSplitAddress VARCHAR(255),
ADD COLUMN OwnerSplitCity    VARCHAR(255),
ADD COLUMN OwnerSplitState   VARCHAR(255);

UPDATE `nashvillehousing-portfolioproject`.`nashville housing data for data cleaning`
SET
    OwnerSplitAddress = TRIM(SUBSTRING_INDEX(OwnerAddress, ',', 1)),
    OwnerSplitCity    = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1)),
    OwnerSplitState   = TRIM(SUBSTRING_INDEX(OwnerAddress, ',', -1));

-- --------------------------------------------------------
-- Standardize SoldAsVacant: Y/N → Yes/No
-- --------------------------------------------------------

-- Check distinct values first
SELECT SoldAsVacant, COUNT(SoldAsVacant)
FROM `nashvillehousing-portfolioproject`.`nashville housing data for data cleaning`
GROUP BY SoldAsVacant
ORDER BY 2;

UPDATE `nashvillehousing-portfolioproject`.`nashville housing data for data cleaning`
SET SoldAsVacant = CASE
    WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
END;

-- --------------------------------------------------------
-- Remove Duplicates
-- --------------------------------------------------------

-- Preview duplicates
WITH RowNumCTE AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
            ORDER BY `UniqueID `
        ) AS row_num
    FROM `nashvillehousing-portfolioproject`.`nashville housing data for data cleaning`
)
SELECT * FROM RowNumCTE WHERE row_num > 1;

-- Delete duplicates (MySQL doesn't allow deleting directly from a CTE,
-- so we use a subquery join instead)
DELETE n FROM `nashvillehousing-portfolioproject`.`nashville housing data for data cleaning` n
JOIN (
    SELECT `UniqueID `
    FROM (
        SELECT `UniqueID `,
            ROW_NUMBER() OVER (
                PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
                ORDER BY `UniqueID `
            ) AS row_num
        FROM `nashvillehousing-portfolioproject`.`nashville housing data for data cleaning`
    ) sub
    WHERE row_num > 1
) dupes ON n.`UniqueID ` = dupes.`UniqueID `;

-- --------------------------------------------------------
-- Drop Unused Columns
-- --------------------------------------------------------

ALTER TABLE `nashvillehousing-portfolioproject`.`nashville housing data for data cleaning`
    DROP COLUMN OwnerAddress,
    DROP COLUMN TaxDistrict,
    DROP COLUMN PropertyAddress,
    DROP COLUMN SaleDate;