---
--xcyy
--2018年5月23日
--FruitPartySpotOpenView.lua

local FruitPartySpotOpenView = class("FruitPartySpotOpenView", util_require("base.BaseView"))

local MAX_COUNT         =       24      --最大收集数量

function FruitPartySpotOpenView:initUI(params)
    self.m_machine = params.machine
    self.m_roomData = self.m_machine.m_roomData

    self:createCsbNode("FruitParty_SpotBonusWin.csb")
    local leftNode = self:findChild("Node_SpotLeft")

    self.m_title = util_createAnimation("FruitParty_SpotLeft.csb")
    leftNode:addChild(self.m_title)
    self:showBonusComing(false)
    self:showUpSign(true)


    --背景遮罩
    self.m_darkPanel = self:findChild("Panel_2")
    self.m_darkPanel:setTouchEnabled(false)

    self.m_touchPanel = self:findChild("touchPanel")
    self:addClick(self.m_touchPanel)
    self:addClick(self.m_darkPanel)
    self:runCsbAction("idle", false, nil, 60)

    self.m_bShow = false
    self.m_bClick = false
    
end

function FruitPartySpotOpenView:onEnter( )
    self:initBonusViewData()
    self.m_updataAction = schedule(self.m_touchPanel,function()
        self:playSpotIdle()
    end,90 / 60)
end

function FruitPartySpotOpenView:showBonusComing(isShow)
    self.m_title:findChild("Node_Coming"):setVisible(isShow)
    self.m_title:findChild("Node_Num"):setVisible(not isShow)
end

function FruitPartySpotOpenView:showUpSign(isShow)
    self.m_title:findChild("up"):setVisible(isShow)
    self.m_title:findChild("down"):setVisible(not isShow)
end

--初始化
function FruitPartySpotOpenView:initBonusViewData()
    self.m_spotItem = {}
    for index = 1, 24 do
        local node = self:findChild("Node_Spot_" .. index)

        local spotItem = self:createBonusSpotItemByIndex(index, node)

        self.m_spotItem[index] = spotItem
    end

    self:updataLeftTimes()
    self:showLastSpotShow(false)
end

function FruitPartySpotOpenView:resetBonusViewData()

end

function FruitPartySpotOpenView:setClickTouch(_Enabled)
    self.m_touchPanel:setTouchEnabled(_Enabled)
end

--刷新数据
function FruitPartySpotOpenView:updataBonusViewData(_SpotPos)

end

function FruitPartySpotOpenView:getSpotLeftData()
    local collectDatas = self:getCollectsData()
    local num = 0
    for i = 1, #collectDatas do
        local data = collectDatas[i]
        if data and data.udid ~= "" then
            num = num + 1
        end
    end
    return 24 - num
end

--[[
    创建spot
]]
function FruitPartySpotOpenView:createBonusSpotItemByIndex(index, node)
    local collectDatas = self:getCollectsData()

    local spotItem = util_createView("CodeFruitPartySrc.FruitPartySpotItem")
    spotItem:setIndex(index)
    node:addChild(spotItem)
    local data = collectDatas[index]
    if data and data.udid ~= "" then
        spotItem:refreshData(data)
        spotItem:refreshHead(true)
    end
    return spotItem
end

--[[
    刷新spot
]]
function FruitPartySpotOpenView:refreshSpotItem()
    self:updataLeftTimes()
    local collectDatas = self:getCollectsData()
    for index = 1,24 do
        local spotItem = self.m_spotItem[index]
        spotItem:resetStatus()
        --刷新头像
        local data = collectDatas[index]
        if data and data.udid ~= "" then
            spotItem:refreshData(data)
            spotItem:refreshHead(true)
        end
    end
end

function FruitPartySpotOpenView:updataLeftTimes()
    local num = self:getSpotLeftData()
    
    self.m_title:findChild("m_lb_num"):setString(num)

    if num <= 3 then
        if not self.m_title.isRunIdle then
            self.m_title:runCsbAction("idle2",true)
            self.m_title.isRunIdle = true
        end
        
    else
        self.m_title:runCsbAction("idle")
        self.m_title.isRunIdle = false
    end

    self.m_title:findChild("SpotNumLeft_1"):setVisible(num ~= 1)
    self.m_title:findChild("SpotNumLeft_2"):setVisible(num == 1)
end

function FruitPartySpotOpenView:setWinNum(_num, _spotData)
    self.m_OpenNum = _num
    self.m_spotData = _spotData
end

