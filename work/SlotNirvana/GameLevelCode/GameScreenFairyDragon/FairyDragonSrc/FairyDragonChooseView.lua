---
--xcyy
--2018年5月23日
--FairyDragonChooseView.lua
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local FairyDragonChooseView = class("FairyDragonChooseView", BaseGame)

FairyDragonChooseView.m_ClickIndex = 1
FairyDragonChooseView.m_spinDataResult = {}

function FairyDragonChooseView:initUI(machine)
    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end
    self:createCsbNode("FairyDragon/FreeSpinStart.csb")

    self.m_machine = machine

    self.m_Click = false

    self.m_isStart_Over_Action = false

    self.bonusChooseType = nil

    self.selectIndex = nil

    self:addClick(self:findChild("panel_free"))
    self:addClick(self:findChild("panel_link"))
end

function FairyDragonChooseView:onEnter()
    FairyDragonChooseView.super.onEnter(self)
    -- gLobalNoticManager:addObserver(
    --     self,
    --     function(self, params)
    --         self:featureResultCallFun(params)
    --     end,
    --     ViewEventType.NOTIFY_GET_SPINRESULT
    -- )
end

function FairyDragonChooseView:onExit()
    FairyDragonChooseView.super.onExit(self)
    self:clearBaseData()
    gLobalNoticManager:removeAllObservers(self)
end

function FairyDragonChooseView:showStartAct()
    self:runCsbAction(
        "start",
        false,
        function()
            self:runCsbAction("idle", true)
        end
    )
end

function FairyDragonChooseView:initMachine(machine)
    self.m_machine = machine
end

function FairyDragonChooseView:checkAllBtnClickStates()
    local notClick = false

    -- if self.m_action == self.ACTION_SEND then
    --     notClick = true
    -- end

    if self.m_Click then
        notClick = true
    end

    if self.m_isStart_Over_Action then
        notClick = true
    end

    return notClick
end

--数据接收
function FairyDragonChooseView:recvBaseData(featureData)
    local data = featureData.p_data
    local selfData = data.selfData

    self:setChooseData(selfData.selectType)

    self.m_isStart_Over_Action = true

    self:showGameSwithForSelect(self.selectIndex, self.bonusChooseType)

    -- self:showEndCall()
end

--数据发送
function FairyDragonChooseView:sendData(pos)
    -- self.m_action=self.ACTION_SEND
    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData = nil
    messageData = {msg = MessageDataType.MSG_BONUS_SELECT, data = pos}
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData, self.m_isShowTournament)
end

function FairyDragonChooseView:setChooseData(chooseType)
    self.bonusChooseType = nil
    if chooseType == "FREE" then
        self.bonusChooseType = 1
    elseif chooseType == "RESPIN" then
        self.bonusChooseType = 2
    end
end

--默认按钮监听回调（服务器随机）
function FairyDragonChooseView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if self:checkAllBtnClickStates() then
        -- 网络消息回来之前 所有按钮都不允许点击
        return
    end
    self.m_Click = true
    -- if self.bonusChooseType == nil then
    --     return
    -- end
    if name == "panel_free" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:sendData(1)
        self.selectIndex = 1
    elseif name == "panel_link" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:sendData(1)
        self.selectIndex = 2
    end
end

--根据服务器返回的选择展示(selectIndex点击的球，selectDate服务器返回的玩法)
function FairyDragonChooseView:showGameSwithForSelect(selectIndex, selectDate)
    --将所有玩法图片都隐藏
    self:setAllWinningFishVisible()
    if selectIndex == 1 then --左边
        if selectDate == 1 then --freeSpin
            self:findChild("WinningFish_freegame"):setVisible(true) --free显示
            self:findChild("WinningFish_freegame"):setOpacity(255)
            self:findChild("WinningFish_reelrespin"):setVisible(true)
            self:findChild("WinningFish_reelrespin"):setOpacity(255)
        elseif selectDate == 2 then
            self:findChild("WinningFish_freegame_1"):setVisible(true)
            self:findChild("WinningFish_freegame_1"):setOpacity(255)
            self:findChild("WinningFish_reelrespin_1"):setVisible(true)
            self:findChild("WinningFish_reelrespin_1"):setOpacity(255)
        end
    elseif selectIndex == 2 then --右边
        if selectDate == 1 then --freeSpin
            self:findChild("WinningFish_freegame_1"):setVisible(true)
            self:findChild("WinningFish_freegame_1"):setOpacity(255)
            self:findChild("WinningFish_reelrespin_1"):setVisible(true)
            self:findChild("WinningFish_reelrespin_1"):setOpacity(255)
        elseif selectDate == 2 then
            self:findChild("WinningFish_freegame"):setVisible(true)
            self:findChild("WinningFish_freegame"):setOpacity(255)
            self:findChild("WinningFish_reelrespin"):setVisible(true)
            self:findChild("WinningFish_reelrespin"):setOpacity(255)
        end
    end
    if selectIndex == 1 then
        self:runCsbAction(
            "switch2",
            false,
            function()
                self:runCsbAction("idle3")
                self:showEndCall()
            end
        )
    elseif selectIndex == 2 then
        self:runCsbAction(
            "switch1",
            false,
            function()
                self:runCsbAction("idle2")
                self:showEndCall()
            end
        )
    end
end

function FairyDragonChooseView:setAllWinningFishVisible()
    self:findChild("WinningFish_freegame"):setVisible(false)
    self:findChild("WinningFish_freegame"):setOpacity(0)
    self:findChild("WinningFish_freegame_1"):setVisible(false)
    self:findChild("WinningFish_freegame_1"):setOpacity(0)
    self:findChild("WinningFish_reelrespin"):setVisible(false)
    self:findChild("WinningFish_reelrespin"):setOpacity(0)
    self:findChild("WinningFish_reelrespin_1"):setVisible(false)
    self:findChild("WinningFish_reelrespin_1"):setOpacity(0)
end

function FairyDragonChooseView:showEndCall()
    performWithDelay(
        self,
        function()
            if self.m_bonusEndCall then
                self.m_bonusEndCall()
            end
        end,
        0.5
    )
end

function FairyDragonChooseView:setEndCall(func)
    self.m_bonusEndCall = func
end

return FairyDragonChooseView
