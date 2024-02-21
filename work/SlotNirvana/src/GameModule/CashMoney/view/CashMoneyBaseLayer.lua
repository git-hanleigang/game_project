--[[
Author: dhs
Date: 2022-04-19 17:56:56
LastEditTime: 2022-04-19 17:56:57
LastEditors: your name
Description: CashMoney 基类
FilePath: /SlotNirvana/src/GameModule/CashMoney/view/CashMoneyBaseLayer.lua
--]]
-- CashMoneyBaseLayer 需要做的事情，初始化界面
local CashMoneyBaseLayer = class("CashMoneyBaseLayer", BaseLayer)
local CashMoneyConfig = util_require("GameModule.CashMoney.config.CashMoneyConfig")

function CashMoneyBaseLayer:ctor()
    CashMoneyBaseLayer.super.ctor(self)
    self:setPauseSlotsEnabled(true)
    -- self:setKeyBackEnabled(true)
    -- setDefaultTextureType("RGBA8888", nil)
    local csbName = self:getCashMoneyCsbName()
    self:setLandscapeCsbName(csbName)
    -- setDefaultTextureType("RGBA4444", nil)
end

function CashMoneyBaseLayer:initUI()
    CashMoneyBaseLayer.super.initUI(self)
end

function CashMoneyBaseLayer:initView()
end

-- *********************************** 子类重写 ***************************************** --
function CashMoneyBaseLayer:getCashMoneyCsbName()
    return ""
end

function CashMoneyBaseLayer:getTakeBtnNode()
    return nil
end

function CashMoneyBaseLayer:getTryAgainBtnNode()
    return nil
end
-- 这里是子类重写，创建新的CashMoney Node
function CashMoneyBaseLayer:getRollNode()
    return nil
end

function CashMoneyBaseLayer:getResPath()
    return ""
end

function CashMoneyBaseLayer:getEffectNodes()
    return ""
end

function CashMoneyBaseLayer:getPaidHighestNode()
    return nil
end

function CashMoneyBaseLayer:getConfig()
    return nil
end

function CashMoneyBaseLayer:getPaidCloseBtn()
    return nil
end

-- ****************************** Node ************************ --
function CashMoneyBaseLayer:initCsbNodes()
    -- 这里处理的是通用的节点
    self.m_valueLb = self:findChild("txt_value")
    self.m_bottomNode = self:findChild("Node_bottom")
    self.m_vipNode = self:findChild("Node_vip")
    self.m_overUINode = self:findChild("Node_overui")
    self.m_lianziBgNode = self:findChild("Node_lianzi_bg")
    self.m_lianziTopNode = self:findChild("Node_lianzi_top")
    self.m_lianziLeftNode = self:findChild("Node_lianzi_left")
    self.m_lianziRightNode = self:findChild("Node_lianzi_right")
    -- 动效节点
    self.m_rollEffectNode = self:findChild("Node_Roll")
    self.m_LogoEffectNode = self:findChild("Node_LogoSG")

    local takeBtnNode = self:getTakeBtnNode()
    local tryAgainBtnNode = self:getTryAgainBtnNode()
    local paidCloseBtn = self:getPaidCloseBtn()
    if takeBtnNode then
        self.m_btnTakeSGNode = self:findChild("Node_Btn_Take_SG")
        self.m_btnTake = self:findChild("Button_take")
    end

    if tryAgainBtnNode then
        self.m_btnTryAgainSGNode = self:findChild("Node_Btn_TryAgain_SG")
        self.m_btnTryAgain = self:findChild("Button_tryagain")
    end

    if paidCloseBtn then
        self.m_paidCloseBtn = paidCloseBtn
        self.m_paidCloseBtn:setVisible(false)
    end

    self.m_btnTrySGNode = self:findChild("Node_Btn_Try_SG")
    self.m_offerEffectNode = self:findChild("Node_KuangSG")
    -- 按钮
    self.m_btnTry = self:findChild("Button_try")

    -- offer
    self.m_winNode = self:findChild("Node_win")
    self.m_offerNode = self:findChild("Node_offer")
    self.m_txtCurrent = self:findChild("txt_current")
    self.m_txtLeft = self:findChild("txt_left")
    local paidHighest = self:getPaidHighestNode()
    if paidHighest then
        self.m_txtHighest = self:findChild("txt_highest")
    end
    self.m_offerSps = {}
    for i = 1, globalData.constantData.MEGACASH_PLAY_TIMES do
        local sp_offser = self:findChild("sp_offer_" .. i)
        if sp_offser then
            self.m_offerSps[i] = sp_offser
        end
    end

    self.m_effectNodesList = self:getEffectNodes()

    self:initEffectNodes()
    self:initCurtainSpine()
    self:initRollNodes()
end

