---
--xcyy
--2018年5月23日
--RobinIsHoodColorfulGame.lua
--多福多彩
--[[
    使用方式
    需要在调用时构造参数,具体如下:
    local bonusData = {
        rewardList = selfData.cards,
        winJackpot = jackpotType
    }

    --在调用showView之前需重置界面显示
    local endFunc = function()
    
    end
    self.m_colorfulGameView:resetView(bonusData,endFunc)
    self.m_colorfulGameView:showView()
]]
local PublicConfig = require "RobinIsHoodPublicConfig"
local RobinIsHoodColorfulGame = class("RobinIsHoodColorfulGame",util_require("Levels.BaseLevelDialog"))

RobinIsHoodColorfulGame.m_bonusData = nil   --bonus数据
RobinIsHoodColorfulGame.m_endFunc = nil     --结束回调
RobinIsHoodColorfulGame.m_curClickIndex = 1 --当前点击的索引

local ITEM_COUNT            =           12          --可点击道具数量
local JACKPOT_TYPE = {"grand","major","minor","mini"}

function RobinIsHoodColorfulGame:initUI(params)
    self.m_machine = params.machine

    self:createCsbNode("RobinIsHood/GameScreenRobinIsHood_dfdc.csb")

    --jackpot
    self.m_jackpotBar = util_createView("CodeRobinIsHoodSrc.RobinIsHoodColofulJackPotBar",{machine = self.m_machine})
    self:findChild("Node_jackpotbar_dfdc"):addChild(self.m_jackpotBar)

    self.m_tip = util_createAnimation("RobinIsHood_dfdc_respin.csb")
    self:findChild("Node_respin"):addChild(self.m_tip)

    --定时节点
    self.m_scheduleNode = cc.Node:create()
    self:addChild(self.m_scheduleNode)

    --所有道具数组
    self.m_items = {}
    local parentNode = self:findChild("Panel_pick_jackpot")
    local parentSize = parentNode:getContentSize()
    local itemWidth = parentSize.width / 4
    local itemHeight = parentSize.height / 3
    for index = 1,ITEM_COUNT do
        
        local item = util_createView("CodeRobinIsHoodSrc.RobinIsHoodColorfulItem",{
            parentView = self,
            itemID = index
        })

        parentNode:addChild(item)
        local colIndex = (index - 1) % 4
        local rowIndex = math.floor((index - 1) / 4) 
        local posX = (colIndex + 0.5) * itemWidth
        local posY = parentSize.height - (rowIndex + 0.5) * itemHeight
        item:setPosition(cc.p(posX,posY))
        
        self.m_items[index] = item
    end

    self.m_left_item_counts = {}
end

--[[
    开启定时idle
]]
function RobinIsHoodColorfulGame:startIdleAni()
    self:stopIdleAni()
    performWithDelay(self.m_scheduleNode,function()
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
        self:startIdleAni()
    end,5)
end

--[[
    停止定时idle
]]
function RobinIsHoodColorfulGame:stopIdleAni()
    self.m_scheduleNode:stopAllActions()
end

--[[
    获取还未点击位置
]]
function RobinIsHoodColorfulGame:getUnClickeItem()
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

    bonusData数据结构如下,需手动拼接数据结构
    {
        rewardList = selfData.cards,
        winJackpot = jackpotType
    }
]]
function RobinIsHoodColorfulGame:setBonusData(bonusData,endFunc)
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
    self.m_isNotice = false
end

--[[
    重置界面显示
]]
function RobinIsHoodColorfulGame:resetView(bonusData,endFunc)
    self:setClickEnabled(false)
    self:setBonusData(bonusData,endFunc)
    self.m_jackpotBar:resetView()
    for index,item in ipairs(self.m_items) do
        item:resetStatus()
    end
end

--[[
    设置点击状态
]]
function RobinIsHoodColorfulGame:setClickEnabled(isEnabled)
    self.m_clickEnabled = isEnabled
end

--[[
    显示界面(执行start时间线)
]]
function RobinIsHoodColorfulGame:showView(func)
    self:setVisible(true)
    self:startIdleAni()
    -- self:runCsbAction("start",false,function()
    --     self:startIdleAni()
    --     if type(func) == "function" then
    --         func()
    --     end
    -- end)
    
end

--[[
    隐藏界面(执行over时间线)
]]
function RobinIsHoodColorfulGame:hideView(func)
    self:setVisible(false)
    -- self:runCsbAction("over",false,function()
    --     self:setVisible(false)
    --     if type(func) == "funciton" then
    --         func()
    --     end
    -- end)
end

