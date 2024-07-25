--cleaning data in sql queries

select * 
from NashvillieHousing

-- standardize the date format
select SaleDate
from NashvillieHousing

select SaleDateConverted, CONVERT(Date, SaleDate)
from NashvillieHousing

--update NashvillieHousing
--set SaleDate = CONVERT(Date, SaleDate)

alter table NashvillieHousing
add SaleDateConverted Date;

update NashvillieHousing
set SaleDateConverted = CONVERT(Date, SaleDate)

-- check if SaleDateConverted column is added at the end
select * 
from NashvillieHousing

-- populate property address missing data

select PropertyAddress
from NashvillieHousing
where PropertyAddress is null

select *
from NashvillieHousing
where PropertyAddress is null

-- ParcelID is unique to a property
-- so, if 2 properties have same ParcelID. but one properties PropertyAddress is missing
-- we can populate it first property address

select *
from NashvillieHousing
--where PropertyAddress is null
order by ParcelID


select a.parcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress 
from NashvillieHousing a
join NashvillieHousing b
 on a.ParcelID = b.ParcelID
 and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null

update a
set PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
from NashvillieHousing a
join NashvillieHousing b
 on a.ParcelID = b.ParcelID
 and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null

-- Breaking out address into individual columns (Address, City, State)
-- in all the propertyAddress's address & city are separated by ',' (delimeter)

select PropertyAddress
from NashvillieHousing
--where PropertyAddress is null
--order by ParcelID

select
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) as Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, len(PropertyAddress)) as Address
from NashvillieHousing

-- add 2 new columns for Address and City
alter table NashvillieHousing
add PropertySplitAddress Nvarchar(255);

update NashvillieHousing
set PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) 

select *
from NashvillieHousing

alter table NashvillieHousing
add PropertySplitCity Nvarchar(255);

update NashvillieHousing
set PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, len(PropertyAddress)) 


-- breaking down OwnerAddress

select OwnerAddress
from NashvillieHousing

-- Instead of SUBSTRING's, this time we use PARSENAME
select
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
from NashvillieHousing

alter table NashvillieHousing
add OwnerSplitAddress Nvarchar(255);

update NashvillieHousing
set OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

alter table NashvillieHousing
add OwnerSplitCity Nvarchar(255);

update NashvillieHousing
set OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

alter table NashvillieHousing
add OwnerSplitState Nvarchar(255);

update NashvillieHousing
set OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

select *
from NashvillieHousing

ALTER TABLE NashvillieHousing
DROP COLUMN OwnerPropertySplitCity;

-- change Y and N to Yes and No in 'Sold as Vacant' Column

select distinct(SoldAsVacant), COUNT(SoldAsVacant)
from NashvillieHousing
group by SoldAsVacant
order by 2

select SoldAsVacant,
 CASE when SoldAsVacant = 'Y' THEN  'Yes'
	  when SoldAsVacant = 'N' Then 'No'
	  else SoldAsVacant
	  end
from NashvillieHousing

update NashvillieHousing
set SoldAsVacant = CASE when SoldAsVacant = 'Y' THEN  'Yes'
	  when SoldAsVacant = 'N' Then 'No'
	  else SoldAsVacant
	  end

-- remove duplicates
--  ROW_NUMBER gives numbering to each row based on partition by columns, unique rows will be numbered as 1
select *,
ROW_NUMBER() OVER (
partition by ParcelID,
	         PropertyAddress,
			 SalePrice,
			 SaleDate,
			 LegalReference
			 ORDER BY
			  uniqueID
			  ) row_num
from NashvillieHousing
order by ParcelID
-- where row_num > 2 : doesn't work cuz there is a window's function here
-- so, lets create CTE 

with RowNumCTE as(
select *,
ROW_NUMBER() OVER (
partition by ParcelID,
	         PropertyAddress,
			 SalePrice,
			 SaleDate,
			 LegalReference
			 ORDER BY
			  uniqueID
			  ) row_num
from NashvillieHousing
--order by ParcelID
)
select *
from RowNumCTE
where row_num > 1
order by PropertyAddress

-- lets delete all those duplcates

with RowNumCTE as(
select *,
ROW_NUMBER() OVER (
partition by ParcelID,
	         PropertyAddress,
			 SalePrice,
			 SaleDate,
			 LegalReference
			 ORDER BY
			  uniqueID
			  ) row_num
from NashvillieHousing
--order by ParcelID
)
delete 
from RowNumCTE
where row_num > 1
--order by PropertyAddress

-- delte unused columns

select * 
from NashvillieHousing

alter table NashvillieHousing
drop column OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

select OwnerAddress, TaxDistrict, PropertyAddress, SaleDate
from NashvillieHousing
