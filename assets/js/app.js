// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.css";

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html";

// Import local files
//
// Local files can be imported directly using relative paths, for example:
// import socket from "./socket"

import LiveSocket from "phoenix_live_view";

const is_in_iframe = window !== window.parent;

if (is_in_iframe) {
  document.body.classList.add("iframe");
}

let liveSocket = new LiveSocket("/live");
liveSocket.connect();

const target = document.querySelector("#log code");

if (target) {
  window.logObserver = new MutationObserver(function(mutationsList, observer) {
    // const lastMutation = mutationsList[mutationsList.length - 1];
    // const lastNode =
    //   lastMutation.addedNodes[lastMutation.addedNodes.length - 1];
    // lastNode.scrollIntoView({ behavior: "smooth", block: "end" });

    target.scrollTop = target.scrollHeight;
  });

  window.logObserver.observe(target, {
    attributes: false,
    childList: true,
    subtree: true
  });

  console.log("Observing");

  target.scrollTop = target.scrollHeight;
}

const code_editor = document.getElementById("code-editor");

if (code_editor) {
  (async function() {
    const monaco = await import("monaco-editor/esm/vs/editor/editor.api.js");
    // await import("monaco-editor/esm/vs/editor/browser/controller/coreCommands.js");

    const { registerRulesForLanguage } = await import("monaco-ace-tokenizer");
    const { default: ElixirHighlightRules } = await import(
      "monaco-ace-tokenizer/lib/ace/definitions/elixir"
    );

    monaco.languages.register({ id: "elixir" });
    registerRulesForLanguage("elixir", new ElixirHighlightRules());

    const configuration_form = document.getElementById("configuration-form");
    const dsl_input = configuration_form.elements["dsl"];

    const editor = monaco.editor.create(code_editor, {
      value: dsl_input.value,
      language: "elixir",
      minimap: {
        enabled: false
      },
      scrollBeyondLastLine: false
    });

    function debounce(func, wait, immediate) {
      var timeout;
      return function() {
        var context = this,
          args = arguments;
        var later = function() {
          timeout = null;
          if (!immediate) func.apply(context, args);
        };
        var callNow = immediate && !timeout;
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
        if (callNow) func.apply(context, args);
      };
    }

    const validate_configuration = debounce(() => {
      const form_data = new FormData();
      form_data.append("configuration", editor.getValue());
      fetch("/assignment/validate_configuration", {
        method: "POST",
        body: form_data
      })
        .then(res => res.text())
        .then(text => console.log(text));
    }, 2000);

    editor.onDidChangeModelContent(e => validate_configuration());

    configuration_form.addEventListener("submit", e => {
      dsl_input.value = editor.getValue();
      // console.log(dsl_input.value, code_editor.innerText);
    });
  })();
}
