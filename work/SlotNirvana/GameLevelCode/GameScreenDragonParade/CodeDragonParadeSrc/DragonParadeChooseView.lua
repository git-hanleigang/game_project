---
--xcyy
--2018年5月23日
--DragonParadeChooseView.lua

local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local DragonParadeChooseView = class("DragonParadeChooseView", BaseGame)

DragonParadeChooseView.m_ClickIndex = 1

DragonParadeChooseView.CLICK_TAG_FREE = 10001
DragonParadeChooseView.CLICK_TAG_RESPIN = 10002
function DragonParadeChooseView:initUI(machine, isSuper, score)
    local isAutoScale = false
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end

    self:createCsbNode("DragonParade/FeatureChoice.csb", isAutoScale)

    self.m_machine = machine
    self.m_isSuper = isSuper --是否是加强玩法

    self.m_Click = false
    self.m_isStart_Over_Action = true
    self.m_isReceiveData = false
    self.m_selectAnimIsPlayed = false

    self.m_selectFree = util_spineCreate("Socre_DragonParade_xz", true, true)
    self:findChild("FG"):addChild(self.m_selectFree)
    if self.m_isSuper then
        self.m_selectFree:setSkin("FG_c")
    else
        self.m_selectFree:setSkin("FG_d")
    end
    
    self.m_selectRespin = util_spineCreate("Socre_DragonParade_xz", true, true)
    self:findChild("Respin"):addChild(self.m_selectRespin)
    if self.m_isSuper then
        self.m_selectRespin:setSkin("ReSpin_c")
    else
        self.m_selectRespin:setSkin("ReSpin_d")
    end
    

    --触发收集时 增长计数板
    self.m_baseBonusCollectAddBar = util_createAnimation("DragonParade_jiaqian.csb")
    self:findChild("Node_jiaqian"):addChild(self.m_baseBonusCollectAddBar)
    -- self.m_baseBonusCollectAddBar:setVisible(false)
    -- self.m_baseBonusCollectAddBar:runCsbAction("start", false, function()
        self.m_baseBonusCollectAddBar:runCsbAction("idle", true)
    -- end)
    local scoreStr = self.m_machine:formatCoins(score, 3)
    self.m_baseBonusCollectAddBar:findChild("m_lb_num"):setString(scoreStr)

    self.m_machine.m_baseBonusCollectAddBar:setVisible(false)

    --注册点击
    self.m_panel_free = self:findChild("click_free")
    self.m_panel_free:setTag(self.CLICK_TAG_FREE)
    self.m_panel_respin = self:findChild("click_respin")
    self.m_panel_respin:setTag(self.CLICK_TAG_RESPIN)
    self:addClick(self.m_panel_free)
    self:addClick(self.m_panel_respin)

    -- gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_choose_popupstart_begin.mp3")
    self:runCsbAction("start", false, function()
        self:runCsbAction("idle", true)
    end)
    self:playSpineAnim(self.m_selectFree, "start", false, function()
        self:playSpineAnim(self.m_selectFree, "idle", true)
    end)
    self:playSpineAnim(self.m_selectRespin, "start", false, function()
        self:playSpineAnim(self.m_selectRespin, "idle", true)

        --点击选项置回 已spine为准
        self.m_isStart_Over_Action = false
    end)
end

function DragonParadeChooseView:playSpineAnim(spine, name, loop, func)
    if not spine then
        return 
    end
    local spineName = name
    -- if self.m_isSuper then
        spineName = name
    -- else
        -- spineName = name .. "2"    --命名有规律 就通一取了
    -- end
    util_spinePlay(spine, spineName, loop)
    local spineEndCallFunc = function()
        if func then
            func()
        end
    end
    if loop == false then
        util_spineEndCallFunc(spine, spineName, spineEndCallFunc)
    end
end

function DragonParadeChooseView:setInitUI()

end

function DragonParadeChooseView:playSelectAnim(type)
    local funcPlayOver = function()
        self.m_selectAnimIsPlayed = true --标记动画播到位

        if self.m_isReceiveData == true then
            self:closeUi()
        end
    end
    if type == 1 then
        -- respin
        self:playSpineAnim(self.m_selectFree, "yaan", false, function()
            self:playSpineAnim(self.m_selectFree, "yaan_idle", true)
        end)
        self:playSpineAnim(self.m_selectRespin, "dj", false, function()
            self:playSpineAnim(self.m_selectRespin, "idle_actionframe", true)
            performWithDelay(self, function()
                funcPlayOver()
            end, 1.5)
        end)
    else
        --free
        self:playSpineAnim(self.m_selectRespin, "yaan", false, function()
            self:playSpineAnim(self.m_selectRespin, "yaan_idle", true)
        end)
        self:playSpineAnim(self.m_selectFree, "dj", false, function()
            self:playSpineAnim(self.m_selectFree, "idle_actionframe", true)
            performWithDelay(self, function()
                funcPlayOver()
            end, 1.5)
        end)
    end
    

    --模拟动画20帧
    -- performWithDelay(
    --     self,
    --     function()
    --         self.m_selectAnimIsPlayed = true
    --     end,
    --     20/30
    -- )

    --动画结束
    -- performWithDelay(
    --     self,
    --     function()
    --         -- gLobalSoundManager:playSound("PussSounds/music_Puss_ChooseView_Over.mp3")

    --         if self.m_isReceiveData == true then
    --             self:closeUi()
    --         end
    --     end,
    --     20/30
    -- )
