---
--xcyy
--2018年5月23日
--FoodStreetBuyDogFreeTipView.lua

local FoodStreetBuyDogFreeTipView = class("FoodStreetBuyDogFreeTipView", util_require("base.BaseView"))
local SendDataManager = require "network.SendDataManager"
local BUY_DOG_ID = -200 -- 免费的类型
function FoodStreetBuyDogFreeTipView:initUI(data)
    self:createCsbNode("FoodStreet_maigoutanban_0.csb")

    local lab = self:findChild("BitmapFontLabel_1") -- 获得子节点
    self.m_NeedNum = data.num
    self.m_machine = data.machine

    if lab then
        lab:setString(self.m_NeedNum)
        self:updateLabelSize({label=lab,sx=0.6,sy=0.6},133)  
    end
 
   

    self.m_bClick = true
    self:runCsbAction(
        "star",
        false,
        function()
            self.m_bClick = false
        end
    )

end

function FoodStreetBuyDogFreeTipView:setFun(_fun)
    self.m_fun = _fun
end

function FoodStreetBuyDogFreeTipView:onEnter()
end

function FoodStreetBuyDogFreeTipView:onExit()
end

--默认按钮监听回调
function FoodStreetBuyDogFreeTipView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if self.m_bClick then
        return
    end
    self.m_bClick = true
    gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_click.mp3")
    if name == "Button_1" then --买

        self.m_machine:setBuyDogStates("")
        
        local httpSendMgr = SendDataManager:getInstance()
        local messageData = nil
        local shopPosData = {}
        shopPosData.pageCellIndex = BUY_DOG_ID
        messageData = {msg = MessageDataType.MSG_BONUS_SPECIAL, data = shopPosData}
        httpSendMgr:getNetWorkSlots():requestFeatureData(messageData, self.m_isShowTournament)
        gLobalViewManager:addLoadingAnima()

        self:closeUI()
    end
end

function FoodStreetBuyDogFreeTipView:closeUI()
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


return FoodStreetBuyDogFreeTipView
