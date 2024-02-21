--[[
    
]]

local AvatarGameJackpot = class("AvatarGameJackpot", BaseView)

function AvatarGameJackpot:getCsbName()
    return "Activity/csb/Cash_dice/CashDice_jackpot.csb"
end

function AvatarGameJackpot:initDatas(_isUpdateReward)
    self.m_hasUpdateReward = _isUpdateReward
end

function AvatarGameJackpot:initCsbNodes()
    self.m_node_bubble = self:findChild("node_qipao")
    self.m_sp_jakepot = self:findChild("sp_jakepot")
end

function AvatarGameJackpot:initUI()
    AvatarGameJackpot.super.initUI(self)

    self.m_bubble = util_createView("views.AvatarGame.AvatarGameJackpotBubble")
    self.m_node_bubble:addChild(self.m_bubble)
    self:runCsbAction("idle", true)

    self:rewardUpdate()
end

function AvatarGameJackpot:clickFunc(_sander)
    if self.m_isTouch then 
        return
    end
    self.m_isTouch = true
    
    self:addMask()
    self.m_bubble:playStart(function ()
        self.m_isTouch = false
    end)

    performWithDelay(self.m_bubble, function ()
        self.m_bubble:playOver(function ()
            self.m_isTouch = false
            if self.m_mask then
                self.m_mask:removeFromParent()
                self.m_mask = nil
            end
        end)
    end, 2.5)
end

function AvatarGameJackpot:rewardUpdate()
    self.m_bubble:updateUI()
    self:updateIcon()
end

function AvatarGameJackpot:addMask()
    self.m_mask = util_newMaskLayer()
    self.m_mask:setOpacity(0)
    self.m_mask:onTouch(
        function(event)
            if event.name == "ended" and not self.m_isTouch then
                self.m_isTouch = true
                self.m_bubble:stopAllActions()
                self.m_bubble:playOver(function ()
                    self.m_isTouch = false
                    if self.m_mask then
                        self.m_mask:removeFromParent()
                        self.m_mask = nil
                    end
                end)
            end
            return true
        end,
        false,
        true
    )
    self:addChild(self.m_mask)
end

function AvatarGameJackpot:updateIcon()
    if self.m_hasUpdateReward then 
        self.m_hasUpdateReward = false
        util_changeTexture(self.m_sp_jakepot, "Activity/img/frame_cashDice/frame_jackpot_jin.png")
    else
        self.m_hasUpdateReward = true
        util_changeTexture(self.m_sp_jakepot, "Activity/img/frame_cashDice/frame_jackpot.png")
    end
end

return AvatarGameJackpot