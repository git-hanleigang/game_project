---
--smy
--2018年4月26日
--BunnysLockMapView.lua


local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseDialog = require "Levels.BaseDialog"
local BaseGame = util_require("base.BaseGame")
local BunnysLockMapView = class("BunnysLockMapView",BaseGame )

local MAX_COL   =   9   --最大行数
local MAX_ROW   =   5   --最大列数

local BTN_TAG_RETURN = 1001 --返回

--游戏类型
local GAME_TYPE         =       {
    GRASS   =   0,  --草
    EMPTY   =   1,  --空  
    LAST_ORDER  =   2,  --最终大奖
    MUTILPLE    =   3,  --倍数加成
    BOX         =   4,  --开箱子(赛马bonus)
    TOP_DOLLAR  =   5,  --topdollar
    PICK        =   6,  --多福多彩
    MONEY       =   7,  --钱
    BOMB        =   8,  --炸弹
}

function BunnysLockMapView:initUI(params)
    self.m_machine = params.machine
    self.m_curDirection = 1
    self:createCsbNode("BunnysLock/Map.csb")

    self:setVisible(false)
    self.m_isCanRecMsg = false

    self.m_rootNode = self:findChild("root")

    --返回按钮
    self.m_btn_return = self:findChild("Button_fanhui")
    self.m_btn_return:setTag(BTN_TAG_RETURN)

    --地图块
    self.m_mapItems = {}
    for iCol = 1,MAX_COL do
        self.m_mapItems[iCol] = {}
        for iRow = 1,MAX_ROW do
            local mapItem = util_createView("CodeBunnysLockBonus.BunnysLockMapItem",{parentView = self})
            local node = self:findChild("cao_"..iCol.."_"..iRow)
            node:addChild(mapItem)
            self.m_mapItems[iCol][iRow] = mapItem

            util_setCascadeOpacityEnabledRescursion(node,true)
        end
    end

    self.m_leftItems = {}
    for index = 1,5 do
        local item = util_createAnimation("Map_loadingBar.csb")
        self:findChild("loadingBar_"..(index - 1)):addChild(item)
        item:findChild("baoxiang"):setVisible(index == 1)
        item:findChild("wenzi"):setVisible(index == 2)
        
        item:findChild("lihe"):setVisible(index == 3)
        item:findChild("lanzi"):setVisible(index == 4)
        item:findChild("youqitong"):setVisible(index == 5)
        
        self.m_leftItems[index] = item
    end

    self.m_player = util_createView("CodeBunnysLockBonus.BunnysLockPlayer",{parentView = self})
    self.m_rootNode:addChild(self.m_player)

    util_setCascadeOpacityEnabledRescursion(self.m_player,true)

    self.m_lbl_final_prize = self:findChild("m_lb_coins_0")
    self.m_lbl_start_prize = self:findChild("m_lb_coins_1")
    self.m_lbl_total_win = self:findChild("m_lb_coins_2")

    self.m_mutilpleNode = util_createAnimation("Map_xingxing.csb")
    self:findChild("Map_xingxing"):addChild(self.m_mutilpleNode)
end

function BunnysLockMapView:showView(isStart,func)
    self:setVisible(true)
    self:resetView(false)
    self.m_isWaiting = false
    if isStart then
        
        self.m_isEnd = false
        self.m_isCanRecMsg = true
        self.m_btn_return:setVisible(false)
        self:setEndCallFunc(func)
    else
        self.m_player:hideAllBtns()
        self.m_btn_return:setVisible(true)
        self.m_lbl_total_win:setString("")
    end
    
end

function BunnysLockMapView:hideView()
    self:setVisible(false)
    self.m_isCanRecMsg = false
    if self.m_finalItem then
        self.m_finalItem:removeFromParent()
        self.m_finalItem = nil
    end
end

--[[
    设置结束回调
]]
function BunnysLockMapView:setEndCallFunc(func)
    self.m_endFunc = func
end

