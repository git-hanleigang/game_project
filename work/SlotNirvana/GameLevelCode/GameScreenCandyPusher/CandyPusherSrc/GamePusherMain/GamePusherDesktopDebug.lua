
local GamePusherDesktopDebug = class("CoinPusherCardLayer", util_require("base.BaseView"))
local Config    = require("CandyPusherSrc.GamePusherMain.GamePusherConfig")
local GamePusherManager   = require "CandyPusherSrc.GamePusherManager"

function GamePusherDesktopDebug:initUI(mainUI)
    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 or globalData.slotRunData.isPortrait == true then
        isAutoScale = false
    end
    self.m_pMainUI = mainUI
    
    self:createCsbNode(Config.UICsbPath.DeBugLayer,isAutoScale)

    local lbStage = self:findChild("Label_Stage")
    self.m_nodeTextbStage = self:findChild("Text_Stage")

    lbStage:setString("Stage:")
    self:initData()
    -- self:initCheckBox()
    -- self:initTextField()

    self:initTextStage()

end

function GamePusherDesktopDebug:initData()
    self.m_tCoinsData     = clone(Config.DeskTopConfig)
    self.m_tCoinsDataCopy = clone(Config.DeskTopConfig)
end

function GamePusherDesktopDebug:initCheckBox()
    local config = Config.CoinModelRefer 
    for i = 1, #config do
        local name = config[i]
        local checkBox = self:findChild("CheckBox_"..name)
        checkBox:setSelected(false)
        checkBox:onEvent(function(event)
            if event.name == "selected" then
                checkBox:setSelected(true)
                self:checkBoxSelect(name)
            elseif event.name == "unselected" then
                checkBox:setSelected(false)
                self:checkBoxUnSelect()
            end
        end)
    end
end

function GamePusherDesktopDebug:checkBoxSelect(cName)
    local config = Config.CoinModelRefer 
    self.m_pCBSelectName = cName
    for i = 1, #config do
        local name = config[i]
        local checkBox = self:findChild("CheckBox_"..name)
        if name ~= cName then
            checkBox:setSelected(false)
        end
    end
end

function GamePusherDesktopDebug:checkBoxUnSelect()
    self.m_pCBSelectName = false
end

function GamePusherDesktopDebug:initTextStage()
    self.m_nodeTextbStage:addEventListener(function(sender, eventType)
        local event = {}
        if eventType == 0 then
            event.name = "ATTACH_WITH_IME"
        elseif eventType == 1 then
            event.name = "DETACH_WITH_IME"
        elseif eventType == 2 then
            event.name = "INSERT_TEXT"
        elseif eventType == 3 then
            event.name = "DELETE_BACKWARD"
        end
    end)
end

function GamePusherDesktopDebug:initTextField()
    local config = Config.CoinModelRefer 
    for i = 1, #config do
        local name = config[i]
        local textField = self:findChild("Text_"..name)
        local count = self.m_tCoinsData[name] or 0
        textField:setString(tostring(count))
        textField:addEventListener(function(sender, eventType)
            local event = {}
            if eventType == 0 then
                event.name = "ATTACH_WITH_IME"
            elseif eventType == 1 then
                event.name = "DETACH_WITH_IME"
            elseif eventType == 2 then
                event.name = "INSERT_TEXT"
                self.m_tCoinsData[name] = textField:getString()
            elseif eventType == 3 then
                event.name = "DELETE_BACKWARD"
            end
        end)
    end
end

--初始化
function GamePusherDesktopDebug:resetTextFieldString()
    for k,v in pairs(self.m_tCoinsData) do
        local textField = self:findChild("Text_"..k)
        -- textField:setString(tostring(v))
    end
end

function GamePusherDesktopDebug:reducePushType(type)
    -- self.m_tCoinsData[type] = self.m_tCoinsData[type] - 1
    -- if self.m_tCoinsData[type] < 0 then
    --     self.m_tCoinsData[type] = 0
    -- end
    -- local textField = self:findChild("Text_"..type)
    -- textField:setString(tostring(self.m_tCoinsData[type]))
end 

function GamePusherDesktopDebug:addPushType(type)
    -- self.m_tCoinsData[type] = self.m_tCoinsData[type] + 1
    -- local textField = self:findChild("Text_"..type)
    -- textField:setString(tostring(self.m_tCoinsData[type]))
end

function GamePusherDesktopDebug:getPushType()
    if not self.m_pCBSelectName then
        return false
    end

    local leftCount = self.m_tCoinsData[self.m_pCBSelectName] or 0
    if leftCount == 0 then
        return false
    end

    return self.m_pCBSelectName
end

function GamePusherDesktopDebug:clickFunc(sender)
    local senderName = sender:getName()
  
    if senderName == "Button_Random" then
        self.m_pMainUI.m_sp3DEntityRoot:removeAllChildren()
        -- 设置 mask --
        self.m_pMainUI.m_nEntityIndex = Config.EntityIndex 
        self.m_pMainUI.m_tEntityList = {}

        self._RadnomDeskpot = true
        -- self:resetTextFieldString()
        self.m_pMainUI:randomSetDesktop(self.m_tCoinsData)
    elseif senderName == "Button_Delete" then
        if self._RadnomDeskpot then
            self.m_pMainUI.m_sp3DEntityRoot:removeAllChildren()
            self.m_pMainUI.m_nEntityIndex = Config.EntityIndex 
            self.m_pMainUI.m_tEntityList = {}

            self.m_tCoinsData = clone(self.m_tCoinsDataCopy)
            self:resetTextFieldString()
            self._RadnomDeskpot = false
        end
  
    elseif senderName == "Button_Clear" then
        self.m_pMainUI.m_sp3DEntityRoot:removeAllChildren()
        self.m_pMainUI.m_nEntityIndex = Config.EntityIndex        
        self.m_pMainUI.m_tEntityList = {}

        self.m_tCoinsData = clone(self.m_tCoinsDataCopy)
        self:resetTextFieldString()
    elseif senderName == "Button_Save" then
        gLobalNoticManager:postNotification( Config.Event.GamePusherTestSaveData)
    end
end

return GamePusherDesktopDebug