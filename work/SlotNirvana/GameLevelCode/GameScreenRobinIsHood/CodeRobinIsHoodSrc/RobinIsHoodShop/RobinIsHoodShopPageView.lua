---
--xcyy
--2018年5月23日
--RobinIsHoodShopPageView.lua
local PublicConfig = require "RobinIsHoodPublicConfig"
local RobinIsHoodShopPageView = class("RobinIsHoodShopPageView",util_require("base.BaseView"))

local ITEM_COUNT        =       9

function RobinIsHoodShopPageView:initUI(params)
    self.m_machine = params.machine
    self.m_shopView = params.shopView

    self.m_items = {}

    local pageSize = params.pageSize
    local itemWidth = pageSize.width / 3
    local itemHeight = pageSize.height / 3
    for index = 1,ITEM_COUNT do
        local itemParams = {
            machine = self.m_machine,
            shopView = self.m_shopView,
            pageView = self,
            itemID = index
        }
        local item = util_createView("CodeRobinIsHoodSrc.RobinIsHoodShop.RobinIsHoodShopItem",itemParams)
        self:addChild(item,index)

        local colIndex = (index - 1) % 3
        local rowIndex = math.floor((index - 1) / 3) 
        local posX = (colIndex + 0.5) * itemWidth
        local posY = pageSize.height - (rowIndex + 0.5) * itemHeight
        item:setPosition(cc.p(posX,posY))
        self.m_items[index] = item
    end
    
end

function RobinIsHoodShopPageView:initSpineUI()
    
end

--刷新界面
function RobinIsHoodShopPageView:updateView(data,cost,pageIndex,isFinished,isFree)
    for index = 1,ITEM_COUNT do
        local item = self.m_items[index]
        local params = {
            pageIndex = pageIndex,
            reward = data[index] or 0,
            cost = cost[index],
            isLock = not isFinished,
            isDiscount = self.m_machine.m_isDiscount,
            isFree = isFree
        }
        item:updateUI(params)
    end
end

--[[
    解锁动画
]]
function RobinIsHoodShopPageView:runUnLockAni(func)
    for index = 1,ITEM_COUNT do
        local item = self.m_items[index]
        item:runUnlockAni()
    end

    performWithDelay(self,function()
        if type(func) == "function" then
            func()
        end
    end,40 / 30)
end

--[[
    显示压黑
]]
function RobinIsHoodShopPageView:showBlackAni()
    for index = 1,ITEM_COUNT do
        local item = self.m_items[index]
        item:showDarkAni()
    end
end

--[[
    转换为free标签
]]
function RobinIsHoodShopPageView:switchToFreePrice()
    for index = 1,ITEM_COUNT do
        local item = self.m_items[index]
        item:switchFree()
    end
end

--[[
    转换为普通价签
]]
function RobinIsHoodShopPageView:switchToNormalPrize()
    for index = 1,ITEM_COUNT do
        local item = self.m_items[index]
        item:switchNormal()
    end
end

--[[
    飞乘倍
]]
function RobinIsHoodShopPageView:flyDoublePickAni(endNode,coins,func)
    local doubleItem
    for index = 1,ITEM_COUNT do
        local item = self.m_items[index]
        if item.m_reward == "extraPick" then
            doubleItem = item
            break
        end
    end

    if doubleItem then
        doubleItem:doublePicRunIdleAni()
        local startPos = cc.p(doubleItem:getPosition()) 
        local endPos = cc.p(endNode:getPosition())
        local flyNode = util_createAnimation("RobinIsHood_shop_main_pick_double_fly.csb")
        self:addChild(flyNode,100)
        flyNode:setPosition(startPos)

        for index = 1,2 do
            local particle = flyNode:findChild("Particle_"..index)
            if not tolua.isnull(particle) then
                particle:setPositionType(0)
            end
        end
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_RobinIsHood_shop_item_multi)
        local actionList = {
            cc.MoveTo:create(0.5,endPos),
            cc.CallFunc:create(function()
                if not tolua.isnull(flyNode:findChild("m_lb_num_2x")) then
                    flyNode:findChild("m_lb_num_2x"):setVisible(false)
                end

                for index = 1,2 do
                    local particle = flyNode:findChild("Particle_"..index)
                    if not tolua.isnull(particle) then
                        particle:stopSystem()
                    end
                end
                
                if not tolua.isnull(endNode) then
                    endNode:runMultiAni(coins,func)
                end
            end),
            cc.DelayTime:create(1),
            cc.RemoveSelf:create(true)
        }
        flyNode:runAction(cc.Sequence:create(actionList))

    else
        if type(func) == "function" then
            func()
        end
    end
end
return RobinIsHoodShopPageView