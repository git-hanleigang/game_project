local MrCashGoJackPotWinView = class("MrCashGoJackPotWinView",util_require("Levels.BaseLevelDialog"))

function MrCashGoJackPotWinView:onExit()
    MrCashGoJackPotWinView.super.onExit(self)
    self:stopUpDateCoins()

    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end
end

--[[
    _initData = {
        coins        = 0,
        jackpotIndex = 1,
        isMulti      = false,   -- 是否乘倍，不需要乘倍的具体数值，这个是拼死的
    }
]]
function MrCashGoJackPotWinView:initUI(_initData)
    self.m_initData = _initData
    self.m_allowClick = false

    self:createCsbNode("MrCashGo/JackpotWinView.csb")

    self.m_roleSpine = util_spineCreateDifferentPath("Socre_MrCashGo_jiaose", "Socre_MrCashGo_Bonus", true, true)
    self:findChild("Node_role"):addChild(self.m_roleSpine)
    

    self:upDateJackPotShow()
    self:findChild("m_lb_coins"):setString("0")
end

function MrCashGoJackPotWinView:upDateJackPotShow()
    local nameList = {
        [4] = "MINI",
        [3] = "MINOR",
        [2] = "MAJOR",
        [1] = "GRAND",
    }

    for _jpIndex,_nodeName in ipairs(nameList) do
        local isVisible = _jpIndex == self.m_initData.jackpotIndex
        -- 底板
        self:findChild(_nodeName):setVisible(isVisible)
        -- 字
        self:findChild(string.format("%s_Zi", _nodeName)):setVisible(isVisible)
        -- 乘倍
        self:findChild(string.format("%s_x5", _nodeName)):setVisible(isVisible and self.m_initData.isMulti)
    end
end
--点击回调
function MrCashGoJackPotWinView:clickFunc(sender)
    if not self.m_allowClick then
        return
    end

    local name = sender:getName()

    if name == "Button_collect" then
        self:clickCollectBtn(sender)
    end
end

function MrCashGoJackPotWinView:clickCollectBtn(_sender)
    gLobalSoundManager:playSound("MrCashGoSounds/sound_MrCashGo_dialog_click.mp3")

    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end

    if self.m_updateAction ~= nil then
        self:stopUpDateCoins()
        self:setFinalWinCoins()
    else
        self:playOverAnim()
    end

end


function MrCashGoJackPotWinView:initViewData()
    -- x5 和 普通的jackpot 要走两条时间线区分一下
    local startName = self.m_initData.isMulti and "start2" or "start1"
    self:runCsbAction(startName, false, function()
        self:runCsbAction("idle", true)
        self.m_allowClick = true

        if self.m_initData.isAuto then
            local animTime = 3
            performWithDelay(
                self,
                function()
                    self:playOverAnim()
                end,
                animTime
            )
        end
    end)
    util_spinePlay(self.m_roleSpine, startName, false)
    util_spineEndCallFunc(self.m_roleSpine, startName, function()
        util_spinePlay(self.m_roleSpine, "idle", true)
    end)

    -- x5 和 普通jackpot 区分一下跳钱的时机
    if self.m_initData.isMulti then
        local baseCoins = math.floor(self.m_initData.coins/5)
        local labCoins = self:findChild("m_lb_coins")
        labCoins:setString(util_formatCoins(baseCoins,50))
        self:updateLabelSize({label=labCoins,sx=1.05,sy=1.05},670)

        local waitNode_1 = cc.Node:create()
        self:addChild(waitNode_1)
        performWithDelay(waitNode_1,function()    
            gLobalSoundManager:playSound("MrCashGoSounds/sound_MrCashGo_jackpotView_fankui.mp3")
            waitNode_1:removeFromParent()
        end, 45/60)

        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(waitNode,function()    
            self:jumpCoins(self.m_initData.coins, baseCoins)
            waitNode:removeFromParent()
        end, 78/60)

    else
        self:jumpCoins(self.m_initData.coins)
    end

    -- 弹板音效
    local nameList = {
        [4] = "MINI",
        [3] = "MINOR",
        [2] = "MAJOR",
        [1] = "GRAND",
    }
    local sMulti    = self.m_initData.isMulti and "_x5" or ""
    local sName     = nameList[self.m_initData.jackpotIndex]
    local soundName = string.format("MrCashGoSounds/sound_MrCashGo_jackpotView_%s%s.mp3", sName, sMulti) 
    gLobalSoundManager:playSound(soundName)
end

function MrCashGoJackPotWinView:jumpCoins(coins, _curCoins)
    local coinRiseNum =  coins / (3 * 60)  -- 每秒60帧

    local str   = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = _curCoins or 0

    local node=self:findChild("m_lb_coins")
    --  数字上涨音效
    self.m_soundId = gLobalSoundManager:playSound("MrCashGoSounds/sound_MrCashGo_jackpotView_jumpCoin.mp3",true)
    

    self.m_updateAction = schedule(self,function()
        curCoins = curCoins + coinRiseNum

        curCoins = curCoins < coins and curCoins or coins
        node:setString(util_formatCoins(curCoins,50))
        self:updateLabelSize({label=node,sx=1.05,sy=1.05},670)

        if curCoins >= coins then
            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil
            end
            self:stopUpDateCoins()
        end
    end,0.008)
end

function MrCashGoJackPotWinView:stopUpDateCoins()
    if self.m_updateAction then
        self:stopAction(self.m_updateAction)
        self.m_updateAction = nil

        gLobalSoundManager:playSound("MrCashGoSounds/sound_MrCashGo_jackpotView_jumpCoinStop.mp3")
    end
end

function MrCashGoJackPotWinView:setFinalWinCoins()
    if not self.m_initData then
        return
    end
    local labCoins = self:findChild("m_lb_coins")
    labCoins:setString(util_formatCoins(self.m_initData.coins,50))
    self:updateLabelSize({label=labCoins,sx=1.05,sy=1.05},670)
end



function MrCashGoJackPotWinView:playOverAnim()
    self:findChild("Button_collect"):setEnabled(false)
    self.m_allowClick = false
    self:stopAllActions()

    if self.m_btnClickFunc then
        self.m_btnClickFunc()
        self.m_btnClickFunc = nil
    end

    self:runCsbAction("over", false)
    util_spinePlay(self.m_roleSpine, "over", false)

    performWithDelay(
        self,
        function()
            if self.m_overRuncallfunc then
                self.m_overRuncallfunc()
                self.m_overRuncallfunc = nil
            end
    
            self:removeFromParent()
        end,
        32/60
    )

end

--[[
    模仿一下 BaseDialog 的点击结束流程
]]
function MrCashGoJackPotWinView:setBtnClickFunc(func)
    self.m_btnClickFunc = func
end
function MrCashGoJackPotWinView:setOverAniRunFunc(func)
    self.m_overRuncallfunc = func
end

return MrCashGoJackPotWinView