-- 初始化特效节点
function CashMoneyBaseLayer:initEffectNodes()
    -- 滚动特效
    self.m_rollAnima = util_createAnimation(self.m_effectNodesList.CashMoney_Roll, true)
    self.m_rollEffectNode:addChild(self.m_rollAnima)
    self.m_rollAnima:playAction("an", true, nil, 30)
    -- LOGO扫光特效
    self.m_logoSG = util_createAnimation(self.m_effectNodesList.CashMoney_SG_Logo, true)
    self.m_LogoEffectNode:addChild(self.m_logoSG)
    self.m_logoSG:playAction("roll", true)
    self.m_logoSG:setVisible(false)
    -- 按钮扫光特效
    self.m_btnTrySG = util_createAnimation(self.m_effectNodesList.Cashmoney_SG_Try, true)
    self.m_btnTrySGNode:addChild(self.m_btnTrySG)
    self.m_btnTrySG:playAction("roll", true)
    self.m_btnTrySG:setVisible(false)

    if self.m_btnTakeSGNode then
        self.m_btnTakeSG = util_createAnimation(self.m_effectNodesList.Cashmoney_SG_Take, true)
        self.m_btnTakeSGNode:addChild(self.m_btnTakeSG)
        self.m_btnTakeSG:playAction("roll", true)
        self.m_btnTakeSG:setVisible(false)
    end

    if self.m_btnTryAgainSGNode then
        self.m_btnTryAgainSG = util_createAnimation(self.m_effectNodesList.Cashmoney_SG_Try, true)
        self.m_btnTryAgainSGNode:addChild(self.m_btnTryAgainSG)
        self.m_btnTryAgainSG:playAction("roll", true)
        self.m_btnTryAgainSG:setVisible(false)
    end

    -- 中间扫光特效
    self.m_offerSG = util_createAnimation(self.m_effectNodesList.CashMoney_SG_Kuang, true)
    self.m_offerEffectNode:addChild(self.m_offerSG)
    self.m_offerSG:playAction("roll", true)
    self.m_offerSG:setVisible(false)
end

function CashMoneyBaseLayer:initRollNodes(_configList)
    self.m_rollMainNodes = {}
    self.m_rollCsbs = {}
    local rollList = self:getRollNode()
    local path = self:getResPath()
    local configList = _configList or self:getConfig()
    if rollList then
        for i = 1, #rollList do
            self.m_rollMainNodes[i] = self:findChild(rollList[i])

            self.m_rollCsbs[i] = util_createAnimation(path .. rollList[i] .. ".csb", true)
            local lb = self.m_rollCsbs[i]:findChild("lb_num")
            if #configList ~= 0 then
                lb:setString(configList[i])
            end
            self.m_rollMainNodes[i]:addChild(self.m_rollCsbs[i])
        end
    end
end

-- 初始化帘子动效
function CashMoneyBaseLayer:initCurtainSpine()
    self.m_curtainBgSpine = util_spineCreate("Hourbonus_new3/spine/CashBonus_lianzi", false, true, 1)
    self.m_curtainLeftSpine = util_spineCreate("Hourbonus_new3/spine/CashBonus_lianzi2", false, true, 1)
    self.m_curtainRightSpine = util_spineCreate("Hourbonus_new3/spine/CashBonus_lianzi2", false, true, 1)
    self.m_curtainTopSpine = util_spineCreate("Hourbonus_new3/spine/CashBonus_lianzi3", false, true, 1)
    self.m_lianziBgNode:addChild(self.m_curtainBgSpine)
    self.m_lianziLeftNode:addChild(self.m_curtainLeftSpine)
    self.m_lianziRightNode:addChild(self.m_curtainRightSpine)
    self.m_lianziTopNode:addChild(self.m_curtainTopSpine)

    self.m_lianziLeftNode:setScaleX(-1)

    util_spinePlay(self.m_curtainBgSpine, "idleframe", true)
    util_spinePlay(self.m_curtainLeftSpine, "idleframe", true)
    util_spinePlay(self.m_curtainRightSpine, "idleframe", true)
    util_spinePlay(self.m_curtainTopSpine, "idleframe", true)
end

function CashMoneyBaseLayer:playSpine(type, spineEndCallFunc)
    if type == "Enter" then
        util_spinePlay(self.m_curtainTopSpine, "animation2", false)
        util_spineEndCallFunc(
            self.m_curtainTopSpine,
            "animation2",
            function()
                util_spinePlay(self.m_curtainTopSpine, "idleframe", true)
            end
        )
        util_spinePlay(self.m_curtainLeftSpine, "animation2", false)
        util_spineEndCallFunc(
            self.m_curtainLeftSpine,
            "animation2",
            function()
                util_spinePlay(self.m_curtainLeftSpine, "idleframe", true)
            end
        )
        util_spinePlay(self.m_curtainRightSpine, "animation2", false)
        util_spineEndCallFunc(
            self.m_curtainRightSpine,
            "animation2",
            function()
                util_spinePlay(self.m_curtainRightSpine, "idleframe", true)
            end
        )
        util_spinePlay(self.m_curtainBgSpine, "animation2", false)
        util_spineEndCallFunc(
            self.m_curtainBgSpine,
            "animation2",
            function()
                if spineEndCallFunc then
                    spineEndCallFunc()
                end
            end
        )
    elseif type == "Exit" then
        util_spinePlay(self.m_curtainBgSpine, "animation", false)

        performWithDelay(
            self,
            function()
                util_spinePlay(self.m_curtainTopSpine, "animation3", false)
                util_spinePlay(self.m_curtainLeftSpine, "animation3", false)
                util_spinePlay(self.m_curtainRightSpine, "animation3", false)
                util_spinePlay(self.m_curtainBgSpine, "animation2", false)
                util_spineEndCallFunc(
                    self.m_curtainBgSpine,
                    "animation2",
                    function()
                        if spineEndCallFunc then
                            spineEndCallFunc()
                        end
                    end
                )
            end,
            1.5
        )
    end
end

return CashMoneyBaseLayer
