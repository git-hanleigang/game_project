--[[
    处理base场景的鱼类游动
]]
local CastFishingBaseSceneFish = class("CastFishingBaseSceneFish", util_require("CodeCastFishingSrc.CastFishingFish.CastFishingFishObj"))
local CastFishingManager = require "CodeCastFishingSrc.CastFishingFish.CastFishingManager"

--游动
function CastFishingBaseSceneFish:playStateAnim_move()
    --[[
        -- 动效描述
        idle:  正常游
        idle2：快速游泳（直接游出去百分百机率）
        idle3：特殊游（不动位置20%机率）
        idle4：慢游（20%机率
    ]]
    local moveName  = self:getStateAnimName_move()
    local baseLineList = {
        -- 时间线名称 = {配置参数}
        idle  = {},
        idle3 = {},
        idle4 = {},
    }
    if nil ~= baseLineList[moveName] then
        -- 随机一个时间线出来
        local randomNum = math.random(1,10)
        if "idle" ~= moveName or randomNum <= 6 then
            moveName = "idle"
        else
            moveName = 1 == math.random(1,2) and "idle3" or "idle4"
        end
        self:setStateAnimName_move(moveName)
        -- 播放时间线后恢复速度
        self:playSpineAnim(moveName, false , function()
            self:playStateAnim_move()
        end)
    else
        self:playSpineAnim(moveName, true)
    end
end

return CastFishingBaseSceneFish
