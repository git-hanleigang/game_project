--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-12-07 14:44:59
]]
local SidekicksStdCfg = class("SidekicksStdCfg")
local SidekicksStdCfg_honor = util_require("GameModule.Sidekicks.model.stdTb.SidekicksStdCfg_honor")
local SidekicksStdCfg_pet = util_require("GameModule.Sidekicks.model.stdTb.SidekicksStdCfg_pet")
local SidekicksStdCfg_season = util_require("GameModule.Sidekicks.model.stdTb.SidekicksStdCfg_season")
local SidekicksConfig = util_require("GameModule.Sidekicks.config.SidekicksConfig")

function SidekicksStdCfg:ctor()
    self._cfgSeasonList = {} -- 赛季时间信息
    self._cfgHonorLvList = {} -- 荣誉等级配置
    self._cfgPetList = {} -- 宠物配置 按 petId区分
    self._cfgPStageMaxLvMap = {} -- 宠物配置 大赛季区_小赛季 最大等级 信息
    self._cfgPlsMap = {} -- 宠物配置 宠物ID_等级_星 信息
    self._cfgPStarMaxLvMap = {} -- 宠物配置 宠物每颗星可升级的最大等级 信息
end

function SidekicksStdCfg:parseCfg(_cfg)
    -- 赛季时间信息
    if _cfg.seasons and #_cfg.seasons > 0 then
        self:parseSeasonCfg(_cfg.seasons)
    end
    -- 荣誉等级配置
    if _cfg.levels and #_cfg.levels > 0 then
        self:parseHonorLvCfg(_cfg.levels)
    end
    -- 宠物配置
    -- if _cfg.pets and #_cfg.pets > 0 then
    --     self:parsePetCfg(_cfg.pets)
    -- end
    self._bOpen = self._newSeasonIdx ~= nil and self._newSeasonStageIdx ~= nil
end
-- 赛季时间信息
function SidekicksStdCfg:parseSeasonCfg(_list)
    for i, v in ipairs(_list) do
        local data = SidekicksStdCfg_season:create(v)
        local seasonIdx = data:getSeasonIdx()
        if not self._cfgSeasonList[seasonIdx] then
            self._cfgSeasonList[seasonIdx] = {}
        end
        table.insert(self._cfgSeasonList[seasonIdx], data)
    end
    table.walk(self._cfgSeasonList, function(list, seasonIdx)
        table.sort(list, function(a, b) return a:getStageIdx() < b:getStageIdx() end) 
    end)

    self._newSeasonIdx = self:getNewSeasonIdx()
    self._newSeasonStageIdx = self:getCurSeasonStageIdx(self._newSeasonIdx) 
end
-- 获取  当前最新赛季 idx
function SidekicksStdCfg:getNewSeasonIdx(_bForce)
    if self._newSeasonIdx and not _bForce then
        return self._newSeasonIdx
    end

    local seasonIdx = SidekicksConfig.NewSeasonIdx
    for idx, stageList in ipairs(self._cfgSeasonList) do
        local firstInfo = stageList[1]
        if firstInfo and firstInfo:checkIsInSeasonTime() then
            seasonIdx = firstInfo:getSeasonIdx()
            break
        end
    end
    self._newSeasonIdx = seasonIdx
    return seasonIdx
