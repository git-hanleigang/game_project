---
--island
--2018年4月12日
--GoldenGhostJackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local GoldenGhostJackPotWinView = class("GoldenGhostJackPotWinView", util_require("base.BaseView"))

function GoldenGhostJackPotWinView:initUI(_machine)
    
    local resourceFilename = "GoldenGhost/Jackpotwin.csb"
    self:createCsbNode(resourceFilename)


    self:runCsbAction("start",false,function()
        self:runCsbAction("idle",true)
    end)

    -- 展示上的节点 从 m_showView 里面取
    self.m_lb_coins = self.m_showView:findChild("m_lb_coins")
    --隐藏 逻辑界面的 文本，修改按钮的透明度和可见性
    self:findChild("m_lb_coins"):setVisible(false)
    local btnCollect = self:findChild("Button_collect")
    btnCollect:setVisible(true)
    btnCollect:setOpacity(0)

    self:createGrandShare(_machine)

    self:findChild("Node_share"):setPositionY(self:findChild("Node_share"):getPositionY() - 25)
end

--创建csb节点 解决csbNode挂在spine上的问题
function GoldenGhostJackPotWinView:createCsbNode(filePath, isAutoScale)
    self.m_spine =  util_spineCreate("Jackpotwin",true,true)
    self:addChild(self.m_spine)
    self.m_spine:setLocalZOrder(5)

    -- self.m_spineGuadian = util_spineCreate("GoldenGhost_tanban_guadian",true,true)
    self.m_spineGuadian = util_spineCreate("Jackpotwin_2",true,true)
    self:addChild(self.m_spineGuadian)
    self.m_spineGuadian:setLocalZOrder(10)
    
    self.m_baseFilePath = filePath
    local fullPath = cc.FileUtils:getInstance():fullPathForFilename(filePath)
    --展示界面 只修改文本不做逻辑处理
    self.m_showView = util_createAnimation(filePath)
    util_spinePushBindNode(self.m_spineGuadian,"Jackpotwin_2k",self.m_showView)


    self.m_csbNode, self.m_csbAct = util_csbCreate(self.m_baseFilePath, self.m_isCsbPathLog)
    self:addChild(self.m_csbNode, 20)
    self:bindingEvent(self.m_csbNode)
    self:pauseForIndex(0)
    self:setAutoScale(isAutoScale)

    self:initCsbNodes()

    local viewSize = self.m_csbNode:getContentSize()
    self.m_spine:setPosition(viewSize.width/2, viewSize.height/2)
    self.m_spineGuadian:setPosition(viewSize.width/2, viewSize.height/2)
    self.m_csbNode:setPosition(viewSize.width/2, viewSize.height/2)
end

function GoldenGhostJackPotWinView:initViewData(index,coins,callBackFun,machine)
    self.m_machine = machine
    self.m_callFun = callBackFun
    self.m_jackpotIndex = index
    local skinList = {"grand", "major", "minor", "mini"}
    local skinName = skinList[index] or skinList[4]
    self.m_spine:setSkin(skinName)

    self.m_machine:bindSecondViewBtnState(self.m_showView, self)

    self.coins = coins
    local m_lb_coins = self.m_lb_coins
    self:updateLabelSize({label=m_lb_coins,sx = 1,sy = 1},639)
    self.m_bJumpOver = false
    self:jumpCoins(m_lb_coins,coins)

    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins, self.m_jackpotIndex)
end

--金币跳动
function GoldenGhostJackPotWinView:jumpCoins(lb,coins)
    local coins = tonumber(coins)
    local ratio = 0.1
    local time = 1.5
    local baseCoins = coins*ratio
    local addValue = coins*(1-ratio)*time/60

    util_jumpNum(lb, baseCoins, coins, addValue, time/60, {30},nil, nil,function ( ... )
        self.m_bJumpOver = true
        self:jumpCoinsFinish()
    end)
end

function GoldenGhostJackPotWinView:addSpinAni(index)
    local aniNameList = {"Socre_GoldenGhost_9","Socre_GoldenGhost_8","Socre_GoldenGhost_6","Socre_GoldenGhost_5"}
    local aniName = aniNameList[index]
    local spinAni = util_spineCreate(aniName,true,true)

    if index == 2 then 
        spinAni:setPosition(cc.p(20,-35))
    else
        spinAni:setScale(1.5)
    end

    util_spinePlay(spinAni, "actionframe2", false)
    util_spineEndCallFunc( spinAni,"actionframe2",function()
        util_spinePlay(spinAni, "idleframe2", true)
    end)
end

function GoldenGhostJackPotWinView:clickFunc(sender)
    if self:checkShareState() then
        return
    end
    if sender:getName() == "Button_collect" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        if not self.m_bJumpOver then
            self.m_bJumpOver = true
            self.m_lb_coins:stopAllActions()
            self.m_lb_coins:setString(util_formatCoins(self.coins, 30))
            self:jumpCoinsFinish()
        else
            sender:setEnabled(false)
            self:jackpotViewOver(function()
                performWithDelay(
                    self,
                    function()
                        self:runCsbAction("over",false,function()
                            if self.m_callFun then
                                self.m_callFun()
                            end
                            self:removeFromParent()
                        end)
                    end,
                1)
            end)
        end
    end
end

--------------------------- Class Base CCB Functions  END---------------------------

-- 如果本界面需要添加touch 事件，则从BaseView 获取


--播放动画 解决播放cocos时间线时 播一下spine时间线
function GoldenGhostJackPotWinView:runCsbAction(key, loop, func, fps)
    util_csbPlayForKey(self.m_csbAct, key, loop, func, fps)

    util_spinePlay(self.m_spine, key, loop)
    util_spinePlay(self.m_spineGuadian, key, loop)
end

--[[
    自动分享 | 手动分享
]]
function GoldenGhostJackPotWinView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end
function GoldenGhostJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end
function GoldenGhostJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end
function GoldenGhostJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return GoldenGhostJackPotWinView