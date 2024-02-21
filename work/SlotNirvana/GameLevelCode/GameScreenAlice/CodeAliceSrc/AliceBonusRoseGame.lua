---
--xcyy
--2018年5月23日
--AliceView.lua

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local AliceBonusRoseGame = class("AliceBonusRoseGame",BaseGame )

AliceBonusRoseGame.m_currMultip = nil

function AliceBonusRoseGame:initUI(data)

    self.m_isShowTournament = true

    self:createCsbNode("Alice/BonusGame2.csb")
    -- self.m_csbNode:setPosition(display.cx, display.cy)
    self.m_isBonusCollect=true
    -- TODO 输入自己初始化逻辑

    self.m_labStartPrice = self:findChild("m_lb_start")
    self.m_labMultip = self:findChild("m_lab_multip")

    self.m_vecItem = {}
    local itemTag = 1
    local index = 1
    while true do
        local node = self:findChild("rose_" .. index )
        if node ~= nil then
            local item = util_createView("CodeAliceSrc.AliceBonusRoseItem", index)
            self.m_vecItem[index] = item
            item:setTag(itemTag)
            local func = function ()
                self:clickItemCallFunc(item)
            end
            item:setClickFunc(func)
            node:addChild(item)
            itemTag = itemTag + 1
        else
            break
        end
        index = index + 1
    end
    
    self.m_bClickFlag = false

end

function AliceBonusRoseGame:clickItemCallFunc(item)
    if self.m_bClickFlag == false then
        return 
    end
    gLobalSoundManager:playSound("AliceSounds/sound_Alice_rose_click.mp3")
    self.m_bClickFlag = false
    self.m_currClickItem = item
    self:sendData(item:getTag())
    
end

function AliceBonusRoseGame:onEnter()
    BaseGame.onEnter(self)
end
function AliceBonusRoseGame:onExit()
    BaseGame.onExit(self)

    -- gLobalSoundManager:stopBgMusic()
end

function AliceBonusRoseGame:initViewData(startPrice, callBackFun)
    self:runCsbAction("start", false, function ()
        self.m_bClickFlag = true
        self:runCsbAction("idle", true)
        self:showItemStart()
    end)
    self.m_startPrice = startPrice
    self.m_labStartPrice:setString(util_formatCoins(startPrice,50))
    self.m_labMultip:setString("")
    self:updateLabelSize({label = self.m_labStartPrice,sx = 1,sy = 1}, 222)

    self.m_callFunc = callBackFun

    -- self:sendStartGame()
    -- gLobalSoundManager:playSound("AZTECSounds/sound_despicablewolf_enter_fs.mp3")
    
end

function AliceBonusRoseGame:showItemStart()
    for i = 1, #self.m_vecItem, 1 do
        self.m_vecItem[i]:showItemStart()
    end
end

--默认按钮监听回调
function AliceBonusRoseGame:clickItem(func)
    if self.m_startClick ~= true then
        for i = 1, #self.m_vecItem, 1 do
            if self.m_vecItem[i] ~= self.m_currClickItem then
                self.m_vecItem[i]:showItemIdle()
            end
        end
        self.m_startClick = true
    end
    self.m_currClickItem:showResult(self.m_currMultip, function()
        self:clickCallBack()
    end, func)
    
end

function AliceBonusRoseGame:clickCallBack()
   
    if self.m_bGameOver ~= true then
        self:flyParticleEffect()
    end

end

