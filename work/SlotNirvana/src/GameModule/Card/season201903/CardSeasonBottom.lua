--[[--
]]
local CardSeasonBottom = class("CardSeasonBottom", util_require("base.BaseView"))

function CardSeasonBottom:getCsbName()
    return string.format(CardResConfig.seasonRes.CardBottomNodeRes, "season201903")
end

function CardSeasonBottom:getMenuNodeLua()
    return "GameModule.Card.season201903.CardMenuNode"    
end

function CardSeasonBottom:getMenuWheelLua()
    return "GameModule.Card.season201903.CardMenuWheel"    
end

function CardSeasonBottom:getSeasonNadoWheelLua()
    return "GameModule.Card.season201903.CardSeasonNadoWheel"    
end

function CardSeasonBottom:initUI(source, isPlayStart, mainClass)
    self.m_source = source
    self.m_mainClass = mainClass

    self:createCsbNode(self:getCsbName())

    self:initNode()

    self:initAdapt()
    self:initData()
end

function CardSeasonBottom:getMainClass()
    return self.m_mainClass    
end

function CardSeasonBottom:closeUI()
    self.m_bottomAction = true
    self:runCsbAction("over", false, function()
        self.m_bottomAction = false
    end)
end

function CardSeasonBottom:onEnter()  
    gLobalNoticManager:addObserver(self, function(params)
        -- print("!!! ===== CARD_MENU_CLOSE === 001")
        if self.m_menuAction == true then
            return
        end
        self.m_menuAction = true

        -- print("!!! ===== CARD_MENU_CLOSE === 002")
        self:updateMore(false, function()
            self.m_menuAction = false
        end)
        self.m_bottomAction = true
        self:runCsbAction("shouhui", false, function()
            self.m_bottomAction = false
            self:setMenuStatus("closed")
        end)
    end, CardSysConfigs.ViewEventType.CARD_MENU_CLOSE)

    gLobalNoticManager:addObserver(self, function(params)
        if self.m_nadoWheel and self.m_nadoWheel.updateNum then
            self.m_nadoWheel:updateNum()
        end
    end, CardSysConfigs.ViewEventType.CARD_NADO_WHEEL_ROLL_OVER)
end

function CardSeasonBottom:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

function CardSeasonBottom:initNode()
    self.m_menuNode = self:findChild("Node_more")
    self.m_menuBtnClose = self:findChild("Button_menu_close")
    self.m_menuBtnOpen = self:findChild("Button_menu_open")
    self.m_bottomLotto = self:findChild("Lucky_lotto")
    self.m_bottomNadoWheel = self:findChild("Nado_wheel")
    self.m_bottomLuckyWild = self:findChild("Lucky_wild")
end

function CardSeasonBottom:initAdapt()
    local ori = display.width/display.height
    if ori >= 2 then
        self.m_menuBtnOpen:setPositionX(-40)
    end
end

function CardSeasonBottom:initData()

end

function CardSeasonBottom:updateUI(isPlayStart)
    if isPlayStart then
        self.m_bottomAction = true
        self:runCsbAction("show", false, function()
            self.m_bottomAction = false
            self:runCsbAction("idle", true)
        end)
    else
        self:runCsbAction("idle", true)
    end

    self:setMenuStatus("closed")

    local albumID = CardSysRuntimeMgr:getSelAlbumID()
    if albumID and CardSysRuntimeMgr:isPastAlbum(albumID) then
        self.m_bottomLotto:setVisible(false)
        self.m_bottomNadoWheel:setVisible(false)
        self.m_bottomLuckyWild:setVisible(false)
    else

        self:initBottomNode()
    end
end

function CardSeasonBottom:initBottomNode()
    self:initLetto()
    self:initNadoWheel()
end

function CardSeasonBottom:setMenuStatus(status)
    if status == "closed" then
        -- print("----- setMenuStatus ----- closed")
        self.m_menuBtnClose:setVisible(true)
        self.m_menuBtnOpen:setVisible(false)
    elseif status == "opened" then
        self.m_menuBtnClose:setVisible(false)
        self.m_menuBtnOpen:setVisible(true)        
    end
end

function CardSeasonBottom:updateMore(isShow, overCallFunc)
    if isShow then
        if not self.m_menu then
            self.m_menu = util_createView(self:getMenuNodeLua(), self)
            self.m_menuNode:addChild(self.m_menu)
            local pos = self.m_menuNode:getParent():convertToNodeSpace(cc.p(0, display.height/2))
            self.m_menuNode:setPosition(pos)        
        end
        self.m_menu:playStartAction(overCallFunc)
        self.m_menu:setVisible(true)
    else
        self.m_menu:playOverAction(function()
            self.m_menu:setVisible(false)
            if overCallFunc then
                overCallFunc()
            end
        end)
    end
end

function CardSeasonBottom:initLetto()
    if not self.m_wheelUI then
        self.m_wheelUI = util_createView(self:getMenuWheelLua())
        self.m_bottomLotto:addChild(self.m_wheelUI)
    end
    self.m_wheelUI:initCountDown()
end
function CardSeasonBottom:initNadoWheel()
    if not self.m_nadoWheel then
        self.m_nadoWheel = util_createView(self:getSeasonNadoWheelLua())
        self.m_bottomNadoWheel:addChild(self.m_nadoWheel)
    end
    self.m_nadoWheel:updateNum()
end

function CardSeasonBottom:clickFunc(sender)
    local name = sender:getName()
    -- print("!!! -------- CardSeasonBottom name = ", name)
    if name == "Button_menu_open" then
        -- print("!!! ------  Button_menu_open 1", self.m_menuAction)
        if self.m_bottomAction == true then
            return
        end
        if self.m_menuAction == true then
            return
        end
        self.m_menuAction = true
        -- print("!!! ------  Button_menu_open 2", self.m_menuAction)
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnBack)
        self:updateMore(false, function()
            self.m_menuAction = false
        end)
        self.m_bottomAction = true
        self:runCsbAction("shouhui", false, function()
            self.m_bottomAction = false
            self:setMenuStatus("closed")
        end)
    elseif name == "Button_menu_close" then
        -- print("!!! ------  Button_menu_close 1", self.m_menuAction)
        if self.m_bottomAction == true then
            return
        end
        if self.m_menuAction == true then
            return
        end
        self.m_menuAction = true
        -- print("!!! ------  Button_menu_close 2", self.m_menuAction)
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        self:setMenuStatus("opened")
        self:updateMore(true, function()
            self.m_menuAction = false
        end)
        self.m_bottomAction = true    
        self:runCsbAction("dianji", false, function()
            self.m_bottomAction = false
        end)
    elseif name == "Button_back" then
        if CardSysRuntimeMgr:isClickOtherInAlbum() then
            return
        end
        CardSysRuntimeMgr:setClickOtherInAlbum(true)

        -- 返回赛季大厅
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnBack)
        CardSysManager:closeCardAlbumView(function()
            CardSysManager:exitCardAlbum()
        end)

    end
end

return CardSeasonBottom
