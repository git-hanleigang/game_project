---
--xcyy
--2018年5月23日
--OrcaCaptainColorfulGame.lua
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
local PublicConfig = require "OrcaCaptainPublicConfig"
local OrcaCaptainColorfulGame = class("OrcaCaptainColorfulGame",util_require("Levels.BaseLevelDialog"))

OrcaCaptainColorfulGame.m_bonusData = nil   --bonus数据
OrcaCaptainColorfulGame.m_endFunc = nil     --结束回调
OrcaCaptainColorfulGame.m_curClickIndex = 1 --当前点击的索引

local ITEM_COUNT            =           15          --可点击道具数量
local JACKPOT_TYPE = {"grand","mega","major","minor","mini"}

function OrcaCaptainColorfulGame:initUI(params)
    self.m_machine = params.machine

    self:createCsbNode("OrcaCaptain_dfdc_qipan.csb")

    --jackpot
    self.m_jackpotBar = util_createView("CodeOrcaCaptainSrc.OrcaCaptainColofulJackPotBar",{machine = self.m_machine})
    self:findChild("Node_jackpot"):addChild(self.m_jackpotBar)

    self.colorfulLogo = util_spineCreate("OrcaCaptain_LOGO", true, true)
    self:findChild("Node_LOGO"):addChild(self.colorfulLogo)
    self.colorfulLogo:setVisible(false)

    --定时节点
    self.m_scheduleNode = cc.Node:create()
    self:addChild(self.m_scheduleNode)

    --所有道具数组
    self.m_items = {}
    for index = 1,ITEM_COUNT do
        local parentNode = self:findChild("Node_coin_"..index)
        local item = util_createView("CodeOrcaCaptainSrc.OrcaCaptainColorfulItem",{
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

function OrcaCaptainColorfulGame:onExit()
    self:stopIdleAni()
    OrcaCaptainColorfulGame.super.onExit(self)
end

--[[
    开启定时idle
]]
function OrcaCaptainColorfulGame:startIdleAni()
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
        self:startIdleAni()
    end,8)
end

--[[
    停止定时idle
]]
function OrcaCaptainColorfulGame:stopIdleAni()
    self.m_scheduleNode:stopAllActions()
end

--[[
    获取还未点击位置
]]
function OrcaCaptainColorfulGame:getUnClickeItem()
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
function OrcaCaptainColorfulGame:setBonusData(bonusData,endFunc)
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
function OrcaCaptainColorfulGame:resetView(bonusData,endFunc)
    self:setBonusData(bonusData,endFunc)
    self.m_jackpotBar:resetView()
    for index,item in ipairs(self.m_items) do
        item:resetStatus()
    end
end

--[[
    显示界面(执行start时间线)
]]
function OrcaCaptainColorfulGame:showView(func)
    self.colorfulLogo:setVisible(true)
    util_spinePlay(self.colorfulLogo, "idleframe",true)
    -- self:setVisible(true)
    -- self:runCsbAction("start",false,function()
        self:startIdleAni()
        if type(func) == "function" then
            func()
        end
    -- end)
    
end

--[[
    隐藏界面(执行over时间线)
]]
function OrcaCaptainColorfulGame:hideView(func)
    self:runCsbAction("over",false,function()
        self:setVisible(false)
        if type(func) == "funciton" then
            func()
        end
    end)
    
end

--[[
    点击道具回调
]]
function OrcaCaptainColorfulGame:clickItem(clickItem)
    if self.m_isEnd then
        return
    end
    --获取当前点击的的奖励
    local rewardType = self:getCurReward()

    --收集到jackpot上
    local process = self.m_jackpotBar:getProcessByType(rewardType)
    local pointNode = self.m_jackpotBar:getFeedBackPoint(rewardType,process)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OrcaCaptain_color_collect_fly)
    self:flyParticleAni(clickItem,pointNode,function()
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OrcaCaptain_color_collect_fankui)
        self.m_jackpotBar:collectFeedBackAni(rewardType,pointNode)
    end)

    --累加点击索引
    self.m_curClickIndex  = self.m_curClickIndex + 1

    --减少剩余奖励数量
    self.m_left_item_counts[rewardType] = self.m_left_item_counts[rewardType] - 1

    --游戏结束
    if self.m_curClickIndex > #self.m_rewardList then
        self.m_isEnd = true
        --停止idle定时器
        self:stopIdleAni()
    end

    --刷新点击位置的道具显示
    if not self.m_isEnd then
        clickItem:showRewardAni(rewardType)
    else
        --游戏结束
        clickItem:showRewardAni(rewardType,function()
            --显示其他未点击的位置的奖励
            self:showUnClickItemReward()
            --显示jackpot上的中奖光效(未中奖的压黑)
            self.m_jackpotBar:showHitLight(self.m_bonusData.winJackpot)

            --显示中奖动效
            self:showHitJackpotAni(rewardType,function()
                --展示jackpotWin
                self.m_machine:showJackpotView(function ()
                    if type(self.m_endFunc) == "function" then
                        self.m_endFunc()
                    end
                end)
            end)
        end)
    end
end

--[[
    显示中奖动效
]]
function OrcaCaptainColorfulGame:showHitJackpotAni(winType,func)
    for index = 1,#self.m_items do
        local item = self.m_items[index]
        --未中奖的压黑
        if not item:isSameType(winType) then
            item:runDarkAni()
        else
            item:getRewardAni()
        end
    end

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
function OrcaCaptainColorfulGame:getCurReward()
    local reward = self.m_rewardList[self.m_curClickIndex] or ""

    --防止服务器数据大小写不统一,一律转化为小写
    return string.lower(reward)
end

--[[
    显示未点击位置的奖励
]]
function OrcaCaptainColorfulGame:showUnClickItemReward()
    local leftReward = {}
    --计算还没有点出来的jackpot
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
        item:setJackpotTypeShow(rewardType)
    end
end
--[[
    飞粒子动画
]]
function OrcaCaptainColorfulGame:flyParticleAni(startNode,endNode,func)
    local flyNode = util_createAnimation("OrcaCaptain_jackpot_lizi.csb")
    if flyNode:findChild("Particle_1") then --粒子必须判空,线上有获取不到的情况,原因不明
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
            if flyNode:findChild("Particle_1") then--粒子必须判空,线上有获取不到的情况,原因不明
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
function OrcaCaptainColorfulGame:getLeftRewrdCount(rewardType)
    return self.m_left_item_counts[rewardType] or 3
end


return OrcaCaptainColorfulGame