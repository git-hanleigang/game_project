---
--island
--2018年4月12日
--MiningManiaBonusCarEndTips.lua
local MiningManiaBonusCarEndTips = class("MiningManiaBonusCarEndTips", util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "MiningManiaPublicConfig"
MiningManiaBonusCarEndTips.m_isOver = false

function MiningManiaBonusCarEndTips:onEnter()
    MiningManiaBonusCarEndTips.super.onEnter(self)
end
function MiningManiaBonusCarEndTips:onExit()
    MiningManiaBonusCarEndTips.super.onExit(self)
end

function MiningManiaBonusCarEndTips:initUI()
    self:createCsbNode("MiningMania_Shejiao2_Timeup.csb")
    self.m_rewardText = self:findChild("m_lb_num")
end

function MiningManiaBonusCarEndTips:resetData()
    self.m_isOver = false
    self:setVisible(false)
end

function MiningManiaBonusCarEndTips:startAni(_mul, _isMe)
    if self.m_isOver then
        return
    end
    self:findChild("sp_me"):setVisible(_isMe)
    self:findChild("sp_other"):setVisible(not _isMe)
    local curMul = _mul
    self.m_isOver = true
    self.m_rewardText:setString("X"..curMul)
    self:setVisible(true)
    gLobalSoundManager:playSound(PublicConfig.Music_BonusCar_OverText)
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("start", false, function()
        self:runCsbAction("idle", true)
    end)
end

function MiningManiaBonusCarEndTips:overAni()
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("over", false, function()
        self:setVisible(false)
    end)
end

return MiningManiaBonusCarEndTips

