local BaseGameModel = util_require("GameBase.BaseGameModel")
local SidekicksData = class("SidekicksData", BaseGameModel)
local SidekicksStdCfg = util_require("GameModule.Sidekicks.model.SidekicksStdCfg")
local SidekicksPetInfoData = util_require("GameModule.Sidekicks.model.SidekicksPetInfoData")
local SidekicksHonorLvSaleData = util_require("GameModule.Sidekicks.model.SidekicksHonorLvSaleData")
local SidekicksMiniGameData = util_require("GameModule.Sidekicks.model.SidekicksMiniGameData")
local SideKicksStdRes_pet = util_require("GameModule.Sidekicks.model.stdTb.SideKicksStdRes_pet")
local SidekicksConfig = util_require("GameModule.Sidekicks.config.SidekicksConfig")

function SidekicksData:ctor()
    SidekicksData.super.ctor(self)

    self._stdCfg = SidekicksStdCfg:create()  -- 赛季配置表
    self._lvUpItemCount = 0 -- 宠物升级道具 数量
    self._starUpItemCount = 0 -- 宠物突破升星道具 数量
    self._totalPetsList = {
        PetIdList = {},
        SeaonIdxList = {}
    } -- 宠物信息列表
    self._skillExInfoMap = {
        FreeEx = 0,
        PayEx = 0,
        SpecialEx = {}
    } -- 宠物技能加成总
    self._honorLv = 0 --荣誉等级
    self._honorExp = 0 --荣誉经验
    self._honorLvSaleList = {} -- 荣誉等级 对应促销
    self._dailyReward = nil --每日奖励 也就是小游戏
    self._levelMax = 0 -- 最大等级

    self._bInit = false --是否初始化过
    self._recordNewSeasonIdxInfo = {} -- 记录的赛季信息

    self:setRefName(G_REF.Sidekicks)
end

function SidekicksData:parseData(_data)
    if not _data then
        return
    end
    self._bInit = true --是否初始化过

    -- 赛季配置表
    if _data.config then
        self._stdCfg:parseCfg(_data.config) 
        self:parsePetResInfoList()
        self._bOpen = self._stdCfg._bOpen
    end
    -- 宠物升级道具 数量
    if _data.levelProps then
        self._lvUpItemCount = _data.levelProps
    end
    -- 宠物突破升星道具 数量
    if _data.starProps then
        self._starUpItemCount = _data.starProps
    end
    -- 宠物信息列表
    if _data.pets and #_data.pets > 0 then
        self:parsePetInfoList(_data.pets)
    end
    --荣誉等级
    if _data.level then
        self._honorLv =  _data.level
    end
    --荣誉经验
    if _data.exp then
        self._honorExp =  _data.exp
    end
    -- 最大等级
    if _data.levelMax then
        self._levelMax =  _data.levelMax
    end
    -- 荣誉等级 对应促销 列表
    if _data.levelSales and #_data.levelSales > 0 then
        self:parseHonorSaleList(_data.levelSales)
    end
    --每日奖励 也就是小游戏
    if _data.dailyReward then
        if not self._dailyReward then
            self._dailyReward = SidekicksMiniGameData:create()
        end
        self._dailyReward:parseData(_data.dailyReward)
    end

    SidekicksData.super.parseData(self, _data)
    gLobalNoticManager:postNotification(SidekicksConfig.EVENT_NAME.NOTICE_UPDATE_SIDEKICKS_DATE) -- 宠物数据更新
end

function SidekicksData:getStdCfg()
    return self._stdCfg
end
function SidekicksData:getLvUpItemCount()
    return self._lvUpItemCount
end
function SidekicksData:getStarUpItemCount()
    return self._starUpItemCount
end
function SidekicksData:getHonorLv()
    return self._honorLv
end
function SidekicksData:getHonorExp()
    return self._honorExp
end
function SidekicksData:getLevelMxa()
    return self._levelMax
end
function SidekicksData:getMiniGameData()
    return self._dailyReward
end

