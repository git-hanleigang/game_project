--[[
    服务器配置
    author:{author}
    time:2021-11-07 13:57:14
]]
-- 资源模式
GD.ResMode = {
    -- 正式服
    Online = {
        key = "Online",
        name = "正式服资源"
    },
    -- 上线服
    Release = {
        key = "Release",
        name = "上线服资源"
    },
    -- 上线服备用
    ReleaseB = {
        key = "ReleaseB",
        name = "上线服备用"
    },
    -- 预发布
    Beta = {
        key = "Beta",
        name = "预发布资源"
    },
    -- 测试服
    Alpha = {
        key = "Alpha",
        name = "测试服资源"
    },
    -- 换图服
    Uploader = {
        key = "Uploader",
        name = "换图服资源"
    }
}

-- 链接模式
GD.LinkMode = {
    Online = {
        key = "Online",
        name = "正式服",
        resModes = {"Online"}
    },
    -- 广域网 link 局域网
    W2L = {
        key = "W2L",
        name = "外网",
        resModes = {"Alpha", "Beta", "Release"}
    },
    -- 局域网 link 局域网
    L2L = {
        key = "L2L",
        name = "内网",
        resModes = {"Alpha", "Beta", "Release", "Online", "Uploader", "ReleaseB"}
    }
}

-- 链接配置配置
GD.LinkConfig = {
    -- 正式服
    Online = {
        -- 入口服务器地址
        -- gateUrl = "https://apinew.topultragame.com/support",
        -- 数据地址
        dataUrl = "https://apinew.topultragame.com/support",
        -- 机器人头像
        robotDlUrl = "https://res.topultragame.com/Robot",
        -- 默认地址
        logRecordUrl = "https://log.topultragame.com/collector/v1"
    },
    -- 开发服局域网
    L2L = {
        -- 入口服务器地址
        -- gateUrl = "http://192.168.1.70",
        -- 数据地址
        dataUrl = "http://192.168.1.62",
        -- 机器人头像
        robotDlUrl = "http://192.168.1.150/SlotNewRes/SlotCashLink_Test/Robot",
        -- 默认地址
        logRecordUrl = "http://192.168.1.51:80/v1/log"
    },
    -- 开发服广域网连局域网
    W2L = {
        -- 入口服务器地址
        -- gateUrl = "http://106.120.89.238:23070",
        -- 数据地址
        dataUrl = "http://106.120.89.238",
        dataPort = 23062,
        -- 资源地址
        resUrl = "http://ctres.xcyy.org",
        resPort = 50150,
        -- 机器人头像
        robotDlUrl = "http://106.120.89.238:23150/SlotNewRes/SlotCashLink_Test/Robot",
        -- 默认地址
        logRecordUrl = "http://106.120.89.238:23051/v1/log"
    }
}
