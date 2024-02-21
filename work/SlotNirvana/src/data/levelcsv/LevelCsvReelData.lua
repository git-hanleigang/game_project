---
--island
--2018-12-05
--LevelCsvReelData.lua
--

----
--
-- 所有关卡的csv 类都必须继承于此，具体需要的字段已经在当前的table(类就是table) 中， 用 self["propertyName"] 来访问
--
local LevelCSVData = util_require("data.levelcsv.LevelCSVData")
local LevelCsvReelData = class("LevelCsvReelData",LevelCSVData)

LevelCsvReelData.AllSymBolInfo = nil
LevelCsvReelData.fsSymBolInfo = nil  -- freespin 下的所有信号分数

LevelCsvReelData.vecFreeSpinTimes = nil;

LevelCsvReelData.reelDataNormal = nil
LevelCsvReelData.reelDataFs = nil

---------- 根据基本数据整理出来供 -------------

-- 构造函数
function LevelCsvReelData:ctor()
    print("LevelCsvReelData")
end

---
-- 解析common 和 spec 的得分概率
-- 
function LevelCsvReelData:parseNoramlCommonSymbolScoreValue(colValue)
    local verStrs = util_string_split(colValue,";")
    local verLen = #verStrs

    if self.AllSymBolInfo == nil then
    	self.AllSymBolInfo = {}
    end
    
    if self.AllSymBolInfo.veccommonSymbol == nil then
        self.AllSymBolInfo.veccommonSymbol = {}
    end
    
    self:parseCommonSymbolScoreValue(verStrs , self.AllSymBolInfo.veccommonSymbol)
end
--[[
    @desc: 
    time:2018-11-28 12:25:52
    --@dataStrs:
	--@vecCommonSymbols: 
    @return:
]]
function LevelCsvReelData:parseCommonSymbolScoreValue( dataStrs , vecCommonSymbols )
    local symbolCount = #dataStrs
    
    for index = 1,symbolCount do
        local value = dataStrs[index]
        
        local symbolInfo = nil-- 由于new 出来也是一个空的table ，所以直接用空table 处理不在用new 

        if vecCommonSymbols[index] == nil then
            vecCommonSymbols[index] = {}
        end 
        symbolInfo = vecCommonSymbols[index]
        
        local vecScores = util_string_split(value,"-",true)
        local vecScoresLen = #vecScores

        -- 从连接2个元素 开始赋值， 如果本关卡的元素没有2个连线，配置成0
        for i = 1,vecScoresLen, 1 do
            
            symbolInfo[i + 1] = tonumber(vecScores[i]);

        end
    end
end

function LevelCsvReelData:parseNormalSpecSymbolScoreValue(colValue)
    local verStrs = util_string_split(colValue,";")
    local verLen = #verStrs

    assert(verLen == SPECIAL_SYMBOL_NUM,"ordianrySymbolCommName's num != 3 ckeck document")
    
    if self.AllSymBolInfo == nil then
        self.AllSymBolInfo = {}
    end
    
    if self.AllSymBolInfo.vecspecialSymbol == nil then
        self.AllSymBolInfo.vecspecialSymbol = {}
    end
    
    self:parseSpecSymbolScoreValue(verStrs,self.AllSymBolInfo.vecspecialSymbol)
end
--[[
    @desc: 解析spec 信号的得分
    time:2018-11-28 14:10:29
    --@dataStrs:
	--@vecSpecSymbols: 
]]
function LevelCsvReelData:parseSpecSymbolScoreValue(dataStrs , vecSpecSymbols )
    for index = 1,#dataStrs do 
        local value = dataStrs[index]
        
        local symbolInfo = nil --由于new 出来也是一个空的table ，所以直接用空table 处理不在用new 

        if vecSpecSymbols[index] == nil then
            vecSpecSymbols[index] = {}
        end 
        symbolInfo = vecSpecSymbols[index]

        local vecScores = util_string_split(value,"-",true)
        local vecScoresLen = #vecScores

        -- 配置的特殊信号也是从2个元素赢钱开始的， 如果2个元素不赢钱则配置为0
        for i = 1,vecScoresLen, 1 do  -- 这里从3个开始处理
            
            symbolInfo[i + 1] = tonumber(vecScores[i])
        end
    end
end

---
-- 解析 自定义字段
--
function LevelCsvReelData:parseSelfDefinePron(colValue)
    local vecPros = util_string_split(colValue,";",true)
    return  vecPros 
end


function LevelCsvReelData:parseFsCommonSymbolScoreValue( colValue )
    local verStrs = util_string_split(colValue,";")
    local verLen = #verStrs
    
    if self.fsSymBolInfo == nil then
    	self.fsSymBolInfo = {}
    end
    
    if self.fsSymBolInfo.veccommonSymbol == nil then
        self.fsSymBolInfo.veccommonSymbol = {}
    end

    self:parseCommonSymbolScoreValue(verStrs , self.fsSymBolInfo.veccommonSymbol)