--[[
    按钮回调
]]
function BunnysLockMapView:clickFunc(sender)
    local btnTag = sender:getTag()
    if btnTag == BTN_TAG_RETURN then
        if self.m_machine.m_isChangeToBonus or self.m_isWaiting then
            return
        end
        gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_click_btn.mp3")
        self.m_isWaiting = true
        self.m_machine:changeSceneToBase(function()
            self.m_isWaiting = false
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
        end)
    end
end

-------------------子类继承-------------------
--处理数据 子类可以继承改写
--:calculateData(featureData)
--子类调用
--:getZoomScale(width)获取缩放比例
--:isTouch()item是否可以点击
--:sendStep(pos)item点击回调函数
--.m_otherTime=1      --其他宝箱展示时间
--.m_rewardTime=3     --结算界面弹出时间

function BunnysLockMapView:initViewData(callBackFun, gameSecen)
    self:initData()
end


function BunnysLockMapView:resetView(isHideBtn)
    local mapData = self.m_machine.m_mapData
    local collectData = self.m_machine.m_collectData
    if not mapData or not collectData then
        return
    end
    
    for k,data in pairs(mapData) do
        local mapItem = self.m_mapItems[data[1][1] + 1][data[1][2] + 1]
        mapItem:refreshUI(data)
    end

    --设置兔子位置
    local location = collectData.location
    self.m_player:resetUI(location,isHideBtn)
    local curItem = self.m_mapItems[location[1] + 1][location[2] + 1]
    self.m_player:setPosition(util_convertToNodeSpace(curItem,self.m_rootNode))

    local avgbet = collectData.avgbet or 0
    self.m_lbl_start_prize:setString(util_formatCoins(avgbet,50))
    self:updateLabelSize({label=self.m_lbl_start_prize,sx=0.8,sy=0.8},360)

    local finalWin = collectData.collectwin or 0
    self.m_lbl_final_prize:setString(util_formatCoins(finalWin,50))
    self:updateLabelSize({label=self.m_lbl_final_prize,sx=0.8,sy=0.8},465)

    local totalWin = collectData.turnwin or 0
    self.m_lbl_total_win:setString(util_formatCoins(totalWin,50))
    self:updateLabelSize({label=self.m_lbl_total_win,sx=0.8,sy=0.8},360)

    local collectup = collectData.collectup or 0
    collectup = collectup * 100
    self.m_mutilpleNode:findChild("shuzi"):setString(collectup) 
    if collectup == 0 then
        self.m_mutilpleNode:setVisible(false)
    end

    self:refreshLeftItemCount()

    
end

--[[
    刷新剩余道具数量
]]
function BunnysLockMapView:refreshLeftItemCount()
    local collectData = self.m_machine.m_collectData
    if not collectData then
        return
    end
    local leftcollect = collectData.leftcollect
    if leftcollect and #leftcollect > 0 then
        for index = 1,5 do
            local count = leftcollect[index]
            self.m_leftItems[index]:findChild("BitmapFontLabel_1"):setString(count)
        end
    end
end

function BunnysLockMapView:initData()
    self:initItem()
end

function BunnysLockMapView:initItem()
    
end

--数据发送
function BunnysLockMapView:sendData(select)
    if self.m_isWaiting or self.m_isEnd then
        return
    end


    self.m_action=self.ACTION_SEND
    --防止连续点击
    self.m_isWaiting = true
    self.m_curDirection = select

    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData = {msg=MessageDataType.MSG_BONUS_SELECT,data = select}
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)
end

