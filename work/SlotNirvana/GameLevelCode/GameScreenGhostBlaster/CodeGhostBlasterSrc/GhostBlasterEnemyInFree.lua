---
--xcyy
--2018年5月23日
--GhostBlasterEnemyInFree.lua
local PublicConfig = require "GhostBlasterPublicConfig"
local GhostBlasterEnemyInFree = class("GhostBlasterEnemyInFree", util_require("base.BaseView"))

local ENEMY_CONFIG = {
    {spineName = "GhostBlaster_xg3",spineType = 3},
    {spineName = "GhostBlaster_xg2",spineType = 2},
    {spineName = "GhostBlaster_xg1",spineType = 1},
    {spineName = "GhostBlaster_xg2",spineType = 2},
    {spineName = "GhostBlaster_xg3",spineType = 3},
}

local GHOST_ZORDER = {5,4,3,4,5}

function GhostBlasterEnemyInFree:initUI(params)
    self.m_machine = params.machine

    self.m_isShowBoss = false

    self.m_curTotalWin = 0

    self.m_enemyItems = {}
    for index = 1,#ENEMY_CONFIG do
        local item = util_createView("CodeGhostBlasterSrc.GhostBlasterEnemyItem",{
            parent = self,
            spineName = ENEMY_CONFIG[index].spineName,
            spineType = ENEMY_CONFIG[index].spineType,
            index = index,
            machine = self.m_machine
        })

        self.m_enemyItems[#self.m_enemyItems + 1] = item

        self:addChild(item,GHOST_ZORDER[index])
    end

    --boss
    self.m_bossItem = util_createView("CodeGhostBlasterSrc.GhostBlasterBossItem",{parent = self,machine = self.m_machine})
    self:addChild(self.m_bossItem)
end

--[[
    刷新当前赢钱
]]
function GhostBlasterEnemyInFree:resetWinCoins()
    self.m_curTotalWin = 0
end

--[[
    累加totalWin
]]
function GhostBlasterEnemyInFree:addTotalWin(winCoins)
    self.m_curTotalWin = self.m_curTotalWin + winCoins
end

--[[
    获取totalWin
]]
function GhostBlasterEnemyInFree:getTotalWin()
    return self.m_curTotalWin
end

function GhostBlasterEnemyInFree:onEnter()
    GhostBlasterEnemyInFree.super.onEnter(self)
    for index = 1,#self.m_enemyItems do
        local item = self.m_enemyItems[index]
        local pos = util_convertToNodeSpace(self.m_machine:findChild("Node_freebox"..index),self)
        item:setPosition(pos)
    end
end

--[[
    检测结果是否与服务器结果一致
]]
function GhostBlasterEnemyInFree:checkIsSameResult(data)
    if not data then
        return
    end
    if self.m_machine:checkShowBoss() and not self.m_isShowBoss then
        self:resetView(data)
        return
    end

    local firstRoundProgress = data.firstRoundProgress
    if not self.m_isShowBoss then
        --检测小兵血量是否一致
        for index = 1,#self.m_enemyItems do
            local item = self.m_enemyItems[index]
            if item.m_hp ~= firstRoundProgress[index] then
                item:resetView(firstRoundProgress[index])
            end
        end
    end
end

--[[
    重置界面显示
]]
function GhostBlasterEnemyInFree:resetView(data)
    self:resetWinCoins()
    local isShowBoss = self.m_machine:checkShowBoss()

    local firstRoundProgress = data.firstRoundProgress
    for index = 1,#self.m_enemyItems do
        local hp = firstRoundProgress[index]
        local item = self.m_enemyItems[index]
        item:resetView(hp)
        item:setVisible(not isShowBoss)
    end

    self.m_bossItem:resetView(data)
    self.m_bossItem:setVisible(isShowBoss)
    self.m_isShowBoss = isShowBoss
end

--[[
    显示boss动画
]]
function GhostBlasterEnemyInFree:showBossAni(data,func)
    local isShowBoss = self.m_machine:checkShowBoss()
    if not isShowBoss then
        return
    end
    self.m_bossItem:initStatus(data)
    self.m_bossItem:setVisible(isShowBoss)
    self.m_isShowBoss = isShowBoss


    self.m_bossItem:showBossAni(func)

    for index = 1,#self.m_enemyItems do
        local item = self.m_enemyItems[index]
        item:setVisible(not isShowBoss)
    end
end

--[[
    小鬼受击动画
]]
function GhostBlasterEnemyInFree:hitGhostAni(colIndex,hp,coins,count,maxCount,isLastShoot,func)
    self:addTotalWin(coins)
    if not self.m_isShowBoss then
        local enemyItem = self.m_enemyItems[colIndex]
        enemyItem:hitGhostAni(hp,coins,count,function()
            if count >= maxCount then
                enemyItem:runGhostIdleAni()
            end
            if type(func) == "function" then
                func()
            end
        end)
        local isDefeat = enemyItem:isDefeat()
        local startNode = enemyItem:getFlyNode(count)

        local freeCount = 0
        --击败后检测是否加次数
        if isDefeat and count >= maxCount then
            freeCount = self.m_machine:getAddFreeCount()
            if freeCount > 0 then
                --飞free次数
                self.m_machine:flyFreeCountOrCoinsInFree(enemyItem:getFlyNode(maxCount + 1),freeCount,0)
            end
            
        end
        --飞金币
        self.m_machine:flyFreeCountOrCoinsInFree(startNode,0,coins)
    else
        self:hitBossAni(coins,count,maxCount,isLastShoot,func)
    end
end

--[[
    boss受击动画
]]
function GhostBlasterEnemyInFree:hitBossAni(coins,count,maxCount,isLastShoot,func)

    self.m_bossItem:hitGhostAni(coins,self.m_machine.m_isDefeatBoss,isLastShoot,function()
        if type(func) == "function" then
            func()
        end
    end)

    local freeCount = 0
    --检测是否加次数
    if self.m_machine.m_isLastBonusInFree and count >= maxCount and maxCount ~= 0 then
        freeCount = self.m_machine:getAddFreeCount()
        if freeCount > 0 then
            --飞free次数
            self.m_machine:flyFreeCountOrCoinsInFree(self.m_bossItem:getFlyNode(count + 1),freeCount,0)
        end
    end

    local startNode = self.m_bossItem:getFlyNode(count)

    if self.m_machine.m_isLastShoot then
        self.m_machine:delayCallBack(1,function()
            --飞金币
            self.m_machine:flyFreeCountOrCoinsInFree(startNode,0,coins)
        end)
    else
        --飞金币
        self.m_machine:flyFreeCountOrCoinsInFree(startNode,0,coins)
    end
end

--[[
    获取对应列的小鬼
]]
function GhostBlasterEnemyInFree:getGhostAniByCol(colIndex)
    if self.m_isShowBoss then
        return self.m_bossItem
    end

    return self.m_enemyItems[colIndex]
end

--[[
    检测是否显示boss
]]
function GhostBlasterEnemyInFree:checkShowBoss()

    for index = 1,#self.m_enemyItems do
        local item = self.m_enemyItems[index]
        if item.m_hp > 0 then
            return false
        end
    end

    return true
end

return GhostBlasterEnemyInFree