--[[
    
]]

local AvatarGameWinner = class("AvatarGameWinner", BaseView)

function AvatarGameWinner:getCsbName()
    return "Activity/csb/Cash_dice/CashDice_winnerShow.csb"
end

function AvatarGameWinner:initCsbNodes()
    self.m_sp_avatar = self:findChild("sp_avater")
    self.m_node = self:findChild("Node_1")
    self.m_sp_frame = self:findChild("sp_frame")
    self.m_sp_frame:setZOrder(100)
end

function AvatarGameWinner:initUI()
    AvatarGameWinner.super.initUI(self)

    self:updateAvatar()
end

function AvatarGameWinner:updateAvatar()
    local gameData = globalData.avatarFrameData:getMiniGameData()
    local winnerList = gameData:getWinners()
    if winnerList and #winnerList > 0 then 
        if  not self.m_index or  self.m_index == #winnerList then
            self.m_index = 1
        else
            self.m_index = self.m_index + 1
        end

        local winnerData = winnerList[self.m_index]
        local fbid = winnerData:getFacebookId()
        local headName = winnerData:getHead()
        local frameId = winnerData:getFrame()
        local nodeAvatar =  G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(fbid, headName, frameId, nil, nil)
        nodeAvatar:setPosition(self.m_sp_avatar:getPosition())
        nodeAvatar:setScale(0.65)
        self.m_node:addChild(nodeAvatar)
        self.m_hasAvatar = true

        performWithDelay(self.m_sp_avatar, function ()
            self:updateAvatar()
        end, 5)
    else
        self.m_hasAvatar = false
    end
end

function AvatarGameWinner:updateWinner()
    if not self.m_hasAvatar then 
        self:updateAvatar()
    end
end

return AvatarGameWinner