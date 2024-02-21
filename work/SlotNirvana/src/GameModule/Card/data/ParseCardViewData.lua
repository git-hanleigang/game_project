-- //浏览卡片请求返回数据，重置卡片new状态
-- message CardViewResponse {
--   optional string clanId = 1;//查看的卡组id都重置new
-- }
local ParseCardViewData = class("ParseCardViewData")

function ParseCardViewData:ctor()
end

function ParseCardViewData:parseData(data)
    self.clanId = data.clanId
end

return ParseCardViewData
