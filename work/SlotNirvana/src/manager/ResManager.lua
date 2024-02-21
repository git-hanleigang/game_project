--
-- Author: island
-- Date: 2017年8月11日
-- File: ResManager.lua
-- 
-- 资源数据管理

-- local CSVData = require "data.levelcsv.CSVData"
local ResManager = class("ResManager")

ResManager.m_instance = nil
ResManager.m_CSVTempletDatas = {}  -- 模板类， key: 文件名字 value: 继承自CSVData的类 
ResManager.m_CSVDatas = {}

function ResManager:getInstance()
    if ResManager.m_instance == nil then
        ResManager.m_instance = ResManager.new()
	end
    return ResManager.m_instance
end

function ResManager:ctor()
    
end

---------------------------
--@param csv名字
--@return 返回CSVData
-- function ResManager:parseCsvDataByName(fileName)
	
--     if self.m_CSVDatas[fileName] ~= nil then
--         return self.m_CSVDatas[fileName]
-- 	end
	
-- 	local content = xcyy.SlotsUtil:getCSVDataFromFile(fileName)  -- 可以同时读取加密和非加密文件， 在c++层面实现的
   
--     if content == nil then
--     	return nil
--     end
    
--     -- 按行划分  
--     local rowStrs = util_split(content,'\r\n')
--     local rowNum = table_length(rowStrs)
    
--     if rowNum == 0 then
--         printInfo("%s content is null ",fileName)
--         return
--     end
    
--     local csvStrList = {}
--     for i = 1, rowNum, 1 do
--         local rowData = rowStrs[i]
--         local colDatas = util_split(rowData,",")
--     	csvStrList[i] = colDatas
--     end
    
--     self.m_CSVDatas[fileName] = csvStrList
    
--     return csvStrList
    
    
    
-- end

-- function ResManager:getCSVRowColNum(csvTable)
    
--     local csvRCData = {}
--     csvRCData["rowNum"] = 0
--     csvRCData["colNum"] = 0
--     local rowNum = table_length(csvTable)
--     if rowNum == 0 then
--         return csvRCData
--     end

--     local colDatas = csvTable[1]  -- 在第一个位置拿 列的数量， 每个csv里面列相同
--     local colNum = table_length(colDatas)

--     csvRCData["rowNum"] = rowNum
--     csvRCData["colNum"] = colNum

--     return csvRCData
-- end

---
-- 解析各个关卡的reel 数据， 图片对应数据的配置文件， config ，
--
function ResManager:getCSVLevelConfigData(fileName, levelConfigName)
    local content = self:parseCsvDataByName(fileName)
    if content == nil then
        return nil
    end

    local csvRCData = self:getCSVRowColNum(content)
    globalData.slotRunData.gameMachineConfigName = fileName -- 存储上当前读取的关卡配置config

    local configName = levelConfigName or "data.slotsdata.LevelConfigData"

    local configData = require(configName).new()
    for i = 1,csvRCData["rowNum"],1 do
        local colList = content[i]
        if colList ~= nil and #colList >= 2 then
            local colKey = colList[1]
            local colValue = colList[2]
            configData:parseBaseConfigData(colKey,colValue)
            if string.find(colKey,"reel_cloumn") ~= nil or string.find(colKey,"freespinModeId") ~= nil then
                local verStrs = util_string_split(colValue,";",true)
--                dump(verStrs)
                configData[colKey] = verStrs
--                dump(configData[colKey])
            elseif string.find(colKey,"respinCloumn") ~= nil or string.find(colKey,"freespinRespinCloumn") ~= nil then
                local verStrs = util_string_split(colValue,";",true)
                configData[colKey] = verStrs
            elseif string.find( colKey, "init_reel" ) ~= nil then
                local verStrs = util_string_split(colValue,";",true)
                configData[colKey] = verStrs
            elseif string.find(colKey,"bigwin_datas") then
                configData:parseBigWinReelData(colValue)
            elseif string.find(colKey,"news_period") then
                configData:parseNewsPeriodData(colKey,colValue)
            elseif string.find( colKey, "SpineSymbol_" ) then
                configData:parseSpineSymbolInfo(colKey,colValue)
            elseif string.find( colKey, "Socre_" ) then
                configData:parseScoreImage(colKey,colValue)
            elseif string.find( colKey, "Normal_Reel" ) ~= nil then
                configData:parseReelDatas(colKey,colValue,1)
            elseif string.find( colKey, "FreeSpin_Reel" ) ~= nil then
                configData:parseReelDatas(colKey,colValue,2)
            elseif string.find( colKey, "SymbolBulingAnim_" ) ~= nil then
                configData:parseSymbolBulingAnimDatas(colKey,colValue)
            elseif string.find( colKey, "SymbolBulingSound_" ) ~= nil then
                configData:parseSymbolBulingSoundDatas(colKey,colValue)
                
            else
                configData:parseSelfConfigData(colKey,colValue)
            end
        end
    end

    -- 根据配置的Csv文件强行修改
    configData:parseCsvRunDataConfigData()

    return configData