--数据接收
function BunnysLockMapView:recvBaseData(featureData)
    self.m_isWaiting = false


    local collectData = featureData.p_data.selfData.collectData
    local mapData = featureData.p_data.selfData.map_result

    if  featureData.p_data.selfData.oldmap_result then
        collectData = featureData.p_data.selfData.oldcollectData
        mapData = featureData.p_data.selfData.oldmap_result

    end

    --更新缓存数据
    self.m_machine:updateBonusData(mapData,collectData)
    self.m_selfData = featureData.p_data.selfData
    self.m_winAmount = featureData.p_data.winAmount
    self.m_machine.m_runSpinResultData.p_selfMakeData = self.m_selfData
    self.m_machine.m_runSpinResultData.p_winAmount = self.m_winAmount
    self.m_bonusData = self.m_selfData.bonus
    self.m_machine.m_runSpinResultData.p_features = featureData.p_data.features
    
    
    --bonus是否结束
    local isBonusEnd = false
    if self.m_selfData.bonus and self.m_selfData.bonus.status == "CLOSED" then
        isBonusEnd = true
    end

    self.m_isEnd = isBonusEnd

    local location = collectData.location
    local mapItemData = mapData[self:getPosIndexByRowAndCol(location[1],location[2]) + 1]
    local gameType = mapItemData[3]
    local curItem = self.m_mapItems[location[1] + 1][location[2] + 1]
    local isHasGrass = curItem:isHaveGrass()

    self:movePlayer(location,mapItemData,function()
        local callBack = function()
            
            --是否触发了玩法
            local isNeedHideBtn,isFinalPrize,isTrigger = true,false,false

            if self.m_selfData.bonus and self.m_selfData.bonus.game and self.m_selfData.bonus.game == "box" then
                self.m_machine:showOpenBoxView(self.m_selfData.bonus,self.m_endFunc)
                isTrigger = true
            elseif self.m_selfData.bonus and self.m_selfData.bonus.game and self.m_selfData.bonus.game == "topdollar" then
                self.m_machine:showTopDollarView(self.m_selfData.bonus,self.m_endFunc)
                isTrigger = true
            elseif self.m_selfData.bonus and self.m_selfData.bonus.game == "colorful" then
                self.m_selfData.bonus.winAmount = self.m_winAmount
                self.m_machine:showColorfulView(self.m_selfData.bonus,self.m_endFunc)
                isTrigger = true
            elseif self.m_isEnd then
                if gameType == GAME_TYPE.LAST_ORDER then
                    isTrigger = true
                end
                self.m_machine:delayCallBack(0.5,function()
                    --最终大奖
                    if gameType == GAME_TYPE.LAST_ORDER then
                        isFinalPrize = true
                        self.m_leftItems[1]:findChild("BitmapFontLabel_1"):setString(0)
                        --乘倍特效
                        self:finalPrizeMultiAni(function()
                            -- self:resetView(isNeedHideBtn)
                            local totalWin = collectData.turnwin or 0
                            self.m_lbl_total_win:setString(util_formatCoins(totalWin,50))
                            self:updateLabelSize({label=self.m_lbl_total_win,sx=0.8,sy=0.8},360)
                            self.m_machine:delayCallBack(0.3,function()
                                self:showWinCoinsView()

                                local collectData = featureData.p_data.selfData.collectData
                                local mapData = featureData.p_data.selfData.map_result
                                self.m_machine:updateBonusData(mapData,collectData)
                            end)
                        end)

                        
                    else
                        self:showBaseWinCoinsView()
                    end
                end)
            else
                isNeedHideBtn = false
            end

            if not isTrigger or gameType ~= GAME_TYPE.LAST_ORDER and gameType ~= GAME_TYPE.PICK and gameType ~= GAME_TYPE.TOP_DOLLAR then
                --刷新界面
                self:resetView(isNeedHideBtn)
            else
                self:refreshLeftItemCount()
            end
            
        end
            
        --是否已经走过
        if isHasGrass then
            self:showItemAni(mapItemData,callBack)
        else
            callBack()
        end
        
    end)

end

