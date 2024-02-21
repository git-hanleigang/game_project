--[[
    遮罩
]]
local CherryBountyMask = class("CherryBountyMask")

function CherryBountyMask:initData_(_machine)
    self.m_machine = _machine
    self:initUI()
end
function CherryBountyMask:initUI()
    --棋盘遮罩
    local parent  = self.m_machine.m_onceClipNode 
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
    local maskPos = util_convertToNodeSpace(spReel0, parent)
    maskPos.x =  maskPos.x + offsetPos.x
    maskPos.y =  maskPos.y + offsetPos.y
    self.m_reelMask:setPosition(maskPos)
    self.m_reelMask:setBackGroundColor(cc.c3b(0, 0, 0))
    self.m_reelMask:setBackGroundColorOpacity(255*0.8)
    self.m_reelMask:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
    parent:addChild(self.m_reelMask, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1)
    self.m_reelMask:setVisible(false)
end

function CherryBountyMask:playReelMaskStart()
    self.m_reelMask:stopAllActions()
    self.m_reelMask:setVisible(true)
    self.m_reelMask:setOpacity(0)
    util_playFadeInAction(self.m_reelMask, 0.5, nil)
end
function CherryBountyMask:playReelMaskOver()
    self.m_reelMask:stopAllActions()
    util_playFadeOutAction(self.m_reelMask, 0.5, function()
        self.m_reelMask:setVisible(false)
    end)
end

return CherryBountyMask