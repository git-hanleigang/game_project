---
--xcyy
--2018年5月23日
--FoodStreetBuyDogTipView.lua

local FoodStreetBuyDogTipView = class("FoodStreetBuyDogTipView", util_require("base.BaseView"))
local SendDataManager = require "network.SendDataManager"
local BUY_DOG_ID = -100
function FoodStreetBuyDogTipView:initUI(data)
    self:createCsbNode("FoodStreet_maigoutanban.csb")

    local lab = self:findChild("BitmapFontLabel_1") -- 获得子节点
    self.m_NeedNum = data.num
    self.m_machine = data.machine
    if lab then
        lab:setString(self.m_NeedNum)
        self:updateLabelSize({label = lab, sx = 0.65, sy = 0.65}, 133)
    end

    self.m_bClick = true
    self:runCsbAction(
        "star",
        false,
        function()
            self.m_bClick = false
        end
    )

    --2.5秒自动关闭
    -- performWithDelay(
    --     self,
    --     function()
    --         self.m_bClick = true
    --         self:closeUI()
    --     end,
    --     2.5
    -- )
end

function FoodStreetBuyDogTipView:setFun(_fun)
    self.m_fun = _fun
end

function FoodStreetBuyDogTipView:onEnter()
end

function FoodStreetBuyDogTipView:onExit()
end

--默认按钮监听回调
function FoodStreetBuyDogTipView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if self.m_bClick then
        return
    end
    self.m_bClick = true
    gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_click.mp3")
    if name == "Button_2" then --不买
        self:closeUI()
    elseif name == "Button_1" then --买
        if self:isEnoughGems() then
            self.m_machine:setBuyDogStates("")
            local httpSendMgr = SendDataManager:getInstance()
            local messageData = nil
            local shopPosData = {}
            shopPosData.pageCellIndex = BUY_DOG_ID
            messageData = {msg = MessageDataType.MSG_BONUS_SPECIAL, data = shopPosData}
            httpSendMgr:getNetWorkSlots():requestFeatureData(messageData, self.m_isShowTournament)
            gLobalViewManager:addLoadingAnima()
        end
        self:closeUI()
    end
end

function FoodStreetBuyDogTipView:closeUI()
    self:runCsbAction(
        "over",
        false,
        function()
            if self.m_fun then
                self.m_fun()
            end
            self:removeFromParent()
        end
    )
end

function FoodStreetBuyDogTipView:isEnoughGems()
    if globalData.userRunData.gemNum >= self.m_NeedNum then
        return true
    else
        local params = {shopPageIndex = 2 , dotKeyType = "Button_1", dotUrlType = DotUrlType.UrlName , dotIsPrep = false}
        G_GetMgr(G_REF.Shop):showMainLayer(params)
    end
end
return FoodStreetBuyDogTipView
