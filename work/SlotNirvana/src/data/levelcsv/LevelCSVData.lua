---
--island
--2017年8月15日
--LevelCSVData.lua
--

----
--
-- 所有关卡的csv 类都必须继承于此，具体需要的字段已经在当前的table(类就是table) 中， 用 self["propertyName"] 来访问
--


local LevelCSVData = class("LevelCSVData",util_require("data.levelcsv.CSVData"))


LevelCSVData.iColumnNumber = nil -- 

--LevelCSVData.comm_symbol_score = nil
--LevelCSVData.spec_symbol_score 
LevelCSVData.symbolCount = nil -- 信号的数量 

LevelCSVData.AllSymBolInfo = nil
LevelCSVData.level_idx = nil -- 
LevelCSVData.line_num = nil

--LevelCSVData.big_symbol_prob = nil
LevelCSVData.vecBigWildAccuProb = nil -- 

--LevelCSVData.bonus_prob = nil
LevelCSVData.vecBonusAccuProb = nil -- 
--LevelCSVData.scatter_prob = nil
LevelCSVData.vecScatterAccuProb = nil -- 
--LevelCSVData.comm_small_wild_prob = nil
LevelCSVData.vecReelWildProb = nil -- 

LevelCSVData.vecReelBonusPro = nil -- 

LevelCSVData.vecReelScatterPro = nil -- 

LevelCSVData.vecFreeSpinTimes = nil;

-- 处理stacked 数据
LevelCSVData.vecStackedSymbolProb = nil
LevelCSVData.vecScatterShowCol = nil
LevelCSVData.vecStackedSymbolTotalProb = nil    
LevelCSVData.vecStacked1stColumnProb = nil
LevelCSVData.vecStacked1stColumnTotalProb = nil
LevelCSVData.vecStacked2ndColumnProb = nil
LevelCSVData.vecStacked2ndColumnTotalProb = nil
LevelCSVData.vecStacked3rdColumnProb = nil
LevelCSVData.vecStacked3rdColumnTotalProb = nil
LevelCSVData.vecStacked4thColumnProb = nil
LevelCSVData.vecStacked4thColumnTotalProb = nil
LevelCSVData.vecStacked5thColumnProb = nil
LevelCSVData.vecStacked5thColumnTotalProb = nil
LevelCSVData.vecStacked6thColumnProb = nil
LevelCSVData.vecStacked6thColumnTotalProb = nil

LevelCSVData.vecStackedDisturbOneColumnProb = nil
LevelCSVData.vecStackedDisturbOneColumnTotalProb = nil
LevelCSVData.vecStackedDisturbTwoColumnProb = nil
LevelCSVData.vecStackedDisturbTwoColumnTotalProb = nil
LevelCSVData.vecStackedDisturbThreeColumnProb = nil
LevelCSVData.vecStackedDisturbThreeColumnTotalProb = nil
LevelCSVData.vecStackedDisturbFourColumnProb = nil
LevelCSVData.vecStackedDisturbFourColumnTotalProb = nil
LevelCSVData.vecStackedDisturbFiveColumnProb = nil
LevelCSVData.vecStackedDisturbFiveColumnTotalProb = nil
LevelCSVData.vecStackedDisturbSixColumnProb = nil
LevelCSVData.vecStackedDisturbSixColumnTotalProb = nil

---------- 根据基本数据整理出来供 -------------

-- 构造函数
function LevelCSVData:ctor()
    print("LevelCSVData")
end

---
-- 解析common 和 spec 的得分概率
-- 
function LevelCSVData:parseCommonSymbolScoreValue(colValue)
    local verStrs = util_string_split(colValue,";")
    local verLen = #verStrs
    
    -- assert(verLen >= ORDINARY_SYMBOL_NUM,"ordianrySymbolCommName's num < 9 ckeck document")
    
    if self.AllSymBolInfo == nil then
    	self.AllSymBolInfo = {}
    end
    
    if self.AllSymBolInfo.veccommonSymbol == nil then
        self.AllSymBolInfo.veccommonSymbol = {}
    end
    
    self.symbolCount = #verStrs
    
    for index = 1,self.symbolCount do
        local value = verStrs[index]
        
        local symbolInfo = nil  --由于new 出来也是一个空的table ，所以直接用空table 处理不在用new 

        if self.AllSymBolInfo.veccommonSymbol[index] == nil then
            self.AllSymBolInfo.veccommonSymbol[index] = {}
        end 
        symbolInfo = self.AllSymBolInfo.veccommonSymbol[index]
        
        local vecScores = util_string_split(value,"-",true)
        local vecScoresLen = #vecScores
