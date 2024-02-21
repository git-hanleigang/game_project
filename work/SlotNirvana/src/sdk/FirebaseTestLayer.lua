--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-12-14 18:26:14
]]
local FirebaseTestTable = require("sdk.FirebaseTestTable")
local FirebaseTestLayer = class("FirebaseTestLayer", BaseLayer)

function FirebaseTestLayer:initDatas()
    self:setShowActionEnabled(false)
    self:setHideActionEnabled(false)
end

function FirebaseTestLayer:initView()
    local _tbSize = cc.size(display.width / 2, display.height)
    local param = {tableSize = _tbSize, parentPanel = self, directionType = 2}
    self.m_tbFbase = FirebaseTestTable:create(param)
    self.m_tbFbase:setPositionX(display.width / 4)
    self:addChild(self.m_tbFbase)

    local btn_1 = ccui.Button:create("Default/Button_Normal.png", "Default/Button_Press.png")
    btn_1:setName("Clear")
    btn_1:setTitleText("Clear")
    btn_1:setTitleFontSize(28)
    btn_1:ignoreContentAdaptWithSize(false)
    btn_1:setContentSize(cc.size(100, 50))
    btn_1:setTitleColor(cc.c3b(255, 0, 0))
    btn_1:setPosition(display.width - 200, display.cy - 50)
    self:addChild(btn_1)
    self:addClick(btn_1)

    local btn_2 = ccui.Button:create("Default/Button_Normal.png", "Default/Button_Press.png")
    btn_2:setName("Close")
    btn_2:setTitleText("Close")
    btn_2:setTitleFontSize(28)
    btn_2:ignoreContentAdaptWithSize(false)
    btn_2:setContentSize(cc.size(100, 50))
    btn_2:setTitleColor(cc.c3b(255, 0, 0))
    btn_2:setPosition(display.width - 200, display.cy + 50)
    self:addChild(btn_2)
    self:addClick(btn_2)
end

function FirebaseTestLayer:initUI()
    FirebaseTestLayer.super.initUI(self)
    self.m_tbFbase:reload(globalFireBaseManager:getLog())
end

function FirebaseTestLayer:clearData()
    globalFireBaseManager:clearLog()
    self.m_tbFbase:reload(globalFireBaseManager:getLog())
end

function FirebaseTestLayer:clickFunc(sender)
    local sName = sender:getName()
    if sName == "Close" then
        self:closeUI()
    elseif sName == "Clear" then
        self:clearData()
    end
end

return FirebaseTestLayer
