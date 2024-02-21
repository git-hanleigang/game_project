--
--版权所有:{company}
-- Author:{author}
-- Date: 2019-05-09
--
local NovicePopupItemConfig = class("NovicePopupItemConfig")

function NovicePopupItemConfig:ctor()
    self.id = nil --弹窗id
    self.type = nil --弹窗类型
    self.desc = nil --描述
    self.leftLevel = nil --最小等级
    self.rightLevel = nil --最大等级
    self.time = nil --间隔时间
    self.fb = nil --是否为fb用户  0:非  1:是  -1:都可以
    self.vType = nil --弹出位置
    self.zOrder = nil --优先级
    self.zOrder1 = nil --优先级,同一优先级只显示一个
    self.luaName = nil --程序引用名
    self.pathCsbName = nil --资源路径
    self.hotPriority = nil --资源路径
    self.open = 1
    -- self.hallPriority = nil --展示图优先级
    -- self.hallShow = nil --是否显示展示图 如果为0不显示
    -- self.slidShow = nil --是否显示轮播图 如果为0不显示
    -- self.loginShow = nil --登录是否显示 如果为0不显示
    --开启状态  （发过来的数据，都是开启的）
end

function NovicePopupItemConfig:parseData(data)
    self.id = data.popupId
    self.type = data.type
    self.desc = data.description
    self.leftLevel = data.levelMin or 1
    self.rightLevel = data.levelMax or -1
    self.time = data.weekDays
    -- self.fb = data.facebook
    self.pos = PushViewPosType.LoginToLobby
    self.zOrder = data.priority or 0
    self.zOrder1 = data.secondPriority or 0
    self.luaName = data.activityName
    self.pathCsbName = data.popupImage
    -- if data.hotPriority then
    --     self.hotPriority = data.hotPriority
    -- end
    self.cd = data.cd or 0
end

-- 弹板活动名
function NovicePopupItemConfig:getRefName()
    return self.luaName
end

-- 首要优先
function NovicePopupItemConfig:getPriority()
    return self.zOrder
end

function NovicePopupItemConfig:setPriority(order)
    self.zOrder = order
end

-- 次级优先
function NovicePopupItemConfig:getSecondPriority()
    return self.zOrder1
end

-- 点位类型
function NovicePopupItemConfig:getPosType()
    return self.pos
end

-- 获得弹板类型
function NovicePopupItemConfig:getPopType()
    return self.type
end

-- 获得弹板ID
function NovicePopupItemConfig:getPopUpId()
    return self.id
end

function NovicePopupItemConfig:getCdSecs()
    return self.cd
end

-- 获得资源路径
function NovicePopupItemConfig:getCsbPath()
    return self.pathCsbName
end

return NovicePopupItemConfig
