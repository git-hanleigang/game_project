---
--zhpx
--2017年12月5日
--LevelFoodStreetCSVData.lua
--

local LevelFoodStreetCSVData = class("LevelFoodStreetCSVData",util_require("data.levelcsv.LevelCsvReelData"))


-- 构造函数
function LevelFoodStreetCSVData:ctor()
   -- print("LevelFoodStreetCSVData")
end

function LevelFoodStreetCSVData:parsePro( value )
    local verStrs = util_string_split(value,";")

    local proValues = {}
    local totalWeight = 0
    for i=1,#verStrs do
        local proValue = verStrs[i]
        local vecPro = util_string_split(proValue,"-" , true)

        proValues[#proValues + 1] = vecPro
        totalWeight = totalWeight + vecPro[2]
    end
    return proValues , totalWeight
end

return LevelFoodStreetCSVData