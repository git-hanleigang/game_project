---
--xcyy
--2018年5月23日
--LuckyRacingView.lua

local LuckyRacingView = class("LuckyRacingView",util_require("base.BaseView"))


function LuckyRacingView:initUI(params)
    self.m_index = params.index
    self:createCsbNode("LuckyRacing_score.csb")

    self.m_rank = -1

    for index = 1,4 do
        local node = self:findChild("score_"..(index - 1))
        if self.m_index == index then
            node:setVisible(true)
            self.m_rootNode = node
        else
            node:setVisible(false)
        end
    end
    
    self.m_node_jiantou = self.m_rootNode:getChildByName("jiantou")
    self.m_node_head = self.m_rootNode:getChildByName("touxiang")
    self.m_node_level = self.m_rootNode:getChildByName("dengji")
    self.m_lbl_coins = self.m_rootNode:getChildByName("Node_1"):getChildByName("font")
    --粒子
    self.m_particle = self.m_rootNode:getChildByName("Panel_1"):getChildByName("Particle_1")

    --头像
    local head = util_createView("CodeLuckyRacingSrc.LuckyRacingPlayerHead",{index = self.m_index})
    self.m_node_head:addChild(head)
    self.m_headItem = head
    self.m_headItem:refreshHead()

    --箭头
    local jiantou = util_createAnimation("LuckyRacing_jiantou_1.csb")
    self.m_node_jiantou:addChild(jiantou)
    jiantou:findChild("jiantou_left_0"):setVisible(false)
    jiantou:findChild("jiantou_right_0"):setVisible(false)
    self.m_jiantou = jiantou
    self.m_jiantou:runCsbAction("idleframe",true)

    

    --bonus数量
    local countItem = util_createAnimation("LuckyRacing_dengji.csb")
    self.m_node_level:addChild(countItem)
    self.m_countItem = countItem

    self.m_bonusCount = 0
    self.m_score = 0
    for index = 1,4 do
        local node = self.m_countItem:findChild("quan_"..(index - 1))
        if self.m_index == index then
            node:setVisible(true)
            self.m_lbl_count = node:getChildByName("Node_2"):getChildByName("font")
            self.m_lbl_count:setString(self.m_bonusCount)
        else
            node:setVisible(false)
        end
    end

end

--[[
    刷新头像
]]
function LuckyRacingView:refreshHead(playerInfo)
    self.m_playerInfo = playerInfo
    local isMe = (playerInfo and globalData.userRunData.userUdid == playerInfo.udid)
    self.m_node_jiantou:setVisible(isMe)

    self:setScale(isMe and 1.1 or 1)
    self.m_isMe = isMe

    self.m_headItem:refreshData(playerInfo)
    --刷新头像
    self.m_headItem:refreshHead()
end

--[[
    刷新倍数
]]
function LuckyRacingView:refreshMutiples(mutilple)
    self.m_lbl_coins:setString("x"..mutilple)
    local info={label = self.m_lbl_coins,sx = 0.32,sy = 0.32}
    self:updateLabelSize(info,300)
end

--[[
    增加倍数
]]
function LuckyRacingView:addMultiples(mutiple)
    self.m_score = self.m_score + mutiple
    self:refreshMutiples(self.m_score)
end

--[[
    收集动画
]]
function LuckyRacingView:collectAni(func)
    self:runCsbAction("actionframe",false,function()
        self:runCsbAction("idleframe")
        if type(func) == "function" then
            func()
        end
    end)

    self.m_jiantou:runCsbAction("actionframe",false,function()
        self.m_jiantou:runCsbAction("idleframe",true)
    end)

    self.m_countItem:runCsbAction("actionframe",false,function()
        self.m_countItem:runCsbAction("idleframe")
    end)

    self.m_particle:resetSystem()

    self.m_headItem:runCollectAni()

    self.m_bonusCount = self.m_bonusCount + 1
    self.m_lbl_count:setString(self.m_bonusCount)
end

--[[
    重置bonus数量
]]
function LuckyRacingView:resetBonusCount()
    self.m_bonusCount = 0
    self.m_score = 0
    self.m_lbl_count:setString(self.m_bonusCount)
    self:refreshMutiples(self.m_score)
end

--修改排名
function LuckyRacingView:changeRank(rank)
    self.m_rank = rank
end

return LuckyRacingView