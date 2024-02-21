local BaseView = util_require("base.BaseView")
local BaseStoreTitle = class("BaseStoreTitle", BaseView)

BaseStoreTitle.m_titleIndex = nil
BaseStoreTitle.m_lastTitleIndex = nil

local TITLE_RES_NAME = "SHOP_TITLE"
local TITLE_UPDATE_TIME = 2.5

-- 子类重写
function BaseStoreTitle:getTitleResPath()
    return "shop_title/"
end

-- 子类重写
-- 添加配置注意
-- 商城标题的优先级，按照从上向下的优先级排的，每次新加需要向策划询问优先级
function BaseStoreTitle:getTitleInfos()
    return {
        {handler(self, self.getShowNormalTitle), "NormalTitle"}
    }
end

function BaseStoreTitle:ctor()
    BaseStoreTitle.super.ctor(self)
    self:initView()
end

function BaseStoreTitle:initView()
    self.m_titleInfos = self:getTitleInfos()
    self.m_titleIndex = #self.m_titleInfos --初始化 默认title index
    self.m_lastTitleIndex = 0
    self.m_buySuccess = false -- 是否购买成功

    -- 实时更新游戏状态
    self:updateShopTitleInfo()
    -- 计时器
    if self.m_updateAction then
        self:stopAction(self.m_updateAction)
        self.m_updateAction = nil
    end
    self.m_updateAction =
        schedule(
        self,
        function()
            self:updateShopTitleInfo()
        end,
        TITLE_UPDATE_TIME
    )
end

function BaseStoreTitle:updateShopTitleInfo()
    self.m_shopDats = globalData.shopRunData:getShopItemDatas()
    self.m_luckySpinLevel = globalData.shopRunData:getLuckySpinLevel()

    for i = 1, #self.m_titleInfos do
        local titleInfo = self.m_titleInfos[i]
        local refName = titleInfo[4]
        if titleInfo[1](refName) then
            self.m_titleIndex = i
            if self.m_titleIndex ~= self.m_lastTitleIndex then
                self:changeTilteRes(titleInfo)
            else
                -- 如果当前title index 没有变化,但是发生了购买行为,需要重新刷新一次当前标题
                if self.m_buySuccess then
                    self.m_buySuccess = nil
                    self:changeTilteRes(titleInfo)
                end
            end
            break
        end
    end
end

function BaseStoreTitle:changeTilteRes(titleInfo)
    self:removeChildByName(TITLE_RES_NAME)
    local titlePath = nil
    if globalData.slotRunData.isPortrait == true then
        titlePath = titleInfo[2] .. "_Portrait.csb"
    else
        titlePath = titleInfo[2] .. ".csb"
    end
    local titleNode = util_createAnimation(self:getTitleResPath() .. titlePath)
    util_setCascadeOpacityEnabledRescursion(titleNode, true)
    titleNode:setName(TITLE_RES_NAME)
    self:addChild(titleNode)

    local func = titleInfo[3]
    if func then
        func(titleNode)
    end

    self.m_lastTitleIndex = self.m_titleIndex
end

function BaseStoreTitle:onEnter()
    -- 注册一个购买完毕的监听 用来处理商城活动刷新标题内容
    gLobalNoticManager:addObserver(
        self,
        function(params)
            if not tolua.isnull(self) then
                self.m_buySuccess = true
            end
        end,
        ViewEventType.NOTIFY_BUYTIP_CLOSE
    )
end

function BaseStoreTitle:onExit()
    if self.m_updateAction then
        self:stopAction(self.m_updateAction)
        self.m_updateAction = nil
    end
    gLobalNoticManager:removeAllObservers(self)
end

return BaseStoreTitle
