---
--xcyy
--2018年5月23日
--LevelMagneticBreakInConfig.lua
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelMagneticBreakInConfig = class("LevelMagneticBreakInConfig", LevelConfigData)

LevelMagneticBreakInConfig.m_bnBasePro1 = nil
LevelMagneticBreakInConfig.m_bnBaseTotalWeight1 = nil
LevelMagneticBreakInConfig.m_bnBasePro2 = nil
LevelMagneticBreakInConfig.m_bnBaseTotalWeight2 = nil
LevelMagneticBreakInConfig.m_bnBasePro3 = nil
LevelMagneticBreakInConfig.m_bnBaseTotalWeight3 = nil
LevelMagneticBreakInConfig.m_bnBasePro4 = nil
LevelMagneticBreakInConfig.m_bnBaseTotalWeight4 = nil

function LevelMagneticBreakInConfig:ctor()
    LevelConfigData.ctor(self)
end

function LevelMagneticBreakInConfig:parseSelfConfigData(colKey, colValue)

    if colKey == "BN_Base1_pro" then
        self.m_bnBasePro1 , self.m_bnBaseTotalWeight1 = self:parsePro(colValue)
    end
    if colKey == "BN_Base2_pro" then
        self.m_bnBasePro2 , self.m_bnBaseTotalWeight2 = self:parsePro(colValue)
    end
    if colKey == "BN_Base3_pro" then
        self.m_bnBasePro3 , self.m_bnBaseTotalWeight3 = self:parsePro(colValue)
    end
    if colKey == "BN_Base4_pro" then
        self.m_bnBasePro4 , self.m_bnBaseTotalWeight4 = self:parsePro(colValue)
    end

end

function LevelMagneticBreakInConfig:randomBonusByBet(betLevel)
    --随机个数
    local bonusNum = self:randomBonusNum()
    local tempListForBonus = {}
    for i=1,bonusNum do
        local index = self:randomBonusIndex()
        
        local score,type,jackpotType = self:randomBonusScoreForBet(betLevel)
        local color = self:randomBonusColor()
        local life = self:randomBonusLife()
        local tempList = {
            index,
            score,
            type,
            color,
            jackpotType,
            life
        }
        tempListForBonus[#tempListForBonus + 1] = tempList
    end
    return tempListForBonus
end

function LevelMagneticBreakInConfig:randomBonusScoreForBet(betLevel)
    local score = nil
    local jackpotType = "bonus"
    local type = self:randomBonusType()
    if type == "score" then
        score = self:getFixSymbolPro(betLevel)  
        if tonumber(score) == 10 then
            jackpotType = "mini"
        elseif tonumber(score) == 20 then
            jackpotType = "minor"
        elseif tonumber(score) == 50 then
            jackpotType = "major"
        elseif tonumber(score) == 100 then
            jackpotType = "mega"
        elseif tonumber(score) == 1000 then
            jackpotType = "grand"
        end
    else
        score = self:randomBonusFreeNum()
    end
    return score,type,jackpotType
end

--[[
  time:2018-11-28 16:39:26
  @return: 返回中的倍数
]]
function LevelMagneticBreakInConfig:getFixSymbolPro(betLevel)
    local value = nil
    if betLevel == 1 then
        value = self:getValueByPros(self.m_bnBasePro1 , self.m_bnBaseTotalWeight1)
    else
        value = self:getValueByPros(self.m_bnBasePro2 , self.m_bnBaseTotalWeight2)
    end
    return value[1]
end

function LevelMagneticBreakInConfig:randomBonusColor()
    local tempNum = util_random(1,2)
    if tempNum == 1 then
        return "red"
    else
        return "blue"
    end
end

function LevelMagneticBreakInConfig:randomBonusType()
    local tempNum = util_random(1,108)
    if tempNum == 1 then
        return "free"
    else
        return "score"
    end
end

function LevelMagneticBreakInConfig:randomBonusLife()
    return 6
end

--总和：200
function LevelMagneticBreakInConfig:randomBonusFreeNum()

    local tempNum = util_random(1,1300)
    if tempNum <= 800 then
        return "5"
    elseif tempNum > 800 and tempNum <= 1200 then
        return "10"
    else
        return "15"
    end      
    
end


function LevelMagneticBreakInConfig:randomBonusNum()
    return util_random(5,8)
end

function LevelMagneticBreakInConfig:randomBonusIndex()
    return -1
end


--0.2-20;0.4-20;0.6-30;1-30;2-40;3-40;10-8;20-6;50-4;100-2;1000-1;free5-10;free10-12;free15-14;
--0.4-20;0.8-20;1-30;3-30;5-40;10-8;20-6;50-4;100-2;1000-1;free2-10;free4-12;free6-14;
function LevelMagneticBreakInConfig:getReelSymbolShowType(isFree)
    local type = "score"
    local score = 0.2
    if isFree then
        local num1 = util_random(1,193)
        if num1 <= 161 then
            type = "score"
            score = self:getFixSymbolPro2(true)
            if tonumber(score) == 10 then
                type = "mini"
            elseif tonumber(score) == 20 then
                type = "minor"
            elseif tonumber(score) == 50 then
                type = "major"
            elseif tonumber(score) == 100 then
                type = "mega"
            elseif tonumber(score) == 1000 then
                type = "grand"
            end
        else
            type = "free"
            score = self:randomBonusFreeNumForFree()
        end
    else
        local num1 = util_random(1,232)
        
        if num1 <= 201 then
            type = "score"
            score = self:getFixSymbolPro2(false)
            if tonumber(score) == 10 then
                type = "mini"
            elseif tonumber(score) == 20 then
                type = "minor"
            elseif tonumber(score) == 50 then
                type = "major"
            elseif tonumber(score) == 100 then
                type = "mega"
            elseif tonumber(score) == 1000 then
                type = "grand"
            end
        else
            type = "free"
            score = self:randomBonusFreeNumForbase()
        end
    end
    
    return type,score
end

function LevelMagneticBreakInConfig:getFixSymbolPro2(isFree)
    local value = nil
    if not isFree then
        value = self:getValueByPros(self.m_bnBasePro4 , self.m_bnBaseTotalWeight4)
    else
        value = self:getValueByPros(self.m_bnBasePro3 , self.m_bnBaseTotalWeight3)
    end
    return value[1]
end


function LevelMagneticBreakInConfig:randomBonusFreeNumForbase()

    local tempNum = util_random(1,32)
    if tempNum <= 10 then
        return "5"
    elseif tempNum > 10 and tempNum <= 22 then
        return "10"
    else
        return "15"
    end      
    
end

function LevelMagneticBreakInConfig:randomBonusFreeNumForFree()

    local tempNum = util_random(1,36)
    if tempNum <= 10 then
        return "2"
    elseif tempNum > 10 and tempNum <= 22 then
        return "4"
    else
        return "6"
    end      
    
end

return LevelMagneticBreakInConfig