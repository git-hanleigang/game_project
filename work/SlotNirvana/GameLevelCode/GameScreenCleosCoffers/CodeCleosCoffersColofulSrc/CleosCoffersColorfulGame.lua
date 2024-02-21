---
--xcyy
--2018年5月23日
--CleosCoffersColorfulGame.lua
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
local PublicConfig = require "CleosCoffersPublicConfig"
local CleosCoffersColorfulGame = class("CleosCoffersColorfulGame",util_require("Levels.BaseLevelDialog"))

CleosCoffersColorfulGame.m_bonusData = nil   --bonus数据
CleosCoffersColorfulGame.m_endFunc = nil     --结束回调
CleosCoffersColorfulGame.m_curClickIndex = 1 --当前点击的索引

local ITEM_COUNT            =           18          --可点击道具数量
local JACKPOT_TYPE = {"grand", "mega", "major", "minor", "mini"}

function CleosCoffersColorfulGame:initUI(params)
    self.m_machine = params.machine

    self:createCsbNode("CleosCoffers/ColorfulGame.csb")

    --jackpot
    self.m_jackpotBar = util_createView("CodeCleosCoffersColofulSrc.CleosCoffersColofulJackPotBar",{machine = self.m_machine})
    self:findChild("Node_dfdc_jackpot"):addChild(self.m_jackpotBar)

    --jackpot
    self.m_boostBarView = util_createView("CodeCleosCoffersColofulSrc.CleosCoffersColorfulBoostBar",{machine = self.m_machine})
    self:findChild("Node_dfdc_boostbar"):addChild(self.m_boostBarView)

    --定时节点
    self.m_scheduleNode = cc.Node:create()
    self:addChild(self.m_scheduleNode)

    --所有道具数组
    self.m_items = {}
    for index = 1,ITEM_COUNT do
        local parentNode = self:findChild("Node_"..index)
        local item = util_createView("CodeCleosCoffersColofulSrc.CleosCoffersColorfulItem",{
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
function CleosCoffersColorfulGame:startIdleAni()
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
    performWithDelay(self.m_scheduleNode, function()
        self:startIdleAni()
    end, 5)
end

--[[
    停止定时idle
]]
function CleosCoffersColorfulGame:stopIdleAni()
    self.m_scheduleNode:stopAllActions()
end

--[[
    获取还未点击位置
]]
function CleosCoffersColorfulGame:getUnClickeItem()
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
function CleosCoffersColorfulGame:setBonusData(bonusData,endFunc)
    self.m_bonusData = bonusData
    --兼容数据格式,可根据具体的数据调整
    self.m_rewardList = bonusData.process
    -- 奖励配置
    self.m_allRewardList = bonusData.jackpot_list
    -- jackpot倍速
    self.m_jackpotmulList = bonusData.jackpotmulList
    self.m_endFunc = endFunc
    --当前点击的索引
    self.m_curClickIndex = 1
    --当前是否结束
    self.m_isEnd = false
    -- 当前点出remove是否可以点击
    self.m_isBuffClick = false
    -- 当前点击的remove索引
    self.m_buffTypeIndex = 0
    -- 所有的buff类型
    self.m_buffRewardList = {}
    for index, buffName in pairs(self.m_allRewardList) do
        if self:curRewardTypeIsBuff(string.lower(buffName), true) then
            table.insert(self.m_buffRewardList, buffName)
        end
    end
    --重置收集剩余数量
    for index,jackpotType in pairs(JACKPOT_TYPE) do
        self.m_left_item_counts[jackpotType] = 3
    end
    self.m_boostBarView:setVisible(false)
    self.m_jackpotBar:setOldMul(1)
    self.m_jackpotBar:setNewMul(1)
end

--[[
    重置界面显示
]]
function CleosCoffersColorfulGame:resetView(bonusData,endFunc)
    self:setBonusData(bonusData,endFunc)
    self.m_jackpotBar:resetView()
    for index,item in ipairs(self.m_items) do
        item:resetStatus()
        item:setVisible(false)
    end
end

-- 时间线第145帧，控制创建pick选项
function CleosCoffersColorfulGame:showPickItem()
    for index,item in ipairs(self.m_items) do
        item:setVisible(true)
    end
end

--[[
    显示界面(执行start时间线)
]]
function CleosCoffersColorfulGame:showView(func)
    self:setVisible(true)
    self:runCsbAction("start",false,function()
        self:startIdleAni()
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    隐藏界面(执行over时间线)
]]
function CleosCoffersColorfulGame:hideView(func)
    self:runCsbAction("over",false,function()
        self:setVisible(false)
        if type(func) == "funciton" then
            func()
        end
    end)
end

--获取当前boost奖励类型
function CleosCoffersColorfulGame:curRewardTypeIsBuff(_rewardType, _isInit)
    if _rewardType == "buff_boost" or _rewardType == "buff_mega" or _rewardType == "buff_super" then
        if not _isInit then
            for index, buffName in pairs(self.m_buffRewardList) do
                if _rewardType == string.lower(buffName) then
                    table.remove(self.m_buffRewardList, index)
                end
            end
        end
        return true
    end
    return false
end

-- 获取当前jackpot奖励
function CleosCoffersColorfulGame:getCurJackpotMul()
    local curMul = 1
    if self.m_jackpotmulList[self.m_buffTypeIndex] then
        curMul = self.m_jackpotmulList[self.m_buffTypeIndex]
    end

    return curMul
end

--[[
    点击道具回调
]]
function CleosCoffersColorfulGame:clickItem(clickItem)
    if self.m_isEnd then
        return
    end
    --获取当前点击的的奖励
    local rewardType = self:getCurReward()
    if self:curRewardTypeIsBuff(rewardType) then
        self.m_buffTypeIndex = self.m_buffTypeIndex + 1
        self.m_isBuffClick = true
    else
        -- --收集到jackpot上
        -- local process = self.m_jackpotBar:getProcessByType(rewardType)
        -- local pointNode = self.m_jackpotBar:getFeedBackPoint(rewardType,process)
        -- self:flyParticleAni(clickItem,pointNode,function()
        --     self.m_jackpotBar:collectFeedBackAni(rewardType,pointNode)
        -- end)

        --减少剩余奖励数量
        self.m_left_item_counts[rewardType] = self.m_left_item_counts[rewardType] - 1
        self.m_isBuffClick = false
    end

    --累加点击索引
    self.m_curClickIndex  = self.m_curClickIndex + 1

    --游戏结束
    if self.m_curClickIndex > #self.m_rewardList then
        self.m_isEnd = true
        --停止idle定时器
        self:stopIdleAni()
    end

    --刷新点击位置的道具显示
    if not self.m_isEnd then
        clickItem:showRewardAni(rewardType, function()
            if not self:curRewardTypeIsBuff(rewardType) then
                --收集到jackpot上
                local process = self.m_jackpotBar:getProcessByType(rewardType)
                local pointNode = self.m_jackpotBar:getFeedBackPoint(rewardType,process)
                self:flyParticleAni(clickItem,pointNode,function()
                    self.m_jackpotBar:collectFeedBackAni(rewardType,pointNode)
                end)
            end
        end)
    else
        --游戏结束
        clickItem:showRewardAni(rewardType,function()
            if self:curRewardTypeIsBuff(rewardType) then
                self:showEndJackpotEffect(rewardType)
            else
                --收集到jackpot上
                local process = self.m_jackpotBar:getProcessByType(rewardType)
                local pointNode = self.m_jackpotBar:getFeedBackPoint(rewardType,process)
                self:flyParticleAni(clickItem,pointNode,function()
                    self.m_jackpotBar:collectFeedBackAni(rewardType,pointNode)
                    performWithDelay(self, function()
                        self:showEndJackpotEffect(rewardType)
                    end, 0.5)
                end)
            end
        end)
    end
end

function CleosCoffersColorfulGame:showEndJackpotEffect(_rewardType)
    local rewardType = _rewardType
    --显示jackpot上的中奖光效(未中奖的压黑)
    self.m_jackpotBar:showHitLight(self.m_bonusData.win_jackpot[1])

    performWithDelay(self, function()
        --显示其他未点击的位置的奖励
        self:showUnClickItemReward()
        
        --显示中奖动效
        self:showHitJackpotAni(rewardType,function()
            if type(self.m_endFunc) == "function" then
                self.m_endFunc()
            end
        end)
    end, 1.5)
end

-- 翻出boost，jackpot加成
function CleosCoffersColorfulGame:addJackpotReward(_itemID)
    local curMul = self:getCurJackpotMul()
    self.m_boostBarView:runStartAni(curMul)
    -- 显示jackpot加成
    self.m_jackpotBar:showAddJackpotHitLight()
    self.m_jackpotBar:setNewMul(curMul+1, true)
    self.m_machine:setAddJackptState(true)
    self.m_machine:delayCallBack(2.0, function()
        self.m_isBuffClick = false
    end)
end

--[[
    显示中奖动效
]]
function CleosCoffersColorfulGame:showHitJackpotAni(winType,func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_Pick_JackpotTrigger)
    for index = 1,#self.m_items do
        local item = self.m_items[index]
        --未中奖的压黑
        if not item:isSameType(winType) then
            item:runDarkAni()
        else
            item:getRewardAni()
        end
    end

    -- 除去触发；其余的reset
    self.m_jackpotBar:resetTriggerView(winType)
    --结果多展示一会(延迟为中奖时间时间线长度+0.5s)
    performWithDelay(self,function()
        if type(func) == "function" then
            func()
        end
    end,2)
end

--[[
    获取当前的奖励
]]
function CleosCoffersColorfulGame:getCurReward()
    local reward = self.m_rewardList[self.m_curClickIndex] or ""

    --防止服务器数据大小写不统一,一律转化为小写
    return string.lower(reward)
end

--[[
    显示未点击位置的奖励
]]
function CleosCoffersColorfulGame:showUnClickItemReward()
    local leftReward = {}
    --计算还没有点出来的jackpot
    for rewardType,count in pairs(self.m_left_item_counts) do
        for iCount = 1,count do
            leftReward[#leftReward + 1] = rewardType
        end
    end

    -- 添加剩余的buff
    if self.m_buffRewardList and next(self.m_buffRewardList) then
        for index, buffName in pairs(self.m_buffRewardList) do
            leftReward[#leftReward + 1] = string.lower(buffName)
        end
    end

    --打乱数组
    randomShuffle(leftReward)

    local unClickItems = self:getUnClickeItem()
    for index = 1,#leftReward do
        local rewardType = leftReward[index]
        local item = unClickItems[index]
        -- item:setJackpotTypeShow(rewardType)
        item:showRewardAni(rewardType)
    end
end
--[[
    飞粒子动画
]]
function CleosCoffersColorfulGame:flyParticleAni(startNode,endNode,func)
    local flyNode = util_createAnimation("CleosCoffers_fly.csb")
    local particleTbl = {}
    for i=1, 3 do
        local particle = flyNode:findChild("Particle_"..i)
        if not tolua.isnull(particle) then
            particle:setPositionType(0)
            table.insert(particleTbl, particle)
        end
    end

    local startPos = util_convertToNodeSpace(startNode,self)
    local endPos = util_convertToNodeSpace(endNode,self)

    self:addChild(flyNode)
    flyNode:setPosition(startPos)

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_Pick_Collect)
    local actionList = {
        cc.MoveTo:create(0.5,endPos),
        cc.CallFunc:create(function()
            if type(func) == "function" then
                func()
            end
            for i=1, #particleTbl do
                if not tolua.isnull(particleTbl[i]) then
                    particleTbl[i]:stopSystem()
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
function CleosCoffersColorfulGame:getLeftRewrdCount(rewardType)
    return self.m_left_item_counts[rewardType] or 3
end


return CleosCoffersColorfulGame