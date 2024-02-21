---
--xcyy
--2018年5月23日
--JungleJauntColorfulGame.lua
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
local PBC = require "JungleJauntPublicConfig"
local JungleJauntColorfulGame = class("JungleJauntColorfulGame",util_require("Levels.BaseLevelDialog"))

JungleJauntColorfulGame.m_bonusData = nil   --bonus数据
JungleJauntColorfulGame.m_endFunc = nil     --结束回调
JungleJauntColorfulGame.m_curClickIndex = 1 --当前点击的索引

local ITEM_COUNT = 9   --可点击道具数量

function JungleJauntColorfulGame:initUI(params)
    self.m_machine = params.machine

    self:createCsbNode("JungleJaunt_base_buff1.csb")

    --所有道具数组
    self.m_items = {}
    for index = 1,ITEM_COUNT do
        local parentNode = self:findChild("bianfu"..index)
        local item = util_createView("JungleJauntSrc.PickGame.JungleJauntColorfulItem",{
            parentView = self,
            itemID = index
        })

        item:setRoadMain(self)
        if parentNode then
            parentNode:addChild(item)
        else
            self:addChild(item)
        end
        self.m_items[index] = item
    end

end

function JungleJauntColorfulGame:initSpineUI()

    self.m_showViewTX = util_spineCreate("JungleJaunt_base_buff1tx",true,true)
    self.m_machine:findChild("base_buff1TX"):addChild(self.m_showViewTX)
    self.m_showViewTX:setVisible(false)

end

--[[
    设置bonus数据

    bonusData数据结构如下,需手动拼接数据结构
    {
        rewardList = selfData.cards,
        winJackpot = jackpotType
    }
]]
function JungleJauntColorfulGame:setBonusData(bonusData,endFunc)
    self.m_bonusData = bonusData
    --兼容数据格式,可根据具体的数据调整
    self.m_rewardList = bonusData
    self.m_endFunc = endFunc
    --当前点击的索引
    self.m_curClickIndex = 1
    --当前是否结束
    self.m_isEnd = false
    --当前是否可以点击
    self.m_isEndClick = false
    -- 当前收集的倍数
    self.m_totalMul = 0
end

--[[
    重置界面显示
]]
function JungleJauntColorfulGame:resetView(bonusData,endFunc)
    self:updateMainMulLab("X0")
    self:setBonusData(bonusData,endFunc)
    for index,item in ipairs(self.m_items) do
        item:resetStatus()
    end
end

--[[
    显示界面(执行start时间线)
]]
function JungleJauntColorfulGame:showView(func)

    self.m_showViewTX:setVisible(true)
    util_spinePlay(self.m_showViewTX,"switch2")
    util_spineEndCallFunc(self.m_showViewTX,"switch2",function()
        self.m_showViewTX:setVisible(false)
    end)


    self:setVisible(true)
    self:runCsbAction("start",false,function()
        if type(func) == "function" then
            func()
        end
    end)
    local time = 0
    for index,item in ipairs(self.m_items) do
        time = util_max(item:showAinm(),time)
    end
    time = util_max(util_csbGetAnimTimes(self.m_csbAct, "start"),time) 
    performWithDelay(self,function()
        for index,item in ipairs(self.m_items) do
            item:beginClick()
        end
    end,time)
    
end

--[[
    隐藏界面(执行over时间线)
]]
function JungleJauntColorfulGame:hideView(func)
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
function JungleJauntColorfulGame:clickItemFunc(clickItem)

    gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_5)

    -- 当前点击节点的ID
    self.m_currItemID = clickItem.m_itemID

    local curClickIndex = self.m_curClickIndex
    if curClickIndex == #self.m_rewardList - 1 then
        self.m_isEndClick = true
    end

    --获取当前点击的的奖励
    local rewardType = self:getCurReward()
    --累加点击索引
    self.m_curClickIndex  = self.m_curClickIndex + 1
    
    --游戏结束
    if self.m_curClickIndex > #self.m_rewardList then
        self.m_isEnd = true
    end

    --刷新点击位置的道具显示
    if not self.m_isEnd then
        self.m_totalMul = self.m_totalMul + rewardType
        clickItem:showRewardAni(rewardType,function()
            self:flyParticleAni(rewardType,clickItem,self:findChild("Node_205"),function()
                if curClickIndex == #self.m_rewardList - 1 then
                    self.m_isEndClick = false
                end
            end)
        end,self.m_isEnd)
    else
        --游戏结束
        clickItem:setHitBonusTypeShow(rewardType)
        --显示中奖动效
        self:showHitBonusAni(function()
                
            if type(self.m_endFunc) == "function" then
                self.m_endFunc()
            end
        end)  
    end
