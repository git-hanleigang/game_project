--
--版权所有:{company}
-- Author:{author}
-- Date: 2019-04-13 11:30:18
--
local BaseActivityData = require("baseActivity.BaseActivityData")
local OpenNewLvData = class("OpenNewLvData", BaseActivityData)

function OpenNewLvData:ctor()
    OpenNewLvData.super.ctor(self)
    self.p_open = true
end

function OpenNewLvData:checkOpenLevel()
    if not OpenNewLvData.super.checkOpenLevel(self) then
        return false
    end

    local curLevel = globalData.userRunData.levelNum
    if curLevel == nil then
        return false
    end

    --常量表开启等级
    local needLevel = globalData.constantData.OPENLEVEL_ACTIVITY_NEWLEVEL or 5
    if needLevel > curLevel then
        return false
    end

    return true
end

return OpenNewLvData
