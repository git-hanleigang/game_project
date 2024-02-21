local GoldExpressBonusMapBigLevel = class("GoldExpressBonusMapBigLevel", util_require("base.BaseView"))
-- 构造函数
local DESCRIBE_LAYER_WIDTH = 212
function GoldExpressBonusMapBigLevel:initUI(data)
    local resourceFilename = "Bonus_GoldExpress_daguan.csb"
    self:createCsbNode(resourceFilename)
    self:idle()

    self.m_selfPos = data.selfPos
    self.m_vecChooseIcon = {}
    self.m_vecDescribe = {}
    self.m_vecCha = {}
    self.m_vecTittle = {}
    self.m_currGameID = nil
    local index = 1
    while true do
        local choose = self:findChild("dui_" .. index )
        local describe = self:findChild("describe_" .. index )
        local cha = self:findChild("cha_" .. index )
        if choose ~= nil then
            choose:setVisible(false)
            cha:setVisible(false)
            describe:setContentSize(0, 26)
            self.m_vecChooseIcon[index] = choose
            self.m_vecDescribe[index] = describe
            self.m_vecCha[index] = cha
        else
            break
        end
        index = index + 1
    end

    local info = data.info
    local currLevel = data.currLevel
    local vecReels = {}
    local index = 1
    while true do
        local reel = self:findChild("GoldExpress_" .. index )
        if reel ~= nil then
            reel:setVisible(false)
            vecReels[index] = reel
        else
            break
        end
        index = index + 1
    end
    vecReels[info.levelID]:setVisible(true)

    self.m_bIsUpShow = false
    for i = 1, #info.allGames, 1 do
        local gameID = info.allGames[i]
        local tittle = util_createView("CodeGoldExpressSrc.GoldExpressBonusExtraGamesTittle")
        self:findChild("node_"..i):addChild(tittle)
        tittle:unselected(gameID)
        tittle:setTag(gameID)
        self.m_vecTittle[#self.m_vecTittle + 1] = tittle
        if gameID == currLevel then
            self.m_bIsUpShow = true
        end
    end

    if self.m_bIsUpShow == false then
        self:runCsbAction("normalcy")
    else
        for i = 1, #info.allGames, 1 do
            local gameID = info.allGames[i]
            if gameID <= currLevel then
                self.m_vecDescribe[i]:setContentSize(DESCRIBE_LAYER_WIDTH, 35)
                self.m_vecCha[i]:setVisible(true)
            else
                break
            end
            for j = 1, #info.extraGames, 1 do
                if info.extraGames[j] == gameID then
                    self.m_vecTittle[i]:selected(gameID)
                    self.m_vecCha[i]:setVisible(false)
                    self.m_vecChooseIcon[i]:setVisible(true)
                    break
                end
            end
        end
    end
end

function GoldExpressBonusMapBigLevel:updateExtraGame(info, pos, func)
    local showTittle = function ()
        for i = 1, #info.allGames, 1 do
            local gameID = info.allGames[i]
            if gameID == pos then
                self.m_currGameID = i
                -- self.m_vecDescribe[i]:setContentSize(DESCRIBE_LAYER_WIDTH, 26)
                self.m_vecCha[i]:setVisible(true)
                self.m_vecCha[i]:setScale(0)
                gLobalSoundManager:playSound("GoldExpressSounds/sound_bonus_contentItemShow.mp3")

                for j = 1, #info.extraGames, 1 do
                    if info.extraGames[j] == gameID then
                        self.m_vecTittle[i]:selected(gameID)
                        self.m_vecCha[i]:setVisible(false)
                        self.m_vecChooseIcon[i]:setVisible(true)
                        self.m_vecChooseIcon[i]:setScale(0)
                        break
                    end
                end

                break
            end
        end

        local width = 0
        local addDistance = 8
        -- gLobalSoundManager:playSound("GoldExpressSounds/sound_GoldExpress_show_words.mp3")
        self.m_show = schedule(self,function()
            width = width + addDistance
            if width >= DESCRIBE_LAYER_WIDTH then
                width = DESCRIBE_LAYER_WIDTH
                self:stopAction(self.m_show)
                self.m_show = nil
                -- self.m_vecCha[self.m_currGameID]:setScale(9)
                -- self.m_vecChooseIcon[self.m_currGameID]:setScale(9)
                self.m_vecCha[self.m_currGameID]:runAction(cc.EaseBackOut:create(cc.ScaleTo:create(0.2, 1)))
                self.m_vecChooseIcon[self.m_currGameID]:runAction(cc.EaseBackOut:create(cc.ScaleTo:create(0.2, 1)))
                performWithDelay(self, function()
                    if func ~= nil then
                        func()
                    end
                end, 1)
            end
            self.m_vecDescribe[self.m_currGameID]:setContentSize(width, 26)
        end, 0.01)

        if self.lightAni then
            self:stopAction(self.lightAni)
            self.lightAni = nil
        end
    end
    if self.m_bIsUpShow == false then
        for i = 1, #info.allGames, 1 do
            local gameID = info.allGames[i]
            if gameID == pos then
                self.m_bIsUpShow = true
            end
        end
        if self.m_bIsUpShow == true then
            self:runCsbAction("up", false, function()
                showTittle()
            end)
        else
            performWithDelay(self, function()
                if func ~= nil then
                    func()
                end
            end, 1)
        end

    else
        showTittle()
    end
end

function GoldExpressBonusMapBigLevel:idle()
    self:runCsbAction("idleframe", true)
end

function GoldExpressBonusMapBigLevel:click(func)
    gLobalSoundManager:playSound("GoldExpressSounds/sound_bonus_houseTopDown.mp3")
    self:runCsbAction("actionframe", false, function()
        if func ~= nil then
            -- performWithDelay(self, function()
                func()
            -- end, 0.5)
        end
    end)
end

function GoldExpressBonusMapBigLevel:levelReset()
    for i = 1, #self.m_vecChooseIcon, 1 do
        self.m_vecChooseIcon[i]:setVisible(false)
        self.m_vecCha[i]:setVisible(false)
        self.m_vecDescribe[i]:setContentSize(0, 26)
    end
    self.m_bIsUpShow = false
    self:runCsbAction("normalcy")
end

function GoldExpressBonusMapBigLevel:completed()
    -- self:runCsbAction("idleframe1", true)
end

function GoldExpressBonusMapBigLevel:onEnter()

end

function GoldExpressBonusMapBigLevel:onExit()

end

return GoldExpressBonusMapBigLevel