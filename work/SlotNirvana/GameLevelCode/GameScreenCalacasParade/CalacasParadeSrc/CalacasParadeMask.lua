--[[
    -- 遮罩
    self.m_maskCtr = util_createView("CalacasParadeSrc.CalacasParadeMask", self)
]]
local CalacasParadeMask = class("CalacasParadeMask")

function CalacasParadeMask:initData_(_machine)
    self.m_machine = _machine

    self:initUI()
end
function CalacasParadeMask:initUI()
    --关卡遮罩
    self.m_levelMask = util_createAnimation("CalacasParade_mask.csb")
    self.m_machine:findChild("Node_mask"):addChild(self.m_levelMask)
    self.m_levelMask:setVisible(false)
    util_setCascadeOpacityEnabledRescursion(self.m_levelMask, true)

    --棋盘遮罩
    local reelMaskParent  = self.m_machine.m_onceClipNode 
    local spReel0 = self.m_machine:findChild("sp_reel_0")
    local spReel4 = self.m_machine:findChild("sp_reel_4")
    local spReel0Pos  = cc.p(spReel0:getPosition())
    local spReel4Pos  = cc.p(spReel4:getPosition())
    local spReel4Size = spReel4:getContentSize()
    local offsetPos  = cc.p(0, -5)
    local offsetSize = cc.size(0, 5)
    local maskSize = cc.size(0, 0)
    maskSize.width  = (spReel4Pos.x + spReel4Size.width) - spReel0Pos.x + offsetSize.width
    maskSize.height = spReel4Size.height + offsetSize.height
    self.m_reelMask = ccui.Layout:create()
    self.m_reelMask:setContentSize(maskSize)
    self.m_reelMask:setAnchorPoint(cc.p(0, 0))
    local maskPos = util_convertToNodeSpace(spReel0, reelMaskParent)
    maskPos.x =  maskPos.x + offsetPos.x
    maskPos.y =  maskPos.y + offsetPos.y
    self.m_reelMask:setPosition(maskPos)
    self.m_reelMask:setBackGroundColor(cc.c3b(0, 0, 0))
    self.m_reelMask:setBackGroundColorOpacity(255*0.8)
    self.m_reelMask:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
    reelMaskParent:addChild(self.m_reelMask, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1)
    self.m_reelMask:setVisible(false)
end

function CalacasParadeMask:playLevelMaskStart(_delayTime, _fun)
    self.m_levelMask:setOpacity(0)
    self.m_levelMask:setVisible(true)
    local delayTime = _delayTime or 0
    performWithDelay(self.m_levelMask, function()
        self.m_levelMask:setOpacity(255)
        self.m_levelMask:runCsbAction("start", false, _fun)
    end, delayTime)
end
function CalacasParadeMask:playLevelMaskOver()
    self.m_levelMask:runCsbAction("over", false, function()
        self.m_levelMask:setVisible(false)
    end)
end

function CalacasParadeMask:playReelMaskStart(_fun)
    self.m_reelMask:stopAllActions()
    self.m_reelMask:setVisible(true)
    self.m_reelMask:setOpacity(0)
    util_playFadeInAction(self.m_reelMask, 0.5, _fun)
end
function CalacasParadeMask:playReelMaskOver()
    self.m_reelMask:stopAllActions()
    util_playFadeOutAction(self.m_reelMask, 0.5, function()
        self.m_reelMask:setVisible(false)
    end)
end

return CalacasParadeMask