end

--[[
    显示中奖动效
]]
function JungleJauntColorfulGame:showHitBonusAni(func)


    local coinsItem = nil
    for index,item in ipairs(self.m_items) do
        if self.m_currItemID ~= item.m_itemID then
            item:noClickItemOver()
        else
            coinsItem = item
        end
    end

    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local currCoins = coinsItem.m_curRewardType
    local totalCoins = selfData.dice_game1_win
    coinsItem:playEndRewardAni(currCoins,totalCoins,function()

        performWithDelay(self,function()

            gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_25)
            if not self.m_overBat then
                self.m_overBat = util_spineCreate("JungleJaunt_base_buff1_sp",true,true)
                self.m_machine:addChild( self.m_overBat,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
                self.m_overBat:setScale(self.m_machine.m_machineRootScale)
                local endPos = util_convertToNodeSpace(self:findChild("bianfu"),self.m_machine)
                self.m_overBat:setPosition(endPos)
            end
            self:runCsbAction("shouji3")
            -- self.m_overBat:setVisible(false)
            util_spinePlay(self.m_overBat,"actionframe_jiesuan")
            util_spineEndCallFunc(self.m_overBat,"actionframe_jiesuan",function()
                self.m_overBat:setVisible(false)
            end)
            util_spinePlay(coinsItem.m_spine,"actionframe_jiesuan")

            performWithDelay(coinsItem.m_spine,function()
                coinsItem.m_spine:setVisible(false)
                self.m_overBat:setVisible(true)
            
                performWithDelay(self.m_overBat,function()

                    gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_26)
                    -- 更新下UI赢钱 -- 添加大赢:直接用Base的即可
                    
                    self.m_machine:playCoinWinEffectUI()

                    local winCoins = self.m_machine.m_runSpinResultData.p_winAmount
                    self.m_machine:setLastWinCoin(winCoins)

                    local params = {selfData.dice_game1_win, true, true}
                    params[self.m_machine.m_stopUpdateCoinsSoundIndex] = true
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)

                    self.m_machine:runCsbAction("over",false,function()
                        performWithDelay(self,function()
                            if type(func) == "function" then
                                func()
                            end  
                        end,0.1)
                    end)
                end,13/30)

            end,27/30)

        end,1)
    end)

end



--[[
    获取当前的奖励
]]
function JungleJauntColorfulGame:getCurReward()
    local reward = self.m_rewardList[self.m_curClickIndex] or ""
    return reward
end

function JungleJauntColorfulGame:updateMainMulLab(_str)
    local mainMulLab = self:findChild("chengbei")
    if _str then
        mainMulLab:setString("")
    else
        mainMulLab:setString("X"..self.m_totalMul)  
    end
    
end

--[[
    飞粒子动画
]]
function JungleJauntColorfulGame:flyParticleAni(rewardType,startNode,endNode,func)
    local flyNode = util_createAnimation("JungleJaunt_base_buff1_bianfu.csb")
    flyNode:runCsbAction("idle2")
    local startPos = util_convertToNodeSpace(startNode:findChild("Node_3"),self)
    local endPos = util_convertToNodeSpace(endNode,self)

    self:addChild(flyNode)
    flyNode:setPosition(startPos)
    local slab = startNode:findChild("chengbei")
    local str = slab:getString()
    flyNode:findChild("chengbei"):setString(str)
    slab:setString("")
    
    local actionList = {
        cc.EaseIn:create(cc.MoveTo:create(0.5,endPos),1),
        cc.CallFunc:create(function()
            gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_21)
            flyNode:setVisible(false)
            self:runCsbAction("shouji")
            self:updateMainMulLab()
            if type(func) == "function" then
                func()
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
function JungleJauntColorfulGame:getLeftRewrdCount(rewardType)
    return self.m_left_item_counts[rewardType] or 3
end


return JungleJauntColorfulGame