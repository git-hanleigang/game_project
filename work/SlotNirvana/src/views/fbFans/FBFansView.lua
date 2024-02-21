local FBFansView = class("FBFansView", util_require("base.BaseView"))

function FBFansView:initUI(times, callback)
    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end

    self.m_callback = callback
    local csbName = "FbFans.csb"
    self:createCsbNode("FbFans/" .. csbName, isAutoScale)
    if isAutoScale and globalData.slotRunData.isPortrait == true then
        util_csbScale(self.m_csbNode, 0.56)
    end
    self:addClick(self:findChild("Panel_1"))
    local closeBtn = self:findChild("btn_close")
    -- closeBtn:setPosition(display.width/2-75,display.height/2-75)

    -- local kuangBg1 = self:findChild("dikuang")

    local root = self:findChild("root")
    if root then
        self:runCsbAction("idle")
        self:commonShow(
            root,
            function()
                self.m_startOver = true
                self:runCsbAction("idle")
            end
        )
    else
        self:runCsbAction(
            "start",
            false,
            function()
                self.m_startOver = true
                self:runCsbAction("idle")
            end,
            60
        )
    end
end

function FBFansView:onEnter()
end

function FBFansView:onExit()
end

function FBFansView:onKeyBack()
    self:closeUI(true)
end

function FBFansView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    -- 尝试重新连接 network
    if name == "btn_close" then
        self:closeUI()
    elseif name == "Panel_1" or name == "btn_FB" then
        --FBFANS_URL
        -- if globalData.constantData.FBFANS_URL then
            -- cc.Application:getInstance():openURL(globalData.constantData.FBFANS_URL)
            globalPlatformManager:openFB(globalData.constantData:getFbFansUrl())
        -- end
        if globalFireBaseManager.sendFireBaseLogDirect then
            globalFireBaseManager:sendFireBaseLogDirect("FBFansView" .. "_PopupClick", false)
        end
        self:closeUI()
    end
end

function FBFansView:closeUI()
    if not self.m_startOver then
        return
    end
    if self.isClose then
        return
    end
    self.isClose = true

    local root = self:findChild("root")
    if root then
        self:commonHide(
            root,
            function()
                if self.m_callback then
                    self.m_callback()
                end
                self:removeFromParent()
            end
        )
    else
        self:runCsbAction(
            "over",
            false,
            function()
                if self.m_callback then
                    self.m_callback()
                end
                self:removeFromParent()
            end,
            60
        )
    end
end

return FBFansView
