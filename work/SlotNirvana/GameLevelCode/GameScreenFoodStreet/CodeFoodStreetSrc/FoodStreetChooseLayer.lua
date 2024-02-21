---
--xcyy
--2018年5月23日
--FoodStreetChooseLayer.lua

local FoodStreetChooseLayer = class("FoodStreetChooseLayer", util_require("base.BaseView"))
local SendDataManager = require "network.SendDataManager"
local BUY_DOG_ID = -100

FoodStreetChooseLayer.m_click = false

FoodStreetChooseLayer.m_viewType = 4

function FoodStreetChooseLayer:initUI(data)
    local isHouse = false
    local csbName = "FoodStreet/xiaotanban4.csb"
    if data.type == "FOOD" then
        self.m_viewType = 1
        csbName = "FoodStreet/xiaotanban1.csb"
    elseif data.index == 0 then
        self.m_viewType = 3
        csbName = "FoodStreet/xiaotanban3.csb"
    elseif data.price == 0 then
        self.m_viewType = 2
        csbName = "FoodStreet/xiaotanban2.csb"
        isHouse = true
    end
    self:createCsbNode(csbName)

    self.m_index = data.index
    self.m_price = data.price or 0
    self:setPriceNum()
    local index = 1
    while true do
        local animal = self:findChild("animal_" .. index)
        if animal ~= nil then
            if index ~= data.group then
                animal:setVisible(false)
            end
        else
            break
        end
        index = index + 1
    end

    if isHouse then
        for i = 1, 4 do
            local house = self:findChild("FoodStreet_jianzhu0" .. i)
            if house ~= nil then
                house:setVisible(i == data.group)
            end
        end
    end

    self.m_click = true

    self:runCsbAction(
        "start",
        false,
        function()
            self.m_click = false
        end
    )
end

function FoodStreetChooseLayer:onEnter()
end

function FoodStreetChooseLayer:onExit()
end

--默认按钮监听回调
function FoodStreetChooseLayer:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if self.m_click then
        return
    end

    gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_click.mp3")
    if name == "Button_no" then
        self.m_click = true
        if self.m_cancleCallFunc then
            self.m_cancleCallFunc()
        end
        self:closeUI()
    else
        local httpSendMgr = SendDataManager:getInstance()
        local messageData = nil
        local shopPosData = {}
        shopPosData.pageCellIndex = self.m_index
        if self.m_index == 0 and name == "Button_zuanshi" then
            if not self:isEnoughGems() then
                return
            end
            shopPosData.pageCellIndex = BUY_DOG_ID

            self:setBuyDogStates("")
        end

        messageData = {msg = MessageDataType.MSG_BONUS_SPECIAL, data = shopPosData}

        httpSendMgr:getNetWorkSlots():requestFeatureData(messageData, self.m_isShowTournament)
        gLobalViewManager:addLoadingAnima()

        self.m_click = true

        self:closeUI()
    end
end

function FoodStreetChooseLayer:setBuyDogStates(states)
    gLobalDataManager:setStringByField("buyDogStates", states, true)
end

function FoodStreetChooseLayer:closeUI()
    self:runCsbAction(
        "over",
        false,
        function()
            self:removeFromParent()
        end
    )
end

function FoodStreetChooseLayer:setPriceNum()
    -- if 0 == self.m_index then
    --     print("设置买狗的价格 = " .. self.m_price)
    -- end
    local lab = self:findChild("BitmapFontLabel_1")
    if lab then
        lab:setString(self.m_price)
        if self.m_viewType == 3 then
            self:updateLabelSize({label = lab, sx = 0.7, sy = 0.7}, 217)
        end
    end
end

function FoodStreetChooseLayer:sendMessage()
end

function FoodStreetChooseLayer:isEnoughGems()
    if globalData.userRunData.gemNum >= self.m_price then
        return true
    else
        local params = {shopPageIndex = 2, dotKeyType = "Button_1", dotUrlType = DotUrlType.UrlName, dotIsPrep = false}
        G_GetMgr(G_REF.Shop):showMainLayer(params)
    end
end

function FoodStreetChooseLayer:setCancleCallFunc(callFunc)
    self.m_cancleCallFunc = callFunc
end

return FoodStreetChooseLayer