end


---------------------------
--自定义字段 关卡中继承重写
function ResManager:selfParseCsvDataByName(fileName)
    
end

---------------------------
--@param csv名字
--@return 返回CSVData
function ResManager:parseCsvDataByName(fileName)
	
    if self.m_CSVDatas[fileName] ~= nil then
        return self.m_CSVDatas[fileName]
	end
	
	local content = xcyy.SlotsUtil:getCSVDataFromFile(fileName)  -- 可以同时读取加密和非加密文件， 在c++层面实现的
   
    if content == nil then
    	return nil
    end
    
    -- 按行划分  
    local rowStrs = util_split(content,'\r\n')
    local rowNum = table_length(rowStrs)
    
    if rowNum == 0 then
        printInfo("%s content is null ",fileName)
        return
    end
    
    local csvStrList = {}
    for i = 1, rowNum, 1 do
        local rowData = rowStrs[i]
        local colDatas = util_split(rowData,",")
    	csvStrList[i] = colDatas
    end
    
    self.m_CSVDatas[fileName] = csvStrList
    
    return csvStrList
    
    
    
end

function ResManager:getCSVRowColNum(csvTable)
    
    local csvRCData = {}
    csvRCData["rowNum"] = 0
    csvRCData["colNum"] = 0
    local rowNum = table_length(csvTable)
    if rowNum == 0 then
        return csvRCData
    end

    local colDatas = csvTable[1]  -- 在第一个位置拿 列的数量， 每个csv里面列相同
    local colNum = table_length(colDatas)

    csvRCData["rowNum"] = rowNum
    csvRCData["colNum"] = colNum

    return csvRCData
end

---
-- 使用时先从模板类里面拿下， 看看是否存在不存在在读取
-- @param fileName string csv 文件名字
-- @param luaFileName string 承载csv 数据的lua文件 例如 data.LevelCSVData
function ResManager:getCSVDataByFileName_Templet(fileName,luaFileName)
    
--    if self.m_CSVTempletDatas[fileName] ~= nil then  -- 暂时不做缓存， 这个以后再处理..
--        return self.m_CSVTempletDatas[fileName]
--    end
    
    local csvData = require(luaFileName).new()
    assert(csvData ~= nil,string.format("%s new error",luaFileName))
    local content = self:parseCsvDataByName(fileName)
    if content == nil then
    	return nil
    end
    csvData:parseData(content)
--    self.m_CSVTempletDatas[fileName] = csvData;
    
    return csvData
end

---
-- 获取运行时数据，也就是copy 一份
function ResManager:getCSVDataByFileName_Run(fileName,luaFileName)
    local csvData_T = self:getCSVDataByFileName_Templet(fileName,luaFileName)   
    
    if csvData_T == nil then
    	return nil
    end
    
    return csvData_T
end

--[[
    @desc: 返回PayOut CsvName
    time:2018-11-06 12:20:06
    @param: payOutMode赔率模式
    @param: sLevelName 关卡名字
    @return:
]]
function ResManager:getCurrCtrlPayOutCsvName( payOutMode,sLevelName)
    local curCSVName = nil
    if payOutMode== ENUM_CTRL_PAYOUT.PAYOUT_0P9 then
        curCSVName = string.format("Cvs_Config_%s.csv",sLevelName)
    elseif payOutMode== ENUM_CTRL_PAYOUT.PAYOUT_0P5 then
        curCSVName = string.format("Cvs_Config_%s_0p5.csv",sLevelName)
    elseif payOutMode== ENUM_CTRL_PAYOUT.PAYOUT_2P0 then
        curCSVName = string.format("Cvs_Config_%s_2p0.csv",sLevelName)
    elseif payOutMode== ENUM_CTRL_PAYOUT.PAYOUT_0P85 then
        curCSVName = string.format("Cvs_Config_%s_0p85.csv",sLevelName)
    elseif payOutMode== ENUM_CTRL_PAYOUT.PAYOUT_1P5 then
        curCSVName = string.format("Cvs_Config_%s_1p5.csv",sLevelName)
    elseif payOutMode == ENUM_CTRL_PAYOUT.PAYOUT_1P0 then
        curCSVName = string.format("Cvs_Config_%s_1p0.csv",sLevelName)
    elseif payOutMode== ENUM_CTRL_PAYOUT.PAYOUT_1P2 then
        curCSVName = string.format("Cvs_Config_%s_1p2.csv",sLevelName)
    else
        assert(false, "getCsvForPayoutCtrlOpenLevel error")
    end
    return curCSVName
end

return ResManager