function AliceBonusRoseGame:flyParticleEffect()

    gLobalSoundManager:playSound("AliceSounds/sound_Alice_tree_game_over.mp3")
    local endPos = cc.p(self.m_labMultip:getPosition())
    local flyNum = 1
    local multip = 0

    if self.m_labMultip:getString() ~= "" then
        multip = tonumber(self.m_labMultip:getString()) + self.m_currMultip
    else
        multip = self.m_currMultip
    end

    local node = self:findChild("rose_"..self.m_currClickItem:getTag())
    local startPos = cc.p(node:getPosition())
    local particle = cc.ParticleSystemQuad:create("partical/Alice_tuowei.plist")
    self:findChild("Node_15"):addChild(particle)
    particle:setPosition(startPos)
    local distance = ccpDistance(startPos, endPos)
    local flyTime = distance / 600
    local moveTo = cc.MoveTo:create(flyTime, endPos)
    particle:runAction(cc.Sequence:create(moveTo, cc.CallFunc:create(
        function()
            gLobalSoundManager:playSound("AliceSounds/sound_Alice_tree_key_down.mp3")
            self:addMultipEffect()
            self.m_totalMultip = multip
            self.m_labMultip:setString(multip)
            self.m_bClickFlag = true
            performWithDelay(self, function()
                particle:removeFromParent()
            end, 0.2)
        end
    )))    
end

function AliceBonusRoseGame:addMultipEffect()
    local effect, act = util_csbCreate("BonusGame_fankuilizi.csb")
    self.m_labMultip:getParent():addChild(effect)
    effect:setPosition(self.m_labMultip:getPosition())
    util_csbPlayForKey(act, "actionframe", false, function()
        effect:removeFromParent()
    end)
end

function AliceBonusRoseGame:resetView(startPrice, featureData, callBackFun)
    self:runCsbAction("start", false, function ()
        self.m_bClickFlag = true
        self:runCsbAction("idle", true)
        if self.m_startClick ~= true then
            self:showItemStart()
        end
    end)
    self.m_startPrice = startPrice
    self.m_labStartPrice:setString(util_formatCoins(startPrice,50))
    self.m_labMultip:setString("")
    self:updateLabelSize({label = self.m_labStartPrice,sx = 1,sy = 1}, 222)

    self.m_callFunc = callBackFun

    if featureData ~= nil and featureData.p_bonus.extra.clickPoses ~= nil then
        local vecClickPoses = featureData.p_bonus.extra.clickPoses
        local vecMultiples = featureData.p_bonus.extra.roseResult.multiples
        local totalMultip = 0
        for i = 1, #vecClickPoses, 1 do
            local index = tonumber(vecClickPoses[i])
            local result = vecMultiples[i]
            local item = self.m_vecItem[index]
            item:showSelected(result)
            totalMultip = totalMultip + result
        end
        self.m_startClick = true
        self.m_labMultip:setString(totalMultip)
    end
    

end

--数据发送
function AliceBonusRoseGame:sendData(pos)
    self.m_action=self.ACTION_SEND

    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData=nil
    if self.m_isBonusCollect then
        
        messageData={msg = MessageDataType.MSG_BONUS_SELECT , data = pos} -- self.m_collectDataList -- MessageDataType.MSG_BONUS_COLLECT
    end
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,true)
    
end

