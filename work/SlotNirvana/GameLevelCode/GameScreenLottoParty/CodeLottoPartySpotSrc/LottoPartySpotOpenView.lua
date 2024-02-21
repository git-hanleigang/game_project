---
--xcyy
--2018年5月23日
--LottoPartySpotOpenView.lua

local LottoPartySpotOpenView = class("LottoPartySpotOpenView", util_require("base.BaseView"))

function LottoPartySpotOpenView:initUI()
    self:createCsbNode("LottoParty_SpotBonusWin.csb")
    local leftNode = self:findChild("Node_SpotLeft")
    self.m_left = util_createAnimation("LottoParty_SpotLeft.csb")
    leftNode:addChild(self.m_left)
    self.m_leftTimes = self.m_left:findChild("m_lb_num")
    self.m_textComing = self.m_left:findChild("Node_Coming")
    self.m_textComing:setVisible(false)
    self.m_NumNode = self.m_left:findChild("Node_Num")

    self.m_leftUp = self.m_left:findChild("up")
    self.m_leftDown = self.m_left:findChild("down")
    self.m_leftDown:setVisible(false)

    self.m_darkPanel = self:findChild("Panel_2")
    self.m_darkPanel:setTouchEnabled(false)
    self.m_touchPanel = self:findChild("touchPanel")
    self:addClick(self.m_touchPanel)
    self:addClick(self.m_darkPanel)
    self:runCsbAction("idle", false, nil, 60)
    self.m_bShow = false
    self.m_bClick = false
    self:initBonusViewData()
    self.m_updataAction =
        schedule(
        self.m_touchPanel,
        function()
            self:playSpotIdle()
        end,
        90 / 60
    )
end

--初始化
function LottoPartySpotOpenView:initBonusViewData()
    local collectDatas = LottoPartyManager:getRoomCollects()
    self.m_spotCsb = {}
    for i = 1, #collectDatas do
        local data = collectDatas[i]
        -- local itemCsb = self:createBonusSpotItem(i, data)
        local node = self:findChild("Node_Spot_" .. i)
        local pos = cc.p(node:getPosition())

        local itemCsb1 = self:createBonusSpotItemByIndex(i, data, 1, pos)
        local itemCsb2 = self:createBonusSpotItemByIndex(i, data, 2, pos)
        local itemCsb3 = self:createBonusSpotItemByIndex(i, data, 3, pos)
        local itemCsb4 = self:createBonusSpotItemByIndex(i, data, 4, pos)
        local itemCsb5 = self:createBonusSpotItemByIndex(i, data, 5, pos)
        local itemCsb6 = self:createBonusSpotItemByIndex(i, data, 6, pos)
        local csbData = {}

        csbData[1] = itemCsb1
        csbData[2] = itemCsb2
        csbData[3] = itemCsb3
        csbData[4] = itemCsb4
        csbData[5] = itemCsb5
        csbData[6] = itemCsb6

        self.m_spotCsb[i] = csbData
    end

    self:updataLeftTimes()
    self:showOrHideThreeRow(false)
end

function LottoPartySpotOpenView:resetBonusViewData()
    local collectDatas = LottoPartyManager:getRoomCollects()

    for i = 1, #collectDatas do
        local data = collectDatas[i]
        local itemCsbData = self.m_spotCsb[i]
        if _SpotPos ~= i then
            for i = 1, #itemCsbData do
                local itemCsb = itemCsbData[i]
                itemCsb:updateUI(data)
            end
        end
    end
    local num = self:getSpotLeftData()
    self.m_leftTimes:setString(tostring(num))
    self.m_textComing:setVisible(false)
    self.m_NumNode:setVisible(true)
    if num <= 3 then
        self.m_left:runCsbAction("idle2", true, nil, 60)
    else
        self.m_left:runCsbAction("idle", false, nil, 60)
    end
end

function LottoPartySpotOpenView:setClickTouch(_Enabled)
    self.m_touchPanel:setTouchEnabled(_Enabled)
end