--        if vecScoresLen ~= self.iColumnNumber - 2 then
--            assert(false,"SymbolCommScore != z parameter num")
--        end
        
        if symbolInfo[2] == nil then
            symbolInfo[2] = 0
        end
        for i = 1,vecScoresLen, 1 do
            
            symbolInfo[i + 2] = tonumber(vecScores[i]);
            
            
--            if i ==1 then
--                symbolInfo.iThreeScore = tonumber(vecScores[i]);
--            elseif i ==2 then
--                symbolInfo.iFourScore = tonumber(vecScores[i]);
--            elseif i ==3 then
--                symbolInfo.iFiveScore = tonumber(vecScores[i]);
--            elseif i == 4 then
--                symbolInfo.iSixScore = tonumber(vecScores[i]);  
--            end
        end
        
    end
    
end

---
-- colValue ， 如果允许两个元素相连接的话
function LevelCSVData:parseCommSymbolTwoScoreValue(colValue)
    
    if self.AllSymBolInfo == nil then
        self.AllSymBolInfo = {}
    end
    
    if self.AllSymBolInfo.veccommonSymbol == nil then
        self.AllSymBolInfo.veccommonSymbol = {}
    end

    local verStrs = util_string_split(colValue,";",true)

    for i = 1, #verStrs do
        local value = verStrs[i]
        local symbolInfo = nil
        if self.AllSymBolInfo.veccommonSymbol[i] == nil then
            self.AllSymBolInfo.veccommonSymbol[i] = {}
        end

        symbolInfo = self.AllSymBolInfo.veccommonSymbol[i]

        symbolInfo[2] = value
    end
end

---
-- colValue ， 如果允许两个元素相连接的话
function LevelCSVData:parseSpecSymbolTwoScoreValue(colValue)
    if self.AllSymBolInfo == nil then
        self.AllSymBolInfo = {}
    end
    
    if self.AllSymBolInfo.vecspecialSymbol == nil then
        self.AllSymBolInfo.vecspecialSymbol = {}
    end
    
    local verStrs = util_string_split(colValue,";",true)
    
    for i = 1, #verStrs do
        local value = verStrs[i]
        local symbolInfo = nil
        if self.AllSymBolInfo.vecspecialSymbol[i] == nil then
        	self.AllSymBolInfo.vecspecialSymbol[i] = {}
        end
        
        symbolInfo = self.AllSymBolInfo.vecspecialSymbol[i]
        
        symbolInfo[2] = value
    end
end



function LevelCSVData:parseSpecSymbolScoreValue(colValue)
    local verStrs = util_string_split(colValue,";")
    local verLen = #verStrs

    assert(verLen == SPECIAL_SYMBOL_NUM,"ordianrySymbolCommName's num != 3 ckeck document")
    
    if self.AllSymBolInfo == nil then
        self.AllSymBolInfo = {}
    end
    
    if self.AllSymBolInfo.vecspecialSymbol == nil then
        self.AllSymBolInfo.vecspecialSymbol = {}
    end
    
    for index = 1,#verStrs do 
        local value = verStrs[index]
        
        local symbolInfo = nil  --由于new 出来也是一个空的table ，所以直接用空table 处理不在用new 

        if self.AllSymBolInfo.vecspecialSymbol[index] == nil then
            self.AllSymBolInfo.vecspecialSymbol[index] = {}
        end 
        symbolInfo = self.AllSymBolInfo.vecspecialSymbol[index]

        local vecScores = util_string_split(value,"-",true)
        local vecScoresLen = #vecScores
