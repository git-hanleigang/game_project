---
--xcyy
--2018年5月23日
--MiningManiaPlayerItem.lua

local MiningManiaPlayerItem = class("MiningManiaPlayerItem",util_require("base.BaseView"))


function MiningManiaPlayerItem:initUI()
    self:createCsbNode("MiningMania_RoomPlayer.csb")

    self.m_spWin = self:findChild("win")

    self:resetEventStatus()
    
    self.m_winType_pool = {}
end


function MiningManiaPlayerItem:onEnter()
    MiningManiaPlayerItem.super.onEnter(self)
    --关闭个人信息界面
    gLobalNoticManager:addObserver(self,handler(self,function()
        self:refreshHead()
    end),ViewEventType.NOTIFY_USERINFO_CLOSE_MAINLAYER
)
end

--[[
    重置事件状态
]]
function MiningManiaPlayerItem:resetEventStatus()
    self.m_spWin:setVisible(false)
end

--[[
    刷新数据
]]
function MiningManiaPlayerItem:refreshData(data)
    self.m_playerInfo = data
end

--[[
    获取用户ID
]]
function MiningManiaPlayerItem:getPlayerID()
    if self.m_playerInfo then
        return self.m_playerInfo.udid
    end
    return ""
end

-- 判断是否是自己
function MiningManiaPlayerItem:isMySelf()
    return globalData.userRunData.userUdid == self:getPlayerID()
end

--[[
    获取机器人信息
]]
function MiningManiaPlayerItem:getPlayerRobotInfo()
    if self.m_playerInfo then
        return self.m_playerInfo.robot
    end
    return ""
end

--[[
    获取用户数据
]]
function MiningManiaPlayerItem:getPlayerInfo( )
    return self.m_playerInfo
end

--[[
    刷新头像
]]
function MiningManiaPlayerItem:refreshHead()
    if not self.m_playerInfo then
        return
    end
    local isMe = self:isMySelf()

    local head = self:findChild("touxiang")
    head:removeAllChildren(true)
    local headSize = head:getContentSize()

    local frameId = isMe and globalData.userRunData.avatarFrameId or self.m_playerInfo.frame
    if frameId == nil or frameId == "" then
        self:findChild("ziji"):setVisible(isMe)
        self:findChild("qitaren"):setVisible(not isMe)
    else
        self:findChild("ziji"):setVisible(false)
        self:findChild("qitaren"):setVisible(false)
    end

    if self.m_playerInfo then
        local robot = self.m_playerInfo.robot
        if robot and tostring(robot) ~= ""  then
            self:showHead(head, self.m_playerInfo.facebookId, self.m_playerInfo.head, frameId, robot, headSize)
        else
            self:showHead(head, self.m_playerInfo.facebookId, self.m_playerInfo.head, frameId, nil, headSize)
        end
    else
        self:showHead(head, "", 1, frameId, nil, headSize)
    end

    self:resetEventStatus()

    -- local layout = ccui.Layout:create()
    -- layout:setName("layout_touch")
    -- layout:setTouchEnabled(true)
    -- layout:setContentSize(headSize)
    -- self:addClick(layout)
    -- layout:addTo(head)
end

function MiningManiaPlayerItem:showHead(headNode, facebookId, head, frameId, robot, headSize)
    local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(facebookId, head, frameId, robot, headSize)
    headNode:addChild(nodeAvatar)
    nodeAvatar:setPosition(headSize.width * 0.5, headSize.height * 0.5)
end

--[[
    显示大赢动画
]]
function MiningManiaPlayerItem:showBigWinAni(winType)
    table.insert(self.m_winType_pool,#self.m_winType_pool + 1,winType)

    if not self.isBigWinPlaying then
        self:playNextBigWin()
    end
end

--[[
    播放大赢
]]
function MiningManiaPlayerItem:playNextBigWin()
    local winType = self.m_winType_pool[1]
    if winType then
        table.remove(self.m_winType_pool,1,1)
        self.m_spWin:setVisible(false)
        if winType == "BIG_WIN" then
            self.m_spWin:setVisible(true)
        elseif winType == "MAGE_WIN" then
            self.m_spWin:setVisible(true)
        elseif winType == "EPIC_WIN" then
            self.m_spWin:setVisible(true)
        end

        self.isBigWinPlaying = true
        self:runCsbAction("actionframe",false,function(  )
            self.m_spWin:setVisible(false)
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
function MiningManiaPlayerItem:checkBigEnd()
    if #self.m_winType_pool > 0 then
        return false
    end

    return true
end

--增加头像点击看个人信息
function MiningManiaPlayerItem:clickFunc(sender)
    local name = sender:getName()
    if name == "layout_touch" then
       if not self.m_playerInfo then
          return
       end
       G_GetMgr(G_REF.UserInfo):sendInfoMationReq(self.m_playerInfo.udid, "","",self.m_playerInfo.head)
    end
end

return MiningManiaPlayerItem
