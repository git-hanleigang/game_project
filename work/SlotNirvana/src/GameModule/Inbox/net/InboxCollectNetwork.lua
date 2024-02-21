-- 处理网络请求
local BaseInboxNetwork = util_require("GameModule.Inbox.net.BaseInboxNetwork")
local InboxCollectNetwork = class("InboxCollectNetwork", BaseInboxNetwork)
function InboxCollectNetwork:ctor()
    BaseInboxNetwork.ctor(self)
end

function InboxCollectNetwork:sendLog(mailIds)
    local mailData = G_GetMgr(G_REF.Inbox):getSysRunData():getMailData()
    for i = #mailIds, 1, -1 do
        for j = 1, #mailData do
            if tonumber(mailData[j].id) == tonumber(mailIds[i]) then
                local collectTime = os.time()
                gLobalSendDataManager:getLogFeature():sendInboxLog(mailData[j],G_GetMgr(G_REF.Inbox):getReadTime(),collectTime)
                break
            end
        end
    end    
end

-- 领取某些邮件
function InboxCollectNetwork:collectMail(mailIds, successBackFun, faildBackFun)
    -- self:sendLog(mailIds)
    
    --发送领取消息
    gLobalSendDataManager:getNetWorkFeature():SendMailCollect(mailIds,function()
        -- 更新邮件信息
        local collectData = G_GetMgr(G_REF.Inbox):getSysRunData()
        if collectData then
            collectData:removeShowMailDataById(mailIds)
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REFRESH_MAIL_COUNT, G_GetMgr(G_REF.Inbox):getMailCount())
        if successBackFun then
            successBackFun()
        end
    end,faildBackFun)
end

-- 请求邮件列表
function InboxCollectNetwork:requestMailList(successCallFun, failedCallFun)
    gLobalSendDataManager:getNetWorkFeature():SendQueryMail(
        function(data)
            -- G_GetMgr(G_REF.Inbox):getSysRunData():updataLocalMail()
            -- G_GetMgr(G_REF.Inbox):getSysRunData():initMailData(data)
            -- G_GetMgr(G_REF.Inbox):getSysRunData():addLocalMail()
            G_GetMgr(G_REF.Inbox):parseCollectData(data)
            --回调
            if successCallFun ~= nil then
                successCallFun()
            end
        end, function(data)
            --请求失败
            if failedCallFun ~= nil then
                failedCallFun(data)
            end
        end
    )
end

return InboxCollectNetwork