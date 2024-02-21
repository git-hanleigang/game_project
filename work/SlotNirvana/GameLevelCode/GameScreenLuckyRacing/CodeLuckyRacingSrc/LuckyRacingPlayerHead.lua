---
--xcyy
--2018年5月23日
--LuckyRacingPlayerHead.lua
local LuckyRacingPlayerHead = class("LuckyRacingPlayerHead",util_require("base.BaseView"))


function LuckyRacingPlayerHead:initUI(params)
    self.m_curIndex = params.index
    self:createCsbNode("LuckyRacing_touxiang.csb")

    self.m_winType_pool = {}

    self.m_head = self:findChild("head_"..self.m_curIndex)

    self.m_kuang = {}
    for index = 1,5 do
        self.m_kuang[index] = self:findChild("touxiang_"..(index - 1))
        self.m_kuang[index]:setVisible(index == self.m_curIndex)
    end

    self.m_tip_ani = util_createAnimation("Socre_LuckyRacing_wenzi.csb")
    self:addChild(self.m_tip_ani)
    self.m_tip_ani:setVisible(false)

    self:hideRankSign()
end

--[[
    刷新框的显示
]]
function LuckyRacingPlayerHead:refreshKuang(isShowAll)
    if self:isMyself() or isShowAll then
        for index = 1,5 do
            self.m_kuang[index]:setVisible(index == self.m_curIndex)
        end
    else
        for index = 1,5 do
            self.m_kuang[index]:setVisible(index == 5)
        end
    end
    
    
end

--[[
    刷新数据
]]
function LuckyRacingPlayerHead:refreshData(data)
    self.m_playerInfo = data
end

--[[
    获取用户ID
]]
function LuckyRacingPlayerHead:getPlayerID()
    if self.m_playerInfo then
        return self.m_playerInfo.udid
    end
    return ""
end

--[[
    获取机器人信息
]]
function LuckyRacingPlayerHead:getPlayerRobotInfo()
    if self.m_playerInfo then
        return self.m_playerInfo.robot
    end
    return ""
end

--[[
    获取用户数据
]]
function LuckyRacingPlayerHead:getPlayerInfo( )
    return self.m_playerInfo
end

--[[
    刷新头像
]]
function LuckyRacingPlayerHead:refreshHead(isShowAll)
    local isMe = self:isMyself()
    if isMe or isShowAll then
        self.m_head = self:findChild("head_"..self.m_curIndex)
    else
        self.m_head = self:findChild("head_5")
    end
    

    self:refreshKuang(isShowAll)
    self.m_head:removeAllChildren(true)
    if self.m_playerInfo then
        local robot = self.m_playerInfo.robot
        if robot and tostring(robot) ~= ""  then
            self:showHead(self.m_head, "", self.m_playerInfo.chairId, self.m_playerInfo, isMe, robot)
        else
            self:showHead(self.m_head, self.m_playerInfo.facebookId, self.m_playerInfo.head, self.m_playerInfo, isMe)
        end
        
    else
        self:showHead(self.m_head, "", 1, nil, isMe)
    end
    
end

function LuckyRacingPlayerHead:showHead(headNode, facebookId, head, _data, isMe, robot)

    util_setHead(headNode, facebookId, head, robot, true)
    -- local data = _data or {}
    -- local frameId = isMe and globalData.userRunData.avatarFrameId or data.frame
    -- local headSize = headNode:getContentSize()
    -- local headSizeUnified = cc.size(headSize.height, headSize.height)
    -- local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(facebookId, head, frameId, robot, headSizeUnified)
    -- headNode:addChild(nodeAvatar)
    -- nodeAvatar:setPosition( headSize.width * 0.5, headSize.height * 0.5 )

    -- local headRoot = headNode:getParent()
    -- local headFrameNode = headRoot:getChildByName("headFrameNode")
    -- if not headFrameNode then
    --     headFrameNode = cc.Node:create()
    --     headRoot:addChild(headFrameNode, 10)
    --     headFrameNode:setName("headFrameNode")
    --     headFrameNode:setPosition(headNode:getPosition())
    --     headFrameNode:setLocalZOrder(10)
    --     headFrameNode:setScale(headNode:getScale())
    -- else
    --     headFrameNode:removeAllChildren(true)
    -- end
    -- util_changeNodeParent(headFrameNode, nodeAvatar.m_nodeFrame)
end

--[[
    收集动效
]]
function LuckyRacingPlayerHead:runCollectAni(func)
    self:runCsbAction("actionframe",false,function()
        self:runCsbAction("idleframe")
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    是否是自己
]]
function LuckyRacingPlayerHead:isMyself()
    local isMe = (globalData.userRunData.userUdid == self:getPlayerID())
    return isMe
end

--[[
    触发动效
]]
function LuckyRacingPlayerHead:playTriggerAni(func)
    self.m_tip_ani:setVisible(true)

    self:resetEventStatus()
    self.m_tip_ani:findChild("sp_jackpot"):setVisible(true)

    self.m_tip_ani:runCsbAction("actionframe",false,function()
        self.m_tip_ani:setVisible(false)
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    显示大赢动画
]]
function LuckyRacingPlayerHead:showBigWinAni(winType)
    table.insert(self.m_winType_pool,#self.m_winType_pool + 1,winType)

    if not self.isBigWinPlaying then
        self:playNextBigWin()
    end
end

--[[
    播放大赢
]]
function LuckyRacingPlayerHead:playNextBigWin()
    local winType = self.m_winType_pool[1]
    if winType then
        table.remove(self.m_winType_pool,1,1)

        self:resetEventStatus()
        if winType == "BIG_WIN" then
            self.m_tip_ani:findChild("sp_big"):setVisible(true)
        elseif winType == "MAGE_WIN" then
            self.m_tip_ani:findChild("sp_megawin"):setVisible(true)
        elseif winType == "EPIC_WIN" then
            self.m_tip_ani:findChild("sp_epicwin"):setVisible(true)
        end

        

        self.isBigWinPlaying = true
        self.m_tip_ani:setVisible(true)
        self.m_tip_ani:runCsbAction("actionframe",false,function(  )
            self:resetEventStatus()
            self.m_tip_ani:setVisible(false)
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
function LuckyRacingPlayerHead:checkBigEnd()
    if #self.m_winType_pool > 0 then
        return false
    end

    return true
end

--[[
    重置事件状态
]]
function LuckyRacingPlayerHead:resetEventStatus()
    self.m_tip_ani:findChild("sp_big"):setVisible(false)
    self.m_tip_ani:findChild("sp_epicwin"):setVisible(false)
    self.m_tip_ani:findChild("sp_megawin"):setVisible(false)
    self.m_tip_ani:findChild("sp_jackpot"):setVisible(false)
end

--[[
    隐藏名次标签
]]
function LuckyRacingPlayerHead:hideRankSign()
    for index = 1,4 do
        self:findChild("No"..index):setVisible(false)
    end
end

--[[
    显示名次
]]
function LuckyRacingPlayerHead:showRank(rank)
    for index = 1,4 do
        self:findChild("No"..index):setVisible(rank == index)
    end
end

return LuckyRacingPlayerHead