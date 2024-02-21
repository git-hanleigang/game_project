local LoadingResConfig = require("views.loading.LoadingResConfig")
local LoadingControl = require("views.loading.LoadingControl")
local LoadingBarNode = class("LoadingBarNode", util_require("base.BaseView"))

--Loading提示语
local LOADING_TIPS = LoadingResConfig.DT_loadingBarTip

-- ios fix 123
function LoadingBarNode:initUI()
    if globalData.slotRunData.isPortrait == false then
        self:createCsbNode("Logon/LoadingBar.csb")
    else
        self:createCsbNode("Logon/LoadingBarEnterGame.csb")
    end

    self.m_loadingBar = self:findChild("loadingBar")
    self.m_loadingBar:setPercent(0)

    self.m_loadingBg = self:findChild("Image_1")

    self.m_loadingRate = self:findChild("loadingRate")
    if self.m_loadingRate then
        self.m_loadingRate:setString("")
    end

    self.m_spTipBg = self:findChild("tiao_bg")
    self.m_txtDownload = self:findChild("txtDownload")
    if self.m_txtDownload then
        if globalData.slotRunData.isPortrait == false then
            self.m_txtDownload:setPosition(cc.p(-100, -50))
        else
            self.m_txtDownload:setPosition(cc.p(-70, -50))
            self.m_txtDownload:setScale(0.8)
        end
        if self.m_spTipBg then
            self.m_spTipBg:setPositionY(-53)
        end
    end
    self.m_txtBytes = self:findChild("txtBytes")
    self.m_loadingTips = self:findChild("loadingTips")
    self.m_loadingTips:setString("")
    self:initTxtDL()

    -- self.m_loadingRate:setVisible(false)

    --流动效果
    self:initClipMask()
end

function LoadingBarNode:onEnter()
    LoadingBarNode.super.onEnter(self)
end

function LoadingBarNode:initTxtDL()
    if self.m_txtDownload then
        self.m_txtDownload:setString("")
    end

    if self.m_txtBytes then
        self.m_txtBytes:setString("")
    end

    if self.m_spTipBg then
        self.m_spTipBg:setVisible(false)
    end
    if self.m_loadingTips then
        self.m_loadingTips:setVisible(true)
    end
end

-- 初始化加载提示
function LoadingBarNode:updateLoadingTip()
    local bNextGame = LoadingControl:getInstance():isNextSceneType(SceneType.Scene_Game)
    if not bNextGame then
        --- cxc 2021年11月30日20:32:52 新增关卡返回大厅 不显示提示文本
        self.m_loadingTips:setString("")
        return
    end
    if bNextGame and LoadingControl:getInstance():getNeedDownloadLevel() then
        -- 需要下载就不要提示
        self.m_loadingTips:setString("")
    else
        local index = math.random(1, #LOADING_TIPS)
        if self.m_loadingTips then
            self.m_loadingTips:setString(LOADING_TIPS[index])
            util_scaleCoinLabGameLayerFromBgWidth(self.m_loadingTips, 700)
        end
    end

    if not bNextGame and self.m_spTipBg then
        self.m_loadingTips:setPositionY(self.m_spTipBg:getPositionY())
    end
end

function LoadingBarNode:setDlNotify(txt)
    txt = txt or ""
    if self.m_txtDownload then
        self.m_txtDownload:setString(txt)
    end

    if self.m_spTipBg then
        self.m_spTipBg:setVisible(#txt > 0)
    end
    if self.m_loadingTips then
        self.m_loadingTips:setVisible(#txt <= 0)
    end
end

function LoadingBarNode:setDlBytes(txt)
    txt = txt or ""
    if self.m_txtBytes then
        self.m_txtBytes:setString(txt)
        self.m_txtBytes:setPositionPercent({x = 1, y = 0.5})
    end
end

function LoadingBarNode:updatePercent(percent)
    self.m_loadingBar:setPercent(percent)
    self.m_loadingRate:setString(math.floor(percent) .. "%")
    if self.m_changeClip and self.m_clipSize then
        self.m_changeClip:setContentSize({width = self.m_clipSize.width * percent / 100, height = self.m_clipSize.height})
    end
end

function LoadingBarNode:getPercent()
    return self.m_loadingBar:getPercent()
end

function LoadingBarNode:autoScale()
    local loadingBg = self:findChild("Image_1")
    local tempSize = loadingBg:getContentSize()
    local rate = display.width * 0.85 / tempSize.width
    loadingBg:setScaleX(rate)
    -- self.m_loadingRate:setPositionX(loadingBg:getPositionX() + tempSize.width/2 * rate + 10)
end

--裁切实现  流动效果
function LoadingBarNode:initClipMask()
    -- if globalData.slotRunData.isPortrait == false then
    --     self:autoScale()
    -- end
    local clipNode = cc.ClippingNode:create()

    local loadEff = nil
    if globalData.slotRunData.isPortrait == false then
        loadEff = util_createAnimation("Logon/LoadingBarEff.csb")
    else
        loadEff = util_createAnimation("Logon/LoadingBarEff2.csb")
    end

    self.m_changeClip = loadEff:findChild("panel_clip")
    loadEff:playAction("animation0", true)

    self.m_loadingBar:addChild(clipNode)
    clipNode:addChild(loadEff)
    self.m_clipSize = self.m_loadingBar:getContentSize()

    self.m_changeClip:setContentSize({width = 0, height = self.m_clipSize.height})

    local stencilNode = cc.Node:create()
    -- local sp_clip = display.newSprite("Logon/ui/loading_guanqia_di2.png")
    local sp_clip = nil
    if globalData.slotRunData.isPortrait == false then
        sp_clip = display.newSprite("Logon/ui/loading_jindu2.png")
    else
        sp_clip = display.newSprite("Logon/ui/loading_guanqia_di2.png")
    end

    stencilNode:addChild(sp_clip)
    clipNode:setStencil(stencilNode)
    clipNode:setPosition(cc.p(self.m_clipSize.width / 2, self.m_clipSize.height / 2))
    clipNode:setInverted(false)
    clipNode:setAlphaThreshold(0.95)
end

return LoadingBarNode
