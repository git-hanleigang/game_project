System.register(["__unresolved_0", "cc", "__unresolved_1", "__unresolved_2"], function (_export, _context) {
  "use strict";

  var _reporterNs, _cclegacy, __checkObsolete__, __checkObsoleteInNamespace__, _decorator, Component, Button, Singleton, reelRoll, _dec, _class, _crd, ccclass, property, machine;

  function _reportPossibleCrUseOfSingleton(extras) {
    _reporterNs.report("Singleton", "./Singleton", _context.meta, extras);
  }

  function _reportPossibleCrUseOfreelRoll(extras) {
    _reporterNs.report("reelRoll", "./reelRoll", _context.meta, extras);
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
    }, function (_unresolved_3) {
      reelRoll = _unresolved_3.reelRoll;
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
        constructor(...args) {
          super(...args);
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
          this.buttonStop = this.node.getChildByName("stopBtn").getComponent(Button); //设置当前列

          for (let index = 0; index < this.colNum; index++) {
            let rollNode = this.getReelRoll(index);
            let scrip = rollNode.getComponent(_crd && reelRoll === void 0 ? (_reportPossibleCrUseOfreelRoll({
              error: Error()
            }), reelRoll) : reelRoll);
            scrip.setReelIndex(index);
          } //初始化按钮状态


          this.setBtnState(true, false);
        }

        update(deltaTime) {}

        callback(event, costomEventData) {
          let button = event.target;
          let buttonName = button.name;

          if (buttonName == "spinBtn") {
            console.log("开始spin");
            this.startSpin();
          } else if (buttonName == "stopBtn") {
            console.log("停止stop");
            this.stopSpin(true);
          }
        }

        getReelRoll(index) {
          let reelNode = this.node.getChildByName("Mask").getChildByName("reel_" + index);
          return reelNode;
        }

        startSpin() {
          this.stopIndex = 0;

          for (let index = 0; index < this.colNum; index++) {
            let rollNode = this.getReelRoll(index);
            let reelScript = rollNode.getComponent(_crd && reelRoll === void 0 ? (_reportPossibleCrUseOfreelRoll({
              error: Error()
            }), reelRoll) : reelRoll);
            reelScript.beginReel();
          }

          this.setBtnState(false, true);
        }

        reelStopFunc(index) {
          this.stopIndex = this.stopIndex + index;

          if (this.stopIndex >= this.colNum) {
            this.stopSpin(false);
            this.setBtnState(true, false);
          }
        }

        stopSpin(isQuickStop) {
          for (let index = 0; index < this.colNum; index++) {
            let rollNode = this.getReelRoll(index);
            let reelScript = rollNode.getComponent(_crd && reelRoll === void 0 ? (_reportPossibleCrUseOfreelRoll({
              error: Error()
            }), reelRoll) : reelRoll);
            reelScript.quickStop = isQuickStop;
          }

          this.setBtnState(true, false);
        }

        setBtnState(spinBtnState, stopBtnState) {
          this.buttonSpin.interactable = spinBtnState;
          this.buttonStop.interactable = stopBtnState;
        }

      }) || _class));

      _cclegacy._RF.pop();

      _crd = false;
    }
  };
});
//# sourceMappingURL=9422b45237b05c41d49a34e95ad998ed337432ec.js.map