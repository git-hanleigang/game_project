
--[[
    author:JohnnyFred
    time:2019-11-08 15:39:42
]]

local InboxItem_luckyChallengeDiamond = class("InboxItem_luckyChallengeDiamond", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_luckyChallengeDiamond:getCsbName()
    return "InBox/InboxItem_luckyChallenge.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_luckyChallengeDiamond:getCardSource()
    return {"Diamond Challenge"}
end
-- 描述说明
function InboxItem_luckyChallengeDiamond:getDescStr()
    return "HERE'S YOUR REWARD"
end

function InboxItem_luckyChallengeDiamond:initView()
    InboxItem_luckyChallengeDiamond.super.initView(self)

    local sp = util_createSprite("InBox/ui_luckyChallenge/luckychallenge.png")
    local scale = 0.5
    sp:setScale(0.7)
    local size = sp:getContentSize()
    self.m_node_reward:addChild(sp)
    table.insert(self.m_uiList, {node = sp, alignX = -size.width/2*scale})

    local extra = cjson.decode(self.m_mailData.extra)
    local str = util_formatCoins(tonumber(extra.points),9)
    self.m_lb_coin:setString(str)
    self.m_lb_coin:setVisible(true)
    self.m_lb_coin:setColor(cc.c3b(255, 255, 255))
    table.insert(self.m_uiList, {node = self.m_lb_coin, alignX = 5.5})

    self:alignLeft(self.m_uiList)
end

return  InboxItem_luckyChallengeDiamond

