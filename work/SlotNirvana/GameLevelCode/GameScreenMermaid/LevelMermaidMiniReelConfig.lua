--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于DwarfFairyConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelMermaidMiniReelConfig = class("LevelMermaidMiniReelConfig", LevelConfigData)


---
-- 获取普通情况下滚动数据
-- @param columnIndex 列索引
function LevelMermaidMiniReelConfig:getNormalReelDatasByColumnIndex(columnIndex)
    local colKey = "freespinModeId_0_"..columnIndex
    return self[colKey]
end





function LevelMermaidMiniReelConfig:parseSelfConfigData(colKey, colValue)
    


    if colKey == "BN_Base1_pro" then
        self.m_bnBasePro1 , self.m_bnBaseTotalWeight1 = self:parsePro(colValue)
    elseif colKey == "BN_Fs_15_pro" then
        self.m_bnBasePro15 , self.m_bnBaseTotalWeight15 = self:parsePro(colValue)
    elseif colKey == "BN_Fs_234_pro" then
        self.m_bnBasePro234 , self.m_bnBaseTotalWeight234 = self:parsePro(colValue)
    elseif colKey == "BN_Rs_pro" then
        self.m_bnBaseProRs , self.m_bnBaseTotalWeightRs = self:parsePro(colValue)  
    end
end
--[[
    time:2018-11-28 16:39:26
    @return: 返回中的倍数
]]
function LevelMermaidMiniReelConfig:getFixSymbolPro( )
    local value = self:getValueByPros(self.m_bnBasePro1 , self.m_bnBaseTotalWeight1)
    return value[1] / 10
end

--[[
    time:2018-11-28 16:39:26
    @return: 返回中的倍数
]]
function LevelMermaidMiniReelConfig:getFS_15_FixSymbolPro( ) 
    local value = self:getValueByPros(self.m_bnBasePro15 , self.m_bnBaseTotalWeight15)
    return value[1] / 10
end

--[[
    time:2018-11-28 16:39:26
    @return: 返回中的倍数
]]
function LevelMermaidMiniReelConfig:getFS_234_FixSymbolPro( )
    local value = self:getValueByPros(self.m_bnBasePro234 , self.m_bnBaseTotalWeight234)
    return value[1] / 10
end

function LevelMermaidMiniReelConfig:getRs_FixSymbolPro( )

    local value = self:getValueByPros(self.m_bnBaseProRs , self.m_bnBaseTotalWeightRs)
    return value[1] / 10
end

--[[
    @desc: 解析普通状态下 滚轮数据
    time:2018-11-28 14:30:00
    --@colValue: 
    --@reelType: 1  普通模式， 2 fs模式
    @return:
]]
function LevelMermaidMiniReelConfig:parseReelDatas( colKey ,  colValue , reelType )

    if reelType == 1 then

        -- local colIndexStr = string.sub( colKey, string.len( "Normal_Reel_1" ) + 1, string.len( colKey ))
        -- local colIndex = tonumber(colIndexStr)

        -- if self.reelDataNormal == nil then
        --     self.reelDataNormal = util_require("data.slotsdata.ReelStripData"):create()
        -- end
        -- self.reelDataNormal:parseReelDatas(colIndex,colValue)
    else
        local colIndexStr = string.sub( colKey, string.len( "FreeSpin_Reel_" ) + 1, string.len( colKey ))
        local colIndex = tonumber(colIndexStr)

        if self.reelDataFs == nil then
            self.reelDataFs = util_require("data.slotsdata.ReelStripData"):create()
        end
        self.reelDataFs:parseReelDatas(colIndex,colValue)

        if self.reelDataNormal == nil then
            self.reelDataNormal = util_require("data.slotsdata.ReelStripData"):create()
        end
        self.reelDataNormal:parseReelDatas(colIndex,colValue)
    end
    
end


return  LevelMermaidMiniReelConfig