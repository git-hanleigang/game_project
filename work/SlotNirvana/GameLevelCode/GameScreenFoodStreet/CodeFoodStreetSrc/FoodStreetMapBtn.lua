---
--xcyy
--2018年5月23日
--FoodStreetMapBtn.lua

local FoodStreetMapBtn = class("FoodStreetMapBtn", util_require("base.BaseView"))
local SendDataManager = require "network.SendDataManager"

function FoodStreetMapBtn:initUI(data)
    self.m_machine = data.machine
    self.m_parentLayer = data.parentLayer
    self:createCsbNode("FoodStreet_buttonx3.csb")


    self.m_btnSale = self:findChild("saleBtn")
    self.m_btnChoose = self:findChild("chooseBtn")
    self.m_btnSaleTip = self:findChild("saleBtnTip")
    self.m_btnSaleTip:setVisible(false)
    self:addClick(self.m_btnSaleTip)

    self.m_helpEffect = util_createAnimation("FoodStreet_anniusaoguang_3.csb")
    --util_createView("CodeFoodStreetSrc.FoodStreetBtnEffect")
    self:findChild("helpEffect"):addChild(self.m_helpEffect)
    self.m_helpEffect:runCsbAction("actionframe", true) -- 播放时间线

    self.m_saleEffect = util_createView("CodeFoodStreetSrc.FoodStreetBtnEffect", true)
    self:findChild("saleEffect"):addChild(self.m_saleEffect)
    self.m_saleEffect:setVisible(false)

    self.m_chooseEffect = util_createView("CodeFoodStreetSrc.FoodStreetBtnEffect", true)
    self:findChild("chooseEffect"):addChild(self.m_chooseEffect)

    util_setCascadeOpacityEnabledRescursion(self, true)
end

function FoodStreetMapBtn:onEnter()
end

function FoodStreetMapBtn:onExit()
end

function FoodStreetMapBtn:updateSaleBtn(saleFlag)
    self.m_btnSale:setEnabled(saleFlag or false)
    -- self.m_btnSale:setVisible(saleFlag or false)
    local isVisible = self.m_btnSale:isVisible()
    if isVisible and saleFlag then
        self.m_saleEffect:setVisible(true)
    else
        self.m_saleEffect:setVisible(false)
    end

    self.m_btnSaleTip:setVisible(not saleFlag)
end

function FoodStreetMapBtn:updateChooseBtn(flag)
    self.m_btnChoose:setEnabled(flag or false)
    -- self.m_btnChoose:setVisible(flag or false)
    local isVisible = self.m_btnChoose:isVisible()
    if isVisible and flag then
        self.m_chooseEffect:setVisible(true)
    else
        self.m_chooseEffect:setVisible(false)
    end

    
end

--默认按钮监听回调
function FoodStreetMapBtn:clickFunc(sender)
    if self.m_parentLayer and self.m_parentLayer:getIsClosing() then
        return
    end

    local name = sender:getName()
    local tag = sender:getTag()
   
    if name == "helpBtn" then
        gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_click.mp3")
        local helpLayer = util_createView("CodeFoodStreetSrc.FoodStreetMapRules")
        gLobalViewManager:showUI(helpLayer)
    elseif name == "chooseBtn" then
        gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_click.mp3")
        local isShowBuy = false
        if self.m_machine then
            if self.m_machine:getBuyDogTime() >= 3 and not self.m_machine:isBuyDogOrCollect() then
                isShowBuy = true
            end
        end

        local buyDogInfo = self.m_machine:getBuyDogInfo()

        if isShowBuy and buyDogInfo then
            local info = {}
            info.index = buyDogInfo.id
            info.group = buyDogInfo.groupId
            info.price = self.m_machine:getBuyDogPay()

            local layer = util_createView("CodeFoodStreetSrc.FoodStreetChooseLayer", info)
            layer:setCancleCallFunc(function (  )
                local chooseLayer = util_createView("CodeFoodStreetSrc.FoodStreetRandom")
                gLobalViewManager:showUI(chooseLayer)
            end)
            gLobalViewManager:showUI(layer)
        else
            local chooseLayer = util_createView("CodeFoodStreetSrc.FoodStreetRandom")
            gLobalViewManager:showUI(chooseLayer)
        end
    elseif name == "saleBtn" then
        gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_click.mp3")
        local chooseSellLayer = util_createView("CodeFoodStreetSrc.FoodStreetSell")
        gLobalViewManager:showUI(chooseSellLayer)

    elseif name == "saleBtnTip" then
        if not self.m_FoodStreet_Tips then
            gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_click.mp3")
            self.m_FoodStreet_Tips = util_createView("CodeFoodStreetSrc.FoodStreetSellShopTips") 
            self:addChild(self.m_FoodStreet_Tips,1000000)
            self.m_FoodStreet_Tips:setCallFunc(function(  )

                self.m_FoodStreet_Tips:removeFromParent()
                self.m_FoodStreet_Tips = nil

            end)
            local worldPos = self.m_btnSale:getParent():convertToWorldSpace(cc.p(self.m_btnSale:getPosition()))
            local nodePos = cc.p(self.m_FoodStreet_Tips:getParent():convertToNodeSpace(worldPos))
            self.m_FoodStreet_Tips:setPosition(cc.p(nodePos.x - 60,nodePos.y + 30))

 
            
        end
        
    end
end

return FoodStreetMapBtn
