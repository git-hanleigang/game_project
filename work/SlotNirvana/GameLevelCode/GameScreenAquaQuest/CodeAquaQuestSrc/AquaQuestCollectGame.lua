---
--xcyy
--2018年5月23日
--AquaQuestCollectGame.lua
local PublicConfig = require "AquaQuestPublicConfig"
local AquaQuestCollectGame = class("AquaQuestCollectGame",util_require("base.BaseView"))

local MOVE_SPEED        =     300

local BASE_ZORDER       =     1000

local JACKPOT_TYPE = {
    "grand",
    "major",
    "minor",
    "mini"
}

function AquaQuestCollectGame:initUI(params)
    self.m_parentView = params.parent
    self.m_machine = params.machine
    self.m_totalWin = util_createAnimation("AquaQuest_totalwin.csb")
    self:addChild(self.m_totalWin,2000)
    self.m_spineList = {}
end

--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function AquaQuestCollectGame:initSpineUI()
    
end

--[[
    显示totalwin
]]
function AquaQuestCollectGame:showTotalWin(lineData,func)
    local jackpotType = self:getSpineType(lineData.id)
    for index = 1,#JACKPOT_TYPE do
        self.m_totalWin:findChild("Node_di_"..JACKPOT_TYPE[index]):setVisible(JACKPOT_TYPE[index] == jackpotType)
    end
    self.m_totalWin:setVisible(true)
    self.m_totalWin:runCsbAction("start",false,function()
        self.m_totalWin:runCsbAction("idle",true)
    end)
    self:updateTotalWinCoins(0)
end

--[[
    totalWin隐藏背景
]]
function AquaQuestCollectGame:runTotalWinOverAni(func)
    self.m_totalWin:runCsbAction("over",false,function()
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    totalwin反馈动画
]]
function AquaQuestCollectGame:runTotalWinFeedBack(coins,curWinCoins,isJackpot)
    local aniName = "actionframe1"
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local winRate = curWinCoins / totalBet
    if winRate >= 5 then
        aniName = "actionframe2"
    end
    if isJackpot then
        aniName = "actionframe"
        local Particle = self.m_totalWin:findChild("Particle_2")
        if not tolua.isnull(Particle) then
            Particle:resetSystem()
        end
    else
        for index = 1,2 do
            local Particle = self.m_totalWin:findChild("Particle_"..index)
            if not tolua.isnull(Particle) then
                Particle:resetSystem()
            end
        end
    end

    self:updateTotalWinCoins(coins)
    self.m_totalWin:runCsbAction(aniName,false,function()
        self.m_totalWin:runCsbAction("idle",true)
    end)
end

--[[
    更新赢钱数
]]
function AquaQuestCollectGame:updateTotalWinCoins(coins)
    local m_lb_coins = self.m_totalWin:findChild("m_lb_coins")
    if not tolua.isnull(m_lb_coins) then
        if coins == 0 then
            m_lb_coins:setString("")
        else
            m_lb_coins:setString(util_formatCoins(coins,50))
            local info = {label = m_lb_coins, sx = 0.45, sy = 0.45}
            self:updateLabelSize(info, 865)
        end
        
    end
end

