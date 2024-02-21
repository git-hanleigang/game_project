--[[--
    邮件页签基类
    可以领奖的界面用的基类
]]
local InboxPage_base = util_require("views.inbox.InboxPage_base")
local InboxPage_collectBase = class("InboxPage_collectBase", InboxPage_base)

function InboxPage_collectBase:initUI(mainClass)
    InboxPage_base.initUI(self, mainClass)
    self.m_list = self:getList()
    self.m_emptyEmailNode = self:findChild("node_notEmail")
    self:showEmptyNode(false)    
    self.m_isRefreshCount = 0
end

function InboxPage_collectBase:showEmptyNode(isShow)
    self.m_emptyEmailNode:setVisible(isShow)
end  

function InboxPage_collectBase:clickFunc(sender)
    InboxPage_base.clickFunc(self, sender)

    local name = sender:getName()
    local tag = sender:getTag()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    
    if name == "btn_collectAll" then --领取所有
        self:collectAllMail()
    end
end

-->>> UI显示部分 子类重写 ------------------------------------------------------ 
-- -- 显示的最小数量
-- function InboxPage_collectBase:getMinNum()
--     return 0
-- end

-- -- 显示的最大数量
-- function InboxPage_collectBase:getMaxNum()
--     return 50
-- end

-- 当前邮件列表的数量
function InboxPage_collectBase:getCount()
    local mailAllData = self:getAllMailData()
    return #mailAllData
    -- return math.max(self:getMinNum(), math.min(self:getMaxNum(), #mailAllData))
end

-- -- 子类实现
-- function InboxPage_collectBase:getAllMailData()
--     return {}
-- end

-- 子类实现
function InboxPage_collectBase:createItemCell()
end

-- 子类实现
function InboxPage_collectBase:getList()
    return self:findChild("list")
end

function InboxPage_collectBase:updataInboxItem()
    --邮件刷新判断
    -- if self.m_isRefreshCount and self.m_isRefreshCount>0 then
    --     return
    -- end
    -- self.m_isRefreshCount = 0

    self.m_list:removeAllItems()
    G_GetMgr(G_REF.Inbox):setInboxCollectStatus(false)
    -- 邮件列表是否为空
    local count = self:getCount()
    if count == 0 then
        self:showEmptyNode(true)
        self.m_mainClass:setTouchStatus(true)
    else
        self:showEmptyNode(false)  
        self:createItemCell()
        self.m_mainClass:setTouchStatus(true)
    end
end
--<<< UI显示部分 子类重写 ------------------------------------------------------ 

-->>> 一键领取请求 -------------------------------------------------------------
-- 能否一键领取
function InboxPage_collectBase:canCollectAll()
    return true
end

-- 开始一键领取
function InboxPage_collectBase:collectAllMail()
    if not self:canCollectAll() then
        return 
    end

    -- 发送请求
    self:requestCollectAllMail(function()
        if not tolua.isnull(self) then
            self:collectAllItemSuccess()
        end
    end, function()
        if not tolua.isnull(self) then
            self:collectAllItemFailed()
        end
    end)
end

-- 子类重写
-- 发送一键领取请求 
function InboxPage_collectBase:requestCollectAllMail(success, fail)
end

-- 领取成功
function InboxPage_collectBase:collectAllItemSuccess()
    -- 领取成功后要刷新邮件列表
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_UPDATE_PAGE)
end

-- 领取失败
function InboxPage_collectBase:collectAllItemFailed()
    gLobalViewManager:showReConnect()
end

-->>> 领取某个邮件
function InboxPage_collectBase:collectMail(mailId, successBackFun, faildBackFun)
    G_GetMgr(G_REF.Inbox):getSysNetwork():collectMail(mailId, successBackFun, faildBackFun)
end
--<<< 领取某个邮件

function InboxPage_collectBase:onEnter()
    InboxPage_base.onEnter(self)

    -- gLobalNoticManager:addObserver(self,function(self,params)
    --     if not tolua.isnull(self) then
    --         self.m_removeTouchLayer()
    --     end
    -- end,ViewEventType.NOTIFY_INBOX_LOADING_REMOVE)
end

return InboxPage_collectBase