-- 宠物 客户端信息表
function SidekicksData:parsePetResInfoList()
    self._totalPetsList = {
        PetIdList = {},
        SeaonIdxList = {}
    }

    self._petResTitleList = SideKicksStdRes_pet["pet_id"]
    for key, info in ipairs(SideKicksStdRes_pet) do
        if type(key) == "string" then
            -- title
        else
            local map = self:parseSingleInfo(key, info)
            local petInfoData = SidekicksPetInfoData:create(map)
            self._totalPetsList.PetIdList[key] = petInfoData

            local seasonIdx = map["season_idx"]
            if not self._totalPetsList.SeaonIdxList[seasonIdx] then
                self._totalPetsList.SeaonIdxList[seasonIdx] = {}
            end
            table.insert(self._totalPetsList.SeaonIdxList[seasonIdx], petInfoData)
            if #self._totalPetsList.SeaonIdxList[seasonIdx] == 2 then
                table.sort(self._totalPetsList.SeaonIdxList[seasonIdx], function(a, b)
                    return a:getPetId() < b:getPetId()             
                end)
            end
        end
    end
end
-- 解析单个信息
function SidekicksData:parseSingleInfo(_key, _info)
    local map = {}
    map["pet_id"] = _key
    for i=1, #_info do
        map[self._petResTitleList[i]] =_info[i]
    end
    return map
end

-- 宠物信息列表
function SidekicksData:parsePetInfoList(_list)
    self._skillExInfoMap = {
        FreeEx = 0,
        PayEx = 0,
        SpecialEx = {}
    }
    local keyList = {"FreeEx", "PayEx", "SpecialEx"}
    local addExFunc = function(_petInfo)
        local skillList = _petInfo:getSkillInfo()
        for i = 1, #skillList do
            local skillInfo = skillList[i]
            if i == 3 then
                local specialType = skillInfo:getSpecialType()
                local currentSpecialParam = skillInfo:getCurrentSpecialParam()
                if not self._skillExInfoMap.SpecialEx[specialType] then
                    self._skillExInfoMap.SpecialEx[specialType] = 0
                end
                self._skillExInfoMap.SpecialEx[specialType] = self._skillExInfoMap.SpecialEx[specialType] + currentSpecialParam
            else
                local curEx = skillInfo:getCurrentEx()
                self._skillExInfoMap[keyList[i]] = self._skillExInfoMap[keyList[i]] + curEx
            end

        end
    end
    for k,v in ipairs(_list) do
        local petId = v.petId or k
        local petInfoData = self._totalPetsList.PetIdList[petId]
        if petInfoData then
            petInfoData:parseData(v)
            addExFunc(petInfoData)
        end
    end
end
function SidekicksData:getTotalPetsList()
    return self._totalPetsList.PetIdList
end
function SidekicksData:getPetInfoById(_petId)
    return self._totalPetsList.PetIdList[_petId]
end
function SidekicksData:getPetInfoListBySeasonIdx(_seasonIdx)
    return self._totalPetsList.SeaonIdxList[_seasonIdx]
end
function SidekicksData:getTotalSkillNum(_type)
    if _type == "FreeEx" then
        return self._skillExInfoMap.FreeEx or 0
    elseif _type == "PayEx" then
        return self._skillExInfoMap.PayEx or 0
    else
        return self._skillExInfoMap.SpecialEx[_type] or 0
    end
end

-- 荣誉等级 对应促销 列表
function SidekicksData:parseHonorSaleList(_list)
    self._honorLvSaleList = {}
    for _,v in ipairs(_list) do
        local HonorLvSaleData = SidekicksHonorLvSaleData:create(v)
        local lv = HonorLvSaleData:getLevel()
        self._honorLvSaleList[lv] = HonorLvSaleData
    end
end
function SidekicksData:getTotalHonorLvSaleList()
    return self._honorLvSaleList
end
function SidekicksData:getHonorLvSaleInfoByLv(_lv)
    local data = nil
    for i,v in pairs(self._honorLvSaleList) do
        if v:getLevel() == _lv then
            data = v
            break
        end
    end

    return data
end

function SidekicksData:isRunning()
    if globalData.userRunData.levelNum < globalData.constantData.SIDE_KICKS_OPEN_LEVEL then
        return false
    end
    return self._bOpen
end

-- 获取最新赛季 idx
function SidekicksData:getNewSeasonIdx()
    return self._stdCfg._newSeasonIdx
end

return SidekicksData 