System.register(["cc"], function (_export, _context) {
  "use strict";

  var _cclegacy, Singleton, _crd;

  _export("default", void 0);

  return {
    setters: [function (_cc) {
      _cclegacy = _cc.cclegacy;
    }],
    execute: function () {
      _crd = true;

      _cclegacy._RF.push({}, "0352eXDmUpGLJ6ivnCso0mp", "Singleton", undefined);

      _export("default", Singleton = class Singleton {
        constructor() {
          this.machineScript = null;
          this.rollList = [[0, 1, 2, 3, 4, 5, 6, 7, 8, 90, 92], // col_1
          [0, 1, 2, 3, 4, 5, 6, 7, 8, 90, 92], // col_2
          [0, 1, 2, 3, 4, 5, 6, 7, 8, 90, 92], // col_3
          [0, 1, 2, 3, 4, 5, 6, 7, 8, 90, 92], // col_4
          [0, 1, 2, 3, 4, 5, 6, 7, 8, 90, 92] // col_5
          ];
          this.reelColAndRow = [3, // col_1 行数
          3, // col_2 行数
          3, // col_3 行数
          3, // col_4 行数
          3 // col_5 行数
          ];
          this.bigSymbols = [{
            key: 94,
            value: 3
          }];
        }

        static getInstance() {
          if (!this.instance) {
            this.instance = new Singleton();
          }

          return this.instance;
        }

        setMachineScript(script) {
          this.machineScript = script;
        }

        getRandomInt(min, max) {
          return Math.floor(Math.random() * (max - min) + min);
        }

        checkIsSameKey(dictionary, currKey) {
          for (let i = 0; i < dictionary.length; i++) {
            let info = dictionary[i];
            let key = info.key;
            let value = info.value;

            if (currKey && currKey == key) {
              return true;
            }
          }

          return false;
        }

        getBigRow(currKey) {
          for (let i = 0; i < this.bigSymbols.length; i++) {
            let info = this.bigSymbols[i];
            let key = info.key;
            let value = info.value;

            if (currKey && currKey == key) {
              return value;
            }
          }

          return null;
        }

      });

      Singleton.instance = void 0;

      _cclegacy._RF.pop();

      _crd = false;
    }
  };
});
//# sourceMappingURL=9ae44005044391bdbcb1d33feb818c5f0d515404.js.map