end
function LevelCsvReelData:parseFsSpecSymbolScoreValue( colValue )

    local verStrs = util_string_split(colValue,";")
    local verLen = #verStrs

    assert(verLen == SPECIAL_SYMBOL_NUM,"ordianrySymbolCommName's num != 3 ckeck document")
    
    if self.fsSymBolInfo == nil then
        self.fsSymBolInfo = {}
    end
    
    if self.fsSymBolInfo.vecspecialSymbol == nil then
        self.fsSymBolInfo.vecspecialSymbol = {}
    end
    
    self:parseSpecSymbolScoreValue(verStrs,self.fsSymBolInfo.vecspecialSymbol)

end
--[[
    @desc: 解析普通状态下 滚轮数据
    time:2018-11-28 14:30:00
    --@colValue: 
    --@reelType: 1  普通模式， 2 fs模式
    @return:
]]
function LevelCsvReelData:parseReelDatas( colKey ,  colValue , reelType )

    if reelType == 1 then

        local colIndexStr = string.sub( colKey, string.len( "Normal_Reel_" ) + 1, string.len( colKey ))
        local colIndex = tonumber(colIndexStr)

        if self.reelDataNormal == nil then
            self.reelDataNormal = util_require("data.slotsdata.ReelStripData"):create()
        end
        self.reelDataNormal:parseReelDatas(colIndex,colValue)
    else
        local colIndexStr = string.sub( colKey, string.len( "FreeSpin_Reel_" ) + 1, string.len( colKey ))
        local colIndex = tonumber(colIndexStr)

        if self.reelDataFs == nil then
            self.reelDataFs = util_require("data.slotsdata.ReelStripData"):create()
        end
        self.reelDataFs:parseReelDatas(colIndex,colValue)
    end
    
end

-- content 传递的参数，可以去掉
function LevelCsvReelData:parseData(content)     
    local csvRCData = gLobalResManager:getCSVRowColNum(content) -- 获得行列数量
    if csvRCData["rowNum"] == 0 or csvRCData["colNum"] <= 2 then
        printInfo("parse LevelCsvReelData is Error ")
    	return false
    end
    
    for i = 1,csvRCData["rowNum"],1 do
        local colList = content[i]
        if colList ~= nil then
            
            local colKey = colList[1]
            if colKey ~= "" then
                local colValue = colList[2]
                if colKey == "comm_symbol_score" then
                    self:parseNoramlCommonSymbolScoreValue(colValue)
                elseif colKey == "spec_symbol_score" then
                    self:parseNormalSpecSymbolScoreValue(colValue)
                elseif colKey == "line_num" or string.find(colKey,"comm_symbol_prob_") ~= nil
                        or colKey == "Bonus_Not_Online" or colKey == "Scatter_Not_Online" then
                    self[colKey] = tonumber(colValue)
                elseif colKey == "level_idx" then
                         -- level_idx  line_num 以及每个关卡特殊的都解析到这里
                    self[colKey] = colValue  
                elseif string.find( colKey, "Normal_Reel" ) ~= nil then
                    self:parseReelDatas(colKey,colValue,1)
                elseif string.find( colKey, "FreeSpin_Reel" ) ~= nil then
                    self:parseReelDatas(colKey,colValue,2)
                elseif colKey == "free_spin_times" then        
                    self.vecFreeSpinTimes = util_string_split_pro(colValue,";",true)
                elseif colKey == "fs_comm_symbol_score" then
                    self:parseFsCommonSymbolScoreValue(colValue)
                elseif colKey == "fs_spec_symbol_score" then
                    self:parseFsSpecSymbolScoreValue(colValue)
                else
                    self:CsvDataRule_ParseSelfData(colKey, colValue)
                end  -- end if 流程
                
            end  -- end if
            
        end
    end -- end for
    
    return true
end

function LevelCsvReelData:CsvDataRule_ParseSelfData(colKey, colValue)

end


function LevelCsvReelData:getValueByPros( proValues , totalWeight )
    if proValues == nil or #proValues == 0 then
        assert("不允许在一个数字区间 获取权重")
    end
    local random = util_random(1,totalWeight)
    local preValue = 0
    local triggerValue = -1
    for i=1,#proValues do
        local value = proValues[i]
        if value[2] ~= 0 then
            if random > preValue and random <= preValue + value[2] then
                triggerValue = value
                break
            end
            preValue = preValue + value[2]
        end
    end

    return triggerValue

end

return LevelCsvReelData
