---
--xcyy
--2018年5月23日
--BombPurrglarPlayerItem.lua

local BombPurrglarPlayerItem = class("BombPurrglarPlayerItem",util_require("base.BaseView"))


function BombPurrglarPlayerItem:initUI()
    self:createCsbNode("BombPurrglar_RoomPlayer.csb")

    self.m_bigwin = self:findChild("sp_big")
    self.m_megawin = self:findChild("sp_mega")
    self.m_epicwin = self:findChild("sp_epic")

    self:resetEventStatus()
    
    self.m_winType_pool = {}
    self.isBigWinPlaying = false
end

--[[
    重置事件状态
]]
function BombPurrglarPlayerItem:resetEventStatus()
    self.m_bigwin:setVisible(false)
    self.m_megawin:setVisible(false)
    self.m_epicwin:setVisible(false)
end

--[[
    刷新数据
]]
function BombPurrglarPlayerItem:refreshData(data)
    self.m_playerInfo = data
end

--[[
    获取用户ID
]]
function BombPurrglarPlayerItem:getPlayerID()
    if self.m_playerInfo then
        return self.m_playerInfo.udid
    end
    return ""
end

--[[
    获取用户数据
]]
function BombPurrglarPlayerItem:getPlayerInfo( )
    return self.m_playerInfo
end

--[[
    刷新头像
]]
function BombPurrglarPlayerItem:refreshHead()
    local isMe = (globalData.userRunData.userUdid == self:getPlayerID())

    self:findChild("BgPlayer_me"):setVisible(isMe)
    self:findChild("BgPlayer"):setVisible(not isMe)
    self:findChild("headbox_me"):setVisible(isMe)
    self:findChild("headbox"):setVisible(not isMe)
    

    local head = self:findChild("sp_head")
    head:removeAllChildren(true)
    -- self:resetEventStatus()


    local fbid = self.m_playerInfo.facebookId
    local headName = self.m_playerInfo.head
    -- local frameId = isMe and globalData.userRunData.avatarFrameId or self.m_playerInfo.frame
    -- local headSizeLayout = head:getContentSize()
    -- local headSize = cc.size(headSizeLayout.height, headSizeLayout.height)
    -- local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(fbid, headName, frameId, nil, headSize)
    -- head:addChild(nodeAvatar)
    -- nodeAvatar:setPosition( headSizeLayout.width * 0.5, headSizeLayout.height * 0.5 )

    -- if not self.m_headFrame then
    --     local headFrameNode = cc.Node:create()
    --     self:findChild("Node_head"):addChild(headFrameNode, 1)
    --     self.m_headFrame = headFrameNode
    --     self.m_headFrame:setPosition(head:getPosition())
    -- else
    --     self.m_headFrame:removeAllChildren(true)
    -- end
    -- util_changeNodeParent(self.m_headFrame, nodeAvatar.m_nodeFrame)


    util_setHead(head, fbid, headName, nil, true)
    local layout = ccui.Layout:create()
    layout:setName("layout_touch")
    layout:setTouchEnabled(true)
    layout:setContentSize(head:getContentSize())
    self:addClick(layout)
    layout:addTo(head)
end


--[[
    显示大赢动画
]]
function BombPurrglarPlayerItem:showBigWinAni(winType)
    table.insert(self.m_winType_pool,#self.m_winType_pool + 1,winType)

    if not self.isBigWinPlaying then
        self:playNextBigWin()
    end
end

--[[
    播放大赢
]]
function BombPurrglarPlayerItem:playNextBigWin()
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
        end

        self.isBigWinPlaying = true
        self:runCsbAction("actionframe2",false,function(  )
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
function BombPurrglarPlayerItem:checkBigEnd()
    if #self.m_winType_pool > 0 then
        return false
    end

    return true
end


--增加头像点击看个人信息
function BombPurrglarPlayerItem:clickFunc(sender)
    local name = sender:getName()
    if name == "layout_touch" then
       if not self.m_playerInfo then
          return
       end
       G_GetMgr(G_REF.UserInfo):sendInfoMationReq(self.m_playerInfo.udid, "","",self.m_playerInfo.head)
    end
end

return BombPurrglarPlayerItem