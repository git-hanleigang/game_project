---
--xcyy
--2018年5月23日
--BunnyBountyColorfulGame.lua
--多福多彩
local PublicConfig = require "BunnyBountyPublicConfig"
local BunnyBountyColorfulGame = class("BunnyBountyColorfulGame",util_require("Levels.BaseLevelDialog"))

BunnyBountyColorfulGame.m_bonusData = nil   --bonus数据
BunnyBountyColorfulGame.m_endFunc = nil     --结束回调
BunnyBountyColorfulGame.m_curClickIndex = 1 --当前点击的索引

local ITEM_COUNT            =           15          --可点击道具数量
local JACKPOT_TYPE = {"grand","major","minor","mini","levelup"}

function BunnyBountyColorfulGame:initUI(params)
    self.m_machine = params.machine

    self:createCsbNode("BunnyBounty/GameScreenduofuduocai.csb")

    --jackpot
    self.m_jackpotBar = util_createView("CodeBunnyBountySrc.BunnyBountyColofulJackPotBar",{machine = self.m_machine})
    self:findChild("Node_jackpot"):addChild(self.m_jackpotBar)

    --定时节点
    self.m_scheduleNode = cc.Node:create()
    self:addChild(self.m_scheduleNode)

    --所有道具数组
    self.m_items = {}
    for index = 1,ITEM_COUNT do
        local parentNode = self:findChild("Node_"..index)
        local item = util_createView("CodeBunnyBountySrc.BunnyBountyColorfulItem",{
            parentView = self,
            itemID = index
        })

        if parentNode then
            parentNode:addChild(item)
        else
            self:addChild(item)
        end
        self.m_items[index] = item
    end

    self.m_left_item_counts = {}
end

--[[
    开启定时idle
]]
function BunnyBountyColorfulGame:startIdleni()
    local unClickdItems = self:getUnClickeItem()
    --每次随机控制3个摆动
    for index = 1,3 do
        if #unClickdItems > 0 then
            local randIndex = math.random(1,#unClickdItems)
            local item = unClickdItems[randIndex]
            if not tolua.isnull(item) then
                item:runShakeAni()
            end
            table.remove(unClickdItems,randIndex)
        end
    end
    performWithDelay(self.m_scheduleNode,function()
        self:startIdleni()
    end,8)
end

--[[
    停止定时idle
]]
function BunnyBountyColorfulGame:stopIdleAni()
    self.m_scheduleNode:stopAllActions()
end

--[[
    获取还未点击位置
]]
function BunnyBountyColorfulGame:getUnClickeItem()
    local unClickdItems = {}
    for k,item in pairs(self.m_items) do
        if not item.m_isClicked then
            unClickdItems[#unClickdItems + 1] = item
        end
    end

    return unClickdItems
end

--[[
    设置bonus数据
]]
function BunnyBountyColorfulGame:setBonusData(bonusData,endFunc)
    self.m_bonusData = bonusData
    --兼容数据格式,可根据具体的数据调整
    self.m_rewardList = bonusData.rewardList
    self.m_endFunc = endFunc
    --当前点击的索引
    self.m_curClickIndex = 1
    --当前是否结束
    self.m_isEnd = false
    --重置收集剩余数量
    for index,jackpotType in pairs(JACKPOT_TYPE) do
        self.m_left_item_counts[jackpotType] = 3
    end
end

--[[
    重置界面显示
]]
function BunnyBountyColorfulGame:resetView(bonusData,endFunc)
    self:setBonusData(bonusData,endFunc)
    self.m_jackpotBar:resetView()
    for index,item in ipairs(self.m_items) do
        item:resetStatus()
    end
end

--[[
    显示界面
]]
function BunnyBountyColorfulGame:showView(func)
    self:setVisible(true)
    self:startIdleni()
end

--[[
    隐藏界面
]]
function BunnyBountyColorfulGame:hideView(func)
    self:setVisible(false)
    if type(func) == "funciton" then
        func()
    end
end

--[[
    点击道具回调
]]
function BunnyBountyColorfulGame:clickItem(clickItem)
    if self.m_isEnd then
        return
    end
    --获取当前点击的的奖励
    local rewardType = self:getCurReward()

    if rewardType ~= "levelup" then
        local process = self.m_jackpotBar:getProcessByType(rewardType)
        local pointNode = self.m_jackpotBar:getFeedBackPoint(rewardType,process)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_BunnyBounty_collect_egg_to_jp)
        self:flyParticleAni(clickItem,pointNode,function()
            self.m_jackpotBar:collectFeedBackAni(rewardType,pointNode)
        end)
        
    end

    --累加点击索引
    self.m_curClickIndex  = self.m_curClickIndex + 1

    --减少剩余奖励数量
    self.m_left_item_counts[rewardType] = self.m_left_item_counts[rewardType] - 1

    --游戏结束
    if self.m_curClickIndex > #self.m_rewardList then
        self.m_isEnd = true
        self:stopIdleAni()
    end

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_BunnyBounty_click_egg_feed_back)
    --刷新点击位置的道具显示
    if not self.m_isEnd then
        clickItem:showRewardAni(rewardType,function()
            self:showPreWinnigIdle(clickItem,rewardType)
        end)
    else
        clickItem:showRewardAni(rewardType,function()
            --显示其他未点击的位置的奖励
            self:showUnClickItemReward()
            

            --显示中奖动效
            self:showHitJackpotAni(rewardType,function()
                
                --结果多展示一会
                self.m_machine:delayCallBack(0.5,function()
                    if type(self.m_endFunc) == "function" then
                        self.m_endFunc()
                    end
                end)
            end)

            
        end)
    end
