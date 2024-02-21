--
--版权所有:{company}
-- Author:{author}
-- Date: 2020-07-03 16:08:42
--

local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelChristmas2021Config = class("LevelChristmas2021Config", LevelConfigData)


LevelChristmas2021Config.m_vecPigShape2x2 = nil
LevelChristmas2021Config.m_vecPigShape2x2Pro = nil
LevelChristmas2021Config.iPigShape2x2TotalWeight = nil

LevelChristmas2021Config.m_vecPigShape2x3 = nil
LevelChristmas2021Config.m_vecPigShape2x3Pro = nil
LevelChristmas2021Config.iPigShape2x3TotalWeight = nil

LevelChristmas2021Config.m_vecPigShape2x4 = nil
LevelChristmas2021Config.m_vecPigShape2x4Pro = nil
LevelChristmas2021Config.iPigShape2x4TotalWeight = nil

LevelChristmas2021Config.m_vecPigShape3x3 = nil
LevelChristmas2021Config.m_vecPigShape3x3Pro = nil
LevelChristmas2021Config.iPigShape3x3TotalWeight = nil

LevelChristmas2021Config.m_vecPigShape2x5 = nil
LevelChristmas2021Config.m_vecPigShape2x5Pro = nil
LevelChristmas2021Config.iPigShape2x5TotalWeight = nil

LevelChristmas2021Config.m_vecPigShape3x4 = nil
LevelChristmas2021Config.m_vecPigShape3x4Pro = nil
LevelChristmas2021Config.iPigShape3x4TotalWeight = nil

LevelChristmas2021Config.m_vecPigShape3x5 = nil
LevelChristmas2021Config.m_vecPigShape3x5Pro = nil
LevelChristmas2021Config.iPigShape3x5TotalWeight = nil

LevelChristmas2021Config.m_vecChooseRespin = nil

function LevelChristmas2021Config:ctor()
      LevelConfigData.ctor(self)
end



