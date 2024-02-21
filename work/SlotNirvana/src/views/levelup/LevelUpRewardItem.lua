--升级奖励
local LevelUpRewardItem = class("LevelUpRewardItem", util_require("base.BaseView"))
function LevelUpRewardItem:initUI(name, value)
    self:createCsbNode("LevelUp_new/LevelUpLayer_tubiao.csb")

    local node_icon = self:findChild("node_icon")
    local node_title = self:findChild("node_title")
    local m_lb_value = self:findChild("m_lb_value")

    --icon
    if node_icon then
        local sp_icon = util_createSprite("LevelUp_new/Other/level_" .. name .. "_icon.png")
        if sp_icon then
            node_icon:addChild(sp_icon)
            sp_icon:setPositionY(60)
            if name == LEVEL_REWARD_ENMU.VIP then
                self:addVipIcon(node_icon)
            end
        end
    end
    --标题
    if node_title then
        local sp_title = util_createSprite("LevelUp_new/Other/level_" .. name .. "_title.png")
        if sp_title then
            node_title:addChild(sp_title)
        end
    end
    --数值
    if m_lb_value and value then
        m_lb_value:setString(util_formatCoins(value, 3))
        if name == LEVEL_REWARD_ENMU.CASHMONEY or name == LEVEL_REWARD_ENMU.CASHWHEEL then
            if node_title then
                local sp_title2 = util_createSprite("LevelUp_new/Other/level_upto.png")
                node_title:addChild(sp_title2)
                --修改upto位置
                local lb_w = m_lb_value:getContentSize().width
                local tl_w = sp_title2:getContentSize().width
                local len = lb_w + 10 + tl_w
                m_lb_value:setPositionX((len - lb_w) * 0.5)
                sp_title2:setPosition((tl_w - len) * 0.5, m_lb_value:getPositionY() - 2)
            end
        end
    end

    self:showFast()
end

--VIP单独处理
function LevelUpRewardItem:addVipIcon(node)
    local path = VipConfig.logo_middle .. globalData.userRunData.vipLevel .. ".png"
    local spVip = util_createSprite(path)
    if spVip then
        spVip:setScale(0.70)
        node:addChild(spVip)
        spVip:setPositionY(62)
        spVip:setPositionX(-1)
    end
end
--正常展示
function LevelUpRewardItem:show()
    self:runCsbAction("show")
end
--快停
function LevelUpRewardItem:showFast()
    self:pauseForIndex(10)
end
return LevelUpRewardItem