--[[
    点击道具回调
]]
function RobinIsHoodColorfulGame:clickItem(clickItem)
    if self.m_isEnd or not self.m_clickEnabled then
        return
    end
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_RobinIsHood_click_colorful_item)
    --获取当前点击的的奖励
    local rewardType = self:getCurReward()

    --累加点击索引
    self.m_curClickIndex  = self.m_curClickIndex + 1

    if not self.m_isNotice then
        for k,count in pairs(self.m_left_item_counts) do
            if count <= 1 then
                self.m_isNotice = true
                break
            end
        end
    end
    
    

    --减少剩余奖励数量
    self.m_left_item_counts[rewardType] = self.m_left_item_counts[rewardType] - 1

    --游戏结束
    if self.m_curClickIndex > #self.m_rewardList then
        self.m_isEnd = true
        
    end

    --停止idle定时器
    self:stopIdleAni()

    local delayTime = 12 / 30
    if self.m_isNotice  then
        delayTime = 22 / 30
    end

    self.m_machine:delayCallBack(delayTime,function()
        --收集到jackpot上
        local process = self.m_jackpotBar:getProcessByType(rewardType)
        local pointNode = self.m_jackpotBar:getFeedBackPoint(rewardType,process)
        self:flyParticleAni(clickItem,pointNode,rewardType,function()
            self.m_jackpotBar:collectFeedBackAni(rewardType,pointNode)
            
        end)
    end)
    
    

    --刷新点击位置的道具显示
    if not self.m_isEnd then
        clickItem:showRewardAni(rewardType,self.m_isNotice,function()
            
        end)
        --重新计算idle时间
        self:startIdleAni()
    else
        --游戏结束
        clickItem:showRewardAni(rewardType,self.m_isNotice,function()
            --显示其他未点击的位置的奖励
            self:showUnClickItemReward(function()
                gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_RobinIsHood_hit_jackpot_reward"])
                --显示jackpot上的中奖光效
                self.m_jackpotBar:showHitLight(self.m_bonusData.winJackpot)
                --显示中奖动效
                self:showHitJackpotAni(rewardType,function()
                    
                    self.m_machine:delayCallBack(1,function()
                        if type(self.m_endFunc) == "function" then
                            self.m_endFunc()
                        end
                    end)
                    
                end)
            end)
            
        end)
    end
end

--[[
    显示中奖动效
]]
function RobinIsHoodColorfulGame:showHitJackpotAni(winType,func)
    local delayTime = 0
    for index = 1,#self.m_items do
        local item = self.m_items[index]
        --未中奖的压黑
        if not item:isSameType(winType) then
            item:runDarkAni()
        else
            delayTime = item:getRewardAni()
        end
    end

    delayTime  = delayTime + 0.5
    --结果多展示一会(延迟为中奖时间时间线长度+0.5s)
    performWithDelay(self,function()
        if type(func) == "function" then
            func()
        end
    end,delayTime)
end

--[[
    获取当前的奖励
]]
function RobinIsHoodColorfulGame:getCurReward()
    local reward = self.m_rewardList[self.m_curClickIndex] or ""

    --防止服务器数据大小写不统一,一律转化为小写
    return string.lower(reward)
end

--[[
    显示未点击位置的奖励
]]
function RobinIsHoodColorfulGame:showUnClickItemReward(func)
    local leftReward = {}
    --计算还没有点出来的jackpot
    for rewardType,count in pairs(self.m_left_item_counts) do
        for iCount = 1,count do
            leftReward[#leftReward + 1] = rewardType
        end
    end

    --打乱数组
    randomShuffle(leftReward)


    local delayTime = 0
    local unClickItems = self:getUnClickeItem()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_RobinIsHood_turn_unclick_item"])
    for index = 1,#leftReward do
        local rewardType = leftReward[index]
        local item = unClickItems[index]
        delayTime = item:runUnClickDarkAni(rewardType)
    end
    self.m_machine:delayCallBack(delayTime,func)
end
--[[
    飞粒子动画
]]
function RobinIsHoodColorfulGame:flyParticleAni(startNode,endNode,jackpotType,func)
    local flyNode = util_createAnimation("RobinIsHood_dfdc_shouji_lizi.csb")
    for index = 1,5 do
        local particle = flyNode:findChild("Particle_"..index)
        if not tolua.isnull(particle) then
            particle:setPositionType(0)
            local extraParticle = flyNode:findChild("Particle_1_0")
            if not tolua.isnull(extraParticle) then
                extraParticle:setPositionType(0)
                extraParticle:setVisible(index == 1)
            end
            if index == 1 then
                particle:setVisible(true)
            elseif index == 2 then
                particle:setVisible(jackpotType == "grand")
            elseif index == 3 then
                particle:setVisible(jackpotType == "major")
            elseif index == 4 then
                particle:setVisible(jackpotType == "minor")
            elseif index == 5 then
                particle:setVisible(jackpotType == "mini")
            else
                particle:setVisible(false)
            end
            
        end
    end

    local startPos = util_convertToNodeSpace(startNode,self)
    local endPos = util_convertToNodeSpace(endNode,self)

    self:addChild(flyNode)
    flyNode:setPosition(startPos)

    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_RobinIsHood_collect_jp_to_bar"])
    local actionList = {
        cc.MoveTo:create(0.5,endPos),
        cc.CallFunc:create(function()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_RobinIsHood_collect_jp_to_bar_feed_back"])
            if type(func) == "function" then
                func()
            end
            for index = 1,5 do
                local particle = flyNode:findChild("Particle_"..index)
                if not tolua.isnull(particle) then
                    particle:stopSystem()
                end
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
function RobinIsHoodColorfulGame:getLeftRewrdCount(rewardType)
    return self.m_left_item_counts[rewardType] or 3
end


return RobinIsHoodColorfulGame