function FruitPartySpotOpenView:showOpenSpotNum(_bshow,func)
    self:showLastSpotShow(true)
    self.m_bClick = true
    self.m_bShow = true
    self.m_darkPanel:setTouchEnabled(true)
    gLobalSoundManager:playSound("FruitPartySounds/sound_FruitParty_wheel_spot_move_over.mp3")
    self:runCsbAction("show",false,function()
        if _bshow then
            self:updataLeftTimes()
        end
        self.m_bClick = false

        performWithDelay(self,function(  )
            if type(func) == "function" then
                func()
            end
        end,1)
        
    end,60)
    self.m_idlePosData = {}


    local collectDatas = self:getCollectsData()
    for i = 1, #collectDatas do
        local data = collectDatas[i]

        if data and data.udid == "" then
            self.m_idlePosData[#self.m_idlePosData + 1] = i
        end
    end
    local WinResult = self.m_roomData:getSpotResult()

    if WinResult then
        self.m_bPlayIdle = false
    else
        self.m_bPlayIdle = true
    end

    self.m_idlePos = 0

    self:showUpSign(false)
end

function FruitPartySpotOpenView:playSpotIdle()
    if self.m_bPlayIdle == true then
        local len = #self.m_idlePosData
        if len > 1 then
            while true do
                local randomPos = xcyy.SlotsUtil:getArc4Random() % len + 1
                local posNum = self.m_idlePosData[randomPos]
                if self.m_idlePos ~= posNum then
                    self.m_idlePos = posNum
                    break
                end
            end
        else
            self.m_idlePos = self.m_idlePosData[1]
        end
    end
end

function FruitPartySpotOpenView:onExit()
    if self.m_updataAction then
        self.m_touchPanel:stopAction(self.m_updataAction)
        self.m_updataAction = nil
    end
end

function FruitPartySpotOpenView:hideSpotWinView(func)
    
    self.m_bClick = true
    self.m_bShow = false
    self.m_OpenNum = nil
    self.m_bPlayIdle = false
    gLobalSoundManager:playSound("FruitPartySounds/sound_FruitParty_wheel_spot_move_over.mp3")
    self:runCsbAction("over",false,function()
        self:showLastSpotShow(false)
        self.m_darkPanel:setTouchEnabled(false)
        self.m_bClick = false
        if type(func) == "function" then
            func()
        end
    end,60)

    self:showUpSign(true)
end

--[[
    中spot动画
]]
function FruitPartySpotOpenView:showHitSpot(data,func)
    self:showOpenSpotNum(true,function(  )
        local spotItem = self.m_spotItem[data.position + 1]
        --最后一格显示直接获取最后一格格子,避免多人同时触发问题
        local result = self.m_roomData:getSpotResult()
        if result then
            spotItem = self:getLastSpot()
        end
        if spotItem then
            spotItem:refreshData(data)
            --提升层级
            local tempZOrder = spotItem:getParent():getLocalZOrder()
            spotItem:getParent():setLocalZOrder(1000)
            spotItem:showHitAni(function()
                --放回原层级
                spotItem:getParent():setLocalZOrder(tempZOrder)
                if result then
                    self:showBonusComing(true)
                else
                    --刷新spot
                    self:refreshSpotItem()
                end
                performWithDelay(self,function(  )
                    self:hideSpotWinView(function(  )
                        if type(func) == "function" then
                            func()
                        end
                    end)
                end,1)
                
            end)
        end
    end)
end

--[[
    获取最后一个spot
]]
function FruitPartySpotOpenView:getLastSpot()
    for k,item in pairs(self.m_spotItem) do
        if item:getPlayerID() == "" then
            return item
        end
    end
end

--默认按钮监听回调
function FruitPartySpotOpenView:clickFunc(sender)
    local name = sender:getName()
    if self.m_bClick then
        return
    end

    if self.m_machine:getGameSpinStage( ) > IDLE or self.m_machine:getCurrSpinMode() ~= NORMAL_SPIN_MODE or self.m_machine.m_isRunningEffect then
        return
    end
    if name == "touchPanel" or name == "Panel_2" then
        if self.m_bShow == false then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
            self:showOpenSpotNum(false)
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
            self:hideSpotWinView()
            
        end
    end
end

--[[
    设置后两行spot显示
]]
function FruitPartySpotOpenView:showLastSpotShow(isShow)
    for index = 17,24 do
        self:findChild("Node_Spot_"..index):setVisible(isShow)
    end
end

--[[
    获取收集数据
]]
function FruitPartySpotOpenView:getCollectsData()
    local WinResult = self.m_roomData:getSpotResult()
    local collectDatas = self.m_roomData:getRoomCollects()
    if WinResult then
        collectDatas = WinResult.data.collects
    end
    return collectDatas
end

return FruitPartySpotOpenView
