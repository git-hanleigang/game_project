--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-12-19 15:21:56
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-12-19 15:25:29
FilePath: /SlotNirvana/src/GameModule/Sidekicks/model/SidekicksPetInfoData.lua
Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
--]]
local SidekicksPetInfoData = class("SidekicksPetInfoData")
local SidekicksConfig = util_require("GameModule.Sidekicks.config.SidekicksConfig")
local SidekicksPetSkillCfgData = util_require("GameModule.Sidekicks.model.SidekicksPetSkillCfgData")

function SidekicksPetInfoData:ctor(_stdMap)
    table.merge(self, _stdMap)

    self._petId = _stdMap["pet_id"] -- 宠物ID
    self._level = 0 -- 等级
    self._levelMax = 0 -- 最大等级
    self._star = 0 -- 星级
    self._starMax = 0 -- 最大星级
    self._levelExp = 0 -- 等级经验
    self._starExp = 0 -- 星级经验
    self._starUpCoins = 0 -- 升星金币
    self._name = _stdMap["pet_name"] -- 宠物名字
end

function SidekicksPetInfoData:parseData(_data)
    if self._petId ~= _data.petId then
        return
    end

    self._level = _data.level or 0 -- 等级
    self._levelMax = _data.levelMax or 0
    self._star = _data.star or 0 -- 星级
    self._starMax = _data.starMax or 0
    self._levelExp = _data.levelExp or 0 -- 等级经验
    self._levelUpNeedExp = _data.levelExpMax or 0 -- 升级需要的经验
    self._bLevelUp = _data.levelUp or false -- 是否可以升级
    self._starExp = _data.starExp or 0 -- 星级经验
    self._starUpNeedExp = _data.starExpMax or 0 -- 升星需要的经验
    self._bStarUp = _data.starUp or false -- 是否可以升星 
    self._starUpCoins = _data.coins
    self._curLevelAndStarSeason = _data.season
    self._curLevelAndStarStage = _data.stage
    self._nextStarNeedLevel = _data.starUpLevel -- 下次升星的等级
    if self._name and #self._name > 0 then
        self._name = _data.name or "" -- 宠物名字
    end

    self._skillInfo = {}
    self._skillInfo[#self._skillInfo + 1] = SidekicksPetSkillCfgData:create(self._petId, _data.freeExParam)
    self._skillInfo[#self._skillInfo + 1] = SidekicksPetSkillCfgData:create(self._petId, _data.payExParam)
    self._skillInfo[#self._skillInfo + 1] = SidekicksPetSkillCfgData:create(self._petId, _data.specialParam)
end

function SidekicksPetInfoData:getPetId()
    return self._petId
end
function SidekicksPetInfoData:getLevel()
    return self._level
end
function SidekicksPetInfoData:getStar()
    return self._star
end
function SidekicksPetInfoData:getLevelExp()
    return self._levelExp
end
function SidekicksPetInfoData:getLevelUpNeedExp()
    return self._levelUpNeedExp
end
function SidekicksPetInfoData:checkCanLevelUp()
    return self._bLevelUp
end
function SidekicksPetInfoData:getStarExp()
    return self._starExp
end
function SidekicksPetInfoData:getStarUpNeedExp()
    return self._starUpNeedExp
end
function SidekicksPetInfoData:checkCanStarUp()
    return self._bStarUp
end
function SidekicksPetInfoData:getName()
    return self._name
end
function SidekicksPetInfoData:getSeasonIdx()
    return self["season_idx"]
end
function SidekicksPetInfoData:getSpineMainPath()
    local seasonIdx = self:getSeasonIdx()
    local path = string.format("Sidekicks_%s/spine/%s", seasonIdx, self["spine_res_main"])
    return path
end
function SidekicksPetInfoData:getCurSkillCfg()
    return self._curSkillCfg
end
function SidekicksPetInfoData:getNextSkillCfg()
    return self._nextSkillCfg
end
function SidekicksPetInfoData:getSkillCfg()
    return self._curSkillCfg, self._nextSkillCfg
end

function SidekicksPetInfoData:getSkillInfoById(_id)
    return self._skillInfo[_id]
end

function SidekicksPetInfoData:getSkillInfo()
    return self._skillInfo
end

function SidekicksPetInfoData:getLevelMax()
    return self._levelMax
end

function SidekicksPetInfoData:getStarMax()
    return self._starMax
end

function SidekicksPetInfoData:getStarUpCoins()
    return (self._starUpCoins == "" and 0 or self._starUpCoins)
end

function SidekicksPetInfoData:getCurLevelAndStarSeason()
    return self._curLevelAndStarSeason
end

function SidekicksPetInfoData:getCurLevelAndStarStage()
    return self._curLevelAndStarStage or 1
end

function SidekicksPetInfoData:getNextStarNeedLevel()
    return self._nextStarNeedLevel
end

return SidekicksPetInfoData