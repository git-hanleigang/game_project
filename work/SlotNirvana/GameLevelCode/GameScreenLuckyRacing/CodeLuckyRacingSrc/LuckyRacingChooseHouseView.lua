---
--xcyy
--2018年5月23日
--LuckyRacingChooseHouseView.lua
local BaseDialog = util_require("Levels.BaseDialog")
local SendDataManager = require "network.SendDataManager"
local LuckyRacingChooseHouseView = class("LuckyRacingChooseHouseView",BaseDialog)

local SOUND_CHOOSE = {
    "LuckyRacingSounds/sound_LuckyRacing_choose_yellow.mp3",
    "LuckyRacingSounds/sound_LuckyRacing_choose_purple.mp3",
    "LuckyRacingSounds/sound_LuckyRacing_choose_bule.mp3",
    "LuckyRacingSounds/sound_LuckyRacing_choose_green.mp3"
}


function LuckyRacingChooseHouseView:initUI(params)
    self.m_machine = params.machine
    self.m_callBack = params.callBack
    self:createCsbNode("LuckyRacing/ChooseHorse.csb")
    --当前选中的马
    self.m_curIndex = -1

    self.m_hourseItems = {}
    for index = 1,4 do
        local item = util_createView("CodeLuckyRacingSrc.LuckyRacingChooseHouseItem",{index = index,parent = self})
        self:findChild("chooseHorse_"..(index - 1)):addChild(item)
        self.m_hourseItems[index] = item
    end

    self.m_btn = self:findChild("Button")
    self.m_btn:setBright(false)
    self.m_btn:setTouchEnabled(false)
end

function LuckyRacingChooseHouseView:onEnter()
    LuckyRacingChooseHouseView.super.onEnter(self)
    gLobalNoticManager:addObserver(self,function(self,params)
        self.m_machine:resetCollectPercent()

        self.m_machine.m_curSelect = self.m_curIndex - 1
        --重新刷新房间消息
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_START_REFRESH_ROOM_DATA)

        self:showViewOver()

    end,ViewEventType.NOTIFY_GET_SPINRESULT)

    local _isPortrait = globalData.slotRunData.isPortrait
    local _isPortraitMachine = globalData.slotRunData:isMachinePortrait()
    if _isPortrait ~= _isPortraitMachine then
        gLobalNoticManager:addObserver(
            self,
            function(self)
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

    gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_show_select_view.mp3")
    self:openDialog()
end

--开始ccb中配置 暂时屏蔽
function LuckyRacingChooseHouseView:showStart()
    self.m_status = self.STATUS_START
    self:runCsbAction(self.m_start_name)
    local time = self:getAnimTime(self.m_start_name)
    if not time or time <= 0 then
        time = self.m_startTime
    end

    performWithDelay(
        self,
        function()
            self:runCsbAction("idle2")
        end,
        time
    )
end

--[[
    点击按钮
]]
function LuckyRacingChooseHouseView:clickFunc(sender)
    if not self.m_allowClick then
        return
    end
    self.m_allowClick = false

    gLobalSoundManager:playSound(SOUND_CHOOSE[self.m_curIndex])

    self:sendChoose()

    
end

--[[
    发送选择
]]
function LuckyRacingChooseHouseView:sendChoose()
    
    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData = {
        msg = MessageDataType.MSG_BONUS_SPECIAL, 
        data = {
            pageCellIndex = self.m_curIndex - 1
        }
        
    }
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)
end

--[[
    隐藏界面
]]
function LuckyRacingChooseHouseView:showViewOver()
    
    self.m_machine:delayCallBack(0.3,function()
        if type(self.m_callBack) == "function" then
            self.m_callBack()
        end
    end)
    if not self.m_machine.m_isRunningEffect then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
    end
    
    self:showOver()
end

--待机ccb中配置暂时屏蔽
function BaseDialog:showidle()
    self.m_status = self.STATUS_IDLE

    --循环播放
    self:runCsbAction(self.m_idle_name, true)
end

--[[
    刷新选中的马
]]
function LuckyRacingChooseHouseView:updateChooseHourse(index)
    self.m_curIndex = index

    self.m_btn:setBright(true)
    self.m_btn:setTouchEnabled(true)

    self:showidle()

    self.m_isRunChooseAni = true

    for key,item in pairs(self.m_hourseItems) do
        if key == index then
            item:runSelectAni(function()
                self.m_isRunChooseAni = false
            end)
        else
            if item.m_isSelected then
                item:overAni(function()
                    item:runIdle()
                end)
            else
                item:runIdle()
            end
            
        end
    end
end

--[[
    获取当前全中的马
]]
function LuckyRacingChooseHouseView:getCurHourse()
    return self.m_curIndex
end

return LuckyRacingChooseHouseView