--刷新数据
function LottoPartySpotOpenView:updataBonusViewData(_SpotPos)
    local collectDatas = LottoPartyManager:getRoomCollects()

    for i = 1, #collectDatas do
        local data = collectDatas[i]
        -- local itemCsb = self.m_spotCsb[i]
        local itemCsbData = self.m_spotCsb[i]
        if _SpotPos ~= i then
            for i = 1, #itemCsbData do
                local itemCsb = itemCsbData[i]
                itemCsb:updateUI(data)
            end
        end
    end
    if _SpotPos == -1 then
        self:updataLeftTimes()
    end

    self.m_idlePosData = {}
    local collectDatas = LottoPartyManager:getRoomCollects()
    for i = 1, #collectDatas do
        local data = collectDatas[i]

        if data and data.udid == "" then
            self.m_idlePosData[#self.m_idlePosData + 1] = i
        end
    end
end

function LottoPartySpotOpenView:getSpotLeftData()
    local collectDatas = LottoPartyManager:getRoomCollects()
    local num = 0
    for i = 1, #collectDatas do
        local data = collectDatas[i]
        if data and data.udid ~= "" then
            num = num + 1
        end
    end
    return 24 - num
end

function LottoPartySpotOpenView:createBonusSpotItem(_num, collectata)
    local spotItem = util_createView("CodeLottoPartySpotSrc.LottoPartySpot", collectata)
    spotItem:setSpotNum(_num)
    return spotItem
end

function LottoPartySpotOpenView:createBonusSpotItemByIndex(_num, _collectata, _index, _pos)
    local spotItem = util_createView("CodeLottoPartySpotSrc.LottoPartySpot" .. _index, _collectata)
    spotItem:setSpotNum(_num)
    spotItem:setPosition(_pos)
    self:findChild("Node_69"):addChild(spotItem, _index)
    return spotItem
end

function LottoPartySpotOpenView:updataLeftTimes()
    local num = self:getSpotLeftData()
    self.m_leftTimes:setString(tostring(num))
    if num <= 3 then
        self.m_left:runCsbAction("idle2", true, nil, 60)
    else
        self.m_left:runCsbAction("idle", false, nil, 60)
    end

    local num = self:getSpotLeftData()
    if num == 24 and LottoPartyManager:getSpotResult() then
        self.m_textComing:setVisible(true)
        self.m_NumNode:setVisible(false)
    else
        self.m_textComing:setVisible(false)
        self.m_NumNode:setVisible(true)
    end
end

function LottoPartySpotOpenView:setWinNum(_num, _spotData)
    self.m_OpenNum = _num
    self.m_spotData = _spotData
end

function LottoPartySpotOpenView:setFunc(_func)
    self.m_func = _func
end

function LottoPartySpotOpenView:playOpenSpotCsbByPos()
    if self.m_OpenNum then
        gLobalSoundManager:playSound("LottoPartySounds/sound_LottoParty_open_spot.mp3")
        local itemCsbData = self.m_spotCsb[self.m_OpenNum]

        for i = 1, #itemCsbData do
            local itemCsb = itemCsbData[i]
            itemCsb:updataSpotData(self.m_spotData)
            if i == 1 then
                itemCsb:openSoptItem(
                    function()
                        performWithDelay(
                            self,
                            function()
                                self:hideSpotWinView()
                            end,
                            0.5
                        )
                    end
                )
            else
                itemCsb:openSoptItem(nil)
            end
        end
    end
end

function LottoPartySpotOpenView:showOpenSpotNum(_bshow)
    self.m_bClick = true
    self.m_bShow = true
    self.m_darkPanel:setTouchEnabled(true)
    self:showOrHideThreeRow(true)
    self.m_leftUp:setVisible(false)
    self.m_leftDown:setVisible(true)
    gLobalSoundManager:playSound("LottoPartySounds/sound_LottoParty_up_and_down.mp3")
    self:runCsbAction(
        "show",
        false,
        function()
            if _bshow then
                self:playOpenSpotCsbByPos()
                self:updataLeftTimes()
            else
                self.m_bClick = false
            end
        end,
        60
    )
    self.m_idlePosData = {}
    local collectDatas = LottoPartyManager:getRoomCollects()
    for i = 1, #collectDatas do
        local data = collectDatas[i]

        if data and data.udid == "" then
            self.m_idlePosData[#self.m_idlePosData + 1] = i
        end
    end
    local WinResult = LottoPartyManager:getSpotResult()

    if WinResult then
        self.m_bPlayIdle = false
    else
        self.m_bPlayIdle = true
    end

    self.m_idlePos = 0
end

function LottoPartySpotOpenView:playSpotIdle()
    if self.m_bPlayIdle == true then
        local len = #self.m_idlePosData
        if len > 1 then
            while true do
                local randomPos = xcyy.SlotsUtil:getArc4Random() % len + 1
                local posNum = self.m_idlePosData[randomPos]
                if self.m_idlePos ~= posNum then
                    self.m_idlePos = posNum
                    print(" LottoPartySpotOpenView:playSpotIdle() ===Pos" .. self.m_idlePos)
                    break
                end
            end
        else
            self.m_idlePos = self.m_idlePosData[1]
        end

        local itemCsbData = self.m_spotCsb[self.m_idlePos]
        if itemCsbData then
            for i = 1, #itemCsbData do
                local itemCsb = itemCsbData[i]
                itemCsb:runCsbAction("idleframe2", false, nil, 60)
            end 
        end
        
    end
end

function LottoPartySpotOpenView:onExit()
    if self.m_updataAction then
        self.m_touchPanel:stopAction(self.m_updataAction)
        self.m_updataAction = nil
    end
end

function LottoPartySpotOpenView:hideSpotWinView()
    self.m_bClick = true
    self.m_bShow = false
    self.m_OpenNum = nil
    self.m_bPlayIdle = false
    self.m_leftUp:setVisible(true)
    self.m_leftDown:setVisible(false)
    gLobalSoundManager:playSound("LottoPartySounds/sound_LottoParty_up_and_down.mp3")
    self:runCsbAction(
        "over",
        false,
        function()
            self:showOrHideThreeRow(false)
            self.m_darkPanel:setTouchEnabled(false)
            self.m_bClick = false
            if self.m_func then
                self.m_func()
                self.m_func = nil
            end
        end,
        60
    )
end

function LottoPartySpotOpenView:showOrHideThreeRow(_show)
    for i = 17, 24 do
        local itemCsbData = self.m_spotCsb[i]
        for i = 1, #itemCsbData do
            local itemCsb = itemCsbData[i]
            itemCsb:setVisible(_show)
        end
    end
end

--默认按钮监听回调
function LottoPartySpotOpenView:clickFunc(sender)
    local name = sender:getName()
    if self.m_bClick then
        return
    end
    if name == "touchPanel" or name == "Panel_2" then
        if self.m_bShow == false then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
            self:showOpenSpotNum(false)
        else
            self:hideSpotWinView()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
        end
    end
end

return LottoPartySpotOpenView
