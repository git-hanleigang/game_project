--
-- Author:zhangkankan
-- Date: 2021-09-06 14:30:45
--
local InboxItem_MergeGameRecycle = class("InboxItem_MergeGameRecycle", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_MergeGameRecycle:getCsbName()
    return "InBox/InboxItem_mergeRecycle.csb"
end

-- 描述说明
function InboxItem_MergeGameRecycle:getDescStr()
    return "MERGIC ISLAND ITEMS RECYCLED"
end

return  InboxItem_MergeGameRecycle