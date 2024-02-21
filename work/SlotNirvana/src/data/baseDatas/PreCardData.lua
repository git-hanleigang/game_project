--
--版权所有:{company}
-- Author:{author}
-- Date: 2019-04-13 11:30:18
--
local BaseActivityData = require("baseActivity.BaseActivityData")
local PreCardData = class("PreCardData", BaseActivityData)

function PreCardData:ctor()
    PreCardData.super.ctor(self)
    self.p_open = true
end

function PreCardData:checkOpenLevel( )
    if not PreCardData.super.checkOpenLevel(self) then
        return false
    end

    local curLevel = globalData.userRunData.levelNum
    if curLevel == nil then
        return false
    end

    if not CC_CAN_ENTER_CARD_COLLECTION then
        return false
    end
    
    --常量表开启等级
    local needLevel = globalData.constantData.CARD_OPEN_LEVEL or 20
    if needLevel > curLevel then
        return false
    end

    return true
end

return PreCardData
