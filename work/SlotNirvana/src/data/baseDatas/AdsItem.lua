--
--版权所有:{company}
-- Author:{author}
-- Date: 2019-04-13 11:30:18
--
local AdsItem = class("AdsItem")

AdsItem.p_position = nil
AdsItem.p_level = nil
AdsItem.p_cdTime = nil
AdsItem.p_coins = nil
AdsItem.p_showTime = nil
AdsItem.p_open = nil
AdsItem.p_type = nil
AdsItem.p_id = nil
AdsItem.p_publicCd = nil
AdsItem.p_dailyTimes = nil
function AdsItem:ctor()
end

function AdsItem:parseData(data)
    self.p_position = data.position
    self.p_level = data.level
    self.p_cdTime = data.cdTime
    self.p_coins = data.coins
    self.p_showTime = os.time() - 1 --防止在统一秒之内进行逻辑判断
    self.p_playTimes = data.playTimes
    if data.open == 1 or data.open == nil then
        self.p_open = true
    else
        self.p_open = false
    end
    self.p_type = data.type
    self.p_id = data.id

    -- csc 2021年09月26日17:07:32 添加一个公用CD字段
    self.p_publicCd = data.publicCd or 60

    self.p_dailyTimes = data.dailyTimes or 0 --每日次数
end

function AdsItem:getType()
    return self.p_type
end

function AdsItem:getPos()
    return self.p_position
end

return AdsItem
