--[[
    
]]

local AvatarGamePlayer = class("AvatarGamePlayer", BaseView)

function AvatarGamePlayer:getCsbName()
    return "Activity/csb/Cash_dice/CashDice_player.csb"
end

function AvatarGamePlayer:initCsbNodes()
    self.m_sp_avatar = self:findChild("sp_avatar")
    self.m_node = self:findChild("Node_1")
end

function AvatarGamePlayer:initUI()
    AvatarGamePlayer.super.initUI(self)

    local fbid = globalData.userRunData.facebookBindingID
    local headName = globalData.userRunData.HeadName or 1
    local frameId = globalData.userRunData.avatarFrameId
    local size = self.m_sp_avatar:getContentSize()
    local scale = self.m_sp_avatar:getScale()
    local nodeAvatar =  G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(fbid, headName, frameId, nil, cc.size(size.width * scale, size.height * scale))
    nodeAvatar:setPosition(self.m_sp_avatar:getPosition())
    self.m_node:addChild(nodeAvatar)
end

function AvatarGamePlayer:Action(_flyFunc, _overCallBack)
    self.m_flyFunc = _flyFunc
    self.m_overCallBack = _overCallBack
    self:playStart()
end

function AvatarGamePlayer:playStart()
    gLobalSoundManager:playSound("Activity/sound/game/PlayerJump.mp3")
    self:runCsbAction("start", false, function ()
        self:playFly()
    end, 60)
end

function AvatarGamePlayer:playFly()
    if self.m_flyFunc then 
        self.m_flyFunc()
        self.m_flyFunc = nil
    end
    self:runCsbAction("fly", false, function ()
        self:playOver()
    end, 60)
end

function AvatarGamePlayer:playOver()
    self:runCsbAction("over", false, function ()
        if self.m_overCallBack then 
            local overCallBack = self.m_overCallBack
            self.m_overCallBack = nil
            overCallBack()
        end
    end, 60)
end

return AvatarGamePlayer