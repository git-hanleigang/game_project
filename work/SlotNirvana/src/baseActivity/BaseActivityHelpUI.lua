--[[
    author:JohnnyFred
    time:2019-12-06 18:12:21
    玩法简介UI基类
]]
local BaseActivityHelpUI = class("BaseActivityHelpUI", util_require("base.BaseView"))

------------------------------------------子类重写---------------------------------------
function BaseActivityHelpUI:initUI(closeCallBack)
    self.closeCallBack = closeCallBack
    self:setCascadeOpacityEnabled(true)
    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 or globalData.slotRunData.isPortrait == true then
        isAutoScale = false
    end

    self:createCsbNode(self:getCsbName(), isAutoScale)

    self.btnPre = self:findChild("btnPre")
    assert(self.btnPre, "BaseActivityHelpUI:initUI btnPre 控件不能缺失")
    self.btnNext = self:findChild("btnNext")
    assert(self.btnNext, "BaseActivityHelpUI:initUI btnPre 按钮不能缺失")
    self.pageView = self:findChild("pageView")
    assert(self.pageView, "BaseActivityHelpUI:initUI pageView 按钮不能缺失")

    self.pageView:addEventListener(
        function(sender, event)
            self:onPageMoveEnd(sender, event)
        end
    )

    self.point = self:findChild("point")

    self:commonShow(
        self:findChild("root"),
        function()
            if not self.btnDisableFlag then
                self:runCsbAction("idle", true)
            end
        end
    )
    self:initGameUIList()
end

function BaseActivityHelpUI:getCsbName()
    return ""
end

function BaseActivityHelpUI:getHelpItemLuaName()
    return ""
end

function BaseActivityHelpUI:getOtherPointPath()
    return ""
end

function BaseActivityHelpUI:getCurrentPointPath()
    return ""
end

function BaseActivityHelpUI:getPageCount()
    return 0
end
------------------------------------------子类重写---------------------------------------

function BaseActivityHelpUI:initGameUIList()
    local pageViewSize = self.pageView:getSize()
    local pageViewWidth, pageViewHeight = pageViewSize.width, pageViewSize.height
    for i = 1, self:getPageCount() do
        local layout = ccui.Layout:create()
        local paytableItemUI = util_createView(self:getHelpItemLuaName(), i)
        layout:addChild(paytableItemUI)
        paytableItemUI:setPosition(pageViewWidth / 2, pageViewHeight / 2)
        self.pageView:addPage(layout)
    end
    self:initPagePointUI()
end

function BaseActivityHelpUI:initPagePointUI()
    local pointUIList = {}
    self.pointUIList = pointUIList
    local pageCount = self:getPageCount()

    if pageCount > 1 then
        local otherPointPath = self:getOtherPointPath()
        if otherPointPath and string.len(otherPointPath) > 0 then
            assert(self.point, "BaseActivityHelpUI:initPagePointUI point 节点不能缺失")

            local pointUISize = util_getSpriteSize(otherPointPath)
            local alignWidth = pointUISize.width + 20
            local startPosX = -(alignWidth / 2) * (pageCount - 1)
            for i = 1, pageCount do
                local pointUI = util_createSprite(otherPointPath)
                self.point:addChild(pointUI)
                pointUI:setPosition(startPosX + (i - 1) * alignWidth, 0)
                table.insert(pointUIList, pointUI)
            end
        end

        self:setCurrentPageIndex(1)
    end
end

function BaseActivityHelpUI:moveToPre()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    local prePageIndex = self.pageView:getCurrentPageIndex() - 1
    if prePageIndex < 0 then
        prePageIndex = self:getPageCount() - 1
    end
    self:setCurrentPageIndex(prePageIndex + 1)
end

function BaseActivityHelpUI:moveToNext()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    local nextPageIndex = (self.pageView:getCurrentPageIndex() + 1) % self:getPageCount()
    self:setCurrentPageIndex(nextPageIndex + 1)
end

function BaseActivityHelpUI:setCurrentPageIndex(index)
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
        self.pageView:scrollToPage(page_index, 0.8)

        -- Index start from 0 to pageCount -1.
        assert(self.btnPre, "必要的切换按钮资源缺失 " .. "btnPre")
        self.btnNext:setVisible(not (page_index == self:getPageCount() - 1))

        assert(self.btnNext, "必要的切换按钮资源缺失 " .. "btnNext")
        self.btnPre:setVisible(not (page_index == 0))
    end
end

function BaseActivityHelpUI:onPageMoveEnd(sender, event)
    -- 翻页时
    if event == ccui.PageViewEventType.turning then
        -- getCurrentPageIndex() 获取当前翻到的页码 打印
        local cur_index = self.pageView:getCurrentPageIndex()
        printInfo("当前页码是" .. cur_index)
        if not self.curPageIndex or self.curPageIndex - 1 ~= cur_index then
            self:setCurrentPageIndex(cur_index + 1)
        end
    end
end

function BaseActivityHelpUI:clickFunc(sender)
    if not self.btnDisableFlag then
        local senderName = sender:getName()

        if senderName == "btnClose" then
            self:close()
        elseif senderName == "btnPre" then
            self:moveToPre()
        elseif senderName == "btnNext" then
            self:moveToNext()
        end
    end
end

function BaseActivityHelpUI:setButtonDisableFlag(flag)
    self.btnDisableFlag = flag
end

function BaseActivityHelpUI:close()
    self:setButtonDisableFlag(true)
    self:commonHide(
        self:findChild("root"),
        function()
            if self.closeCallBack ~= nil then
                self.closeCallBack()
            end
            if not tolua.isnull(self) then
                self:removeFromParent()
            end
        end
    )
end

return BaseActivityHelpUI
