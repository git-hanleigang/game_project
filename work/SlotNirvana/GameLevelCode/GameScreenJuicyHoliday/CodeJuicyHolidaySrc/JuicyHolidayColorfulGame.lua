---
--xcyy
--2018年5月23日
--JuicyHolidayColorfulGame.lua
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
local PublicConfig = require "JuicyHolidayPublicConfig"
local JuicyHolidayColorfulGame = class("JuicyHolidayColorfulGame",util_require("Levels.BaseLevelDialog"))

JuicyHolidayColorfulGame.m_bonusData = nil   --bonus数据
JuicyHolidayColorfulGame.m_endFunc = nil     --结束回调
JuicyHolidayColorfulGame.m_curClickIndex = 1 --当前点击的索引

local ITEM_COUNT            =           12          --可点击道具数量
local JACKPOT_TYPE = {"grand","major","minor","mini"}

function JuicyHolidayColorfulGame:initUI(params)
    self.m_machine = params.machine

    self:createCsbNode("JuicyHoliday_jackpot.csb")

    --jackpot
    self.m_jackpotBar = util_createView("CodeJuicyHolidaySrc.JuicyHolidayColofulJackPotBar",{machine = self.m_machine})
    self:findChild("Node_jackpot"):addChild(self.m_jackpotBar)

    --定时节点
    self.m_scheduleNode = cc.Node:create()
    self:addChild(self.m_scheduleNode)

    --所有道具数组
    self.m_items = {}

    for index = 1,ITEM_COUNT do
        
        local item = util_createView("CodeJuicyHolidaySrc.JuicyHolidayColorfulItem",{
            parentView = self,
            itemID = index
        })
        local parentNode = self:findChild("Node_jinbi_"..index)
        parentNode:addChild(item)
        
        self.m_items[index] = item
    end

    self.m_left_item_counts = {}
end

--[[
    开启定时idle
]]
function JuicyHolidayColorfulGame:startIdleAni()
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
function JuicyHolidayColorfulGame:stopIdleAni()
    self.m_scheduleNode:stopAllActions()
end

--[[
    获取还未点击位置
]]
function JuicyHolidayColorfulGame:getUnClickeItem()
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
function JuicyHolidayColorfulGame:setBonusData(bonusData,endFunc)
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
function JuicyHolidayColorfulGame:resetView(bonusData,endFunc)
    self:setBonusData(bonusData,endFunc)
    self.m_jackpotBar:resetView()
    for index,item in ipairs(self.m_items) do
        item:resetStatus()
    end
end

--[[
    显示界面(执行start时间线)
]]
function JuicyHolidayColorfulGame:showView(func)
    self:setVisible(true)
    self:startIdleAni()
end

--[[
    隐藏界面(执行over时间线)
]]
function JuicyHolidayColorfulGame:hideView(func)
    self:setVisible(false)
end

--[[
    点击道具回调
]]
function JuicyHolidayColorfulGame:clickItem(clickItem)
    if self.m_isEnd then
        return
    end
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JuicyHoliday_click_colorful_item"])
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
            for index = 1,#self.m_items do
                local item = self.m_items[index]
                if item.m_curRewardType == rewardType and self.m_left_item_counts[rewardType] <= 1 then
                    item:runNoticeIdle()
                end
            end
            
        end)
        --重新计算idle时间
        self:startIdleAni()
    else
        --游戏结束
        clickItem:showRewardAni(rewardType,self.m_isNotice,function()
            --显示其他未点击的位置的奖励
            self:showUnClickItemReward(function()
                --显示jackpot上的中奖光效
                self.m_jackpotBar:showHitLight(self.m_bonusData.winJackpot)
                --显示中奖动效
                self:showHitJackpotAni(rewardType,function()
                    
                    if type(self.m_endFunc) == "function" then
                        self.m_endFunc()
                    end
                    
                end)
            end)

            self:noticeItemChangeIdle()
            
        end)
    end
end

--[[
    提示动效转idle
]]
function JuicyHolidayColorfulGame:noticeItemChangeIdle()
    for index = 1,#self.m_items do
        local item = self.m_items[index]
        item:changeIdle()
    end
end

--[[
    显示中奖动效
]]
function JuicyHolidayColorfulGame:showHitJackpotAni(winType,func)
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

    --第75帧显示jackpot弹板
    delayTime  = 75 / 30
    performWithDelay(self,function()
        if type(func) == "function" then
            func()
        end
    end,delayTime)
end

--[[
    获取当前的奖励
]]
function JuicyHolidayColorfulGame:getCurReward()
    local reward = self.m_rewardList[self.m_curClickIndex] or ""

    --防止服务器数据大小写不统一,一律转化为小写
    return string.lower(reward)
end

--[[
    显示未点击位置的奖励
]]
function JuicyHolidayColorfulGame:showUnClickItemReward(func)
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
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JuicyHoliday_show_unclick_item_reward"])
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
function JuicyHolidayColorfulGame:flyParticleAni(startNode,endNode,jackpotType,func)
    local flyNode = util_createAnimation("JuicyHoliday_bufflz.csb")
    for i,jpType in ipairs(JACKPOT_TYPE) do
        flyNode:findChild("Node_"..jpType):setVisible(jackpotType == jpType)
        for index = 1,2 do
            local particle = flyNode:findChild("Particle_"..jackpotType.."_"..index)
            if not tolua.isnull(particle) then
                particle:setPositionType(0)
            end
        end
    end

    local startPos = util_convertToNodeSpace(startNode,self)
    local endPos = util_convertToNodeSpace(endNode,self)

    self:addChild(flyNode)
    flyNode:setPosition(startPos)

    local actionList = {
        -- cc.EaseCubicActionIn:create(cc.MoveTo:create(0.5,endPos)),
        cc.EaseSineIn:create(cc.MoveTo:create(0.5,endPos)),
        -- cc.EaseExponentialIn:create(cc.MoveTo:create(0.5,endPos)),
        cc.CallFunc:create(function()
            if type(func) == "function" then
                func()
            end
            for index = 1,2 do
                local particle = flyNode:findChild("Particle_"..jackpotType.."_"..index)
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
function JuicyHolidayColorfulGame:getLeftRewrdCount(rewardType)
    return self.m_left_item_counts[rewardType] or 3
end


return JuicyHolidayColorfulGame