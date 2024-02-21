--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44

---**********************  ！！！！！
--CodeGameScreenMagicSpiritMachine ， MagicSpiritClassicSlots 中自定义数据的解析



local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelMagicSpiritConfig = class("LevelMagicSpiritConfig", LevelConfigData)

LevelMagicSpiritConfig.m_bnBasePro = {}
LevelMagicSpiritConfig.m_bnBaseTotalWeight = {}

--classic1 轮盘内 图标类型
LevelMagicSpiritConfig.SYMBOL_CLASSIC1_SCORE_WILD = 192
LevelMagicSpiritConfig.SYMBOL_CLASSIC1_SCORE_777 = 100
LevelMagicSpiritConfig.SYMBOL_CLASSIC1_SCORE_77 = 101
LevelMagicSpiritConfig.SYMBOL_CLASSIC1_SCORE_7 = 102
LevelMagicSpiritConfig.SYMBOL_CLASSIC1_SCORE_BAR_2 = 103
LevelMagicSpiritConfig.SYMBOL_CLASSIC1_SCORE_BAR_1 = 104
--classic2 轮盘内 图标类型
LevelMagicSpiritConfig.SYMBOL_CLASSIC2_SCORE_WILD = 292
LevelMagicSpiritConfig.SYMBOL_CLASSIC2_SCORE_777 = 200
LevelMagicSpiritConfig.SYMBOL_CLASSIC2_SCORE_77 = 201
LevelMagicSpiritConfig.SYMBOL_CLASSIC2_SCORE_7 = 202
LevelMagicSpiritConfig.SYMBOL_CLASSIC2_SCORE_BAR_2 = 203
LevelMagicSpiritConfig.SYMBOL_CLASSIC2_SCORE_BAR_1 = 204
--classic3 轮盘内 图标类型
LevelMagicSpiritConfig.SYMBOL_CLASSIC3_SCORE_WILD1 = 390
LevelMagicSpiritConfig.SYMBOL_CLASSIC3_SCORE_WILD2 = 391
LevelMagicSpiritConfig.SYMBOL_CLASSIC3_SCORE_WILD3 = 392
LevelMagicSpiritConfig.SYMBOL_CLASSIC3_SCORE_777 = 300
LevelMagicSpiritConfig.SYMBOL_CLASSIC3_SCORE_77 = 301
LevelMagicSpiritConfig.SYMBOL_CLASSIC3_SCORE_7 = 302
LevelMagicSpiritConfig.SYMBOL_CLASSIC3_SCORE_BAR_2 = 303
LevelMagicSpiritConfig.SYMBOL_CLASSIC3_SCORE_BAR_1 = 304



function LevelMagicSpiritConfig:parseMuiltPro( value )
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

