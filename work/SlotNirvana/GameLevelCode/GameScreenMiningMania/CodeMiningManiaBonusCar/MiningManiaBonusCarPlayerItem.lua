---
--xcyy
--2018年5月23日
--MiningManiaBonusCarPlayerItem.lua

local MiningManiaBonusCarPlayerItem = class("MiningManiaBonusCarPlayerItem",util_require("base.BaseView"))


function MiningManiaBonusCarPlayerItem:initUI()
    self:createCsbNode("MiningManiaSheJiao2Seat.csb")

    self.m_mulText = self:findChild("m_lb_num")
    self.m_totalMul = 0
    self.m_curRank = 5
end


function MiningManiaBonusCarPlayerItem:onEnter()
    MiningManiaBonusCarPlayerItem.super.onEnter(self)
    --关闭个人信息界面
    gLobalNoticManager:addObserver(self,handler(self,function()
        self:refreshHead()
    end),ViewEventType.NOTIFY_USERINFO_CLOSE_MAINLAYER
)
end

--[[
    刷新数据
]]
function MiningManiaBonusCarPlayerItem:refreshData(data)
    self.m_playerInfo = data
end

function MiningManiaBonusCarPlayerItem:refreshMulData(_mul)
    self.m_totalMul = _mul
end

function MiningManiaBonusCarPlayerItem:getMulData()
    return self.m_totalMul
end

function MiningManiaBonusCarPlayerItem:setCurRank(_rank)
    self.m_curRank = _rank
end

function MiningManiaBonusCarPlayerItem:getCurRank(_rank)
    return self.m_curRank
end

--[[
    获取用户ID
]]
function MiningManiaBonusCarPlayerItem:getPlayerID()
    if self.m_playerInfo then
        return self.m_playerInfo.udid
    end
    return ""
end

-- 判断是否是自己
function MiningManiaBonusCarPlayerItem:isMySelf()
    return globalData.userRunData.userUdid == self:getPlayerID()
end

--[[
    获取机器人信息
]]
function MiningManiaBonusCarPlayerItem:getPlayerRobotInfo()
    if self.m_playerInfo then
        return self.m_playerInfo.robot
    end
    return ""
end

--[[
    获取用户数据
]]
function MiningManiaBonusCarPlayerItem:getPlayerInfo( )
    return self.m_playerInfo
end

--[[
    刷新头像
]]
function MiningManiaBonusCarPlayerItem:refreshHead()
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
end

function MiningManiaBonusCarPlayerItem:showHead(headNode, facebookId, head, frameId, robot, headSize)
    local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(facebookId, head, frameId, robot, headSize)
    headNode:addChild(nodeAvatar)
    nodeAvatar:setPosition(headSize.width * 0.5, headSize.height * 0.5)
end

-- 刷新当前倍数
function MiningManiaBonusCarPlayerItem:refreshUserMul(_mul)
    self.m_totalMul = self.m_totalMul + _mul
    local mulStr = "X" ..  self.m_totalMul
    self.m_mulText:setString(mulStr)
end

function MiningManiaBonusCarPlayerItem:setNodeVisible()
    self:findChild("Node_reward"):setVisible(false)
end

-- 获取奖励位置
function MiningManiaBonusCarPlayerItem:getRewardNodePosY()
    local rewardNode = self:findChild("Node_reward")
    return rewardNode:getPositionY()
end

return MiningManiaBonusCarPlayerItem
