--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-12-19 15:21:56
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-12-19 15:29:50
FilePath: /SlotNirvana/src/GameModule/Sidekicks/model/SidekicksPetSkillCfgData.lua
Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
--]]
local SidekicksPetSkillCfgData = class("SidekicksPetSkillCfgData")

-- message SidekicksPetParam {
--     optional int32 currentEx = 1;// 当前收益
--     optional int32 nextEx = 2;// 下一收益
--     optional int32 nextSeason = 3;// 下一赛季
--     optional int32 nextStage = 4;// 下一阶段
--     optional int32 nextLevel = 5;// 下一等级
--     optional int32 nextStar = 6;// 下一星级
--     optional string specialType = 7;// 特殊效果类型 BIG_WIN_MORE BET_COINS_MORE
--     optional string specialText = 8;// 特殊效果描述
--     optional string currentSpecialParam = 9;// 当前特殊效果参数
--     optional string nextSpecialParam = 10;// 下一特殊效果参数
--     optional string currentSpecialRate = 11;// 当前特殊效果概率
--     optional string nextSpecialRate = 12;// 下一特殊效果概率
--   }
function SidekicksPetSkillCfgData:ctor(_petId, _data)
    self._bEnabled = false
    if not _data then
        return
    end
    self._bEnabled = true

    self._petId = _petId or 0 -- 宠物ID
    self._currentEx = _data.currentEx
    self._nextEx = _data.nextEx
    self._nextSeason = _data.nextSeason
    self._nextStage = _data.nextStage
    self._nextLevel = _data.nextLevel
    self._nextStar = _data.nextStar
    self._specialType = _data.specialType
    self._specialText = _data.specialText
    self._currentSpecialParam = _data.currentSpecialParam
    self._nextSpecialParam = _data.nextSpecialParam
    self._currentSpecialRate = _data.currentSpecialRate
    self._nextSpecialRate = _data.nextSpecialRate
end

function SidekicksPetSkillCfgData:getPetId()
    return self._petId
end
function SidekicksPetSkillCfgData:getCurrentEx()
    return self._currentEx or 0
end
function SidekicksPetSkillCfgData:getNextEx()
    return self._nextEx or 0
end
function SidekicksPetSkillCfgData:getNextSeason()
    return self._nextSeason or 1
end
function SidekicksPetSkillCfgData:getNextStage()
    return self._nextStage or 1
end
function SidekicksPetSkillCfgData:getNextLevel()
    return self._nextLevel or 1
end

function SidekicksPetSkillCfgData:getNextStar()
    return self._nextStar or 1
end

function SidekicksPetSkillCfgData:getSpecialType()
    return self._specialType
end

function SidekicksPetSkillCfgData:getSpecialText()
    return self._specialText
end

function SidekicksPetSkillCfgData:getCurrentSpecialParam()
    return tonumber(self._currentSpecialParam) or 0
end

function SidekicksPetSkillCfgData:getNextSpecialParam()
    return tonumber(self._nextSpecialParam) or 0
end

function SidekicksPetSkillCfgData:getCurrentSpecialRate()
    return tonumber(self._currentSpecialRate) or 0
end

function SidekicksPetSkillCfgData:getNextSpecialRate()
    return tonumber(self._nextSpecialRate) or 0
end

return SidekicksPetSkillCfgData