---
--xcyy
--2018年5月23日
--DazzlingDiscoSpotHeadItem.lua

local DazzlingDiscoSpotHeadItem = class("DazzlingDiscoSpotHeadItem",util_require("Levels.BaseLevelDialog"))


function DazzlingDiscoSpotHeadItem:initUI(params)
    self.m_index = params.index
    self.m_parentView = params.parent
    self:createCsbNode("DazzlingDisco_base_touxiang.csb")
end

--[[
    重置头像显示
]]
function DazzlingDiscoSpotHeadItem:resetHeadItem()
    local head = self:findChild("sp_head")
    head:removeAllChildren(true)
    self:runIdleAni()

    self:findChild("Node_ani"):setVisible(false)
    self:findChild("BgPlayer_me"):setVisible(false)
    self:findChild("m_lb_coins"):setString(0)
    self:findChild("Node_coins"):setVisible(false)
    self:findChild("banzi"):setVisible(false)
    self:findChild("sp_bg_1"):setVisible(true)
    self:findChild("sp_bg_2"):setVisible(false)
end

--[[
    刷新头像
]]
function DazzlingDiscoSpotHeadItem:updateHead(headData)
    if headData.udid == "" then
        self.m_headData = headData
        self:resetHeadItem()
        return
    end

    if self.m_headData and self.m_headData.udid and self.m_headData.udid ~= "" and  self.m_headData.udid == headData.udid then
        return
    end

    self:resetHeadItem()
    self:findChild("Node_coins"):setVisible(true)
    self.m_headData = headData

    local isMe = (globalData.userRunData.userUdid == self:getPlayerID())

    local head = self:findChild("sp_head")
    head:removeAllChildren(true)


    local frameId = isMe and globalData.userRunData.avatarFrameId or self.m_headData.frame
    local headId = isMe and globalData.userRunData.HeadName or headData.head
    local headSize = head:getContentSize()

    self:findChild("BgPlayer"):setVisible(not isMe)
    self:findChild("BgPlayer_me"):setVisible(isMe)

    self:findChild("sp_bg_1"):setVisible(false)
    self:findChild("sp_bg_2"):setVisible(true)

    local coins = headData.coins
    local lbl_coins = self:findChild("m_lb_coins")
    if lbl_coins then
        lbl_coins:setString(util_formatCoins(coins,4))
        local info1={label=lbl_coins,sx=0.34,sy=0.34}
        self:updateLabelSize(info1,150)
    end
    
    local nodeAvatar = G_GetMgr(G_REF.Avatar):createAvatarOutClipNode(headData.facebookId,headId,nil,true,headSize)
    head:addChild(nodeAvatar)
    nodeAvatar:setPosition( headSize.width * 0.5, headSize.height * 0.5 )

    util_setCascadeOpacityEnabledRescursion(self,true)
end

--[[
    获取玩家id
]]
function DazzlingDiscoSpotHeadItem:getPlayerID( )
    if self.m_headData then
        return self.m_headData.udid
    end

    return ""
end

--[[
    idle动画
]]
function DazzlingDiscoSpotHeadItem:runIdleAni()
    self:runCsbAction("idle")
end

--[[
    获得动画
]]
function DazzlingDiscoSpotHeadItem:runHitAni(func)
    self:findChild("Node_ani"):setVisible(true)
    self:runCsbAction("start",false,function(  )
        self:findChild("Node_ani"):setVisible(false)
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    显示动画
]]
function DazzlingDiscoSpotHeadItem:runShowAni(func)
    self:runCsbAction("start2",false,function(  )
        if type(func) == "function" then
            func()
        end
    end)
end

return DazzlingDiscoSpotHeadItem