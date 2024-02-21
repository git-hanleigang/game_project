---
--xcyy
--2018年5月23日
--FairyDragonDropCoinsVIew.lua

local FairyDragonDropCoinsVIew = class("FairyDragonDropCoinsVIew", util_require("base.BaseView"))

function FairyDragonDropCoinsVIew:initUI()
    self:createCsbNode("FairyDragon_DropCoins.csb")
end

function FairyDragonDropCoinsVIew:onEnter()
    self:onUpdate(handler(self, self.updateCall))
end
function FairyDragonDropCoinsVIew:onExit()
    self:unscheduleUpdate()
end

-- 定时tick
function FairyDragonDropCoinsVIew:updateCall(dt)
    if self.m_inCreateCoins then
        self:createCoinsUpdate(dt)
    end

    self:updateCoinMove(dt)
end
function FairyDragonDropCoinsVIew:createBaseCoins()
    local coins
    if #self.m_coinCaches>0 then
        coins = self.m_coinCaches[#self.m_coinCaches]
        coins.notDrop = nil
        coins:setVisible(true)
        self.m_coinCaches[#self.m_coinCaches] = nil
        --print("createBaseCoins------------------------------count="..#self.m_coinCaches)
    else
        coins = util_createAnimation("CommonWin/coinsNode.csb")
        local index = math.random(1,3)
        coins:playAction("idle"..index,true)
        self.m_node_coins:addChild(coins, 5)
    end
    if not self.m_coinsTab then
        self.m_coinsTab = {}
    end
    self.m_coinsTab[#self.m_coinsTab + 1] = coins
    return coins
end
--创建背景金币
function FairyDragonDropCoinsVIew:createCoins()
    local coins = self:createBaseCoins()

    local randomHight = 0
    local randomWidth = 0
    local scale = math.random(6, 10) * 0.1

    randomWidth = math.random(-30, 30)
    local midSpeed = self:calInitSpeed(0, 0, self.m_frameSize.height / 2)
    randomHight = math.random(midSpeed - 5, midSpeed + 5)
    scale = scale * 0.7
    local isMid = math.random(1, 10)
    local isFade = math.random(1, 5)

    if isMid <= 3 then
        local yPos = self.m_root:getPositionY() + self.m_frameSize.height * PortraitScale / 40
        coins:setPosition(math.random(-30, 30), yPos)
         --50
        if isFade == 2 then
            coins.notDrop = true
            self:easyFadeIn(coins)
        end
    else
        if isFade == 2 then
            coins.notDrop = true
            self:easyFadeOut(coins)
        end
        coins:setPosition(math.random(-30, 30), 0)
     --50
    end

    local node = coins:findChild("node_coins")
    node:setScale(scale)
    self:runCoinsAction(coins, randomWidth, randomHight, 1) -- 250
end
--金币自由落体
function FairyDragonDropCoinsVIew:runCoinsAction(coins, vx, vy, factor)
    local node = coins:findChild("node_coins")
    node:setVisible(true)
    node.m_vx = vx
    node.m_vy = vy
    node.m_frameTime = 0
    node.m_spinTime = 0.05
    node.m_gravity = self.m_gravity * factor
end
function FairyDragonDropCoinsVIew:updateCoinMove(dt)
    if not self.m_coinsTab or #self.m_coinsTab == 0 then
        return
    end
    for i = #self.m_coinsTab, 1, -1 do
        local coins = self.m_coinsTab[i]
        local node = coins:findChild("node_coins")
        node.m_frameTime = node.m_frameTime + dt
        if node.m_frameTime >= node.m_spinTime then
            node.m_frameTime = node.m_frameTime - node.m_spinTime

            local x, y = node:getPosition()
            local nextVy = node.m_vy - node.m_gravity
            if node.m_vy > 0 then
                if nextVy <= 0 and math.random(1, 10) <= 2 then
                    coins:retain()
                    coins:removeFromParent(false)
                    self.m_node_coins_front:addChild(coins)
                    coins:release()
                end
            else
                nextVy = node.m_vy - node.m_gravity * self.m_downResistance
            end
            node.m_vy = nextVy
            if node.m_vy <= 0 then
                node:setPosition(x, y + node.m_vy)
            else
                node:setPosition(x + node.m_vx, y + node.m_vy)
            end

            if globalData.slotRunData.isPortrait == true then
                if node.m_vy <= 0 then
                    if coins.notDrop then
                        coins:setVisible(false)
                    end
                -- coins:playAction("drop")
                end
                -- end
                local worldpos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
                if worldpos.x < 0 or worldpos.x > display.width or worldpos.y < 0 or worldpos.y > display.height * 1.2 then --
                    self:exchangeCoinsParent(coins, node)
                -- table.remove(self.nodeCoinsList,i)
                end
            else
                local worldpos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
                if worldpos.x < 0 or worldpos.x > display.width or worldpos.y < 0 then
                    self:exchangeCoinsParent(coins, node)
                -- table.remove(self.nodeCoinsList,i)
                end
            end
        end
    end
end

function FairyDragonDropCoinsVIew:exchangeCoinsParent(coins, node)
    self.m_coinCaches[#self.m_coinCaches + 1] = coins
    for i = #self.m_coinsTab, 1, -1 do
        if self.m_coinsTab[i] == coins then
            table.remove(self.m_coinsTab, i)
        end
    end
    coins:retain()
    coins:removeFromParent(false)
    self.m_node_coins:addChild(coins)
    util_nextFrameFunc(
        function()
            coins:release()
        end
    )

    node:unscheduleUpdate()
    node:setPosition(0, 0)
    node:setVisible(false)
end

function FairyDragonDropCoinsVIew:clearCacheCoins()
    -- 所有的金币都做渐隐
    if self.m_coinsTab and #self.m_coinsTab > 0 then
        for i = 1, #self.m_coinsTab do
            self.m_coinsTab[i]:setVisible(false)
        end
    end
end
return FairyDragonDropCoinsVIew
