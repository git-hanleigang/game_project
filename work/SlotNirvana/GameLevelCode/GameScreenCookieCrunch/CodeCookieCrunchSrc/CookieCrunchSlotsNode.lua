local CookieCrunchSlotsNode = class("CookieCrunchSlotsNode", util_require("Levels.SlotsNode"))

-- 解决静态图的展示问题 修改静态图可见性和图片资源的地方都要调用
function CookieCrunchSlotsNode:upDateCookieCrunchSlotsNodeImage(_ccbName)
    -- 不在静态图展示状态
    if nil == self.p_symbolImage or not self.p_symbolImage:isVisible() then
        return
    end
    -- 没有配置
    local ccbName = _ccbName or self.m_ccbName
    local imgList = {
        Socre_CookieCrunch_9 = "#Symbol/Socre_CookieCrunch_9_01.png",
        Socre_CookieCrunch_8 = "#Symbol/Socre_CookieCrunch_8_01.png",
        Socre_CookieCrunch_7 = "#Symbol/Socre_CookieCrunch_7_01.png",
        Socre_CookieCrunch_6 = "#Symbol/Socre_CookieCrunch_6_01.png",
        Socre_CookieCrunch_5 = "#Symbol/Socre_CookieCrunch_5_05.png",
        Socre_CookieCrunch_4 = "#Symbol/Socre_CookieCrunch_4_01.png",
        Socre_CookieCrunch_3 = "#Symbol/Socre_CookieCrunch_3_01.png",
        Socre_CookieCrunch_2 = "#Symbol/Socre_CookieCrunch_2_01.png",
        Socre_CookieCrunch_Wild = "#Symbol/Socre_CookieCrunch_wild_01.png",
    }
    local imgPath = imgList[ccbName]
    if not imgPath then
        local addImage = self.p_symbolImage:getChildByName("CookieCrunchAddImg")
        if addImage then
            addImage:setVisible(false)
        end
        return
    end

    local addImage = self.p_symbolImage:getChildByName("CookieCrunchAddImg")
    if not addImage then
        addImage = display.newSprite(imgPath)
        self.p_symbolImage:addChild(addImage)
        addImage:setName("CookieCrunchAddImg")
        local size = addImage:getContentSize()
        local pos  = cc.p(size.width/2, size.height/2) 
        addImage:setPosition(pos)
    else
        addImage:setVisible(true)
        self:spriteChangeImage(addImage, imgPath)
    end
end

function CookieCrunchSlotsNode:reset()
    CookieCrunchSlotsNode.super.reset(self)
    self:upDateCookieCrunchSlotsNodeImage()
end
function CookieCrunchSlotsNode:resetReelStatus()
    CookieCrunchSlotsNode.super.resetReelStatus(self)
    self:upDateCookieCrunchSlotsNodeImage()
end
function CookieCrunchSlotsNode:initSlotNodeByCCBName(ccbName,symbolType)
    CookieCrunchSlotsNode.super.initSlotNodeByCCBName(self, ccbName,symbolType)
    self:upDateCookieCrunchSlotsNodeImage(ccbName)
end
function CookieCrunchSlotsNode:changeSymbolImageByName(ccbName)
    CookieCrunchSlotsNode.super.changeSymbolImageByName(self, ccbName)
    self:upDateCookieCrunchSlotsNodeImage(ccbName)
end



return CookieCrunchSlotsNode