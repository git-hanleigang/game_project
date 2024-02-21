---
--xcyy
--2018年5月23日
--FoodStreetRandom.lua
local SendDataManager = require "network.SendDataManager"
local FoodStreetRandom = class("FoodStreetRandom",util_require("base.BaseView"))

FoodStreetRandom.m_click = false

function FoodStreetRandom:initUI()

    self:createCsbNode("FoodStreet/tishitanban.csb")

    self.m_click = true

    self:runCsbAction("start", false, function()

        self.m_click = false

        self:runCsbAction("idle", true)

    end) 
end


function FoodStreetRandom:onEnter()
 

end

function FoodStreetRandom:onExit()
 
end

--默认按钮监听回调
function FoodStreetRandom:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if self.m_click then
        return 
    end

    self.m_click = true

    gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_click.mp3")
    if name == "Button_yes" then
        -- gLobalNoticManager:postNotification("RANDOM_SHOW_CHOOSELAYER")
        
        local httpSendMgr = SendDataManager:getInstance()
        local messageData=nil
        local shopPosData = {} 
        shopPosData.pageCellIndex = -1
    
        messageData={msg = MessageDataType.MSG_BONUS_SPECIAL , data = shopPosData }
    
        httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)
        gLobalViewManager:addLoadingAnima()
    end
    self:runCsbAction("over", false, function()
        self:removeFromParent()
    end) 
end


return FoodStreetRandom