end

function DragonParadeChooseView:onEnter( )
    DragonParadeChooseView.super.onEnter(self)
    local _isPortrait = globalData.slotRunData.isPortrait
    local _isPortraitMachine = globalData.slotRunData:isMachinePortrait()
    if _isPortrait ~= _isPortraitMachine then
        gLobalNoticManager:addObserver(
            self,
            function(self)
                assert(self.m_csbNode, "csbNode is nill !!! cname is " .. self.__cname)
                
                local csbNodeName = self.m_csbNode:getName()
                if csbNodeName == "Layer" then
                    self:changeVisibleSize(display.size)
                else
                    if not self.m_isUserDefPos then
                        -- 使用的屏幕大小换算的坐标
                        local posX, posY = self:getPosition()
                        self:setPosition(cc.p(posY, posX))
                    end
                end
            end,
            ViewEventType.NOTIFY_RESET_SCREEN
        )
    end
end

function DragonParadeChooseView:onExit()
    DragonParadeChooseView.super.onExit(self)
end

function DragonParadeChooseView:checkAllBtnClickStates()
    local notClick = false

    if self.m_action == self.ACTION_SEND then
        notClick = true
    end

    if self.m_Click then
        notClick = true
    end

    if self.m_isStart_Over_Action then
        notClick = true
    end

    return notClick
end

--默认按钮监听回调
function DragonParadeChooseView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if self:checkAllBtnClickStates() then
        -- 网络消息回来之前 所有按钮都不允许点击
        return
    end
    self.m_Click = true

    self.m_isReceiveData = false
    self.m_selectAnimIsPlayed = false
    if tag == self.CLICK_TAG_FREE then
        self.m_ClickIndex = 2
        self:sendData(1)
        self:playSelectAnim(2)

        gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_click.mp3")
        gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_choose_select.mp3")
    elseif tag == self.CLICK_TAG_RESPIN then
        self.m_ClickIndex = 1
        self:sendData(3)
        self:playSelectAnim(1)

        gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_click.mp3")
        gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_choose_select.mp3")
    end
end

--数据接收
function DragonParadeChooseView:recvBaseData(featureData)
    self.m_isStart_Over_Action = true

    self.m_isReceiveData = true
    if self.m_selectAnimIsPlayed == true then
        self:closeUi()
    else

    end
end

--数据发送
function DragonParadeChooseView:sendData(pos)
    self.m_action = self.ACTION_SEND

    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData = nil

    messageData = {msg = MessageDataType.MSG_BONUS_SELECT, data = pos}

    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData, self.m_isShowTournament)
end

function DragonParadeChooseView:featureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        dump(spinData.result, "featureResultCallFun data", 3)
        local userMoneyInfo = param[3]
        self.m_serverWinCoins = spinData.result.winAmount -- 记录下服务器返回赢钱的结果
        self.m_totleWimnCoins = spinData.result.winAmount
        print("赢取的总钱数为=" .. self.m_totleWimnCoins)
        globalData.userRate:pushCoins(self.m_serverWinCoins)
        globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
        if spinData.action == "FEATURE" then
            self.m_spinDataResult = spinData.result

            self.m_machine.m_runSpinResultData:parseResultData(spinData.result, self.m_machine.m_lineDataPool)

            self.m_featureData:parseFeatureData(spinData.result)
            self:recvBaseData(self.m_featureData)

            --spin后更新 betData
            local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
            if selfdata then
                self.m_machine:updateSingleBetData(selfdata.wildCount, selfdata.wildPos, selfdata.wildLeftTimes, selfdata.wildStatus)
            end
        elseif self.m_isBonusCollect then
            self.m_featureData:parseFeatureData(spinData.result)
            self:recvBaseData(self.m_featureData)
        else
            dump(spinData.result, "featureResult action" .. spinData.action, 3)
        end
    else
        -- 处理消息请求错误情况
    end
end

function DragonParadeChooseView:setEndCall(funcCut, funcEnd)
    self.m_bonusCutCall = funcCut
    self.m_bonusEndCall = funcEnd
end

function DragonParadeChooseView:closeUi()

    if self.m_ClickIndex == 1 then
        --respin
        self:playSpineAnim(self.m_selectFree, "over2", false, function()
        end)
        self:playSpineAnim(self.m_selectRespin, "over", false, function()
        end)
    else
        self:playSpineAnim(self.m_selectFree, "over", false, function()
        end)
        self:playSpineAnim(self.m_selectRespin, "over2", false, function()
        end)
    end

    gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_choose_popupstart_end.mp3")
    self:runCsbAction("over", false, function()
        
    end)

    self.m_baseBonusCollectAddBar:runCsbAction("over", false, function()
    end)
    if self.m_bonusCutCall then
        self.m_bonusCutCall(self.m_ClickIndex)
    end

    performWithDelay(self, function()
        if self.m_bonusEndCall then
            self.m_bonusEndCall(self.m_ClickIndex)
        end
    end, 15/30)


end

return DragonParadeChooseView
