--[[
    des: bigwin挑战
    author:{author}
]]
local InboxItem_bigWin = class("InboxItem_bigWin", util_require("views.inbox.item.InboxItem_baseReward"))


function InboxItem_bigWin:initView()
    InboxItem_bigWin.super.initView(self)
end

function InboxItem_bigWin:getCsbName()
    return "InBox/InboxItem_bigwin.csb"
end

-- 描述说明
function InboxItem_bigWin:getDescStr()
    return "BIGWIN REWARD"
end

-- 如果有掉卡，在这里设置来源
function InboxItem_bigWin:getCardSource()
    return {"Big Win Challenge"}
end

return  InboxItem_bigWin