--[[
    最终大奖乘倍
]]
function BunnysLockMapView:finalPrizeMultiAni(func)
    local collectData = self.m_machine.m_collectData
    local finalWin = collectData.collectwin or 0
    local collectup = collectData.collectup or 0

    if collectup > 0 then
        local item = util_createAnimation("Map_xingxing.csb")
        self.m_rootNode:addChild(item,1000)
        local pos = util_convertToNodeSpace(self.m_mutilpleNode,self.m_rootNode)
        item:setPosition(pos)
        item:runCsbAction("yidong")
        item:findChild("shuzi"):setString(collectup * 100)
        
        self:flyStarAni(item,self.m_lbl_final_prize,function()
            gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_map_collect_star_to_final_prize_feedback.mp3")
            self:runCsbAction("actionframe")
            
            self:jumpNum(finalWin,finalWin * (1 + collectup),function()
                self.m_machine:delayCallBack(0.1,func)
            end)
            
        end)
        self.m_machine:delayCallBack(25 / 60,function()
            gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_map_collect_star_to_final_prize.mp3")
        end)
    else
        if type(func) == "function" then
            func()
        end
    end
    
end

function BunnysLockMapView:jumpNum(startCoins,coins,func)
    local node = self.m_lbl_final_prize
    self.m_lbl_final_prize:setString(util_formatCoins(startCoins,50))
    self:updateLabelSize({label=self.m_lbl_final_prize,sx=0.8,sy=0.8},465)

    self.m_soundId = gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_map_final_prize_jump.mp3")

    local coinRiseNum =  (coins - startCoins) / 60

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 3 ))
    coinRiseNum = tonumber(str)
    -- coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = startCoins
    node:stopAllActions()
    
    util_schedule(node,function()

        curCoins = curCoins + coinRiseNum

        if curCoins >= coins then

            curCoins = coins

            self.m_lbl_final_prize:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=self.m_lbl_final_prize,sx=0.8,sy=0.8},465)

            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil

                gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_map_final_prize_jump_end.mp3")
            end

            node:stopAllActions()
            if type(func) == "function" then
                func()
            end

        else

            self.m_lbl_final_prize:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=self.m_lbl_final_prize,sx=0.8,sy=0.8},465)
        end
        

    end,1 / 60)
end

--[[
    展示道具
]]
function BunnysLockMapView:showItemAni(mapItemData,func)
    local item = util_createView("CodeBunnysLockBonus.BunnysLockMapItem",{parentView = self})
    item:updateReward(mapItemData)
    item:hideDi()
    self.m_rootNode:addChild(item,1000)
    item:setPosition(cc.p(self.m_player:getPosition()))
    item:runCsbAction("idleframe")

    if mapItemData[3] == GAME_TYPE.MUTILPLE then
        
        item:updateMutiple(self.m_machine.m_collectData.turncollectup or 0)
    end

    local callFunc = function(isNeedSave)
        if isNeedSave then
            self.m_finalItem = item
        else
            item:removeFromParent()
        end
        
        
        if type(func) == "function" then
            func()
        end
    end

    local gameType = mapItemData[3]
    --最终大奖
    if gameType == GAME_TYPE.LAST_ORDER then
        self:runCsbAction("tishi")
        gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_map_find_final_box.mp3")
        item:showBoxReward(function()
            
            callFunc(true)
        end)
    elseif gameType == GAME_TYPE.MUTILPLE then
        
        item:changeToStarAni(function()
            
            self.m_machine:delayCallBack(25 / 60,function()
                gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_map_collect_star.mp3")
            end)
            self:flyStarAni(item,self.m_mutilpleNode,function()
                gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_map_collect_star_feedback.mp3")

                if self.m_mutilpleNode:isVisible() then
                    self.m_mutilpleNode:runCsbAction("actionframe")
                else
                    self.m_mutilpleNode:setVisible(true)
                    self.m_mutilpleNode:runCsbAction("show",false,function()
                        -- self.m_mutilpleNode:runCsbAction("actionframe")
                    end)
                    
                end

                --收集到右上角倍数区域
                callFunc()
            end)
            item:collectStarAni()
            
        end)
    elseif gameType == GAME_TYPE.BOMB then
        item:showBombAni(function()
            callFunc()
        end)
    elseif gameType == GAME_TYPE.EMPTY then
        callFunc()
    else
        gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_show_map_reward.mp3")
        item:showAni(function()
            if gameType == GAME_TYPE.MONEY then
                local randIndex = math.random(1,2)
                gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_map_find_coins_"..randIndex..".mp3")

                gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_map_collect_coins.mp3")
                self:flyMoneyAni(item,self.m_lbl_total_win,function()
                    gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_map_collect_coins_feedback.mp3")
                    self:runCsbAction("actionframe2")
                    callFunc()
                end)
                
            else
                callFunc()
            end
            
        end)
    end