--        if vecScoresLen ~= self.iColumnNumber - 2 then
--            assert(false,"SymbolCommScore != z parameter num")
--        end
        
        
        if symbolInfo[2] == nil then
            symbolInfo[2] = 0
        end
        for i = 1,vecScoresLen, 1 do  -- 这里从3个开始处理
            
            symbolInfo[i + 2] = tonumber(vecScores[i])
            
--            if i ==1 then
--                symbolInfo.iThreeScore = tonumber(vecScores[i]);
--            elseif i ==2 then
--                symbolInfo.iFourScore = tonumber(vecScores[i]);
--            elseif i ==3 then
--                symbolInfo.iFiveScore = tonumber(vecScores[i]);
--            elseif i == 4 then
--                symbolInfo.iSixScore = tonumber(vecScores[i]);  
--            end

        end

    end
end

---
-- 解析 small_wild_pro
function LevelCSVData:parseSmallWildPro(colValue)
    local reelWildPros = util_string_split(colValue,";",true)
    local proLen = #reelWildPros
    assert(proLen == self.iColumnNumber,"ReelWildPro'num check document")
    
    self.vecReelWildProb = reelWildPros
end

---
-- 解析 common_bonus_pro
function LevelCSVData:parseCommonBonusPro(colValue)
    local reelPros = util_string_split(colValue,";",true)
    local proLen = #reelPros
    assert(proLen == self.iColumnNumber,"ReelBonusPro'num check document")

    self.vecReelBonusPro = reelPros
end

---
-- 解析comm_scatter_prob
function LevelCSVData:parseCommonScatterProb(colValue)
    local reelPros = util_string_split(colValue,";",true)
    local proLen = #reelPros
    assert(proLen == self.iColumnNumber,"ReelScatterPro'num check document")

    self.vecReelScatterPro = reelPros
end

---
--
function LevelCSVData:parseBonusPro(colValue) 
    local reelPros = util_string_split(colValue,";",true)
    local proLen = #reelPros
    assert(proLen == RANDOM_ARRAY,"ReelScatterPro'num check document")
    
    self.vecBonusAccuProb = reelPros
end

---
-- 
function LevelCSVData:parseScatterPro(colValue)
    local reelPros = util_string_split(colValue,";",true)
    local proLen = #reelPros
    assert(proLen == RANDOM_ARRAY,"ReelScatterPro'num check document")

    self.vecScatterAccuProb = reelPros
    
end

---
-- 解析大的big wild
-- 
function LevelCSVData:parseBigWildProb(colValue)
    
    
    local vecBigWilds = util_string_split(colValue,";")
    local proLen = #vecBigWilds
    assert(proLen == self.iColumnNumber,"vecBigWild'num check document")
    
    self.vecBigWildAccuProb = {}
    for i = 1,proLen,1 do
        local bigWildValue = vecBigWilds[i]
    	local vecProbs = util_string_split(bigWildValue,"-",true)
    	local vecProbLen = #vecProbs
    	assert(vecProbLen == 3,"vecBigWild != vecBigWild parameter num")
        
--        local struProb = BigSymbolProb.new()
--    	struProb.iTotalCount = tonumber(vecProbs[0])
--    	struProb.iMayBeCount = tonumber(vecProbs[1])
--    	struProb.iMustCount = tonumber(vecProbs[2])
    	
        self.vecBigWildAccuProb[i] = {iTotalCount = tonumber(vecProbs[1]),
            iMayBeCount = tonumber(vecProbs[2]),
            iMustCount = tonumber(vecProbs[3])}
    end 
    
    
end

---
-- 解析 自定义字段
--
function LevelCSVData:parseSelfDefinePron(colValue)
    local vecPros = util_string_split(colValue,";",true)
    return  vecPros 
end


