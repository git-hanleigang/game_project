---
--xcyy
--2018年5月23日
--MiningManiaBonusReelPlayerItem.lua

local MiningManiaBonusReelPlayerItem = class("MiningManiaBonusReelPlayerItem",util_require("base.BaseView"))


function MiningManiaBonusReelPlayerItem:initUI()
    self:createCsbNode("MiningManiaSheJiao1Seat.csb")

    self.m_collectAni = util_createAnimation("MiningManiaSheJiao1Seat_tx.csb")
    self:findChild("Node_xbeibd"):addChild(self.m_collectAni)
    self.m_collectAni:setVisible(false)

    self.m_yaoGanSpine = util_spineCreate("MiningMania_yaogan",true,true)
    self:findChild("Node_yaogan"):addChild(self.m_yaoGanSpine)
    self:playYaoGanIdle()

    self.m_mulText = self:findChild("m_lb_num")
    self.m_totalMul = 0
    self.m_curRank = 5
end


function MiningManiaBonusReelPlayerItem:onEnter()
    MiningManiaBonusReelPlayerItem.super.onEnter(self)
    --关闭个人信息界面
    gLobalNoticManager:addObserver(self,handler(self,function()
        self:refreshHead()
    end),ViewEventType.NOTIFY_USERINFO_CLOSE_MAINLAYER
)
end

--[[
    刷新数据
]]
function MiningManiaBonusReelPlayerItem:refreshData(data)
    self.m_playerInfo = data
end

function MiningManiaBonusReelPlayerItem:refreshMulData(_mul)
    self.m_totalMul = _mul
end

function MiningManiaBonusReelPlayerItem:getMulData()
    return self.m_totalMul
end

function MiningManiaBonusReelPlayerItem:setCurRank(_rank)
    self.m_curRank = _rank
end

function MiningManiaBonusReelPlayerItem:getCurRank(_rank)
    return self.m_curRank
end

--[[
    获取用户ID
]]
function MiningManiaBonusReelPlayerItem:getPlayerID()
    if self.m_playerInfo then
        return self.m_playerInfo.udid
    end
    return ""
end

-- 判断是否是自己
function MiningManiaBonusReelPlayerItem:isMySelf()
    return globalData.userRunData.userUdid == self:getPlayerID()
end

--[[
    获取机器人信息
]]
function MiningManiaBonusReelPlayerItem:getPlayerRobotInfo()
    if self.m_playerInfo then
        return self.m_playerInfo.robot
    end
    return ""
end

--[[
    获取用户数据
]]
function MiningManiaBonusReelPlayerItem:getPlayerInfo( )
    return self.m_playerInfo
end

--[[
    刷新头像
]]
function MiningManiaBonusReelPlayerItem:refreshHead()
    if not self.m_playerInfo then
        return
    end
    local isMe = self:isMySelf()

    self:findChild("Node_arrow"):setVisible(isMe)

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

function MiningManiaBonusReelPlayerItem:showHead(headNode, facebookId, head, frameId, robot, headSize)
    local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(facebookId, head, frameId, robot, headSize)
    headNode:addChild(nodeAvatar)
    nodeAvatar:setPosition(headSize.width * 0.5, headSize.height * 0.5)
end

-- 刷新当前倍数
function MiningManiaBonusReelPlayerItem:refreshUserMul(_mul)
    self.m_totalMul = self.m_totalMul + _mul
    local mulStr = "X" ..  self.m_totalMul
    self.m_mulText:setString(mulStr)
end

-- 收集光效动画
function MiningManiaBonusReelPlayerItem:playCollectEffect()
    util_resetCsbAction(self.m_collectAni.m_csbAct)
    self.m_collectAni:setVisible(true)
    self.m_collectAni:runCsbAction("actionframe", false, function()
        self.m_collectAni:setVisible(false)
    end)
end

-- 摇杆动画
function MiningManiaBonusReelPlayerItem:playYaoGanTrigger()
    util_spinePlay(self.m_yaoGanSpine,"turn",true)
end

function MiningManiaBonusReelPlayerItem:playYaoGanIdle()
    util_spinePlay(self.m_yaoGanSpine,"idle",true)
end

-- 刷新排名
function MiningManiaBonusReelPlayerItem:refreshUserRank(_curRank)
    for i=1, 5 do
        if i == _curRank then
            self:findChild("sp_rank_"..i):setVisible(true)
            self:setCurRank(_curRank)
        else
            self:findChild("sp_rank_"..i):setVisible(false)
        end
    end
end

-- 出现排名；第一次spin结束后
function MiningManiaBonusReelPlayerItem:firstSpinPlayRank()
    self:runCsbAction("paiming", false, function()
        self:runCsbAction("idle1", true)
    end)
end

-- 除第一次外；刷新排名
function MiningManiaBonusReelPlayerItem:refreshRankAni()
    self:runCsbAction("actionframe_shuaxin", false, function()
        self:runCsbAction("idle1", true)
    end)
end

-- spin6次结束后，隐藏相关节点
function MiningManiaBonusReelPlayerItem:setNodeVisible()
    self:findChild("Node_other"):setVisible(false)
end

return MiningManiaBonusReelPlayerItem
