var terminalSingelton = null;

var Rutty = function(argv, terminal) {

  this.terminalForm = terminal;
  this.socket = terminal.dataset.socket;
  this.consoleUid = terminal.dataset.console;
  
  //this.socket = socket;
  //this.consoleUid = consoleUid;

  this.argv_ = argv;

  this.io = null;

  this.sendingSweep = null;
  this.pendingString = [];

  this.sendingResize = null;
  this.pendingResize = [];

  /*
  this.source = new EventSource(this.terminalForm.action + '?socket=' + this.socket); //TODO: fix socket params passing, put in session somehow

  this.source.onopen = function(event) {
  //this.io.showOverlay("wtf", 100000);
  */

    //this.io.terminal_.reset(); //TODO: resume, needs to keep some buffer

  /*
  }.bind(this);

  this.source.onmessage = function(event) {
    var msg = JSON.parse(event.data);

    if (msg.raw && msg.raw.length > 0) { // see: https://github.com/flori/json for discussion on `to_json_raw_object`
      var decoded = '';
      for (var i=0; i<msg.raw.length; i++) {
        //NOTE: what is the difference here?
        decoded += String.fromCodePoint(msg.raw[i]); // & 0xff ??
        //decoded += String.fromCharCode(msg.raw[i]); // & 0xff ??
      }

      this.io.writeUTF16(decoded);
  */
      

  /*
    }
  }.bind(this);

  this.source.onerror = function(e) {
    this.source.close();
    this.io.writeUTF16("\nStream close...");
    this.connected = false;
  }.bind(this);
  */

  this.connected = true;
};

Rutty.prototype.run = function() {
  this.io = this.argv_.io.push();

  this.io.onVTKeystroke = this.sendString_.bind(this);
  this.io.sendString = this.sendString_.bind(this);
  this.io.onTerminalResize = this.onTerminalResize.bind(this);

  //!!!!
  //this.io.terminal_.reset(); //TODO: resume, needs to keep some buffer
  //this.io.writeUTF16("wtf");

};

Rutty.prototype.sendString_ = function(str) {
  if (!this.connected) {
    return;
  }

  if (this.sendingSweep === null) {
    this.sendingSweep = true;

    /*
    var oReq = new XMLHttpRequest();
    oReq.onload = function(e) {
    */

      //console.log("sending", str);

      this.sendingSweep = null;
      if (this.pendingString.length > 0) {
        var joinedPendingStdin = this.pendingString.join('');
        this.pendingString = [];
        this.sendString_(joinedPendingStdin);
      }

    /*
    }.bind(this);
    oReq.onerror = function(e) {
      this.source.close();
      //this.io.writeUTF16("\ndisconnected..");
      this.connected = false;
    }.bind(this);

    var formData = new FormData();
    var in_d = JSON.stringify({data: str});
    formData.append("in", in_d);
    formData.append("socket", this.socket);
    //formData.append("console", this.consoleUid);
    formData.append(document.querySelector("meta[name='csrf-param']").content, document.querySelector("meta[name='csrf-token']").content)
    oReq.open("POST", this.terminalForm.action + "/stdin", true);
    oReq.send(formData);
    */
  } else {
    this.pendingString.push(str);
  }
};

Rutty.prototype.onTerminalResize = function(cols, rows) {
  if (!this.connected || !this.consoleUid) {
    return;
  }

  if (this.sendingResize) {
    //clearTimeout(this.sendingResize);
    //this.sendingResize.abort();
    this.pendingResize.push([cols, rows]);
  } else {
    
    /*
    var oReq = new XMLHttpRequest();
    oReq.onload = function(e) {
    */

      this.sendingResize = null;
      if (this.pendingResize.length > 0) {
        var lastResize = this.pendingResize.pop();
        this.pendingResize = [];
        this.onTerminalResize(lastResize[0], lastResize[1]); // only send the latest pendingResize
      }

    /*
    }.bind(this);

    var formData = new FormData();
    formData.append("rows", rows);
    formData.append("cols", cols);
    formData.append("socket", this.socket); //TODO: figure out socket params passing, use session
    formData.append(document.querySelector("meta[name='csrf-param']").content, document.querySelector("meta[name='csrf-token']").content)
    oReq.open("POST", this.terminalForm.action + "/resize", true);
    oReq.send(formData);

    this.sendingResize = oReq;
    */
  }
};

var initTerminal = function(command, terminalElement) {
    var child = null;
    while(terminalElement.firstChild) {
      child = terminalElement.removeChild(terminalElement.firstChild);
    }

    var term = null;
    var ws = null;

    lib.init(function() {
      terminalSingelton = term = new hterm.Terminal();
      term.decorate(terminalElement);

      //term.setWidth(120);
      //term.setHeight(14);

      term.setCursorPosition(0, 0);
      term.setCursorVisible(true);
      term.prefs_.set('ctrl-c-copy', true);
      term.prefs_.set('use-default-window-copy', true);

      var aRutty = function(argv) {
        return new Rutty(argv, terminalElement);
      };

      term.runCommandClass(aRutty);

      term.command.onTerminalResize(
        term.screenSize.width,
        term.screenSize.height
      );
    });
};

window.addEventListener('load', function(documentLoadedEvent) {
  var terminal = document.getElementById("terminal");
  initTerminal("htop", terminal);

  
  /*
  var terminals = document.getElementsByClassName("terminal");

  for (var i=0; i<terminals.length; i++) {
    var terminal = terminals[i];
    initTerminal(terminal);
  }
  */

  /*
  var forms = document.getElementsByTagName('form'); 
  for (var f=0; f<forms.length; f++) {
    var form = forms[f];
    form.onsubmit = function(ev) {
      if (form.submitted) {
        ev.preventDefault();
      } else {
        form.submitted = true;
      }
    };
  }
  */
});

var terminalReady = function() {
  if (terminalSingelton) {
    return "ready";
  } else {
    return null;
  }
};

var appendStdout = function(str) {
  terminalSingelton.io.writeUTF16(str);
  return "wtf";
};
