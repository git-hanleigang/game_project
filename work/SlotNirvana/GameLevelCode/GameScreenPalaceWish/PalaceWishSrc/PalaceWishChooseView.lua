---
--xcyy
--2018年5月23日
--PalaceWishChooseView.lua

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local PalaceWishChooseView = class("PalaceWishChooseView", BaseGame)

PalaceWishChooseView.m_ClickIndex = 1
PalaceWishChooseView.m_spinDataResult = {}

function PalaceWishChooseView:initUI(machine)
    local isAutoScale = false
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end

    self:createCsbNode("PalaceWish/GameChoose.csb", isAutoScale)

    self.m_machine = machine

    -- self:updateLable()

    self.m_Click = false

    self.m_isStart_Over_Action = true

    self.m_isReceiveData = false
    self.m_selectAnimIsPlayed = false

    self.m_selectSpine = util_spineCreate("PalaceWish_choose", true, true)
    self:findChild("Node_28"):addChild(self.m_selectSpine)
    self.m_selectSpine:setPosition(cc.p(0, 0))


    self:runCsbAction("idle", true)

    util_spinePlay(self.m_selectSpine, "start", false)
    local spineEndCallFunc = function()
        self:addClick(self:findChild("freespinClick"))
        self:addClick(self:findChild("respinClick"))

        util_spinePlay(self.m_selectSpine, "idle", true)

        self.m_isStart_Over_Action = false
    end
    util_spineEndCallFunc(self.m_selectSpine, "start", spineEndCallFunc)


    gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_choose_start.mp3")
end

function PalaceWishChooseView:playSelectAnim(type)
    local animName = "actionframe1"
    local idleName = "idleframe1"
    if type == 1 then
        --respin
        animName = "actionframe1"
        idleName = "idleframe1"
    else
        animName = "actionframe2"
        idleName = "idleframe2"
    end
    self.m_selectSpine:setVisible(true)
    util_spinePlay(self.m_selectSpine, animName, false)
    local spineEndCallFunc = function()
        self.m_selectAnimIsPlayed = true
        util_spinePlay(self.m_selectSpine, idleName, true)
    end
    util_spineEndCallFunc(self.m_selectSpine, animName, spineEndCallFunc)

    --动画结束
    performWithDelay(
        self,
        function()
            -- gLobalSoundManager:playSound("PussSounds/music_Puss_ChooseView_Over.mp3")

            if self.m_isReceiveData == true then
                self:closeUi()
            end
        end,
        20/30
    )
end

-- function PalaceWishChooseView:updateLable()
--     if not self.m_machine then
--         return
--     end

--     local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
--     local freespinTimes = selfdata.freespinTimes

--     local fsNum = self:findChild("BitmapFontLabel_3")

--     if fsNum then
--         fsNum:setString(freespinTimes)
--     end
-- end

function PalaceWishChooseView:onEnter( )
    PalaceWishChooseView.super.onEnter(self)
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

function PalaceWishChooseView:onExit()
    PalaceWishChooseView.super.onExit(self)
end

function PalaceWishChooseView:checkAllBtnClickStates()
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
function PalaceWishChooseView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if self:checkAllBtnClickStates() then
        -- 网络消息回来之前 所有按钮都不允许点击
        return
    end

    -- gLobalSoundManager:playSound("PussSounds/music_Puss_ChooseView_Click.mp3")

    self.m_Click = true

    self.m_isReceiveData = false
    self.m_selectAnimIsPlayed = false
    if name == "freespinClick" then
        self.m_ClickIndex = 2
        self:sendData(1)
        self:playSelectAnim(2)

        gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_click.mp3")
        gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_choose_select_free.mp3")
    elseif name == "respinClick" then
        self.m_ClickIndex = 1
        self:sendData(0)
        self:playSelectAnim(1)

        gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_click.mp3")
        gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_choose_select_respin.mp3")
    end
end

--数据接收
function PalaceWishChooseView:recvBaseData(featureData)
    self.m_isStart_Over_Action = true

    self.m_isReceiveData = true
    if self.m_selectAnimIsPlayed == true then
        self:closeUi()
    else

    end
    -- performWithDelay(
    --     self,
    --     function()
    --         -- gLobalSoundManager:playSound("PussSounds/music_Puss_ChooseView_Over.mp3")

    --         -- self:closeUi(
    --         --     function()
                    
    --         --     end
    --         -- )

    --         self:showReward()
    --     end,
    --     1
    -- )
end

--数据发送
function PalaceWishChooseView:sendData(pos)
    self.m_action = self.ACTION_SEND

    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData = nil

    messageData = {msg = MessageDataType.MSG_BONUS_SELECT, data = pos}

    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData, self.m_isShowTournament)
end

function PalaceWishChooseView:featureResultCallFun(param)
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

function PalaceWishChooseView:setEndCall(funcCut, funcEnd)
    self.m_bonusCutCall = funcCut
    self.m_bonusEndCall = funcEnd
end

function PalaceWishChooseView:closeUi()
    local animName = "guochang1"
    if self.m_ClickIndex == 1 then
        --respin
        animName = "guochang1"
    else
        animName = "guochang2"
    end
    self.m_selectSpine:setVisible(true)
    util_spinePlay(self.m_selectSpine, animName, false)
    local spineEndCallFunc = function()
        self.m_selectSpine:setVisible(false)
    end
    util_spineEndCallFunc(self.m_selectSpine, animName, spineEndCallFunc)


    gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_choose_select_trans.mp3")

    --切
    performWithDelay(
        self,
        function()
            if self.m_bonusCutCall then
                self.m_bonusCutCall(self.m_ClickIndex)
            end
        end,
        40/30
    )
    --end
    performWithDelay(
        self,
        function()
            if self.m_bonusEndCall then
                self.m_bonusEndCall(self.m_ClickIndex)
            end
        end,
        63/30
    )
end

return PalaceWishChooseView