function LevelMagicSpiritConfig:parseSelfConfigData(colKey, colValue)
    
    local prokey = nil
    local BasePro,BaseTotalWeight = nil,nil

    if colKey == "Base_wild_pro" then
        BasePro,BaseTotalWeight = self:parseMuiltPro(colValue)
        prokey = colKey
    elseif colKey == "Base_score9_pro" then
        BasePro,BaseTotalWeight =self:parseMuiltPro(colValue)
        prokey = colKey
    elseif colKey == "Base_score8_pro" then
        BasePro,BaseTotalWeight =self:parseMuiltPro(colValue)
        prokey = colKey
    elseif colKey == "Base_score7_pro" then
        BasePro,BaseTotalWeight =self:parseMuiltPro(colValue)
        prokey = colKey
    elseif colKey == "Base_score6_pro" then
        BasePro,BaseTotalWeight =self:parseMuiltPro(colValue)
        prokey = colKey
    elseif colKey == "Base_score5_pro" then
        BasePro,BaseTotalWeight =self:parseMuiltPro(colValue)
        prokey = colKey
    elseif colKey == "Base_score4_pro" then
        BasePro,BaseTotalWeight =self:parseMuiltPro(colValue)
        prokey = colKey
    elseif colKey == "Base_score3_pro" then
        BasePro,BaseTotalWeight =self:parseMuiltPro(colValue)
        prokey = colKey

    -- classic 1
    elseif colKey == "Classic_1_wild_pro" then
        BasePro,BaseTotalWeight =self:parseMuiltPro(colValue)
        prokey = colKey
    elseif colKey == "Classic_1_seven3_pro" then
        BasePro,BaseTotalWeight =self:parseMuiltPro(colValue)
        prokey = colKey
    elseif colKey == "Classic_1_seven2_pro" then
        BasePro,BaseTotalWeight =self:parseMuiltPro(colValue)
        prokey = colKey
    elseif colKey == "Classic_1_seven1_pro" then
        BasePro,BaseTotalWeight =self:parseMuiltPro(colValue)
        prokey = colKey
    elseif colKey == "Classic_1_bar2_pro" then 
        BasePro,BaseTotalWeight =self:parseMuiltPro(colValue)
        prokey = colKey
    elseif colKey == "Classic_1_bar1_pro" then
        BasePro,BaseTotalWeight =self:parseMuiltPro(colValue)
        prokey = colKey

    -- classic 2
    elseif colKey == "Classic_2_wild_pro" then
        BasePro,BaseTotalWeight =self:parseMuiltPro(colValue)
        prokey = colKey
    elseif colKey == "Classic_2_seven3_pro" then
        BasePro,BaseTotalWeight =self:parseMuiltPro(colValue)
        prokey = colKey
    elseif colKey == "Classic_2_seven2_pro" then
        BasePro,BaseTotalWeight =self:parseMuiltPro(colValue)
        prokey = colKey
    elseif colKey == "Classic_2_seven1_pro" then
        BasePro,BaseTotalWeight =self:parseMuiltPro(colValue)
        prokey = colKey
    elseif colKey == "Classic_2_bar2_pro" then
        BasePro,BaseTotalWeight =self:parseMuiltPro(colValue)
        prokey = colKey
    elseif colKey == "Classic_2_bar1_pro" then
        BasePro,BaseTotalWeight =self:parseMuiltPro(colValue)
        prokey = colKey

    -- classic 3
    elseif colKey == "Classic_3_wild1_pro" then
        BasePro,BaseTotalWeight =self:parseMuiltPro(colValue)
        prokey = colKey
    elseif colKey == "Classic_3_wild2_pro" then
        BasePro,BaseTotalWeight =self:parseMuiltPro(colValue)
        prokey = colKey
    elseif colKey == "Classic_3_wild3_pro" then
        BasePro,BaseTotalWeight =self:parseMuiltPro(colValue)
        prokey = colKey
    elseif colKey == "Classic_3_seven3_pro" then
        BasePro,BaseTotalWeight =self:parseMuiltPro(colValue)
        prokey = colKey
    elseif colKey == "Classic_3_seven2_pro" then
        BasePro,BaseTotalWeight =self:parseMuiltPro(colValue)
        prokey = colKey
    elseif colKey == "Classic_3_seven1_pro" then
        BasePro,BaseTotalWeight =self:parseMuiltPro(colValue)
        prokey = colKey
    elseif colKey == "Classic_3_bar2_pro" then
        BasePro,BaseTotalWeight =self:parseMuiltPro(colValue)
        prokey = colKey
    elseif colKey == "Classic_3_bar1_pro" then
        BasePro,BaseTotalWeight =self:parseMuiltPro(colValue)
        prokey = colKey
    end


    if prokey then
        self.m_bnBasePro[prokey] = BasePro
        self.m_bnBaseTotalWeight[prokey] = BaseTotalWeight
    end

end