end

--[[
    升级触发动画
]]
function BunnyBountyColorfulGame:runLevelUpTriggerAni(winType,func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_BunnyBounty_bonus_level_up)
    for index = 1,#self.m_items do
        local item = self.m_items[index]
        --未中奖的压黑
        if not item:isSameType(winType) and not item:isSameType("levelup") then
            item:runDarkAni()
        else
            --升级动效
            if item:isSameType("levelup") then
                item:getRewardAni()
            end
        end
    end
    self.m_machine:delayCallBack(30 / 30,func)
end

--[[
    显示中奖动效
]]
function BunnyBountyColorfulGame:showHitJackpotAni(winType,func)
    if self.m_bonusData.isLevelUp then
        
        self:runLevelUpTriggerAni(winType,function()
            for index = 1,#self.m_items do
                local item = self.m_items[index]
                --升级动效
                if item:isSameType(winType) then
                    item:runLevelUpAni(function()
                        item:getRewardAni()
                    end)
                end
            end

            if winType == "grand" then
                self.m_jackpotBar:showGrandMultiAni()
            end

            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_BunnyBounty_jackpot_level_up)
            self.m_machine:delayCallBack(44 / 30,function()
                self.m_jackpotBar:showHitLight(self.m_bonusData.winJackpot)
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_BunnyBounty_hit_jackpot)
            end)
            
            self.m_machine:delayCallBack(74 / 30,func)
        end)
    else
        for index = 1,#self.m_items do
            local item = self.m_items[index]
            --未中奖的压黑
            if not item:isSameType(winType)  then
                item:runDarkAni()
            else
                item:getRewardAni()
            end
        end
        self.m_jackpotBar:showHitLight(self.m_bonusData.winJackpot)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_BunnyBounty_hit_jackpot)
        self.m_machine:delayCallBack(44 / 30,func)
    end
end

--[[
    显示预中奖动效
]]
function BunnyBountyColorfulGame:showPreWinnigIdle(clickItem,rewardType)
    local leftCount = self:getLeftRewrdCount(rewardType)
    if leftCount <= 1 then
        clickItem:showPreWinnigIdle()
        for index = 1,#self.m_items do
            local item = self.m_items[index]
            if item:isSameType(rewardType) then
                item:showPreWinnigIdle()
            end
        end
    end
    
end

--[[
    获取当前的奖励
]]
function BunnyBountyColorfulGame:getCurReward()
    local reward = self.m_rewardList[self.m_curClickIndex] or ""

    return string.lower(reward)
end

--[[
    显示未点击位置的奖励
]]
function BunnyBountyColorfulGame:showUnClickItemReward()
    local leftReward = {}
    for rewardType,count in pairs(self.m_left_item_counts) do
        for iCount = 1,count do
            leftReward[#leftReward + 1] = rewardType
        end
    end

    --打乱数组
    randomShuffle(leftReward)

    local unClickItems = self:getUnClickeItem()
    for index = 1,#leftReward do
        local rewardType = leftReward[index]
        local item = unClickItems[index]
        item:setSpineSkin(rewardType)
    end
end
--[[
    飞粒子动画
]]
function BunnyBountyColorfulGame:flyParticleAni(startNode,endNode,func)
    local flyNode = util_createAnimation("BunnyBounty_shoujilizi.csb")
    if flyNode:findChild("Particle_1") then
        flyNode:findChild("Particle_1"):setPositionType(0)
    end

    local startPos = util_convertToNodeSpace(startNode,self)
    local endPos = util_convertToNodeSpace(endNode,self)

    self:addChild(flyNode)
    flyNode:setPosition(startPos)

    local actionList = {
        cc.MoveTo:create(0.5,endPos),
        cc.CallFunc:create(function()
            if type(func) == "function" then
                func()
            end
            if flyNode:findChild("Particle_1") then
                flyNode:findChild("Particle_1"):stopSystem()
            end
        end),
        cc.DelayTime:create(1),
        cc.RemoveSelf:create()
    }
    flyNode:runAction(cc.Sequence:create(actionList))
end

--[[
    获取剩余的奖励数量
]]
function BunnyBountyColorfulGame:getLeftRewrdCount(rewardType)
    return self.m_left_item_counts[rewardType] or 3
end


return BunnyBountyColorfulGame