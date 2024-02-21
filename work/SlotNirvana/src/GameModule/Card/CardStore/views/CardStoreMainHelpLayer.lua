-- 卡牌商店 玩法介绍界面

local BaseActivityHelpUI = util_require("baseActivity.BaseActivityHelpUI")
local CardStoreMainHelpLayer = class("CardStoreMainHelpLayer", BaseActivityHelpUI)

function CardStoreMainHelpLayer:initUI(closeCallBack)
    BaseActivityHelpUI.initUI(self, closeCallBack)
    util_portraitAdaptLandscape(self.m_csbNode)
    self:setExtendData("CardStoreMainHelpLayer")
end

function CardStoreMainHelpLayer:getCsbName()
    local p_config = G_GetMgr(G_REF.CardStore):getConfig()
    return p_config.InfoUI
end

function CardStoreMainHelpLayer:getHelpItemLuaName()
    return "GameModule.Card.CardStore.views.CardStoreMainHelpItem"
end

function CardStoreMainHelpLayer:getPageCount()
    return 2
end

function CardStoreMainHelpLayer:setCurrentPageIndex(index)
    if self.curPageIndex ~= index then
        if self.curPageIndex ~= nil then
            local prePage = self.pointUIList[self.curPageIndex]
            if prePage ~= nil then
                util_changeTexture(prePage, self:getOtherPointPath())
            end
        end
        self.curPageIndex = index
        local curPage = self.pointUIList[index]
        if curPage ~= nil then
            util_changeTexture(curPage, self:getCurrentPointPath())
        end

        local page_index = index - 1
        self.pageView:setCurrentPageIndex(page_index)

        -- Index start from 0 to pageCount -1.
        assert(self.btnPre, "必要的切换按钮资源缺失 " .. "btnPre")
        self.btnNext:setVisible(not (page_index == self:getPageCount() - 1))

        assert(self.btnNext, "必要的切换按钮资源缺失 " .. "btnNext")
        self.btnPre:setVisible(not (page_index == 0))
    end
end

function CardStoreMainHelpLayer:clickFunc(sender)
    BaseActivityHelpUI.clickFunc(self, sender)
    if not self.btnDisableFlag then
        local senderName = sender:getName()
        if senderName == "btn_close" then
            self:close()
        end
    end
end

return CardStoreMainHelpLayer