-- content 传递的参数，可以去掉
function LevelCSVData:parseData(content)     
    local csvRCData = gLobalResManager:getCSVRowColNum(content) -- 获得行列数量
    if csvRCData["rowNum"] == 0 or csvRCData["colNum"] <= 2 then
        printInfo("parse LevelCSVData is Error ")
    	return false
    end
    
    for i = 1,csvRCData["rowNum"],1 do
        local colList = content[i]
        if colList ~= nil then
            
            local colKey = colList[1]
            if colKey ~= "" then
                local colValue = colList[2]
                if colKey == "comm_symbol_score" then
                    self:parseCommonSymbolScoreValue(colValue)
                elseif colKey == "spec_symbol_score" then
                    self:parseSpecSymbolScoreValue(colValue)
                elseif colKey == "comm_score_tow" then
                    self:parseCommSymbolTwoScoreValue(colValue)
                elseif colKey == "spec_score_tow" then
                    self:parseSpecSymbolTwoScoreValue(colValue)
                elseif colKey == "big_symbol_prob" then
                    self:parseBigWildProb(colValue)
                elseif colKey == "bonus_prob" then
                    self:parseBonusPro(colValue)
                elseif colKey == "scatter_prob" then
                    self:parseScatterPro(colValue)
                elseif colKey == "comm_small_wild_prob" then
                    self:parseSmallWildPro(colValue)
                elseif colKey == "scatter_show_col" then
                    self.vecScatterShowCol =  util_string_split_pro(colValue,";",true)
                elseif colKey == "stacked_symbol_prob" then  -- 处理stacked 数据
                    self.vecStackedSymbolProb,self.vecStackedSymbolTotalProb = util_string_split_pro(colValue,";",true)
                elseif colKey == "stacked_1st_column_prob" then
                    self.vecStacked1stColumnProb,self.vecStacked1stColumnTotalProb = util_string_split_pro(colValue,";",true)
                elseif colKey == "stacked_2nd_column_prob" then
                    self.vecStacked2ndColumnProb,self.vecStacked2ndColumnTotalProb = util_string_split_pro(colValue,";",true)
                elseif colKey == "stacked_3rd_column_prob" then
                    self.vecStacked3rdColumnProb,self.vecStacked3rdColumnTotalProb = util_string_split_pro(colValue,";",true)
                elseif colKey == "stacked_4th_column_prob" then
                    self.vecStacked4thColumnProb,self.vecStacked4thColumnTotalProb = util_string_split_pro(colValue,";",true)
                elseif colKey == "stacked_5th_column_prob" then
                    self.vecStacked5thColumnProb,self.vecStacked5thColumnTotalProb = util_string_split_pro(colValue,";",true)
                elseif colKey == "stacked_6th_column_prob" then
                    self.vecStacked6thColumnProb,self.vecStacked6thColumnTotalProb = util_string_split_pro(colValue,";",true)
                elseif colKey == "stacked_disturb_1_column_prob" then
                    self.vecStackedDisturbOneColumnProb,self.vecStackedDisturbOneColumnTotalProb = util_string_split_pro(colValue,";",true)
                elseif colKey == "stacked_disturb_2_column_prob" then
                    self.vecStackedDisturbTwoColumnProb,self.vecStackedDisturbTwoColumnTotalProb = util_string_split_pro(colValue,";",true)
                elseif colKey == "stacked_disturb_3_column_prob" then
                    self.vecStackedDisturbThreeColumnProb,self.vecStackedDisturbThreeColumnTotalProb = util_string_split_pro(colValue,";",true)
                elseif colKey == "stacked_disturb_4_column_prob" then
                    self.vecStackedDisturbFourColumnProb,self.vecStackedDisturbFourColumnTotalProb = util_string_split_pro(colValue,";",true)
                elseif colKey == "stacked_disturb_5_column_prob" then
                    self.vecStackedDisturbFiveColumnProb,self.vecStackedDisturbFiveColumnTotalProb = util_string_split_pro(colValue,";",true)
                elseif colKey == "stacked_disturb_6_column_prob" then  
                    self.vecStackedDisturbSixColumnProb,self.vecStackedDisturbSixColumnTotalProb = util_string_split_pro(colValue,";",true)  -- 处理stacked end    

                elseif colKey == "line_num" or string.find(colKey,"comm_symbol_prob_") ~= nil then
                    
