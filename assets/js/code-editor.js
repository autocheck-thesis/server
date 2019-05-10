export function create_code_editor(target) {
  if (target) {
    (async function() {
      const monaco = await import(
        /* webpackChunkName: "editor" */ "monaco-editor/esm/vs/editor/editor.api.js"
      );
      // await import("monaco-editor/esm/vs/editor/browser/controller/coreCommands.js");

      const { registerRulesForLanguage } = await import(
        /* webpackChunkName: "ace-tokener" */ "monaco-ace-tokenizer"
      );
      const { default: ElixirHighlightRules } = await import(
        /* webpackChunkName: "ace-tokener-elixir" */

        "monaco-ace-tokenizer/lib/ace/definitions/elixir"
      );

      monaco.languages.register({ id: "elixir" });
      registerRulesForLanguage("elixir", new ElixirHighlightRules());

      const configuration_form = document.getElementById("configuration-form");
      const dsl_input = configuration_form.elements["dsl"];

      const editor = monaco.editor.create(target, {
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
}
