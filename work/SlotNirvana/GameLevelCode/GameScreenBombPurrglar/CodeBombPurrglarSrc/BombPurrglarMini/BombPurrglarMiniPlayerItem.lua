---
--xcyy
--2018年5月23日
--BombPurrglarMiniPlayerItem.lua

local BombPurrglarMiniPlayerItem = class("BombPurrglarMiniPlayerItem",util_require("base.BaseView"))

function BombPurrglarMiniPlayerItem:initUI()
    self:createCsbNode("BombPurrglar_BonusSlots.csb")

    self.m_chairId = 0
    
    -- 收集反馈
    self.m_collectEffect = util_createAnimation("BombPurrglar_xbei_shoujibd.csb")
    self:findChild("multi"):addChild(self.m_collectEffect)
    self.m_collectEffect:setVisible(false)

    -- 玩法结束时头像的光效
    self:findChild("Node_shine"):setVisible(false)
end

--刷新数据
function BombPurrglarMiniPlayerItem:refreshData(data)
    --rsItem 共用一个数据初始化时 计算得分会 x2
    self.m_playerInfo = data and clone(data) or {}
end
--获取用户数据
function BombPurrglarMiniPlayerItem:getPlayerInfo( )
    return self.m_playerInfo
end


--重置展示状态
function BombPurrglarMiniPlayerItem:resetShow()
    self:upDateMultiLab(0)
end

--[[
    获取用户ID
]]
function BombPurrglarMiniPlayerItem:getPlayerID()
    if self.m_playerInfo then
        return self.m_playerInfo.udid
    end
    return ""
end



--[[
    刷新头像
]]
function BombPurrglarMiniPlayerItem:refreshHead()
    local isMe = (globalData.userRunData.userUdid == self:getPlayerID())

    self:refreshArrow(true)
    self:findChild("sp_headBg_me"):setVisible(isMe)
    self:findChild("sp_headBg"):setVisible(not isMe)
    self:findChild("sp_headFrame_me"):setVisible(isMe)
    self:findChild("sp_headFrame"):setVisible(not isMe)

    local head = self:findChild("sp_head")
    head:removeAllChildren(true)
    util_setHead(head, self.m_playerInfo.facebookId, self.m_playerInfo.head, nil, false)
end

function BombPurrglarMiniPlayerItem:refreshArrow(_visible)
    if _visible then
        local isMe = (globalData.userRunData.userUdid == self:getPlayerID())
        self:findChild("ARROW_me"):setVisible(isMe)
        self:findChild("ARROW"):setVisible(not isMe)
    else
        self:findChild("ARROW_me"):setVisible(_visible)
        self:findChild("ARROW"):setVisible(_visible)
    end
end

--[[
    刷新分数
]]
function BombPurrglarMiniPlayerItem:upDateMultiLab(_multi, _animName)
    self.m_playerInfo.curMulti = _multi
    local sMulti = string.format("X%d",_multi)
    local labMulti = self:findChild("m_lb_multi")
    labMulti:setString(sMulti)
    self:updateLabelSize({label = labMulti,sx = 0.27,sy = 0.27}, 290)

    self.m_collectEffect:setVisible(true)
    local animName = _animName or "actionframe"
    self.m_collectEffect:runCsbAction(animName, false, function()
        self.m_collectEffect:setVisible(false)
    end)
end
function BombPurrglarMiniPlayerItem:hideSomeUI( )
    self:findChild("Slots"):setVisible(false)
    self:findChild("ARROW"):setVisible(false)
    self:findChild("ARROW_me"):setVisible(false)
    self:findChild("Sprite_1"):setVisible(false)
    self:findChild("Sprite_2"):setVisible(false)

    -- self:findChild("multi"):setVisible(false)
    -- self:findChild("Sprite_2_0"):setVisible(false)
end

function BombPurrglarMiniPlayerItem:playShineAnim()
    self:findChild("Node_shine"):setVisible(true)
    self:runCsbAction("actionframe1",false,function()
        self:runCsbAction("idleframe1", true)
    end)
end
return BombPurrglarMiniPlayerItem