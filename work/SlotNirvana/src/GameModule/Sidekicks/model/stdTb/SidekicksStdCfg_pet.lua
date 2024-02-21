--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-12-07 18:02:22
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-12-07 18:23:29
FilePath: /SlotNirvana/src/GameModule/Sidekicks/model/stdTb/SidekicksStdCfg_pet.lua
Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
--]]
local SidekicksStdCfg_pet = class("SidekicksStdCfg_pet")

function SidekicksStdCfg_pet:ctor(_idx, _data)
    self._idx = _idx
    self._petId = _data.petId or 0 -- 宠物ID
    self._seasonIdx = _data.season or 0 -- 关联赛季
    self._stageIdx = _data.stage or 0 -- 关联阶段
    self._maxLevel = _data.level or 0 -- 阶段等级上限
    self._maxStar = _data.star or 0 -- 阶段星级上限
    self._levelExp = _data.levelExp or 0 -- 等级经验
    self._starExp = _data.starExp or 0 -- 星级经验
    self._freeEx = _data.freeEx or 0 -- 免费收益
    self._payEx = _data.payEx or 0 -- 付费收益
    self._specialEx = _data.specialEx or "" -- 特殊效果类型 BIG_WIN_MORE BET_COINS_MORE
    self._specialExText = _data.specialExText or "" -- 特殊效果描述

    self._mainSPKey = string.format("%s_%s", self._petId, self._stageIdx)
    self._mainPlsKey = string.format("%s_%s_%s", self._petId, self._maxLevel, self._maxStar)
    self._mainPStarKey = string.format("%s_%s", self._petId, self._maxStar)
end

function SidekicksStdCfg_pet:getMainKey(_type)
    if _type == "petId_stage" then
        return self._mainSPKey
    elseif _type == "petId_level_star" then
        return self._mainPlsKey
    elseif _type == "petId_star" then
        return self._mainPStarKey
    end
end
function SidekicksStdCfg_pet:getPetId()
    return self._petId
end
function SidekicksStdCfg_pet:getSeasonIdx()
    return self._seasonIdx
end
function SidekicksStdCfg_pet:getStageIdx()
    return self._stageIdx
end
function SidekicksStdCfg_pet:getMaxLevel()
    return self._maxLevel
end
function SidekicksStdCfg_pet:getNextLevelNeedExp()
    return self._levelExp
end
function SidekicksStdCfg_pet:getMaxStar()
    return self._maxStar
end
function SidekicksStdCfg_pet:getNextStarNeedExp()
    return self._starExp
end
function SidekicksStdCfg_pet:getFreeEx()
    return self._freeEx
end
function SidekicksStdCfg_pet:getPayEx()
    return self._payEx
end
function SidekicksStdCfg_pet:getSpecialEx()
    return {self._specialEx, self._specialExText}
end
function SidekicksStdCfg_pet:getSkillInfoByIdx(_idx)
    if _idx == 1 then
        return self:getFreeEx()
    elseif _idx == 2 then
        return self:getPayEx()
    elseif _idx == 3 then
        return self:getSpecialEx()
    end
end
-- 一级 一个配置， 数值没有按区间来 不用 按区间算
-- function SidekicksStdCfg_pet:checkEnabledByLevel(_lv)
--     return _lv >= self:getMaxLevel()
-- end
function SidekicksStdCfg_pet:checkSkillEnabledByIdx(_idx)
    if _idx == 1 then
        return self:getFreeEx() > 0
    elseif _idx == 2 then
        return self:getPayEx() > 0
    elseif _idx == 3 then
        return self._specialEx ~= ""
    end
    return false
end
return SidekicksStdCfg_pet