end
-- 获取 所选赛季 stageIdx
function SidekicksStdCfg:getCurSeasonStageIdx(_seasonIdx)
    if not _seasonIdx then
        return
    end

    local curSeasonList = self._cfgSeasonList[_seasonIdx]
    if not curSeasonList then
        return
    end

    local newSeasonIdx = self:getNewSeasonIdx()
    if _seasonIdx ~= newSeasonIdx then
        -- 不是最新赛季， 直接指定为最后阶段。
        local lastStageInfo = curSeasonList[#curSeasonList]
        return lastStageInfo:getStageIdx() 
    end 

    local stageIdx = 1
    for i,v in ipairs(curSeasonList) do
        if v:checkIsInStageTime() then
            stageIdx = v:getStageIdx()
            break
        end
    end
    return stageIdx
end
-- 获取所选赛季所选阶段 信息
function SidekicksStdCfg:getSeasonStageInfo(_seasonIdx, _stageIdx)
    if not _seasonIdx then
        return
    end
    local stageList = self._cfgSeasonList[_seasonIdx]
    if not stageList then
        return
    end

    local stageInfo = stageList[_stageIdx]
    if not stageInfo then
        stageInfo = stageList[#stageList]
    end
    return stageInfo
end
function SidekicksStdCfg:getNewSeasonEndTime()
    local info = self:getSeasonStageInfo(self._newSeasonIdx)
    -- local info = self:getSeasonStageInfo(self._newSeasonIdx, self._newSeasonStageIdx)
    if not info then
        return util_getCurrnetTime() * 1000
    end
    return info:getSeasonEndTime() 
end

-- 荣誉等级配置
function SidekicksStdCfg:parseHonorLvCfg(_list)
    for i, v in ipairs(_list) do
        local data = SidekicksStdCfg_honor:create(v)
        self._cfgHonorLvList[data:getLevel()] = data
    end
    table.sort(self._cfgHonorLvList, function(a, b)
        return a:getLevel() < b:getLevel()
    end)
end
function SidekicksStdCfg:getHonorCfgData(_lv)
    return self._cfgHonorLvList[_lv]
end

function SidekicksStdCfg:getHonorLevelNeedExp(_lv)
    local total = 0
    for i = 1, _lv-1 do
        local honorInfo = self._cfgHonorLvList[i]
        total = total + honorInfo:getNextLvExp()
    end
    return total
end

function SidekicksStdCfg:getHonorCfg()
    return self._cfgHonorLvList
end

-- 宠物配置
-- function SidekicksStdCfg:parsePetCfg(_list)
--     for i, v in ipairs(_list) do
--         local data = SidekicksStdCfg_pet:create(i, v)
--         local petId = data:getPetId()

--         local spMainKey = data:getMainKey("petId_stage")
--         -- 主键 petId_stageIdx
--         if not self._cfgPStageMaxLvMap[spMainKey] or self._cfgPStageMaxLvMap[spMainKey]:getMaxLevel() < data:getMaxLevel() then
--             self._cfgPStageMaxLvMap[spMainKey] = data
--         end

--         -- 主键 petId_level_star
--         local plsMainKey = data:getMainKey("petId_level_star")
--         self._cfgPlsMap[plsMainKey] = data

--         -- 主键 petId_star
--         local pstarMainKey = data:getMainKey("petId_star")
--         if not self._cfgPStarMaxLvMap[pstarMainKey] or self._cfgPStarMaxLvMap[pstarMainKey]:getMaxLevel() < data:getMaxLevel() then
--             self._cfgPStarMaxLvMap[pstarMainKey] = data
--         end
--     end
-- end

-- -- 获取宠物配置
-- function SidekicksStdCfg:getPetCfg(_petInfo)
--     local petId = _petInfo:getPetId()
--     local petLv = _petInfo:getLevel()
--     local petStar = _petInfo:getStar()
--     local cfgPet = self:getPetCfgInfoBy(petId, petLv, petStar)

--     local nextCfgPet = self:getPetCfgInfoBy(petId, petLv+1, petStar)
--     if not nextCfgPet then
--         nextCfgPet = self:getPetCfgInfoBy(petId, petLv, petStar+1)
--     end
--     return cfgPet, nextCfgPet
-- end

-- function SidekicksStdCfg:getPetPreCfg(_petInfo)
--     local petId = _petInfo:getPetId()
--     local petLv = _petInfo:getLevel()
--     local petStar = _petInfo:getStar()
--     local cfgPet = self:getPetCfgInfoBy(petId, petLv, petStar)

--     local preCfgPet = self:getPetCfgInfoBy(petId, petLv-1, petStar)
--     if not preCfgPet then
--         preCfgPet = self:getPetCfgInfoBy(petId, petLv, petStar-1)
--     end
--     return cfgPet, preCfgPet
-- end

-- -- 宠物 指定等级 和 星级的 配置（每级都有）
-- function SidekicksStdCfg:getPetCfgInfoBy(_petId, _petLevel, _petStar)
--     local key = string.format("%s_%s_%s", _petId, _petLevel, _petStar)
--     return self._cfgPlsMap[key]
-- end

-- -- 获取宠物 指定阶段最大 等级 星级 信息
-- function SidekicksStdCfg:getPetCfgMaxLevel(_petId, _stage)
--     local key = string.format("%s_%s", _petId, _stage)
--     return self._cfgPStageMaxLvMap[key]
-- end

-- -- 获取宠物 指定星级最大 等级 星级 信息
-- function SidekicksStdCfg:getPetCurStarMaxLevelCfg(_petId, _star)
--     local key = string.format("%s_%s", _petId, _star)
--     return self._cfgPStarMaxLvMap[key]
-- end

return SidekicksStdCfg