--[[
    游戏开始
]]
function AquaQuestCollectGame:gameStart(lineData,func)
    
    local list = lineData.muti
    local spineType = self:getSpineType(lineData.id)

    local delayTime = 0
    local offsetTime = 2

    local totalWinCoins = 0

    local endFunc = function()
        if self.m_soundID then
            gLobalSoundManager:stopAudio(self.m_soundID)
            self.m_soundID = nil
        end
        if type(func) == "function" then
            func()
        end
    end

    self.m_soundID = gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_AquaQuest_show_collect_item"],true)

    --跳舞小人
    local danceSpine = self:getSpineByType(1)
    danceSpine:setLocalZOrder(BASE_ZORDER)
    danceSpine:setPosition(cc.p(-(display.center.x + 500),0))
    util_spinePlay(danceSpine,"actionframe_jiesuan",true)

    local routeList = {}
    routeList[#routeList + 1] = {
        startPos = cc.p(-(display.center.x + 500),0),   --起点位置
        endPos =  cc.p(display.center.x + 500,0),     --终点位置
        speed = MOVE_SPEED,      --移动速度
        endFunc = function()
            -- danceSpine:setVisible(false)
            self:pushSpineToPool(danceSpine,1)
        end,    --结束回调
    }
    util_moveByRouteList(danceSpine,routeList)

    delayTime = delayTime + offsetTime + 0.7

    --创建螃蟹(每隔一段时间间隔创建一个)
    for index = 1,#list do
        local winCoins = list[index]

        local spine = self:getSpineByType(2)
        spine:setLocalZOrder(BASE_ZORDER - index)
        spine:setVisible(false)

        local csbNode = util_createAnimation("AquaQuest_pangxie_coins.csb")
        util_spinePushBindNode(spine,"gd13",csbNode)

        spine:setPosition(cc.p(-(display.center.x + 400),0))
        local aniIndex = 2 
        if lineData.type ~= "bonus" and index == #list then
            csbNode:findChild("Node_jackpot"):setVisible(true)
            csbNode:findChild("Node_coins"):setVisible(false)
            for index = 1,#JACKPOT_TYPE do
                csbNode:findChild("Node_"..JACKPOT_TYPE[index]):setVisible(JACKPOT_TYPE[index] == spineType)
            end
            aniIndex = 1
        else
            csbNode:findChild("Node_jackpot"):setVisible(false)
            csbNode:findChild("Node_coins"):setVisible(true)
            local totalBet = globalData.slotRunData:getCurTotalBet()
            local winRate = winCoins / totalBet
            if winRate >= 5 then
                csbNode:runCsbAction("idle1",true)
                aniIndex = 1
            end
            for index = 1,#JACKPOT_TYPE do
                local lbl_coins_1 = csbNode:findChild("m_lb_coin_1")
                local lbl_coins_2 = csbNode:findChild("m_lb_coin_2")

                lbl_coins_1:setString(util_formatCoins(winCoins,3))
                lbl_coins_2:setString(util_formatCoins(winCoins,3))

                lbl_coins_2:setVisible(winRate >= 5)
                lbl_coins_1:setVisible(winRate < 5)

                csbNode:findChild("Node_coins_"..JACKPOT_TYPE[index]):setVisible(JACKPOT_TYPE[index] == spineType)
            end
        end
        local idleAni = "idleframe_"..spineType..aniIndex.."_zou"
        util_spinePlay(spine,idleAni,true)

        --行动轨迹分两部分,先走到屏幕中间收集金币,然后走出屏幕
        local routeList = {}
        routeList[#routeList + 1] = {
            spcialAct = cc.DelayTime:create(delayTime),
            endFunc = function()
                spine:setVisible(true)
            end,    --结束回调
        }

        --走到屏幕中间
        routeList[#routeList + 1] = {
            startPos = cc.p(-(display.center.x + 400),0),   --起点位置
            endPos = cc.p(-100,0),     --终点位置
            speed = MOVE_SPEED,      --移动速度
            endFunc = function()
                local aniName = "jiesuan_"..spineType..aniIndex
                util_spinePlay(spine,aniName)
                util_spineEndCallFunc(spine,aniName,function()
                    util_spinePlay(spine,"idleframe_"..spineType..aniIndex.."_zou2",true)
                end)

                local winType = "bonus"
                if index == #list then
                    winType = lineData.type
                end

                csbNode:findChild("Node_lbl"):setVisible(false)
                csbNode:findChild("Node_jackpot"):setVisible(false)
                csbNode:runCsbAction("idle")
                --收集金币
                self:flyCoinsToTotalWin(winCoins,csbNode,winType,function()
                    totalWinCoins  = totalWinCoins + winCoins
                    self:runTotalWinFeedBack(totalWinCoins,winCoins,(lineData.type ~= "bonus" and index == #list))

                    --最后一个螃蟹且螃蟹上背的是jackpot,先显示jackpot弹板再结束玩法
                    if lineData.type ~= "bonus" and index == #list then
                        if self.m_soundID then
                            gLobalSoundManager:stopAudio(self.m_soundID)
                            self.m_soundID = nil
                        end
                        self.m_machine:showJackpotView(winCoins,lineData.type,function()
                            gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_AquaQuest_collect_total_win_coins"])
                            self.m_totalWin:runCsbAction("actionframe_zhanshi",false,function()
                                endFunc()
                            end)
                        end)
                        
                    end
                end)
            end,    --结束回调
        }
        --走出屏幕
        routeList[#routeList + 1] = {
            startPos = cc.p(-100,0),   --起点位置
            endPos = cc.p(display.center.x + 400,0),     --终点位置
            speed = MOVE_SPEED,      --移动速度
            delayFuncTime = 1.5,--开始回调后延迟一定时间调用延时回调
            delayFunc = function()
                if index == #list then
                    if lineData.type == "bonus" then
                        --最后一个螃蟹出屏幕后0.5s继续后切换场景
                        performWithDelay(spine,function()
                            gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_AquaQuest_collect_total_win_coins"])
                            self.m_totalWin:runCsbAction("actionframe_zhanshi",false,function()
                                endFunc()
                            end)
                            
                        end,0.5)
                    end
                end
            end,  --延时回调
            endFunc = function()
                --玩法结束后会统一销毁场景,只隐藏即可
                spine:setVisible(false)
                self:pushSpineToPool(spine,2)
            end,    --结束回调
        }
        util_moveByRouteList(spine,routeList)

        delayTime = delayTime + offsetTime
    end
end

--[[
    根据获取spin
    1-人 2-螃蟹
]]
function AquaQuestCollectGame:getSpineByType(spineType)
    if not self.m_spineList[tostring(spineType)] then
        self.m_spineList[tostring(spineType)] = {}
    end
    
    if next(self.m_spineList[tostring(spineType)]) then
        local spine = self.m_spineList[tostring(spineType)][1]
        table.remove(self.m_spineList[tostring(spineType)],1)
        spine:setVisible(true)
        return spine
    end

    if spineType == 1 then
        local spine = util_spineCreate("AquaQuest_tiaowu",true,true)
        self:addChild(spine,BASE_ZORDER)
        return spine
    else
        local spine = util_spineCreate("Socre_AquaQuest_Bonus",true,true)
        self:addChild(spine,BASE_ZORDER)
        return spine
    end
end

--[[
    将spine放回池子
]]
function AquaQuestCollectGame:pushSpineToPool(spine,spineType)
    if tolua.isnull(spine) then
        return
    end
    if not self.m_spineList[tostring(spineType)] then
        self.m_spineList[tostring(spineType)] = {}
    end

    spine:setVisible(false)
    local list = self.m_spineList[tostring(spineType)]
    list[#list + 1] = spine
end

--[[
    收集金币
]]
function AquaQuestCollectGame:flyCoinsToTotalWin(coins,startNode,jackpotType,func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_AquaQuest_collect_coins_in_game"])
    local flyNode = util_createAnimation("AquaQuest_pangxie_coins_fly.csb")
    local startPos = util_convertToNodeSpace(startNode,self)
    self:addChild(flyNode,3000)
    flyNode:setPosition(startPos)
    local endPos = util_convertToNodeSpace(self.m_totalWin:findChild("m_lb_coins"),self)

    local totalBet = globalData.slotRunData:getCurTotalBet()
    local winRate = coins / totalBet

    local lbl_coins_1 = flyNode:findChild("m_lb_coin_1")
    local lbl_coins_2 = flyNode:findChild("m_lb_coin_2")

    lbl_coins_1:setString(util_formatCoins(coins,3))
    lbl_coins_2:setString(util_formatCoins(coins,3))

    lbl_coins_2:setVisible(winRate >= 5)
    lbl_coins_1:setVisible(winRate < 5)

    if winRate >= 5 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_AquaQuest_change_big_symbol_3"])
    end

    if jackpotType ~= "bonus" then
        flyNode:findChild("Node_jackpot"):setVisible(true)
        flyNode:findChild("Node_coins"):setVisible(false)
        for index = 1,#JACKPOT_TYPE do
            flyNode:findChild("Node_"..JACKPOT_TYPE[index]):setVisible(JACKPOT_TYPE[index] == jackpotType)
        end
    else
        flyNode:findChild("Node_jackpot"):setVisible(false)
        flyNode:findChild("Node_coins"):setVisible(true)
    end


    local actionList = {
        cc.EaseSineIn:create(cc.MoveTo:create(24 / 60,endPos)),
        cc.CallFunc:create(function()
            if type(func) == "function" then
                func()
            end
        end),
        cc.RemoveSelf:create()
    }

    flyNode:runCsbAction("fly")
    flyNode:runAction(cc.Sequence:create(actionList))
end

--[[
    获取螃蟹的jackpot
]]
function AquaQuestCollectGame:getSpineType(id)
    if id == "2x2" then
        return "mini"
    elseif id == "2x3" or id == "4x2" or id == "3x2" then
        return "minor"
    elseif id == "5x2" or id == "3x3" then
        return "major"
    else
        return "grand"
    end
end

--[[
    totalwin飞到小块上
]]
function AquaQuestCollectGame:flyTotalwinToBigSymbol(symbolNode,lineData,func)
    if tolua.isnull(symbolNode) then
        if type(func) == 'function' then
            func()
        end
        return
    end
    local aniNode = symbolNode:checkLoadCCbNode()     
    local spine = aniNode.m_spineNode

    if tolua.isnull(spine) or tolua.isnull(spine.m_bindCsbNode) then
        if type(func) == 'function' then
            func()
        end
        return
    end
    local csbNode = spine.m_bindCsbNode

    local endPos = util_convertToNodeSpace(csbNode,self)

    --反馈动效
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_AquaQuest_collect_total_win_coins_feed_back"])
    local actionList = {
        cc.MoveTo:create(24 / 60,endPos),
        cc.CallFunc:create(function()
            self.m_totalWin:setVisible(false)

            if not tolua.isnull(csbNode) then
                csbNode:runCsbAction("actionframe")
                
                local lightAni = util_createAnimation("AquaQuest_Bonus_jiesuantx.csb")
                csbNode:findChild("Node_tx"):addChild(lightAni)
                lightAni:runCsbAction("actionframe_fankui",false,function()
                    if not tolua.isnull(lightAni) then
                        lightAni:removeFromParent()
                    end
                end)

                performWithDelay(csbNode,function()
                    if not tolua.isnull(csbNode) then
                        local Node_coins = csbNode:findChild("Node_coins")
                        if not tolua.isnull(Node_coins) then
                            Node_coins:setVisible(true)
                        end
                    
                        local Node_wenben = csbNode:findChild("Node_wenben")
                        if not tolua.isnull(Node_wenben) then
                            Node_wenben:setVisible(false)
                        end
                    
                        local m_lb_coins = csbNode:findChild("m_lb_coins")
                        local m_lb_num = csbNode:findChild("m_lb_num")
                        local coins = lineData.amount
                    
                        if not tolua.isnull(m_lb_coins) then
                            m_lb_coins:setString(util_formatCoins(coins,3))
                        end
                    
                        if not tolua.isnull(m_lb_num) and lineData then
                            m_lb_num:setString(lineData.num)
                        end 
                    end
                end,17 / 60)
            end


            self.m_totalWin:setPosition(cc.p(0,0))
            performWithDelay(self.m_totalWin,function()
                if type(func) == "function" then
                    func()
                end
            end,50 / 60)
            
        end)
    }

    self.m_totalWin:runCsbAction("fly")
    self.m_totalWin:runAction(cc.Sequence:create(actionList))
end

return AquaQuestCollectGame