function LevelChristmas2021Config:parseSelfConfigData(colKey, colValue)
    
	if colKey == "Pig_Shape1_2x2" or colKey == "Pig_Shape2_2x2" then
        local shape = util_string_split(colValue,";", true)
        if self.m_vecPigShape2x2 == nil then
            self.m_vecPigShape2x2 = {}
        end
        self.m_vecPigShape2x2[#self.m_vecPigShape2x2 + 1] = shape
    elseif colKey == "Pig_Shape_2x2_pro" then 
        self.m_vecPigShape2x2Pro = util_string_split(colValue,";", true)
        self.iPigShape2x2TotalWeight = 0
        for i = 1, #self.m_vecPigShape2x2Pro do
            self.iPigShape2x2TotalWeight = self.iPigShape2x2TotalWeight + self.m_vecPigShape2x2Pro[i]
        end
    elseif colKey == "Pig_Shape1_2x3" or colKey == "Pig_Shape2_2x3" then
        local shape = util_string_split(colValue,";", true)
        if self.m_vecPigShape2x3 == nil then
            self.m_vecPigShape2x3 = {}
        end
        self.m_vecPigShape2x3[#self.m_vecPigShape2x3 + 1] = shape
    elseif colKey == "Pig_Shape_2x3_pro" then 
        self.m_vecPigShape2x3Pro = util_string_split(colValue,";", true)
        self.iPigShape2x3TotalWeight = 0
        for i = 1, #self.m_vecPigShape2x3Pro do
            self.iPigShape2x3TotalWeight = self.iPigShape2x3TotalWeight + self.m_vecPigShape2x3Pro[i]
        end
    elseif colKey == "Pig_Shape1_2x4" or colKey == "Pig_Shape2_2x4" then
        local shape = util_string_split(colValue,";", true)
        if self.m_vecPigShape2x4 == nil then
            self.m_vecPigShape2x4 = {}
        end
        self.m_vecPigShape2x4[#self.m_vecPigShape2x4 + 1] = shape
    elseif colKey == "Pig_Shape_2x4_pro" then 
        self.m_vecPigShape2x4Pro = util_string_split(colValue,";", true)
        self.iPigShape2x4TotalWeight = 0
        for i = 1, #self.m_vecPigShape2x4Pro do
            self.iPigShape2x4TotalWeight = self.iPigShape2x4TotalWeight + self.m_vecPigShape2x4Pro[i]
        end
    elseif colKey == "Pig_Shape1_3x3" or colKey == "Pig_Shape2_3x3" then
        local shape = util_string_split(colValue,";", true)
        if self.m_vecPigShape3x3 == nil then
            self.m_vecPigShape3x3 = {}
        end
        self.m_vecPigShape3x3[#self.m_vecPigShape3x3 + 1] = shape
    elseif colKey == "Pig_Shape_3x3_pro" then 
        self.m_vecPigShape3x3Pro = util_string_split(colValue,";", true)
        self.iPigShape3x3TotalWeight = 0
        for i = 1, #self.m_vecPigShape3x3Pro do
            self.iPigShape3x3TotalWeight = self.iPigShape3x3TotalWeight + self.m_vecPigShape3x3Pro[i]
        end
    elseif colKey == "Pig_Shape1_2x5" or colKey == "Pig_Shape2_2x5" then
        local shape = util_string_split(colValue,";", true)
        if self.m_vecPigShape2x5 == nil then
            self.m_vecPigShape2x5 = {}
        end
        self.m_vecPigShape2x5[#self.m_vecPigShape2x5 + 1] = shape
    elseif colKey == "Pig_Shape_2x5_pro" then 
        self.m_vecPigShape2x5Pro = util_string_split(colValue,";", true)
        self.iPigShape2x5TotalWeight = 0
        for i = 1, #self.m_vecPigShape2x5Pro do
            self.iPigShape2x5TotalWeight = self.iPigShape2x5TotalWeight + self.m_vecPigShape2x5Pro[i]
        end
    elseif colKey == "Pig_Shape1_3x4" or colKey == "Pig_Shape2_3x4" then
        local shape = util_string_split(colValue,";", true)
        if self.m_vecPigShape3x4 == nil then
            self.m_vecPigShape3x4 = {}
        end
        self.m_vecPigShape3x4[#self.m_vecPigShape3x4 + 1] = shape
    elseif colKey == "Pig_Shape_3x4_pro" then 
        self.m_vecPigShape3x4Pro = util_string_split(colValue,";", true)
        self.iPigShape3x4TotalWeight = 0
        for i = 1, #self.m_vecPigShape3x4Pro do
            self.iPigShape3x4TotalWeight = self.iPigShape3x4TotalWeight + self.m_vecPigShape3x4Pro[i]
        end
    elseif colKey == "Pig_Shape1_3x5" or colKey == "Pig_Shape2_3x5" then
        local shape = util_string_split(colValue,";", true)
        if self.m_vecPigShape3x5 == nil then
            self.m_vecPigShape3x5 = {}
        end
        self.m_vecPigShape3x5[#self.m_vecPigShape3x5 + 1] = shape
    elseif colKey == "Pig_Shape_3x5_pro" then 
        self.m_vecPigShape3x5Pro = util_string_split(colValue,";", true)
        self.iPigShape3x5TotalWeight = 0
        for i = 1, #self.m_vecPigShape3x5Pro do
            self.iPigShape3x5TotalWeight = self.iPigShape3x5TotalWeight + self.m_vecPigShape3x5Pro[i]
        end
   
    end
end


   
function LevelChristmas2021Config:getPigShapePro(area)
      if area == 4 then
          local index = self:getValueByPro(self.m_vecPigShape2x2Pro,self.iPigShape2x2TotalWeight)
          return self.m_vecPigShape2x2[index]
      elseif area == 6 then
          local index = self:getValueByPro(self.m_vecPigShape2x3Pro,self.iPigShape2x3TotalWeight)
          return self.m_vecPigShape2x3[index]
      elseif area == 8 then
          local index = self:getValueByPro(self.m_vecPigShape2x4Pro,self.iPigShape2x4TotalWeight)
          return self.m_vecPigShape2x4[index]
      elseif area == 9 then
          local index = self:getValueByPro(self.m_vecPigShape3x3Pro,self.iPigShape3x3TotalWeight)
          return self.m_vecPigShape3x3[index]
      elseif area == 10 then
          local index = self:getValueByPro(self.m_vecPigShape2x5Pro,self.iPigShape2x5TotalWeight)
          return self.m_vecPigShape2x5[index]
      elseif area == 12 then
          local index = self:getValueByPro(self.m_vecPigShape3x4Pro,self.iPigShape3x4TotalWeight)
          return self.m_vecPigShape3x4[index]
      elseif area == 15 then
          local index = self:getValueByPro(self.m_vecPigShape3x5Pro,self.iPigShape3x5TotalWeight)
          return self.m_vecPigShape3x5[index]
      end
end
  
  -- 金块滚动数据
function LevelChristmas2021Config:getPigShapeShow(area)
      if area == 4 then
          return self.m_vecPigShape2x2[1]
      elseif area == 6 then
          return self.m_vecPigShape2x3[1]
      elseif area == 8 then
          return self.m_vecPigShape2x4[1]
      elseif area == 9 then
          return self.m_vecPigShape3x3[1]
      elseif area == 10 then
          return self.m_vecPigShape2x5[1]
      elseif area == 12 then
          return self.m_vecPigShape3x4[1]
      elseif area == 15 then
          return self.m_vecPigShape3x5[1]
      end
end

return  LevelChristmas2021Config