--[[
    time:2018-11-28 16:39:26
    @return: 返回中的倍数
]]
function LevelMagicSpiritConfig:getFixSymbolPro( _symbolType )

    local prokey = "Base_wild_pro"

    local value = 2
    if _symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 then
        prokey = "Base_score9_pro"
    elseif _symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_8 then
        prokey = "Base_score8_pro"
    elseif _symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_7 then
        prokey = "Base_score7_pro"
    elseif _symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_6 then
        prokey = "Base_score6_pro"
    elseif _symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_5 then
        prokey = "Base_score5_pro"
    elseif _symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_4 then
        prokey = "Base_score4_pro"
    elseif _symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_3 then
        prokey = "Base_score3_pro"
    elseif _symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        prokey = "Base_wild_pro"

    --classic1 轮盘内 图标类型
    elseif _symbolType == self.SYMBOL_CLASSIC1_SCORE_WILD then
        prokey = "Classic_1_wild_pro"
    elseif _symbolType == self.SYMBOL_CLASSIC1_SCORE_777 then
        prokey = "Classic_1_seven3_pro"
    elseif _symbolType == self.SYMBOL_CLASSIC1_SCORE_77 then
        prokey = "Classic_1_seven2_pro"
    elseif _symbolType == self.SYMBOL_CLASSIC1_SCORE_7 then
        prokey = "Classic_1_seven1_pro"
    elseif _symbolType == self.SYMBOL_CLASSIC1_SCORE_BAR_2 then
        prokey = "Classic_1_bar2_pro"
    elseif _symbolType == self.SYMBOL_CLASSIC1_SCORE_BAR_1 then
        prokey = "Classic_1_bar1_pro"

    --classic2 轮盘内 图标类型
    elseif _symbolType == self.SYMBOL_CLASSIC2_SCORE_WILD then
        prokey = "Classic_2_wild_pro"
    elseif _symbolType == self.SYMBOL_CLASSIC2_SCORE_777 then
        prokey = "Classic_2_seven3_pro"
    elseif _symbolType == self.SYMBOL_CLASSIC2_SCORE_77 then
        prokey = "Classic_2_seven2_pro"
    elseif _symbolType == self.SYMBOL_CLASSIC2_SCORE_7 then
        prokey = "Classic_2_seven1_pro"
    elseif _symbolType == self.SYMBOL_CLASSIC2_SCORE_BAR_2 then
        prokey = "Classic_2_bar2_pro"
    elseif _symbolType == self.SYMBOL_CLASSIC2_SCORE_BAR_1 then
        prokey = "Classic_2_bar1_pro"
    --classic3 轮盘内 图标类型
    elseif _symbolType == TAG_SYMBOL_TYPE.SYMBOL_CLASSIC3_SCORE_WILD1 then
        prokey = "Classic_3_wild1_pro"
    elseif _symbolType == TAG_SYMBOL_TYPE.SYMBOL_CLASSIC3_SCORE_WILD2 then
        prokey = "Classic_3_wild2_pro"
    elseif _symbolType == TAG_SYMBOL_TYPE.SYMBOL_CLASSIC3_SCORE_WILD3 then
        prokey = "Classic_3_wild3_pro"
    elseif _symbolType == TAG_SYMBOL_TYPE.SYMBOL_CLASSIC3_SCORE_777 then
        prokey = "Classic_3_seven3_pro"
    elseif _symbolType == TAG_SYMBOL_TYPE.SYMBOL_CLASSIC3_SCORE_77 then
        prokey = "Classic_3_seven2_pro"
    elseif _symbolType == TAG_SYMBOL_TYPE.SYMBOL_CLASSIC3_SCORE_7 then
        prokey = "Classic_3_seven1_pro"
    elseif _symbolType == TAG_SYMBOL_TYPE.SYMBOL_CLASSIC3_SCORE_BAR_2 then
        prokey = "Classic_3_bar2_pro"
    elseif _symbolType == TAG_SYMBOL_TYPE.SYMBOL_CLASSIC3_SCORE_BAR_1 then
        prokey = "Classic_3_bar1_pro"
    end



    value = self:getValueByPros(self.m_bnBasePro[prokey] , self.m_bnBaseTotalWeight[prokey])

    return value
end

--[[
    @desc: 根据权重返回对应的值
    time:2018-11-28 16:28:13
    --@proValues: 
    --@totalWeight: 
    @return:
]]
function LevelMagicSpiritConfig:getValueByPros( proValues , totalWeight )
    local random = util_random(1,totalWeight)
    local preValue = 0
    local triggerValue = -1
    for i=1,#proValues do
        local value = proValues[i]
        if value[2] ~= 0 then
            if random > preValue and random <= preValue + value[2] then
                triggerValue = value[1]
                break
            end
            preValue = preValue + value[2]
        end
    end

    return triggerValue

end


---
-- 获取普通情况下滚动数据
-- @param columnIndex 列索引
function LevelMagicSpiritConfig:getNormalReelDatasByColumnIndex(columnIndex,classicIndex)
    local colKey = "reel_cloumn" .. columnIndex
    if classicIndex then
        colKey = "reel_cloumn".. classicIndex .. columnIndex
    end

    return self[colKey]
end


return  LevelMagicSpiritConfig