end

--[[
    收集倍数动画
]]
function BunnysLockMapView:flyStarAni(starItem,endNode,func)

    local endPos = util_convertToNodeSpace(endNode,self.m_rootNode)

    local seq = cc.Sequence:create({
        cc.DelayTime:create(25 / 60),
        cc.MoveTo:create(25 / 60,endPos),
        cc.CallFunc:create(function()
            if type(func) == "function" then
                func()
            end
        end),
        cc.RemoveSelf:create(true)
    })

    starItem:runAction(seq)
end

--[[
    收集倍数动画
]]
function BunnysLockMapView:flyMoneyAni(moneyItem,endNode,func)

    local endPos = util_convertToNodeSpace(endNode,self.m_rootNode)

    local seq = cc.Sequence:create({
        cc.MoveTo:create(30 / 60,endPos),
        cc.CallFunc:create(function()
            if type(func) == "function" then
                func()
            end
        end),
        cc.RemoveSelf:create(true)
    })

    moneyItem:runAction(seq)
end

--[[
    移动兔子
]]
function BunnysLockMapView:movePlayer(location,mapItemData,func)
    local curItem = self.m_mapItems[location[1] + 1][location[2] + 1]
    local endPos = util_convertToNodeSpace(curItem,self.m_rootNode)
    if self.m_curDirection == self.m_player.m_curDirection then
        curItem:clearGrassAni(self.m_curDirection)
    else
        self.m_machine:delayCallBack(0.5,function()
            curItem:clearGrassAni(self.m_curDirection)
        end)
    end
    self.m_player:runMoveAct(self.m_curDirection,endPos,function()
        if type(func) == "function" then
            func()
        end
    end)
    if curItem:isHaveGrass() then
        curItem:runIdleAni()
    end
    
end

--[[
    最终大奖赢钱
]]
function BunnysLockMapView:showWinCoinsView()
    local avgBet = self.m_selfData.collectData.avgbet
    local params = {
        baseCoins = self.m_winAmount - (self.m_bonusData.collect_money or 0), --地图上的钱
        bonusCoins = (self.m_bonusData.collect_money or 0), --最终大奖的钱
        winCoins = self.m_winAmount
    }
    self.m_machine:showBonusWinView("finalprize",params,function()
        self.m_player:resetDirection()
        if type(self.m_endFunc) == "function" then
            self.m_endFunc()
            self.m_endFunc = nil
        end
    end)
end

--[[
    普通赢钱
]]
function BunnysLockMapView:showBaseWinCoinsView()
    local winCoins = self.m_winAmount

    self.m_machine:showBaseBonusWinCoins(winCoins,function()
        if type(self.m_endFunc) == "function" then
            self.m_endFunc()
            self.m_endFunc = nil
        end
    end)
end

function BunnysLockMapView:sortNetData(data)
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

--[[
    接受网络回调
]]
function BunnysLockMapView:featureResultCallFun(param)
    if not self.m_isCanRecMsg  then
        return
    end
    if type(param[2]) ~= "table" then
        return
    end
    local result = param[2].result
    if result and result.action == "BONUS" then
        self.super.featureResultCallFun(self,param)
    end
    
end

function BunnysLockMapView:getPosIndexByRowAndCol(col,row)
    local index = col * MAX_ROW + row
    return index
end

return BunnysLockMapView