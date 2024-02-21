--[[
    卡片收集规则界面  一些玩法说明 --
]]
local BaseView = util_require("base.BaseView")
local CardNadoWheelOverItem = class("CardNadoWheelOverItem", BaseView)

-- 初始化UI --
function CardNadoWheelOverItem:initUI(data)
    self.m_data = data
    self:createCsbNode(self:getCsbName())
    self:initNode()
    self:updateUI()
end

function CardNadoWheelOverItem:getCsbName()
    return string.format(CardResConfig.commonRes.CardNadoWheelOverItemRes, "common" .. CardSysRuntimeMgr:getCurAlbumID())
end

function CardNadoWheelOverItem:initNode()
    self.m_sp_dexule = self:findChild("sp_dexule")
    self.m_sp_vip = self:findChild("sp_vip")
    self.m_sp_coins = self:findChild("sp_coins")

    self.m_lb_num = self:findChild("lb_num")

    self.m_sp_goldchip = self:findChild("sp_goldchip")
    self.m_sp_normalchip = self:findChild("sp_normalchip")
    self.m_sp_super = self:findChild("sp_super")
    self.m_nodeItem = self:findChild("Node_item")
    self.m_spCatFoot1 = self:findChild("sp_catfood1")
    self.m_spCatFoot2 = self:findChild("sp_catfood2")
    self.m_spCatFoot3 = self:findChild("sp_catfood3")
    self.m_sp_redpoint = self:findChild("sp_redpoint")
    self.m_lb_redpoint = self:findChild("lb_redpoint")
    self.m_nodeStatueBuff = self:findChild("diaosu_buff")
end

function CardNadoWheelOverItem:updateUI()
    self.m_sp_dexule:setVisible(false)
    self.m_sp_vip:setVisible(false)
    self.m_sp_coins:setVisible(false)
    self.m_lb_num:setVisible(false)

    self.m_sp_goldchip:setVisible(false)
    self.m_sp_normalchip:setVisible(false)
    self.m_sp_super:setVisible(false)
    if self.m_spCatFoot1 then
        self.m_spCatFoot1:setVisible(false)
    end
    if self.m_spCatFoot2 then
        self.m_spCatFoot2:setVisible(false)
    end
    if self.m_spCatFoot3 then
        self.m_spCatFoot3:setVisible(false)
    end
    self.m_sp_redpoint:setVisible(false)

    local key = self.m_data.key
    local num = self.m_data.data
    if key == "coins" then
        if num > 0 then
            self:updateLabelSize({label = self.m_lb_num, sx = 0.75, sy = 0.75}, 165)
            self.m_sp_coins:setVisible(true)
            self.m_lb_num:setVisible(true)
            self:initStatueBuffNode()
            self.m_lb_num:setString(util_formatCoins(num, 5))
        end
    elseif key == "club" then
        if num > 0 then
            self.m_sp_vip:setVisible(true)
            self.m_lb_num:setVisible(true)
            self:initStatueBuffNode()
            self.m_lb_num:setString(util_formatCoins(num, 5))
        end
    elseif key == "bigCoins" then
        if num > 0 then
            self.m_sp_super:setVisible(true)
        end
        if num > 1 then
            self.m_sp_redpoint:setVisible(true)
            self.m_lb_redpoint:setString(num)
        end
    elseif key == "goldPackages" then
        if num > 0 then
            self.m_sp_goldchip:setVisible(true)
        end
        if num > 1 then
            self.m_sp_redpoint:setVisible(true)
            self.m_lb_redpoint:setString(num)
        end
    elseif key == "packages" then
        if num > 0 then
            self.m_sp_normalchip:setVisible(true)
        end
        if num > 1 then
            self.m_sp_redpoint:setVisible(true)
            self.m_lb_redpoint:setString(num)
        end
    elseif key == "highLimitPoints" then
        if num > 0 then
            self.m_sp_dexule:setVisible(true)
            self.m_lb_num:setVisible(true)
            self:initStatueBuffNode()
            self.m_lb_num:setString(util_formatCoins(num, 5))
        end
    elseif key == "rewards" then
        local isShow = false
        if num.p_icon == "CatFood_1" then
            if self.m_spCatFoot1 then
                isShow = true
                self.m_spCatFoot1:setVisible(true)
            end
        elseif num.p_icon == "CatFood_2" then
            if self.m_spCatFoot2 then
                isShow = true
                self.m_spCatFoot2:setVisible(true)
            end
        elseif num.p_icon == "CatFood_3" then
            if self.m_spCatFoot3 then
                isShow = true
                self.m_spCatFoot3:setVisible(true)
            end
        else
            -- 通用道具
            local customItemNode = gLobalItemManager:createRewardNode(num, ITEM_SIZE_TYPE.REWARD)
            if customItemNode then
                self.m_nodeItem:addChild(customItemNode)
            end
        end
        if isShow and num.p_num > 0 then
            self.m_lb_num:setVisible(true)
            self.m_lb_num:setString(util_formatCoins(num.p_num, 5))
        end
    end
end

--[[-- 神像buff标签 -----------------]]
function CardNadoWheelOverItem:initStatueBuffNode()
    local buffMultiple = self:getBuffMulti()
    if buffMultiple > 0 then
        if not self.m_statueBuffUI then
            local albumId = CardSysRuntimeMgr:getSelAlbumID() or CardSysRuntimeMgr:getCurAlbumID()
            local _logic = CardSysRuntimeMgr:getSeasonLogic(albumId)
            if _logic then
                self.m_statueBuffUI = _logic:createCardSpecialGameBuffNode(buffMultiple)
                self.m_nodeStatueBuff:addChild(self.m_statueBuffUI)
            end
        end
    end
end

function CardNadoWheelOverItem:playItemAction(_over)
    self:runCsbAction(
        "show",
        false,
        function()
            if self:getBuffMulti() > 0 then
                self:playScaleAction(_over)
            else
                self:runCsbAction("idle", true)
                if _over then
                    _over()
                end
            end
        end
    )
end

function CardNadoWheelOverItem:getBuffMulti()
    -- local buffMultiple = CardSysManager:getBuffDataByType(BUFFTYPY.BUFFTYPE_CARD_NADO_REWARD_BONUS)
    -- if buffMultiple and buffMultiple > 0 then
    --     return buffMultiple
    -- end
    return 0
end

function CardNadoWheelOverItem:playScaleAction(overFunc)
    self:runCsbAction(
        "scale",
        false,
        function()
            if self.m_statueBuffUI then
                self.m_statueBuffUI:setVisible(false)
                self:runCsbAction(
                    "actionframe",
                    false,
                    function()
                        self:playNumberScroll(
                            function()
                                self:runCsbAction("idle", true)
                                if overFunc then
                                    overFunc()
                                end
                            end
                        )
                    end
                )
            else
                self:runCsbAction("idle", true)
                if overFunc then
                    overFunc()
                end
            end
        end
    )
end

function CardNadoWheelOverItem:playNumberScroll(_scrollOver)
    local multi = self:getBuffMulti()
    if not (multi and multi > 0) then
        if _scrollOver then
            _scrollOver()
        end
        return
    end
    local startValue = tonumber(self.m_data.data)
    local endValue = tonumber(self.m_data.data * multi)
    local addValue = (endValue - startValue) / 10
    local spendTime = 1 / 30
    util_jumpNumExtra(
        self.m_lb_num,
        startValue,
        endValue,
        addValue,
        spendTime,
        util_formatCoins,
        {5},
        nil,
        nil,
        function()
            if _scrollOver then
                _scrollOver()
            end
        end,
        nil
    )
end

return CardNadoWheelOverItem
