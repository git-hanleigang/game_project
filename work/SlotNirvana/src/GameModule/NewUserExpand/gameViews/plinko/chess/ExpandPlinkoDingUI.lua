--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-20 18:14:42
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-20 18:14:57
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/gameViews/plinko/chess/ExpandPlinkoDingUI.lua
Description: 扩圈小游戏 弹珠 钉子UI
--]]
local ExpandGamePlinkoConfig = util_require("GameModule.NewUserExpand.config.ExpandGamePlinkoConfig")
local ExpandPlinkoDingUI = class("ExpandPlinkoDingUI", BaseView)

function ExpandPlinkoDingUI:getCsbName()
    return "PlinkoGame/csb/PlinkoGame_Ding.csb"
end

function ExpandPlinkoDingUI:initUI()
    ExpandPlinkoDingUI.super.initUI(self)

    self:setName("ExpandPlinkoDingUI")
    self:runCsbAction("idle")
end

-- 播放撞击动画
function ExpandPlinkoDingUI:playHitAni()
    self:runCsbAction("start", false, function()
        self:runCsbAction("idle")
    end, 60)
    gLobalSoundManager:playSound(ExpandGamePlinkoConfig.SOUNDS.BALL_DING)
end

return ExpandPlinkoDingUI