--                    colKey == "comm_symbol_prob_1" or colKey == "comm_symbol_prob_2"
--                    or colKey == "comm_symbol_prob_3"  or colKey == "comm_symbol_prob_4"
--                    or colKey == "comm_symbol_prob_5" or colKey == "comm_symbol_prob_6"
--                    or colKey == "comm_symbol_prob_7" or colKey == "comm_symbol_prob_8"
--                    or colKey == "comm_symbol_prob_9" then
                    
                    self[colKey] = tonumber(colValue)
                elseif colKey == "level_idx" then
                         -- level_idx  line_num 以及每个关卡特殊的都解析到这里
                    self[colKey] = colValue  
                elseif colKey == "free_spin_times" then        
                    self.vecFreeSpinTimes = util_string_split_pro(colValue,";",true)
                else
                    self:CsvDataRule_ParseSelfData(colKey, colValue)
                end  -- end if 流程
                
            end  -- end if
            
        end
    end -- end for
    
    return true
end

function LevelCSVData:CsvDataRule_ParseSelfData(colKey, colValue)

end
---
-- 检测是否有bonus
--
function LevelCSVData:checkHasBonus()
    
    if self.vecBonusAccuProb == nil then
        return false
    end
    
    local len = #self.vecBonusAccuProb
    if len == 0 then
    	return false
    end
    
    for i = 1, len , 1 do
    	if i ~= 1 then
    		local value = self.vecBonusAccuProb[i]
    		
    		if value ~= 0 then
    			return true
    		end
    		
    	end
    end
    
    return false
end

---
-- 检测是否有scatter
--
function LevelCSVData:checkHasScatter()
    
    if self.vecScatterAccuProb == nil then
        return false
    end
    
    local len = #self.vecScatterAccuProb
    if len == 0 then
        return false
    end
    
    for i = 1, len , 1 do
        if i ~= 1 then
            local value = self.vecScatterAccuProb[i]
            
            if value ~= 0 then
                return true
            end
            
        end
    end
    
    return false
end


---
-- 检测是否有大信号
function LevelCSVData:checkHasBigWildSymbol()
    if self.vecBigWildAccuProb == nil then
        return false
    end
    
    local len = #self.vecBigWildAccuProb
    if len == 0 then
        return false
    end
    
    for i = 1, len , 1 do
        local value = self.vecBigWildAccuProb[i]
        
        if value.iTotalCount ~= 0 and value.iMayBeCount ~= 0 and value.iMustCount ~= 0 then
        	return true
        end
    end
    
    return false
    
end

---
-- 检测是否有small wild 信号
--
function LevelCSVData:checkHasSmallWildSymbol()

    if self.vecReelWildProb == nil then
        return false
    end
    
    local len = #self.vecReelWildProb
    if len == 0 then
        return false
    end
    
    for i = 1, len , 1 do
        local value = self.vecReelWildProb[i]
    	if value ~= 0 then
    		return true
    	end
    	
    end
    return false
end

---  这个不考虑了，已经废弃掉了
-- 检测是否有five kind
function LevelCSVData:checkHasFiveKind()
end



---
-- 自定义字段随机返回
--
function LevelCSVData:getSelfProbRandomValue(proTable)

    local baseValue = proTable[1]
    local sumNum = 0
    local randomValue = xcyy.SlotsUtil:getArc4Random() % baseValue + 1
    
    for i = 2, #proTable, 1 do
        sumNum = sumNum + proTable[i]
    	if randomValue <= sumNum  then
    		return i - 2
    	end
    end
    return 0
end

---
-- 判断自定义权重类字段，格式是否正确
--
function LevelCSVData:checkSelfProIsTure(proTable)
    local isTrue = true 
    if proTable == nil then
        isTrue = false
        assert(false, "自定义字段随机值为空！")
    end

    if #proTable < 3 then
        isTrue = false
        assert(false, "自定义字段概率字段 < 3 位")
    end

    local baseValue = proTable[1]
    local sumNum = 0

    for i = 2, #proTable, 1 do
        sumNum = sumNum + proTable[i]
    end
    if sumNum ~= baseValue then
        isTrue = false
        dump(proTable)
        print(sumNum)
        assert(sumNum == baseValue, "概率相加不等于权重！！")
    end

    return isTrue
end

return LevelCSVData
