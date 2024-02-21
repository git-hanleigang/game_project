--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-12-07 18:02:22
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-12-07 19:43:32
FilePath: /SlotNirvana/src/GameModule/Sidekicks/model/stdTb/SidekicksStdCfg_season.lua
Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
--]]
local SidekicksStdCfg_season = class("SidekicksStdCfg_season")

function SidekicksStdCfg_season:ctor(_data)
    self._seasonNum = _data.seasonNum -- 赛季编号
    self._season = _data.season -- 赛季 配置的时间
    self._stageIdx = _data.stage -- 阶段
    self._seasonOpenTime = tonumber(_data.seasonStartAt) or 0 -- 赛季开始时间
    self._seasonEndTime = tonumber(_data.seasonExpireAt) or 0 -- 赛季结束时间
    self._stageOpenTime = tonumber(_data.stageStartAt) or 0 -- 阶段开始时间
    self._stageEndTime = tonumber(_data.stageExpireAt) or 0 -- 阶段结束时间
end

function SidekicksStdCfg_season:getSeasonIdx()
    return self._seasonNum or 1
end
function SidekicksStdCfg_season:getSeason()
    return self._season
end
function SidekicksStdCfg_season:getStageIdx()
    return self._stageIdx
end
function SidekicksStdCfg_season:getSeasonOpenTime()
    return self._seasonOpenTime
end
function SidekicksStdCfg_season:getSeasonEndTime()
    return self._seasonEndTime
end
function SidekicksStdCfg_season:getStageOpenTime()
    return self._stageOpenTime
end
function SidekicksStdCfg_season:getStageEndTime()
    return self._stageEndTime
end

-- 当前赛季是否开启
function SidekicksStdCfg_season:checkIsInSeasonTime()
    local curTime = util_getCurrnetTime() * 1000
    return curTime >= self:getSeasonOpenTime() and curTime <= self:getSeasonEndTime()
end

-- 当前阶段是否开启
function SidekicksStdCfg_season:checkIsInStageTime()
    local curTime = util_getCurrnetTime() * 1000
    return curTime >= self:getStageOpenTime() and curTime <= self:getStageEndTime()
end

return SidekicksStdCfg_season