---
--xcyy
--2018年5月23日
--FruitPartyPlayerItem.lua

local FruitPartyPlayerItem = class("FruitPartyPlayerItem",util_require("base.BaseView"))


function FruitPartyPlayerItem:initUI()
    self:createCsbNode("FruitParty_RoomPlayer.csb")


    self.m_bigwin = self:findChild("sp_big")
    self.m_megawin = self:findChild("sp_mega")
    self.m_epicwin = self:findChild("sp_epic")

    self.m_grand = self:findChild("sp_grand")
    self.m_major = self:findChild("sp_major")
    self.m_minor = self:findChild("sp_minor")

    self:resetEventStatus()
    
    self.m_winType_pool = {}
    self.isBigWinPlaying = false
end


function FruitPartyPlayerItem:onEnter()
    FruitPartyPlayerItem.super.onEnter(self)
    --关闭个人信息界面
    gLobalNoticManager:addObserver(self,handler(self,function()
        self:refreshHead()
    end),ViewEventType.NOTIFY_USERINFO_CLOSE_MAINLAYER
)
end

--[[
    重置事件状态
]]
function FruitPartyPlayerItem:resetEventStatus()
    self.m_bigwin:setVisible(false)
    self.m_megawin:setVisible(false)
    self.m_epicwin:setVisible(false)
    self.m_grand:setVisible(false)
    self.m_major:setVisible(false)
    self.m_minor:setVisible(false)
end

--[[
    刷新数据
]]
function FruitPartyPlayerItem:refreshData(data)
    self.m_playerInfo = data
end

--[[
    获取用户ID
]]
function FruitPartyPlayerItem:getPlayerID()
    if self.m_playerInfo then
        return self.m_playerInfo.udid
    end
    return ""
end

--[[
    获取用户数据
]]
function FruitPartyPlayerItem:getPlayerInfo( )
    return self.m_playerInfo
end

--[[
    刷新头像
]]
function FruitPartyPlayerItem:refreshHead()
    if not self.m_playerInfo then
        return
    end
    local isMe = (globalData.userRunData.userUdid == self:getPlayerID())

    self:findChild("BgPlayer_me"):setVisible(isMe)
    self:findChild("BgPlayer"):setVisible(not isMe)

    local head = self:findChild("sp_head")
    head:removeAllChildren(true)


    local frameId = isMe and globalData.userRunData.avatarFrameId or self.m_playerInfo.frame
    local headSize = head:getContentSize()
    local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(self.m_playerInfo.facebookId, self.m_playerInfo.head, frameId, nil, headSize)
    head:addChild(nodeAvatar)
    nodeAvatar:setPosition( headSize.width * 0.5, headSize.height * 0.5 )

    self:resetEventStatus()

    local layout = ccui.Layout:create()
    layout:setName("layout_touch")
    layout:setTouchEnabled(true)
    layout:setContentSize(headSize)
    self:addClick(layout)
    layout:addTo(head)
end

--[[
    刷新spot数量
]]
function FruitPartyPlayerItem:refreshSpotNum(isInit)
    local num = self.m_playerInfo.value or 0
    self:findChild("m_lb_num"):setString(num)
end

--[[
    排名上升动画
]]
function FruitPartyPlayerItem:showRankUpAni()
    self:runCsbAction("actionframe2",false,function(  )
            
    end)
end


--[[
    显示大赢动画
]]
function FruitPartyPlayerItem:showBigWinAni(winType)
    table.insert(self.m_winType_pool,#self.m_winType_pool + 1,winType)

    if not self.isBigWinPlaying then
        self:playNextBigWin()
    end
end

--[[
    播放大赢
]]
function FruitPartyPlayerItem:playNextBigWin()
    local winType = self.m_winType_pool[1]
    if winType then
        table.remove(self.m_winType_pool,1,1)

        self:resetEventStatus()
        if winType == "BIG_WIN" then
            self.m_bigwin:setVisible(true)
        elseif winType == "MAGE_WIN" then
            self.m_megawin:setVisible(true)
        elseif winType == "EPIC_WIN" then
            self.m_epicwin:setVisible(true)
        elseif winType == "Grand" then
            self.m_grand:setVisible(true)
        elseif winType == "Major" then
            self.m_major:setVisible(true)
        elseif winType == "Minor" then
            self.m_minor:setVisible(true)
        end

        self.isBigWinPlaying = true
        self:runCsbAction("actionframe",false,function(  )
            self:runCsbAction("idle")
            self:resetEventStatus()
            if self:checkBigEnd() then
                self.isBigWinPlaying = false
            else
                self:playNextBigWin()
            end
            
        end)
    end
end

--[[
    检测大赢动画是否播放结束
]]
function FruitPartyPlayerItem:checkBigEnd()
    if #self.m_winType_pool > 0 then
        return false
    end

    return true
end

--增加头像点击看个人信息
function FruitPartyPlayerItem:clickFunc(sender)
    local name = sender:getName()
    if name == "layout_touch" then
       if not self.m_playerInfo then
          return
       end
       G_GetMgr(G_REF.UserInfo):sendInfoMationReq(self.m_playerInfo.udid, "","",self.m_playerInfo.head)
    end
end

return FruitPartyPlayerItem