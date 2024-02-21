--[[--
    游戏公告界面
]]
local STR_WIDTH = 773 -- 公告文字的最大长度，自动换行用

-- 1.关闭游戏；2.FB粉丝页；3.回到游戏；
local BTN_CFG = {
    "views.Announcement.AnnouncementBtnQuit",
    "views.Announcement.AnnouncementBtnFanpage",
    "views.Announcement.AnnouncementBtnSpin"
}
local AnnouncementUI = class("AnnouncementUI", BaseLayer)
function AnnouncementUI:initDatas(_closeCall)
    self.m_closeCall = _closeCall
    self:setLandscapeCsbName("Announcement/csb/AnnouncementMainLayer.csb")
end

function AnnouncementUI:getData()
    return globalAnnouncementManager:getAnnouncementData()
end

function AnnouncementUI:initCsbNodes()
    self.m_nodeBtns = self:findChild("Node_btns")
    self.m_lbTitle = self:findChild("lb_title")
    self.m_lbDes = self:findChild("lb_desc")
end

function AnnouncementUI:initView()
    self:initBtns()
    self:initDesc()
    self:initTitle()
end

-- 标题
function AnnouncementUI:initTitle()
    local data = self:getData()
    local str = data and data:getTitle() or "NOTICE"
    self.m_lbTitle:setString(str)
end

-- 内容
function AnnouncementUI:initDesc()
    local data = self:getData()
    local str = data and data:getDesc() or "THIS IS TEST TEXT!"
    util_AutoLine(self.m_lbDes, str, STR_WIDTH, true)
end

-- 按钮
function AnnouncementUI:initBtns()
    local data = self:getData()
    local btnType = data and data:getBtnType()
    local btnOrders = string.split(btnType, ",")

    local showBtns = {}
    for i = 1, #btnOrders do
        local order = tonumber(btnOrders[i])
        if BTN_CFG[order] then
            local btnNode =
                util_createView(
                BTN_CFG[order],
                function(_senderName)
                    if not tolua.isnull(self) and self.clickBtn then
                        self:clickBtn(_senderName)
                    end
                end
            )
            self.m_nodeBtns:addChild(btnNode)
            table.insert(showBtns, {node = btnNode, alignX = (i > 1 and 100 or 0), size = btnNode:getBtnSize(), anchor = cc.p(0.5, 0.5)})
        end
    end
    util_alignCenter(showBtns)
end

-- function AnnouncementUI:onKeyBack()
--     if DEBUG == 2 then
--         self:closeUI()
--     end
-- end

function AnnouncementUI:canClick()
    if self.m_clicked then
        return false
    end
    return true
end

function AnnouncementUI:clickBtn(name)
    if not self:canClick() then
        return
    end
    self.m_clicked = true
    performWithDelay(
        self,
        function()
            self.m_clicked = false
        end,
        1
    )
    if name == "btn_quit" then
        if device.platform == "ios" then
            globalLocalPushManager:commonBackGround()
            G_GetMgr(G_REF.OperateGuidePopup):saveGuideArchiveData()
            os.exit()
        else
            globalLocalPushManager:commonBackGround()
            G_GetMgr(G_REF.OperateGuidePopup):saveGuideArchiveData()
            local director = cc.Director:getInstance()
            director:endToLua()
        end
    elseif name == "btn_gotospin" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:closeUI()
    elseif name == "btn_fanpage" then
        -- local FB_COMMUNITY_URL = "https://www.facebook.com/CashTornadoSlots"
        -- cc.Application:getInstance():openURL(FB_COMMUNITY_URL)
        globalPlatformManager:openFB(globalData.constantData:getFbFansUrl())
    end
end

function AnnouncementUI:closeUI(_callFunc)
    AnnouncementUI.super.closeUI(
        self,
        function()
            if _callFunc then
                _callFunc()
            end
            if self.m_closeCall then
                self.m_closeCall()
            end
        end
    )
end

return AnnouncementUI