function AliceBonusRoseGame:recvBaseData(featureData)
    --dump(featureData, "featureData", 3)
    self.m_action=self.ACTION_RECV
    if featureData.p_status=="START" then
        self:startGameCallFunc()
        return
    end
    
    self.p_status = featureData.p_status
    self.m_currMultip = featureData.p_bonus.extra.roseResult.multiples[#featureData.p_bonus.extra.clickPoses]
    
    if featureData.p_status=="CLOSED" then
        self:uploadCoins(featureData)

        -- 更新游戏内每日任务进度条
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
        -- 通知bonus 结束， 以及赢钱多少
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{self.m_totleWimnCoins, GameEffect.EFFECT_BONUS})

        self:clickItem(function()
            -- gLobalSoundManager:playSound("AZTECSounds/sound_AZTEC_bonus_reward.mp3")

            local vecChoosed = featureData.p_bonus.extra.clickPoses
            local vecMultiples = featureData.p_bonus.extra.roseResult.multiples
            local startIndex = #vecChoosed + 1
            for i = 1, #self.m_vecItem, 1 do
                local item = self.m_vecItem[i]
                if item:showItemStatus() ~= true then
                    local result = vecMultiples[startIndex]
                    startIndex = startIndex + 1
                    item:showUnselected(result)
                end
            end
             
            -- local vecIndex = {}
            -- for i = 1, #vecChoosed, 1 do
            --     local info = {}
            --     info.index = tonumber(vecChoosed[i])
            --     info.multip = vecMultiples[i]
            --     vecIndex[i] = info
            -- end
            -- table.sort(vecIndex, function(a, b)
            --     return a.index < b.index
            -- end)

            local delayTime = 1.5
            -- local flyTime = 0.4
            -- local endPos = cc.p(self.m_labMultip:getPosition())
            -- local flyNum = 1
            -- local multip = 0
            -- for i = 1, #vecIndex, 1 do
            --     local info = vecIndex[i]
            --     if info.multip ~= "Collect" then
            --         performWithDelay(self, function()
            --             local node = self:findChild("rose_"..info.index)
            --             local startPos = cc.p(node:getPosition())
            --             local particle = cc.ParticleSystemQuad:create("partical/Alice_tuowei.plist")
            --             self:findChild("Node_15"):addChild(particle)
            --             particle:setPosition(startPos)
            --             local moveTo = cc.MoveTo:create(flyTime, endPos)
            --             particle:runAction(cc.Sequence:create(moveTo, cc.CallFunc:create(
            --                 function()
            --                     multip = multip + info.multip
            --                     self.m_labMultip:setString(multip)
            --                     performWithDelay(self, function()
            --                         particle:removeFromParent()
            --                     end, 0.2)
            --                 end
            --             )))
            --         end, 0.5 + flyNum * delayTime)
            --         flyNum = flyNum + 1
            --     end
            -- end
            -- delayTime = (#vecIndex - 1) * delayTime + 1.5
            performWithDelay(self, function()
                gLobalSoundManager:stopBgMusic()
                gLobalSoundManager:playSound("AliceSounds/sound_Alice_bonus_game_end.mp3")
            end, delayTime)
            performWithDelay(self, function()
                
                local bonusOver = util_createView("CodeAliceSrc.AliceBonusGameOver") 
                bonusOver:initViewData(self.m_startPrice, self.m_totalMultip, self.m_totleWimnCoins, function()
                    self:runCsbAction("over", false, function()
                        performWithDelay(self, function()
                            if self.m_callFunc ~= nil then
                                self.m_callFunc()
                            end
                            self:removeFromParent()
                        end, 0.8)
                    end)
                end)
                gLobalViewManager:showUI(bonusOver)

            end, delayTime + 2.5)
            
        end)
        self.m_bGameOver = true
    else
        self:clickItem()
    end
    
end

--弹出结算界面前展示其他宝箱数据
function AliceBonusRoseGame:showOther()
    
end

--开始结束流程
function AliceBonusRoseGame:gameOver()
    
end

--弹出结算奖励

function AliceBonusRoseGame:sortNetData( data)
    -- 服务器非得用这种结构 只能本地转换一下结构
    local localdata = {}
    if data.bonus then
        if data.bonus then
            data.choose = data.bonus.choose
            data.content = data.bonus.content
            data.extra = data.bonus.extra
            data.status = data.bonus.status
        end
    end 


    localdata = data

    return localdata
end

function AliceBonusRoseGame:featureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        -- dump(spinData.result, "featureResultCallFun data", 3)
        local userMoneyInfo = param[3]
        self.m_serverWinCoins = spinData.result.winAmount  -- 记录下服务器返回赢钱的结果
        self.m_totleWimnCoins = spinData.result.winAmount
        print("赢取的总钱数为=" .. self.m_totleWimnCoins)
        globalData.userRate:pushCoins(self.m_serverWinCoins)
        globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
        if spinData.action == "FEATURE" then
            local data = self:sortNetData(spinData.result)
            self.m_featureData:parseFeatureData(data)
            self:recvBaseData(self.m_featureData)
        elseif self.m_isBonusCollect then
            self.m_featureData:parseFeatureData(spinData.result)
            self:recvBaseData(self.m_featureData)
        else
            -- dump(spinData.result, "featureResult action"..spinData.action, 3)
        end
    else
        -- 处理消息请求错误情况
    end
end
return AliceBonusRoseGame