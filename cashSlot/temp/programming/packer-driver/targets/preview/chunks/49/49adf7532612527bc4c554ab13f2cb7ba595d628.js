System.register(["__unresolved_0", "cc", "__unresolved_1"], function (_export, _context) {
  "use strict";

  var _reporterNs, _cclegacy, __checkObsolete__, __checkObsoleteInNamespace__, _decorator, Component, Button, Singleton, _dec, _class, _crd, ccclass, property, machine;

  function _reportPossibleCrUseOfSingleton(extras) {
    _reporterNs.report("Singleton", "./Singleton", _context.meta, extras);
  }

  return {
    setters: [function (_unresolved_) {
      _reporterNs = _unresolved_;
    }, function (_cc) {
      _cclegacy = _cc.cclegacy;
      __checkObsolete__ = _cc.__checkObsolete__;
      __checkObsoleteInNamespace__ = _cc.__checkObsoleteInNamespace__;
      _decorator = _cc._decorator;
      Component = _cc.Component;
      Button = _cc.Button;
    }, function (_unresolved_2) {
      Singleton = _unresolved_2.default;
    }],
    execute: function () {
      _crd = true;

      _cclegacy._RF.push({}, "d17098Xu5VJjbsGZFnZPY0l", "machine", undefined);

      __checkObsolete__(['_decorator', 'Component', 'Event', 'Node', 'Button', 'EventHandler']);

      ({
        ccclass,
        property
      } = _decorator);

      _export("machine", machine = (_dec = ccclass('machine'), _dec(_class = class machine extends Component {
        constructor() {
          super(...arguments);
          this.singleton = (_crd && Singleton === void 0 ? (_reportPossibleCrUseOfSingleton({
            error: Error()
          }), Singleton) : Singleton).getInstance();
          this.buttonSpin = null;
          this.buttonStop = null;
          this.colNum = null;
          // 行配置
          this.stopIndex = null;
        }

        // 行停止计数
        start() {
          this.colNum = this.singleton.reelColAndRow.length;
          this.singleton.setMachineScript(this);
          this.buttonSpin = this.node.getChildByName("spinBtn").getComponent(Button);
          this.buttonStop = this.node.getChildByName("stopBtn").getComponent(Button);
        }

        update(deltaTime) {}

        callback(event, costomEventData) {
          var button = event.target;
          var buttonName = button.name;

          if (buttonName == "spinBtn") {
            console.log("停止stop");
          } else if (buttonName == "spinBtn") {
            console.log("开始spin");
            this.startSpin();
          }
        }

        getReelRoll(index) {}

        startSpin() {
          this.stopIndex = 0;

          for (var i = 0; i < this.colNum; i++) {
            var roll = this.getReelRoll(i);
          }
        }

      }) || _class));

      _cclegacy._RF.pop();

      _crd = false;
    }
  };
});
//# sourceMappingURL=49adf7532612527bc4c554ab13f2cb7ba595d628.js.map