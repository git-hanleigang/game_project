---
--xcyy
--2018年5月23日
--FruitPartySpotItem.lua

local FruitPartySpotItem = class("FruitPartySpotItem",util_require("base.BaseView"))


function FruitPartySpotItem:initUI()
    self:createCsbNode("FruitParty_Spot.csb")

    self.m_node_player = self:findChild("Node_Player")
    self.m_node_spot = self:findChild("Node_1_0")
    self.m_lb_spot = self:findChild("m_lb_spot")
    self.m_lb_coins = self:findChild("m_lb_coins")
    self.m_lb_spot:setVisible(false)
    self:resetStatus()

    self.m_index = -1
end


function FruitPartySpotItem:onEnter()
   
end

function FruitPartySpotItem:onExit()
    
end

--[[
    重置状态
]]
function FruitPartySpotItem:resetStatus()
    self:runCsbAction("idleframe")
    self.m_playerInfo = nil
end

--[[
    设置索引
]]
function FruitPartySpotItem:setIndex(index)
    self.m_index = index
    self.m_lb_spot:setString(index)
end

--[[
    刷新数据
]]
function FruitPartySpotItem:refreshData(data)
    self.m_playerInfo = data
end

--[[
    获取用户ID
]]
function FruitPartySpotItem:getPlayerID()
    if self.m_playerInfo then
        return self.m_playerInfo.udid
    end
    return ""
end

--[[
    获取用户数据
]]
function FruitPartySpotItem:getPlayerInfo( )
    return self.m_playerInfo
end

--[[
    刷新头像
]]
function FruitPartySpotItem:refreshHead(isShowHead)
    local isMe = (globalData.userRunData.userUdid == self:getPlayerID())

    self:findChild("sp_headFrame_me"):setVisible(isMe)
    self:findChild("sp_headFrame"):setVisible(not isMe)

    local head = self:findChild("sp_head")
    head:removeAllChildren(true)
    
    util_setHead(head, self.m_playerInfo.facebookId, self.m_playerInfo.head, nil, true)

    self:refreshScore()

    if isShowHead then
        self:runCsbAction("headIdle")
    end
end

--[[
    中奖动画
]]
function FruitPartySpotItem:showHitAni(func)
    self:refreshHead()
    gLobalSoundManager:playSound("FruitPartySounds/sound_FruitParty_get_spot.mp3")
    self:runCsbAction("actionframe",false,function(  )
        self:runCsbAction("headIdle")
        if type(func) == "function" then
            func()
        end
        
    end)
    
end

--[[
    刷新分数
]]
function FruitPartySpotItem:refreshScore( )
    local score = self.m_playerInfo.coins
    self.m_lb_coins:setString(util_formatCoins(score, 4))
end


return FruitPartySpotItem