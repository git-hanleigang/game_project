--[[
    -- 快滚效果
    self.m_reelRunAnim = util_createView("CalacasParadeSrc.CalacasParadeReelRunEffect", self)
]]
local CalacasParadeReelRunEffect = class("CalacasParadeReelRunEffect")
function CalacasParadeReelRunEffect:initData_(_machine)
    self.m_machine = _machine

    self:initUI()
end
function CalacasParadeReelRunEffect:initUI()
    self:createReelRunAnim()
end

function CalacasParadeReelRunEffect:createReelRunAnim()
    if self.m_frameAnim and self.m_bgAnim then
        return
    end
    local frameParent = self.m_machine.m_slotEffectLayer
    local bgParent    = self.m_machine.m_onceClipNode
    self.m_frameAnim = util_createAnimation("WinFrameCalacasParade_run.csb")
    self.m_bgAnim    = util_createAnimation("WinFrameCalacasParade_run_bg.csb")
    frameParent:addChild(self.m_frameAnim)
    bgParent:addChild(self.m_bgAnim, -1, SYMBOL_NODE_TAG * 1000)
    -- bgParent:addChild(self.m_bgAnim, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1, SYMBOL_NODE_TAG * 1000)
    self.m_frameAnim:setVisible(false)
    self.m_bgAnim:setVisible(false)
end

function CalacasParadeReelRunEffect:playReelRunAnim(_iCol, _bBonus)
    self:createReelRunAnim()
    local reelNode = self.m_machine:findChild(string.format("sp_reel_%d", _iCol-1))
    self.m_frameAnim:setPosition(util_convertToNodeSpace(reelNode,   self.m_frameAnim:getParent()))
    self.m_bgAnim:setPosition(util_convertToNodeSpace(reelNode, self.m_bgAnim:getParent()))
    util_setCsbVisible(self.m_frameAnim, true)
    util_setCsbVisible(self.m_bgAnim, true)
    local animName = _bBonus and "run2" or "run" 
    self.m_frameAnim:runCsbAction(animName, true)
    self.m_bgAnim:runCsbAction("run", true)

    --播放快滚音效
    gLobalSoundManager:stopAudio(self.m_machine.m_reelRunSoundTag)
    self.m_machine.m_reelRunSoundTag = gLobalSoundManager:playSound(self.m_machine.m_reelRunSound)
end

function CalacasParadeReelRunEffect:stopReelRunAnim()
    if self.m_frameAnim:isVisible() then
        util_setCsbVisible(self.m_frameAnim, false)
        util_setCsbVisible(self.m_bgAnim, false)
    end
end
return CalacasParadeReelRunEffect